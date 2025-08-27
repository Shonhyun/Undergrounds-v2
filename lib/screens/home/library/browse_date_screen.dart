import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:learningexamapp/utils/common_widgets/fetch_questions.dart';
import 'package:learningexamapp/utils/common_widgets/library/question_UI.dart';

class BrowseByDateScreen extends StatefulWidget {
  const BrowseByDateScreen({super.key, Map<String, dynamic>? userData});

  @override
  State<BrowseByDateScreen> createState() => _BrowseByDateScreenState();
}

class _BrowseByDateScreenState extends State<BrowseByDateScreen> {
  bool sortAscending = false;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  // We still need selectedAnswers to track the user's choice before they submit
  late List<String?> selectedAnswers;
  // answerResults is no longer needed here as feedback is on a separate page
  // and the parent doesn't need to persist the result of each attempt.

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true; // Set loading to true when fetching starts
    });

    try {
      final questions = await fetchQuestions();
      setState(() {
        _questions = questions;
        selectedAnswers = List<String?>.filled(questions.length, null);
        // answerResults initialization removed
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() {
        _isLoading = false;
        // Optionally show an error message to the user
      });
    }
  }

  List<Map<String, dynamic>> get sortedQuestions {
    List<Map<String, dynamic>> copy = [..._questions];
    copy.sort((a, b) {
      final dynamic createdAtA = a['createdAt'];
      final dynamic createdAtB = b['createdAt'];

      DateTime dateA;
      DateTime dateB;

      if (createdAtA is Timestamp) {
        dateA = createdAtA.toDate();
      } else if (createdAtA is String) {
        dateA = DateTime.parse(createdAtA);
      } else {
        dateA = DateTime(0); // Fallback for invalid or missing timestamp
      }

      if (createdAtB is Timestamp) {
        dateB = createdAtB.toDate();
      } else if (createdAtB is String) {
        dateB = DateTime.parse(createdAtB);
      } else {
        dateB = DateTime(0); // Fallback for invalid or missing timestamp
      }

      return sortAscending
          ? dateA.compareTo(dateB) // Ascending; oldest to latest
          : dateB.compareTo(dateA); // Descending; latest to oldest
    });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text("Browse by Date"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  sortAscending = !sortAscending;
                  // Re-sort the questions after toggling order
                  // No need to set _questions = sortedQuestions here, as sortedQuestions is a getter
                  // which will automatically use the new sortAscending value.
                  // However, if _questions was already a sorted list, then you would need to re-assign.
                  // For simplicity and clarity, explicitly re-fetching or re-sorting _questions might be safer if _questions
                  // is intended to hold the *currently sorted* list.
                  // For this scenario, just triggering a rebuild (setState) is enough as sortedQuestions getter will re-evaluate.
                });
              },
              icon: Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
              label: Text(
                "Sort by Date (${sortAscending ? 'Oldest' : 'Newest'})",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading ||
                          _questions
                              .isEmpty // Check _questions.isEmpty here
                      ? const Center(child: CircularProgressIndicator())
                      : QuestionListWidget(
                        questions: sortedQuestions, // Use the sorted getter
                        isLoading:
                            _isLoading, // This will always be false when questions are displayed
                        selectedAnswers: {
                          for (int i = 0; i < selectedAnswers.length; i++)
                            if (selectedAnswers[i] != null)
                              i: selectedAnswers[i]!,
                        },
                        // Removed answerResults and onSubmit parameters
                        // as QuestionListWidget no longer accepts them directly.
                        onAnswerSelected: (index, answer) {
                          setState(() {
                            selectedAnswers[index] = answer;
                          });
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
