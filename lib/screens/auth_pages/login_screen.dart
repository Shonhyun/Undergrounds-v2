import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learningexamapp/screens/auth_pages/forgot_password_screen.dart';
import 'package:learningexamapp/screens/auth_pages/register_screen.dart';
import 'package:learningexamapp/utils/common_widgets/gradient_background.dart';
import 'package:learningexamapp/utils/common_widgets/announcement_overlay.dart';
import 'package:learningexamapp/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _passwordObscure = ValueNotifier(true);
  final ValueNotifier<bool> _isValid = ValueNotifier(false);
  final ValueNotifier<bool> _showOverlay = ValueNotifier(true);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordObscure.dispose();
    _isValid.dispose();
    _showOverlay.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    final rememberMe = await _storage.read(key: 'rememberMe');

    if (email != null && password != null && rememberMe == 'true') {
      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
        _rememberMe = true;
      });
      _validateForm();
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _storage.write(key: 'email', value: _emailController.text);
      await _storage.write(key: 'password', value: _passwordController.text);
      await _storage.write(key: 'rememberMe', value: 'true');
    } else {
      await _storage.delete(key: 'email');
      await _storage.delete(key: 'password');
      await _storage.write(key: 'rememberMe', value: 'false');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    _isValid.value = email.isNotEmpty && password.isNotEmpty;
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid email address.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return;
    }

    try {
      final error = await AuthService().signin(
        email: email,
        password: password,
        context: context,
      );

      if (error != null) {
        if (error == 'banned') {
          _showBannedDialog();
        } else {
          _showErrorToast(error);
        }
      } else {
        // Save credentials if login is successful
        await _saveCredentials();
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Login failed: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 14.0,
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
    } else if (errorCode == 'invalid-credential' ||
        errorCode == 'wrong-password') {
      message = 'Incorrect email or password.';
    } else if (errorCode == 'user-not-found') {
      message = 'No account found with that email.';
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

  void _showBannedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Account Banned"),
            content: const Text(
              "Your account has been banned. Contact support for more details.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              GradientBackground(
                children: [
                  const SizedBox(height: 70),
                  Text(
                    'Sign in',
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: theme.textTheme.bodyMedium,
                          border: const OutlineInputBorder(),
                          enabledBorder:
                              theme.inputDecorationTheme.enabledBorder,
                          focusedBorder:
                              theme.inputDecorationTheme.focusedBorder,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => _validateForm(),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: _passwordObscure,
                        builder: (_, passwordObscure, __) {
                          return TextFormField(
                            controller: _passwordController,
                            obscureText: passwordObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: const OutlineInputBorder(),
                              enabledBorder:
                                  theme.inputDecorationTheme.enabledBorder,
                              focusedBorder:
                                  theme.inputDecorationTheme.focusedBorder,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _passwordObscure.value = !passwordObscure;
                                },
                                icon: Icon(
                                  passwordObscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            onChanged: (_) => _validateForm(),
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: Colors.red,
                                checkColor: Colors.white,
                                fillColor: WidgetStateProperty.resolveWith<
                                  Color
                                >((states) {
                                  return states.contains(WidgetState.selected)
                                      ? Colors.red
                                      : Colors
                                          .grey
                                          .shade300; // Unselected (unchecked) color
                                }),
                              ),
                              const Text('Remember Me'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: theme.textButtonTheme.style,
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isValid,
                        builder: (_, isValid, __) {
                          return ElevatedButton(
                            onPressed: isValid ? _login : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isValid ? theme.primaryColor : Colors.grey,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Login'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don’t have an account?',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    style: theme.textButtonTheme.style,
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ],
          ),
          AnnouncementOverlay(isVisible: _showOverlay),
        ],
      ),
    );
  }
}
