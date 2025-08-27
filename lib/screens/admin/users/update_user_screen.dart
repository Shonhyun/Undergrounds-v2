import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UpdateUserPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UpdateUserPage({super.key, required this.user});

  @override
  State<UpdateUserPage> createState() => _UpdateUserPageState();
}

class _UpdateUserPageState extends State<UpdateUserPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  List<String> _subjects = [];
  List<String> allSubjects = ['Math', 'ESAS', 'EE', 'Refresher'];
  bool _isLoading = false;
  bool _isBanned = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['fullName']);
    _emailController = TextEditingController(text: widget.user['email']);
    _subjects = [];
    _isBanned = widget.user['isBanned'] ?? false;

    _loadEnrolledSubjects();
  }

  Future<void> _loadEnrolledSubjects() async {
    try {
      String userId = widget.user['uid'];
      for (String subject in allSubjects) {
        DocumentSnapshot enrollmentDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('enrollments')
                .doc(subject.toLowerCase())
                .get();

        if (enrollmentDoc.exists && enrollmentDoc['enrolled'] == true) {
          setState(() {
            _subjects.add(subject);
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error loading enrollments: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubjectChanged(String subject, bool selected) {
    setState(() {
      if (selected) {
        _subjects.add(subject);
      } else {
        _subjects.remove(subject);
      }
    });
  }

  Future<void> _updateUserDetails() async {
    setState(() => _isLoading = true);

    try {
      String userId = widget.user['uid'];

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "fullName": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "isBanned": _isBanned,
      });

      for (String subject in allSubjects) {
        bool isEnrolled = _subjects.contains(subject);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('enrollments')
            .doc(subject.toLowerCase())
            .set({"enrolled": isEnrolled});
      }

      Fluttertoast.showToast(
        msg: "User updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating user: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Update User'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Subjects', style: theme.textTheme.titleMedium),
              Column(
                children:
                    allSubjects.map((subject) {
                      return CheckboxListTile(
                        title: Text(subject, style: theme.textTheme.bodyMedium),
                        value: _subjects.contains(subject),
                        onChanged: (bool? selected) {
                          _onSubjectChanged(subject, selected ?? false);
                        },
                        activeColor: theme.primaryColor,
                        checkColor: Colors.white,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text("Ban User", style: theme.textTheme.bodyMedium),
                value: _isBanned,
                onChanged: (bool value) {
                  setState(() {
                    _isBanned = value;
                  });
                },
                activeColor: Colors.red,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _updateUserDetails,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: theme.primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Save Changes'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
