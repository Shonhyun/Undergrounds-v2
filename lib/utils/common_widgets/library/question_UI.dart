import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learningexamapp/utils/common_widgets/library/answer_feedback_screen.dart';

class QuestionListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final bool isLoading;
  final Function(int index, String selectedAnswer) onAnswerSelected;
  final Map<int, String> selectedAnswers;

  const QuestionListWidget({
    super.key,
    required this.questions,
    this.isLoading = false,
    required this.onAnswerSelected,
    required this.selectedAnswers,
  });

  // A map to store the colors for each subject.
  final Map<String, Color> subjectColors = const {
    'EE': Colors.blue,
    'MATH': Colors.red,
    'ESAS': Colors.yellow,
    'Refresher': Colors.pink,
  };

  String formatDate(dynamic timestamp) {
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      return '';
    }
    return DateFormat.yMMMMd().add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (questions.isEmpty) {
      return const Center(child: Text("No questions available."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        final choices =
            (q['options'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();
        final correctAnswer = q['correctAnswer'];
        final selected = selectedAnswers[index];

        final String subject = q['subject'] ?? 'Unknown';
        final Color subjectColor = subjectColors[subject] ?? Colors.grey;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$subject • ${q['topic'] ?? 'Unknown'}",
                  style: TextStyle(
                    fontSize: 14,
                    color: subjectColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  q['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if ((q['description'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    q['description'],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        q['schoolName'] != null &&
                                q['schoolName'].toString().trim().isNotEmpty
                            ? "By Engr. ${q['author'] ?? 'Unknown'}, ${q['schoolName']}"
                            : "By Engr. ${q['author'] ?? 'Unknown'}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(choices.length, (i) {
                  final optionText = choices[i];
                  final isSelected = selected == optionText;

                  Color borderColor = Colors.black;
                  Color iconColor = Colors.grey.shade300;
                  IconData iconData = Icons.radio_button_off;

                  if (isSelected) {
                    borderColor = Colors.redAccent;
                    iconColor = Colors.redAccent;
                    iconData = Icons.radio_button_checked;
                  }

                  return GestureDetector(
                    onTap: () => onAnswerSelected(index, optionText),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(iconData, color: iconColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              optionText,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  "Created on: ${formatDate(q['createdAt'] ?? '')}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed:
                          selected == null
                              ? null
                              : () {
                                final isCorrect = selected == correctAnswer;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (ctx) => AnswerFeedbackScreen(
                                          question: q,
                                          selectedAnswer: selected,
                                          isCorrect: isCorrect,
                                        ),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Submit Answer"),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'assets/images/logos/white_undergrounds_logo_cropped.png',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
