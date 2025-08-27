import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UpdateProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const UpdateProfilePage({super.key, this.userData});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  bool _isValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.userData?['fullName'] ?? '';
    _schoolNameController.text = widget.userData?['schoolName'] ?? '';
    _validateForm();
  }

  void _validateForm() {
    setState(() {
      _isValid =
          _fullNameController.text.trim().isNotEmpty &&
          _schoolNameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _updateProfile() async {
    final userId = widget.userData?['id'];
    if (userId == null) {
      Fluttertoast.showToast(
        msg: "User ID is missing.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fullName': _fullNameController.text.trim(),
        'schoolName': _schoolNameController.text.trim(),
      });

      Fluttertoast.showToast(msg: "Profile updated successfully!");

      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update profile: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  color: primaryColor,
                ),
                if (widget.userData?['role'] == 'student') ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _schoolNameController,
                    label: 'School Name',
                    color: primaryColor,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isValid && !_isLoading ? _updateProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: theme.disabledColor,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: color,
      onChanged: (_) => _validateForm(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color)),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
