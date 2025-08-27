import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class ManageQuestionsPage extends StatefulWidget {
  final String subject;
  final String examId;

  const ManageQuestionsPage({
    super.key,
    required this.subject,
    required this.examId,
  });

  @override
  ManageQuestionsPageState createState() => ManageQuestionsPageState();
}

class ManageQuestionsPageState extends State<ManageQuestionsPage> {
  List<Map<String, dynamic>> _questions = [];
  bool _isEditMode = false;

  void _fetchQuestions() async {
    try {
      final questionSnapshot =
          await FirebaseFirestore.instance
              .collection('subjects')
              .doc(widget.subject)
              .collection('exams')
              .doc(widget.examId)
              .collection('questions')
              .get();

      final questions =
          questionSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'question': data['question'] ?? '',
              'options': List<String>.from(data['options'] ?? ['', '', '', '']),
              'correctAnswer': data['correctAnswer'] ?? '',
              'questionImageUrl': data['questionImageUrl'] ?? '',
              'optionImageUrls': List<String>.from(
                data['optionImageUrls'] ?? List.generate(4, (_) => ''),
              ),
            };
          }).toList();

      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading questions')));
      }
    }
  }

  Future<void> _deleteQuestion(String id) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.toLowerCase())
          .collection('exams')
          .doc(widget.examId)
          .collection('questions')
          .doc(id);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        // Delete question image if it exists
        final questionImageUrl = data['questionImageUrl'] ?? '';
        if (questionImageUrl.isNotEmpty) {
          await deleteImageFromStorage(questionImageUrl);
        }

        // Delete option images if they exist
        final optionImageUrls = List<String>.from(
          data['optionImageUrls'] ?? [],
        );
        for (final imageUrl in optionImageUrls) {
          if (imageUrl.isNotEmpty) {
            await deleteImageFromStorage(imageUrl);
          }
        }

        // Delete the question document
        await docRef.delete();
      }

      _fetchQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting question')));
      }
    }
  }

  Future<String> uploadImageToStorage(
    String subjectId,
    String examId,
    String questionId,
    String fileName,
    File imageFile,
  ) async {
    try {
      final storageRef = FirebaseStorage.instance.ref(
        'files/subjects/${subjectId.toUpperCase()}/exams/$examId/$questionId/$fileName',
      );
      final uploadTask = storageRef.putFile(imageFile);
      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print("Failed to delete image from storage: $e");
    }
  }

  Future<void> _showQuestionDialog({
    Map<String, dynamic>? existingQuestion,
  }) async {
    final TextEditingController questionController = TextEditingController(
      text: existingQuestion?['question'] ?? '',
    );
    final List<TextEditingController> optionControllers = List.generate(4, (
      index,
    ) {
      return TextEditingController(
        text:
            (existingQuestion?['options'] != null &&
                    index < (existingQuestion!['options'] as List).length)
                ? existingQuestion['options'][index]
                : '',
      );
    });
    final TextEditingController correctAnswerController = TextEditingController(
      text: existingQuestion?['correctAnswer'] ?? '',
    );

    final questionImageController = TextEditingController();
    final optionImageControllers = List.generate(
      4,
      (_) => TextEditingController(),
    );

    File? questionImageFile;
    List<File?> optionImageFiles = List.generate(4, (_) => null);

    final uuid = Uuid();
    final imageId = uuid.v4();

    await showDialog(
      context: context,
      builder: (context) {
        bool _dialogIsLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                existingQuestion == null ? 'Add Question' : 'Edit Question',
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: questionController,
                      cursorColor: Colors.red,
                      decoration: InputDecoration(
                        labelText: 'Question',
                        labelStyle: TextStyle(
                          color: const Color.fromARGB(255, 191, 190, 190),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pickedFile = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setModalState(() {
                                questionImageFile = File(pickedFile.path);
                                questionImageController.text = pickedFile.name;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Upload Image'),
                        ),
                        if (questionImageController.text.isNotEmpty ||
                            (existingQuestion?['questionImageUrl'] ?? '')
                                .isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                questionImageController.clear();
                                questionImageFile = null;
                                if ((existingQuestion?['questionImageUrl'] ??
                                        '')
                                    .isNotEmpty) {
                                  deleteImageFromStorage(
                                    existingQuestion!['questionImageUrl'],
                                  );
                                  existingQuestion['questionImageUrl'] = '';
                                }
                              });
                            },
                            child: Text(
                              "Remove Image",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ...List.generate(4, (index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: optionControllers[index],
                            cursorColor: Colors.red,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              labelStyle: TextStyle(
                                color: const Color.fromARGB(255, 191, 190, 190),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final pickedFile = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setModalState(() {
                                      optionImageFiles[index] = File(
                                        pickedFile.path,
                                      );
                                      optionImageControllers[index].text =
                                          pickedFile.name;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Upload Image'),
                              ),
                              // SizedBox(width: 8),
                              if (
                                optionImageControllers[index].text.isNotEmpty ||
                                (
                                  (existingQuestion?['optionImageUrls'] !=null) &&
                                  index < (existingQuestion!['optionImageUrls'] as List).length &&
                                  (existingQuestion['optionImageUrls'][index] ?? '').isNotEmpty
                                )
                              )
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      optionImageFiles[index] = null;
                                      optionImageControllers[index].clear();

                                      final optionImageUrls = existingQuestion?['optionImageUrls'];
                                      if (optionImageUrls is List &&
                                        index < optionImageUrls.length &&
                                        optionImageUrls[index] != null &&
                                        optionImageUrls[index].toString().isNotEmpty) {
                                          deleteImageFromStorage(optionImageUrls[index],);
                                          optionImageUrls[index] = '';
                                        }          
                                    });
                                  },
                                  child: Text(
                                    'Remove Image',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                      );
                    }),
                    //SizedBox(height: 15),
                    TextField(
                      controller: correctAnswerController,
                      cursorColor: Colors.red,
                      decoration: InputDecoration(
                        labelText: 'Correct Answer',
                        labelStyle: TextStyle(
                          color: const Color.fromARGB(255, 191, 190, 190),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child:
                      _dialogIsLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text('Save', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (_dialogIsLoading) return;
                    setModalState(() => _dialogIsLoading = true);

                    final newQuestion = questionController.text.trim();
                    final newOptions =
                        optionControllers.map((c) => c.text.trim()).toList();
                    final newCorrectAnswer =
                        correctAnswerController.text.trim();

                    if (newQuestion.isEmpty ||
                        newOptions.any((opt) => opt.isEmpty) ||
                        newCorrectAnswer.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill in all fields')),
                      );
                      setModalState(() => _dialogIsLoading = false);
                      return;
                    }

                    String questionImageUrl = '';
                    if (questionImageFile != null) {
                      // Delete old image if it exists
                      if ((existingQuestion?['questionImageUrl'] ?? '')
                          .isNotEmpty) {
                        await deleteImageFromStorage(
                          existingQuestion!['questionImageUrl'],
                        );
                      }

                      questionImageUrl = await uploadImageToStorage(
                        widget.subject,
                        widget.examId,
                        existingQuestion?['id'] ?? imageId,
                        'question_image_$imageId.jpg',
                        questionImageFile!,
                      );
                    } else {
                      questionImageUrl =
                          existingQuestion?['questionImageUrl'] ?? '';
                    }

                    List<String> optionImageUrls = [];
                    for (int i = 0; i < 4; i++) {
                      if (optionImageFiles[i] != null) {
                        // Delete old option image if exists
                        final oldUrl =
                            existingQuestion?['optionImageUrls']?[i] ?? '';
                        if (oldUrl.isNotEmpty) {
                          await deleteImageFromStorage(oldUrl);
                        }

                        final optionId = uuid.v4();
                        optionImageUrls.add(
                          await uploadImageToStorage(
                            widget.subject,
                            widget.examId,
                            existingQuestion?['id'] ?? optionId,
                            'option_${i + 1}_image_$optionId.jpg',
                            optionImageFiles[i]!,
                          ),
                        );
                      } else {
                        optionImageUrls.add(
                          existingQuestion?['optionImageUrls']?[i] ?? '',
                        );
                      }
                    }

                    final data = {
                      'question': newQuestion,
                      'options': newOptions,
                      'correctAnswer': newCorrectAnswer,
                      'questionImageUrl': questionImageUrl,
                      'optionImageUrls': optionImageUrls,
                    };

                    final ref = FirebaseFirestore.instance
                        .collection('subjects')
                        .doc(widget.subject.toLowerCase())
                        .collection('exams')
                        .doc(widget.examId)
                        .collection('questions');

                    if (existingQuestion != null) {
                      await ref.doc(existingQuestion['id']).update(data);
                    } else {
                      await ref.add(data);
                    }

                    if (!mounted) return;

                    Navigator.pop(context);
                    _fetchQuestions();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Questions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() => _isEditMode = !_isEditMode);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question Bank', style: theme.textTheme.titleLarge),
            SizedBox(height: 16),
            if (_questions.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No questions yet. Add one to get started.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            if (_questions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question text
                            Text(
                              'Q${index + 1}: ${question['question']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),

                            // Question image
                            if ((question['questionImageUrl'] ?? '').isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  question['questionImageUrl'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            SizedBox(height: 12),

                            // Options
                            ...List.generate(4, (i) {
                              final optionText = question['options'][i] ?? '';
                              final optionImage =
                                  (question['optionImageUrls'] != null &&
                                          question['optionImageUrls'].length >
                                              i)
                                      ? question['optionImageUrls'][i]
                                      : '';
                              final isCorrect =
                                  question['correctAnswer']
                                      .trim()
                                      .toLowerCase() ==
                                  optionText.trim().toLowerCase();

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : Icons.radio_button_off,
                                      color:
                                          isCorrect
                                              ? Colors.green
                                              : Colors.grey,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Option ${String.fromCharCode(65 + i)}: $optionText',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  isCorrect
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color:
                                                  isCorrect
                                                      ? Colors.green[800]
                                                      : Colors.grey,
                                            ),
                                          ),
                                          if ((optionImage ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.network(
                                                  optionImage,
                                                  height: 100,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            SizedBox(height: 8),

                            // Edit/Delete buttons
                            if (_isEditMode)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed:
                                        () => _showQuestionDialog(
                                          existingQuestion: question,
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => _deleteQuestion(question['id']),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton:
          _isEditMode
              ? null
              : FloatingActionButton(
                backgroundColor: Colors.red, // Was redAccent
                onPressed: () => _showQuestionDialog(),
                child: Icon(Icons.add),
              ),
    );
  }
}
