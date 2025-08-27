import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learningexamapp/screens/home/library/edit_question_screen.dart';

class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key, required this.userData});

  final dynamic userData;

  String formatDate(dynamic timestamp) {
    DateTime date;
    // Check if the timestamp is a Firestore Timestamp object
    if (timestamp is Timestamp) {
      date = timestamp.toDate(); // Convert Firestore Timestamp to DateTime
    } else if (timestamp is String) {
      date = DateTime.parse(
        timestamp,
      ); // In case the timestamp is already a string
    } else {
      return ''; // Return empty string or some fallback value if it's neither a Timestamp nor a String
    }
    return DateFormat.yMMMMd().add_jm().format(date);
  }

  // Method to handle the deletion process
  void deleteQuestion(BuildContext context, String questionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this question?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Proceed to delete from Firestore
                try {
                  await FirebaseFirestore.instance
                      .collection('library')
                      .doc('questions')
                      .collection('items')
                      .doc(questionId)
                      .delete(); // Delete the question from Firestore
                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  // Handle errors
                  Navigator.of(context).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting question: $e")),
                  );
                }
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fetch the current user's questions from Firestore
    final userId = userData['id'];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            AppBar(
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "My Questions",
                style: theme.appBarTheme.titleTextStyle,
              ),
              centerTitle: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              iconTheme: theme.appBarTheme.iconTheme,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('library')
                  .doc('questions')
                  .collection('items')
                  .where('authorId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching data.'));
            }

            final questions = snapshot.data?.docs ?? [];

            return questions.isEmpty
                ? const Center(
                  child: Text("You haven't added any questions yet."),
                )
                : ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question =
                        questions[index].data() as Map<String, dynamic>;

                    final bool isApproved = question['approved'] ?? false;
                    final String? approvedBy = question['approvedBy'];
                    final Timestamp? approvedAt = question['approvedAt'];
                    final bool isRejected = question['rejected'] ?? false;
                    final String? rejectedBy = question['rejectedBy'];
                    final Timestamp? rejectedAt = question['rejectedAt'];

                    final String questionId = questions[index].id;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${question['subject']} • ${question['topic']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (question['description'] != null &&
                                question['description']
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                question['description'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            ...List.generate(question['options'].length, (i) {
                              // Check if the option matches the correct answer string
                              final isCorrect =
                                  question['options'][i] ==
                                  question['correctAnswer'];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isCorrect
                                            ? Colors.redAccent
                                            : Colors.black,
                                    width: isCorrect ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color:
                                          isCorrect
                                              ? Colors.redAccent
                                              : Colors.grey.shade300,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        question['options'][i],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Text(
                              "Created on: ${formatDate(question['createdAt'])}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isApproved)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Approved by: ${approvedBy ?? 'Unknown'}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "on ${formatDate(approvedAt)}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isRejected)
                              Column(
                                // Use Column to stack elements vertically
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Rejected by: ${rejectedBy ?? 'Unknown'}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "on ${formatDate(rejectedAt)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ), // Add some space below the rejected info
                                  const Text(
                                    "Your posted question has been rejected by an admin or instructor. Kindly reach out to us to learn more. You may also double check the accuracy and correctness of your post prior to reaching out to us or prior to attempting to post it again.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors
                                              .redAccent, // You can adjust the color
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                "Review in Progress",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => EditQuestionScreen(
                                              userData: userData,
                                              questionId: questionId,
                                              question: question,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text("Edit"),
                                ),

                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    deleteQuestion(context, questionId);
                                  },
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text("Delete"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
          },
        ),
      ),
    );
  }
}
