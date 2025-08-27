import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/home/exams/exam_screen.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';

class ExamListScreen extends StatefulWidget {
  final String courseName;
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  const ExamListScreen({
    super.key,
    required this.courseName,
    required this.userData,
    required this.onBack,
  });

  @override
  ExamListScreenState createState() => ExamListScreenState();
}

class ExamListScreenState extends State<ExamListScreen> {
  final List<Map<String, dynamic>> exams = [];
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

    try {
      final examSnapshot =
          await FirebaseFirestore.instance
              .collection('subjects')
              .doc(widget.courseName.toLowerCase())
              .collection('exams')
              .orderBy('createdAt', descending: true)
              .get();

      final List<Map<String, dynamic>> fetchedExams = [];
      for (var doc in examSnapshot.docs) {
        // Get the document data as a Map.
        final examData = doc.data() as Map<String, dynamic>;

        // Safely retrieve isFree, defaulting to true if the field is missing.
        // The `??` operator works safely here because `examData['isFree']`
        // will return null if the key doesn't exist, which is handled correctly.
        final bool isFree = examData['isFree'] ?? false;

        fetchedExams.add({
          'examTitle': examData['examTitle'],
          'examDescription': examData['examDescription'],
          'timeLimit': examData['timeLimit'],
          'examId': doc.id,
          'isFree': isFree,
        });
      }

      setState(() {
        exams.clear();
        exams.addAll(fetchedExams);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load exams: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEnrolled =
        widget.userData?['enrollments']?[widget.courseName
            .toLowerCase()]['enrolled'] ??
        false;

    return Scaffold(
      appBar: buildAppBar(
        context,
        "${widget.courseName} - Exams",
        leading: BackButton(onPressed: widget.onBack),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : exams.isEmpty
              ? Center(
                child: Text(
                  'No exams available for this course.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  bool isFree = exams[index]['isFree'];
                  bool canAccess = isFree || isEnrolled;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.quiz,
                        color: canAccess ? Colors.green : Colors.grey,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              exams[index]['examTitle'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: canAccess ? Colors.white : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFree && !isEnrolled)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Free',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        exams[index]['examDescription'] ?? '',
                        style: TextStyle(
                          color: canAccess ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      trailing:
                          // Use a conditional to display either the 'play' icon or the 'lock' icon.
                          canAccess
                              ? const Icon(
                                Icons.play_arrow,
                                size: 20,
                                color: Colors.green,
                              )
                              : const Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                      onTap:
                          // Disable the onTap functionality if the user can't access the exam.
                          canAccess
                              ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ExamScreen(
                                          courseName: widget.courseName,
                                          subject: widget.courseName,
                                          examId: exams[index]['examId'],
                                          examTitle: exams[index]['examTitle'],
                                          examDescription:
                                              exams[index]['examDescription'],
                                          timeLimit: exams[index]['timeLimit'],
                                          userData: widget.userData,
                                          onBack: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                  ),
                                );
                              }
                              : null,
                    ),
                  );
                },
              ),
    );
  }
}
