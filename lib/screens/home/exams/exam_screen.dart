import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:learningexamapp/screens/home/exams/exam_results_screen.dart';
import 'package:learningexamapp/utils/common_widgets/NoScreenshotWrapper.dart';

class ExamScreen extends StatefulWidget {
  final String courseName;
  final String subject;
  final String examId;
  final String examTitle;
  final String examDescription;
  final int timeLimit;
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  const ExamScreen({
    super.key,
    required this.courseName,
    required this.subject,
    required this.examId,
    required this.examTitle,
    required this.examDescription,
    required this.timeLimit,
    required this.userData,
    required this.onBack,
  });

  @override
  ExamScreenState createState() => ExamScreenState();
}

class ExamScreenState extends State<ExamScreen> {
  late Timer _timer;
  int _remainingTimeInSeconds = 0;
  late List<Map<String, dynamic>> exams = [];
  Map<int, String> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _remainingTimeInSeconds = widget.timeLimit;
    _startTimer();
  }

  void _fetchQuestions() async {
    try {
      final questionSnapshot =
          await FirebaseFirestore.instance
              .collection('subjects')
              .doc(widget.subject.toLowerCase())
              .collection('exams')
              .doc(widget.examId)
              .collection('questions')
              .get();

      final questions =
          questionSnapshot.docs.map((doc) {
            final data = doc.data();

            return {
              'question': data['question'] ?? '',
              'questionImageUrl':
                  data.containsKey('questionImageUrl')
                      ? data['questionImageUrl'] ?? ''
                      : '',
              'options': List<String>.from(data['options'] ?? []),
              'optionImageUrls': List<String>.from(
                data['optionImageUrls'] ?? [],
              ),
              'correctAnswer': data['correctAnswer'] ?? '',
            };
          }).toList();

      setState(() {
        exams = questions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading questions')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTimeInSeconds > 0) {
        setState(() {
          _remainingTimeInSeconds--;
        });
      } else {
        _timer.cancel();
        _submitExam();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _submitExam() async {
    int score = 0;
    List<String> correctAnswers = [];

    // Calculate score and collect correct answers
    for (int i = 0; i < exams.length; i++) {
      correctAnswers.add(exams[i]['correctAnswer']);
      if (selectedAnswers[i] == exams[i]['correctAnswer']) {
        score++;
      }
    }

    int timeTaken = widget.timeLimit - _remainingTimeInSeconds;

    // Convert selectedAnswers keys to strings (for Firestore)
    Map<String, String> selectedAnswersStringKeys = selectedAnswers.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    // Firestore Data
    final Map<String, dynamic> resultsForFirestore = {
      'examId': widget.examId.toString(),
      'examTitle': widget.examTitle.toString(),
      'subject': widget.subject.toString(),
      'totalQuestions': exams.length,
      'correctAnswers': score,
      'selectedAnswers': selectedAnswersStringKeys,
      'timeTaken': timeTaken,
      'timestamp': FieldValue.serverTimestamp(),
      'correctAnswerKeys': correctAnswers,
      'questions':
          exams.map((question) {
            return {
              'question': question['question'],
              'questionImageUrl': question['questionImageUrl'],
              'options': question['options'],
              'optionImageUrls': question['optionImageUrls'],
              'correctAnswer': question['correctAnswer'],
            };
          }).toList(), // Ensure question and option image URLs are included
    };

    // Results Page Data
    final Map<String, dynamic> resultsForResultsScreen = {
      'totalQuestions': exams.length,
      'correctAnswers': score,
      'selectedAnswers': selectedAnswers,
      'examTitle': widget.examTitle,
      'questions': exams,
      'timeTaken': timeTaken,
    };

    try {
      final userId = widget.userData?['id'];
      if (userId == null) {
        print('Error: User ID is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User ID is null')),
          );
        }
        return;
      }

      final attemptId = const Uuid().v4();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('examHistory')
          .doc(attemptId)
          .set(resultsForFirestore);

      print('Exam attempt saved successfully!');
    } catch (e) {
      print('Error saving exam attempt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving exam attempt')),
        );
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ExamResultsScreen(
                userData: widget.userData,
                results: resultsForResultsScreen,
              ),
        ),
      );
    }
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Exam'),
          content: const Text('Are you sure you want to submit the exam?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _timer.cancel();
                _submitExam();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NoScreenshotWrapper(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          iconTheme: theme.appBarTheme.iconTheme,
          leading: BackButton(onPressed: widget.onBack),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingTimeInSeconds),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _showSubmitDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Submit"),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        widget.examTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (exams.isEmpty)
                      const Center(child: CircularProgressIndicator()),
                    if (exams.isNotEmpty)
                      ...List.generate(
                        exams.length,
                        (index) => _buildQuestion(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(int index) {
    var question = exams[index]['question'];
    var questionImageUrl = exams[index]['questionImageUrl'];
    List<String> options = exams[index]['options'];
    List<String> optionImageUrls = exams[index]['optionImageUrls'];

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (questionImageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.network(
                questionImageUrl,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          const SizedBox(height: 10),
          Column(
            children: List.generate(
              options.length,
              (i) => _buildOption(
                index,
                options[i],
                i < optionImageUrls.length ? optionImageUrls[i] : '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    int questionIndex,
    String optionText,
    String optionImageUrl,
  ) {
    bool isSelected = selectedAnswers[questionIndex] == optionText;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAnswers[questionIndex] = optionText;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.black,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.redAccent : Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(optionText, style: const TextStyle(fontSize: 16)),
                  if (optionImageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.network(
                        optionImageUrl,
                        errorBuilder:
                            (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
