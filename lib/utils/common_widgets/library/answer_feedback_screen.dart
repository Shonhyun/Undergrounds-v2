import 'package:flutter/material.dart';

class AnswerFeedbackScreen extends StatelessWidget {
  final Map<String, dynamic> question;
  final String selectedAnswer;
  final bool isCorrect;

  const AnswerFeedbackScreen({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctAnswer = question['correctAnswer'];
    final choices =
        (question['options'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCorrect
              ? "Congratulations, you got it right!"
              : "Please try again!",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Feedback Message
            Center(
              child: Icon(
                isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isCorrect ? Colors.green : Colors.red,
                size: 100,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isCorrect ? "Congratulations!" : "Keep learning!",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // --- Feedback Summary Card ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            // Question Title (Existing UI, untouched)
            Text(
              question['title'] ?? 'No Title',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if ((question['description'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                question['description'],
                style: const TextStyle(color: Colors.white),
              ),
            ],
            const SizedBox(height: 16),

            // Options with Results (Modified Logic)
            ...List.generate(choices.length, (i) {
              final optionText = choices[i];
              final isThisSelected = selectedAnswer == optionText;
              final isThisCorrect =
                  correctAnswer ==
                  optionText; // This is the actual correct answer

              Color borderColor = Colors.black;
              Color backgroundColor = Colors.black;
              IconData iconData = Icons.radio_button_off;

              // --- MODIFIED LOGIC START ---
              if (isCorrect) {
                // User got it RIGHT
                if (isThisCorrect) {
                  // This option is the correct one AND selected
                  borderColor = Colors.green;
                  backgroundColor = Colors.green.shade900;
                  iconData = Icons.check_circle;
                } else {
                  // Other options that were not selected (and not correct)
                  borderColor = Colors.black;
                  backgroundColor = Colors.black;
                }
              } else {
                // User got it WRONG
                if (isThisSelected) {
                  // This option is the one the user selected (which is wrong)
                  borderColor = Colors.red;
                  backgroundColor = Colors.red.shade900;
                  iconData = Icons.cancel;
                } else {
                  // Other options that were not selected and not correct
                  borderColor = Colors.black;
                  backgroundColor = Colors.black;
                }
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconData, color: Colors.white),
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
              );
            }),
            const SizedBox(height: 40),

            // Go Back Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Go Back", style: TextStyle(fontSize: 18)),
              ),
            ),

            Center(
              child: Image.asset(
                'assets/images/logos/white_undergrounds_logo.png',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
