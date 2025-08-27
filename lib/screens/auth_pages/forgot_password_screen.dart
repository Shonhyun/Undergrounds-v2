import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learningexamapp/utils/common_widgets/gradient_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ValueNotifier<bool> _isValid = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  @override
  void dispose() {
    _emailController.dispose();
    _isValid.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    _isValid.value = _isValidEmail(email);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    _isLoading.value = true; // START LOADING

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: 'Password reset link sent! Check your email.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } finally {
      _isLoading.value = false; // STOP LOADING
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientBackground(
            children: [
              const SizedBox(height: 70),
              Text(
                'Forgot Password',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your email to receive a reset link.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (_, isLoading, __) {
                return Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading, // Disable while loading
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: theme.textTheme.bodyMedium,
                        border: const OutlineInputBorder(),
                        enabledBorder: theme.inputDecorationTheme.enabledBorder,
                        focusedBorder: theme.inputDecorationTheme.focusedBorder,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _validateEmail(),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isValid,
                      builder: (_, isValid, __) {
                        return ElevatedButton(
                          onPressed:
                              (isValid && !isLoading) ? _resetPassword : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (isValid && !isLoading)
                                    ? theme.primaryColor
                                    : Colors.grey,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                  : const Text('Send Reset Link'),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Back to Login'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
