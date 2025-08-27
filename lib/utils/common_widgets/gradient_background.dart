import 'package:flutter/material.dart';
import 'package:learningexamapp/values/app_colors.dart'; // Assuming app_colors.dart is where the colors are defined
import '../extensions.dart'; // Assuming extensions.dart contains helper methods

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.children,
    this.colors =
        AppColors.defaultGradient, // Using the correct reference to colors
    super.key,
  });

  final List<Color> colors; // Corrected type List<Color>
  final List<Widget> children; // Corrected type List<Widget>

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Corrected to use the proper Dart widget names
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors), // Correctly setting gradient
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: context.heightFraction(sizeFraction: 0.1),
            ), // Assuming 'heightFraction' is defined in your extensions.dart
            ...children, // Spreading the list of child widgets
          ],
        ),
      ),
    );
  }
}
