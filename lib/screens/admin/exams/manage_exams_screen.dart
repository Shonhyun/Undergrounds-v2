import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/admin/exams/manage_exam_questions_screen.dart';
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class ManageExamsPage extends StatefulWidget {
  final String subject;
  const ManageExamsPage({super.key, required this.subject});

  @override
  ManageExamsPageState createState() => ManageExamsPageState();
}

class ManageExamsPageState extends State<ManageExamsPage> {
  final List<Map<String, String>> exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  void _fetchExams() async {
    setState(() {
      _isLoading = true;
    });

    final examSnapshot =
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subject.toLowerCase())
            .collection('exams')
            .orderBy('createdAt', descending: false)
            .get();

    setState(() {
      exams.clear();
      for (var doc in examSnapshot.docs) {
        exams.add({'examTitle': doc['examTitle'], 'examId': doc.id});
      }
      _isLoading = false;
    });
  }

  void _addExam() {
    TextEditingController examController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    int selectedHours = 0;
    int selectedMinutes = 30;
    bool isFree = false;

    showDialog(
      context: context,
      builder: (context) {
        bool isExamSaving = false;

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(
                  'Add New Exam',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: examController,
                        cursorColor: Colors.red,
                        decoration: InputDecoration(
                          labelText: 'Exam Title',
                          labelStyle: TextStyle(
                            color: const Color.fromARGB(255, 191, 190, 190),
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: descriptionController,
                        cursorColor: Colors.red,
                        decoration: InputDecoration(
                          labelText: 'Exam Description',
                          labelStyle: TextStyle(
                            color: const Color.fromARGB(255, 191, 190, 190),
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hours'),
                                DropdownButton<int>(
                                  value: selectedHours,
                                  items:
                                      List.generate(24, (index) => index)
                                          .map(
                                            (value) => DropdownMenuItem<int>(
                                              value: value,
                                              child: Text('$value'),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (value) => setState(
                                        () => selectedHours = value!,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Minutes'),
                                DropdownButton<int>(
                                  value: selectedMinutes,
                                  items:
                                      List.generate(60, (index) => index)
                                          .map(
                                            (value) => DropdownMenuItem<int>(
                                              value: value,
                                              child: Text('$value'),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (value) => setState(
                                        () => selectedMinutes = value!,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text('Is this exam free?'),
                        value: isFree,
                        onChanged: (value) {
                          setState(() {
                            isFree = value;
                          });
                        },
                        secondary: const Icon(Icons.lock_open),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (examController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty) {
                        setState(() {
                          isExamSaving = true;
                        });

                        final totalDuration =
                            (selectedHours * 3600) + (selectedMinutes * 60);

                        await _addExamToFirestore(
                          examController.text,
                          descriptionController.text,
                          totalDuration,
                          isFree, // Pass isFree
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please add a title/description'),
                          ),
                        );
                      }
                    },
                    child:
                        isExamSaving
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                            : Text(
                              'Add',
                              style: TextStyle(color: Colors.black),
                            ),
                  ),
                ],
              ),
        );
      },
    );
  }

  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print("Failed to delete image from storage: $e");
    }
  }

  Future<void> _addExamToFirestore(
    String examTitle,
    String examDescription,
    int timeLimit,
    bool isFree, // Added isFree parameter
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.toLowerCase())
          .collection('exams')
          .add({
            'examTitle': examTitle,
            'examDescription': examDescription,
            'timeLimit': timeLimit,
            'createdAt': FieldValue.serverTimestamp(),
            'isFree': isFree, // Added isFree field
          });

      if (mounted) {
        _fetchExams();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add exam: $e')));
      }
    }
  }

  void _deleteExam(String examId) async {
    try {
      final questionsRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.toLowerCase())
          .collection('exams')
          .doc(examId)
          .collection('questions');

      final questionSnapshots = await questionsRef.get();

      // Delete images and question documents
      for (final doc in questionSnapshots.docs) {
        final data = doc.data();

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
        await doc.reference.delete();
      }

      // Now delete the exam document
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject.toLowerCase())
          .collection('exams')
          .doc(examId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exam removed successfully')));
        _fetchExams();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete exam: $e')));
      }
    }
  }

  void _editExamDialog(Map<String, String> exam) async {
    final examId = exam['examId']!;
    final docRef = FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subject.toLowerCase())
        .collection('exams')
        .doc(examId);

    final snapshot = await docRef.get();
    final currentData = snapshot.data();

    TextEditingController titleController = TextEditingController(
      text: currentData?['examTitle'],
    );
    TextEditingController descriptionController = TextEditingController(
      text: currentData?['examDescription'],
    );
    int totalSeconds = currentData?['timeLimit'] ?? 0;
    int selectedHours = totalSeconds ~/ 3600;
    int selectedMinutes = (totalSeconds % 3600) ~/ 60;
    bool isFree = currentData?['isFree'] ?? false; // Added isFree variable

    showDialog(
      context: context,
      builder: (context) {
        bool isExamSaving = false;

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('Edit Exam'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Exam Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Exam Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hours'),
                                DropdownButton<int>(
                                  value: selectedHours,
                                  items: List.generate(
                                    24,
                                    (index) => DropdownMenuItem(
                                      value: index,
                                      child: Text('$index'),
                                    ),
                                  ),
                                  onChanged:
                                      (value) => setState(
                                        () => selectedHours = value!,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Minutes'),
                                DropdownButton<int>(
                                  value: selectedMinutes,
                                  items: List.generate(
                                    60,
                                    (index) => DropdownMenuItem(
                                      value: index,
                                      child: Text('$index'),
                                    ),
                                  ),
                                  onChanged:
                                      (value) => setState(
                                        () => selectedMinutes = value!,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text('Is this exam free?'),
                        value: isFree,
                        onChanged: (value) {
                          setState(() {
                            isFree = value;
                          });
                        },
                        secondary: const Icon(Icons.lock_open),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed:
                        isExamSaving
                            ? null
                            : () async {
                              setState(() => isExamSaving = true);
                              int totalDuration =
                                  (selectedHours * 3600) +
                                  (selectedMinutes * 60);
                              await docRef.update({
                                'examTitle': titleController.text,
                                'examDescription': descriptionController.text,
                                'timeLimit': totalDuration,
                                'isFree': isFree, // Added isFree field
                              });
                              if (mounted) {
                                Navigator.pop(context);
                                _fetchExams();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Exam updated successfully'),
                                  ),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child:
                        isExamSaving
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                            : Text(
                              'Save',
                              style: TextStyle(color: Colors.black),
                            ),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject} Exams')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : exams.isEmpty
              ? Center(
                child: Text(
                  'No exams yet. Add one to get started.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  final exam = exams[index];
                  return ListTile(
                    title: Text(exam['examTitle']!),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editExamDialog(exam);
                        } else if (value == 'delete') {
                          _deleteExam(exam['examId']!);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        slideForward(
                          ManageQuestionsPage(
                            subject: widget.subject.toLowerCase(),
                            examId: exam['examId']!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExam,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }
}
