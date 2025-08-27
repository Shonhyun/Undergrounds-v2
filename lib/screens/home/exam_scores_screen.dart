import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:learningexamapp/screens/home/exams/exam_results_screen.dart';

class ExamScoresScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  const ExamScoresScreen({
    super.key,
    required this.userData,
    required this.onBack,
  });

  @override
  _ExamScoresScreenState createState() => _ExamScoresScreenState();
}

class _ExamScoresScreenState extends State<ExamScoresScreen> {
  late Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
  _examHistoryFuture;

  @override
  void initState() {
    super.initState();
    _examHistoryFuture = _fetchExamHistory();
  }

  // Fetch exam history
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
  _fetchExamHistory() async {
    try {
      final userId = widget.userData?['id'];
      if (userId == null) {
        throw Exception('User ID is null');
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('examHistory')
              .orderBy('timestamp', descending: true)
              .get();

      final Map<String, Map<String, List<Map<String, dynamic>>>>
      examsBySubjectAndTitle = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] ?? 'Unknown';
        final title = data['examTitle'] ?? 'Untitled Exam';

        final examAttempt = {
          'id': doc.id,
          'title': title,
          'subject': subject,
          'total': data['totalQuestions'] ?? 0,
          'score': data['correctAnswers'] ?? 0,
          'selectedAnswers': data['selectedAnswers'] ?? {},
          'questions': data['questions'] ?? [],
          'timeTaken': data['timeTaken'] ?? 0,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
        };

        examsBySubjectAndTitle.putIfAbsent(subject, () => {});
        examsBySubjectAndTitle[subject]!.putIfAbsent(title, () => []);
        examsBySubjectAndTitle[subject]![title]!.add(examAttempt);
      }

      return examsBySubjectAndTitle;
    } catch (e) {
      print('Error fetching exam scores: $e');
      return {};
    }
  }

  // Format timestamp to look like social media date style
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (timestamp.year == now.year) {
      return DateFormat('MMM d').format(timestamp); // Example: Apr 28
    } else {
      return DateFormat(
        'MMM d, yyyy',
      ).format(timestamp); // Example: Apr 28, 2023
    }
  }

  void _navigateToResultsPage(Map<String, dynamic> exam) {
    final Map<int, String> selectedAnswers = (exam['selectedAnswers']
            as Map<String, dynamic>)
        .map((key, value) => MapEntry(int.parse(key), value as String));

    final resultsForResultsScreen = {
      'totalQuestions': exam['total'],
      'correctAnswers': exam['score'],
      'selectedAnswers': selectedAnswers,
      'examTitle': exam['title'],
      'questions': exam['questions'],
      'timeTaken': exam['timeTaken'],
    };

    Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Scores'),
        leading: BackButton(onPressed: widget.onBack),
      ),
      body: FutureBuilder<Map<String, Map<String, List<Map<String, dynamic>>>>>(
        future: _examHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          }
          final categorizedExams = snapshot.data ?? {};
          if (categorizedExams.isEmpty) {
            return const Center(child: Text('No exam scores found'));
          }

          return ListView(
            children:
                categorizedExams.entries.map((subjectEntry) {
                  final subject = subjectEntry.key;
                  final examsByTitle = subjectEntry.value;

                  return ExpansionTile(
                    title: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children:
                        examsByTitle.entries.map((examEntry) {
                          final examTitle = examEntry.key;
                          final attempts = examEntry.value;

                          return ExpansionTile(
                            title: Text(
                              examTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children:
                                attempts.map((attempt) {
                                  final timestamp =
                                      attempt['timestamp'] as DateTime?;
                                  final scorePercentage = (attempt['score'] /
                                          attempt['total'] *
                                          100)
                                      .toStringAsFixed(0);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 5,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        'Attempt on ${timestamp != null ? formatTimestamp(timestamp) : 'Unknown Date'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Score: ${attempt['score']}/${attempt['total']}',
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value:
                                                attempt['score'] /
                                                attempt['total'],
                                            backgroundColor: Colors.grey[300],
                                            color: Colors.green,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Score: $scorePercentage%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                      ),
                                      onTap:
                                          () => _navigateToResultsPage(attempt),
                                    ),
                                  );
                                }).toList(),
                          );
                        }).toList(),
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
