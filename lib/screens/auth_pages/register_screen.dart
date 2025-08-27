import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learningexamapp/services/auth_service.dart';
import 'package:learningexamapp/utils/common_widgets/gradient_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  bool _passwordObscure = true;
  bool _confirmPasswordObscure = true;
  bool _isValid = false;

  void _validateForm() {
    setState(() {
      _isValid =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text &&
          _fullNameController.text.isNotEmpty &&
          _schoolNameController.text.isNotEmpty;
    });
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    try {
      final error = await AuthService().signup(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        schoolName: _schoolNameController.text,
        context: context,
      );

      if (error != null) {
        _showErrorToast(error);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showErrorToast(String errorCode) {
    String message = '';
    if (errorCode == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (errorCode == 'email-already-in-use') {
      message = 'An account already exists with that email.';
    } else if (errorCode == 'invalid-email') {
      message = 'Please enter a valid email address.';
    } else if (errorCode == 'operation-not-allowed') {
      message = 'Email/password accounts are not enabled.';
    } else {
      message = 'An unknown error occurred. Please try again.';
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
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
                'Sign up',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Form(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTextField(
                    _emailController,
                    'Email',
                    TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    _fullNameController,
                    'Full Name',
                    TextInputType.text,
                  ),
                  _buildTextField(
                    _schoolNameController,
                    'School Name',
                    TextInputType.text,
                  ),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: _passwordObscure,
                    toggleVisibility: () {
                      setState(() {
                        _passwordObscure = !_passwordObscure;
                      });
                    },
                  ),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: _confirmPasswordObscure,
                    toggleVisibility: () {
                      setState(() {
                        _confirmPasswordObscure = !_confirmPasswordObscure;
                      });
                    },
                  ),
                  _buildRegisterButton(),
                ],
              ),
            ),
          ),
          _buildLoginLink(context),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        onChanged: (_) => _validateForm(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium,
          border: const OutlineInputBorder(),
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
        ),
        keyboardType: type,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) => _validateForm(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium,
          border: const OutlineInputBorder(),
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
          suffixIcon: IconButton(
            onPressed: toggleVisibility,
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: theme.iconTheme.color,
            ),
          ),
        ),
        keyboardType: TextInputType.visiblePassword,
      ),
    );
  }

  Widget _buildRegisterButton() {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ValueNotifier(_isValid),
      builder: (_, isValid, __) {
        return ElevatedButton(
          onPressed: isValid ? _register : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? theme.primaryColor : theme.disabledColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Sign up'),
        );
      },
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: theme.textButtonTheme.style,
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}
