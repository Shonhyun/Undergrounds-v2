import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/main_screen.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';
import 'package:learningexamapp/utils/common_widgets/NoScreenshotWrapper.dart';

class ExamResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic> results;

  const ExamResultsScreen({super.key, this.userData, required this.results});

  // Helper method to convert seconds into MM:SS format.
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    // Extract basic score info and exam title from the results.
    final int correctAnswers = results['correctAnswers'] ?? 0;
    final int totalQuestions = results['totalQuestions'] ?? 0;
    final double scorePercentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

    // Extract the questions list and selected answers from results.
    final List<dynamic> questions = results['questions'] ?? [];
    final Map<dynamic, dynamic> selectedAnswers =
        results['selectedAnswers'] ?? {};

    // Extract and format the time taken data (in seconds).
    final int timeTakenSeconds = results['timeTaken'] ?? 0;
    final String formattedTime = formatTime(timeTakenSeconds);

    return NoScreenshotWrapper(
      child: Scaffold(
        appBar: buildAppBar(context, "Exam Results"),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Congratulatory header.
              Center(
                child: Text(
                  "Congratulations, ${userData?['fullName'] ?? 'User'}!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "You completed the exam!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              // Circular progress indicator for score.
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: scorePercentage / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.redAccent,
                      ),
                    ),
                  ),
                  Text(
                    "${scorePercentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Card displaying the overall score.
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Score:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$correctAnswers / $totalQuestions",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Card displaying the time taken to complete the exam.
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Time Taken:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header for detailed results.
              const Text(
                "Detailed Results:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Detailed list of each question.
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final questionData = questions[index];

                  final String questionText = questionData['question'] ?? '';
                  final String correctAnswer =
                      questionData['correctAnswer'] ?? '';
                  final String userAnswer =
                      selectedAnswers[index]?.toString() ?? "No answer";
                  final bool isCorrect = userAnswer == correctAnswer;

                  final String? questionImageUrl =
                      questionData['questionImageUrl'];
                  final List<dynamic> options = questionData['options'] ?? [];
                  final List<dynamic> optionImageUrls =
                      questionData['optionImageUrls'] ?? [];

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Q${index + 1}: $questionText",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (questionImageUrl != null &&
                              questionImageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  questionImageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            "Options:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(options.length, (i) {
                            final String optionText =
                                options[i]?.toString() ?? '';
                            final String imageUrl =
                                (i < optionImageUrls.length)
                                    ? optionImageUrls[i]?.toString() ?? ''
                                    : '';
                            final bool isSelected = userAnswer == optionText;
                            final bool isCorrectOption =
                                correctAnswer == optionText;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color:
                                    isCorrectOption
                                        ? const Color.fromRGBO(0, 255, 0, 0.2)
                                        : isSelected
                                        ? const Color.fromRGBO(255, 0, 0, 0.2)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isCorrectOption
                                          ? Colors.green
                                          : isSelected
                                          ? Colors.red
                                          : Colors.grey,
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (imageUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        if (imageUrl.isNotEmpty)
                                          const SizedBox(height: 8),
                                        Text(
                                          optionText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                isCorrectOption
                                                    ? Colors.green
                                                    : isSelected
                                                    ? Colors.red
                                                    : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          Text(
                            "Your Answer: $userAnswer",
                            style: TextStyle(
                              fontSize: 16,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Correct Answer: $correctAnswer",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCorrect ? "Correct" : "Incorrect",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Display the exam title for reference.
              Text(
                "Exam Title: ${results['examTitle']}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              // Button to navigate back home.
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
