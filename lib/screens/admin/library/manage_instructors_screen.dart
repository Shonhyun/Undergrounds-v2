import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageInstructorsScreen extends StatefulWidget {
  const ManageInstructorsScreen({super.key});

  @override
  State<ManageInstructorsScreen> createState() =>
      _ManageInstructorsScreenState();
}

class _ManageInstructorsScreenState extends State<ManageInstructorsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _editEmailController = TextEditingController();
  String? _currentEditingDocId;

  @override
  void dispose() {
    _emailController.dispose();
    _editEmailController.dispose();
    super.dispose();
  }

  // --- Add Instructor Email ---
  Future<void> _addInstructorEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      // Show loading indicator if you have one on this screen
    });

    try {
      // Check if email already exists
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('library')
              .doc('whitelistedUsers')
              .collection('accounts')
              .doc(email)
              .get();

      if (docSnapshot.exists) {
        _showSnackBar('This email is already an instructor.');
      } else {
        await FirebaseFirestore.instance
            .collection('library')
            .doc('whitelistedUsers')
            .collection('accounts')
            .doc(email)
            .set({
              'addedAt': FieldValue.serverTimestamp(),
            }); // Store addedAt timestamp

        _emailController.clear();
        _showSnackBar('Instructor email added successfully!');
      }
    } catch (e) {
      print('Error adding instructor: $e');
      _showSnackBar('Failed to add instructor: ${e.toString()}');
    } finally {
      setState(() {
        // Hide loading indicator
      });
    }
  }

  // --- Update Instructor Email ---
  Future<void> _updateInstructorEmail() async {
    if (_currentEditingDocId == null) {
      _showSnackBar('No email selected for update.');
      return;
    }

    final newEmail = _editEmailController.text.trim();
    if (newEmail.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    if (newEmail == _currentEditingDocId) {
      _showSnackBar('No changes detected.');
      Navigator.of(context).pop(); // Close dialog
      return;
    }

    setState(() {
      // Show loading indicator
    });

    try {
      // Check if the new email already exists (to prevent overwriting/duplicates)
      final newEmailDoc =
          await FirebaseFirestore.instance
              .collection('library')
              .doc('whitelistedUsers')
              .collection('accounts')
              .doc(newEmail)
              .get();

      if (newEmailDoc.exists) {
        _showSnackBar('The new email already exists as an instructor.');
      } else {
        // 1. Get current data (if any fields other than ID are stored)
        final oldDocSnapshot =
            await FirebaseFirestore.instance
                .collection('library')
                .doc('whitelistedUsers')
                .collection('accounts')
                .doc(_currentEditingDocId!)
                .get();

        Map<String, dynamic> oldData = {};
        if (oldDocSnapshot.exists) {
          oldData = oldDocSnapshot.data() ?? {};
        }

        // 2. Add new document with new email as ID and old data
        await FirebaseFirestore.instance
            .collection('library')
            .doc('whitelistedUsers')
            .collection('accounts')
            .doc(newEmail)
            .set(oldData); // Copy old data to new document

        // 3. Delete the old document
        await FirebaseFirestore.instance
            .collection('library')
            .doc('whitelistedUsers')
            .collection('accounts')
            .doc(_currentEditingDocId!)
            .delete();

        _showSnackBar('Instructor email updated successfully!');
        Navigator.of(context).pop(); // Close dialog
      }
    } catch (e) {
      print('Error updating instructor: $e');
      _showSnackBar('Failed to update instructor: ${e.toString()}');
    } finally {
      setState(() {
        // Hide loading indicator
        _currentEditingDocId = null; // Clear editing state
        _editEmailController.clear();
      });
    }
  }

  // --- Delete Instructor Email ---
  Future<void> _deleteInstructorEmail(String email) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to remove "$email" as an instructor?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                setState(() {
                  // Show loading indicator
                });
                try {
                  await FirebaseFirestore.instance
                      .collection('library')
                      .doc('whitelistedUsers')
                      .collection('accounts')
                      .doc(email)
                      .delete();
                  _showSnackBar('Instructor email deleted successfully!');
                } catch (e) {
                  print('Error deleting instructor: $e');
                  _showSnackBar('Failed to delete instructor: ${e.toString()}');
                } finally {
                  setState(() {
                    // Hide loading indicator
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showEditEmailDialog(String currentEmail) {
    _editEmailController.text = currentEmail;
    _currentEditingDocId = currentEmail;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Instructor Email'),
          content: TextField(
            controller: _editEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'New Email Address',
              hintText: 'e.g., instructor@example.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _editEmailController.clear();
                _currentEditingDocId = null;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _updateInstructorEmail,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Instructors",
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Add New Instructor Section ---
            Text(
              'Add New Instructor',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Instructor Email',
                hintText: 'e.g., new.instructor@example.com',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addInstructorEmail,
                ),
              ),
              onSubmitted:
                  (_) => _addInstructorEmail(), // Allow submission on enter key
            ),
            const SizedBox(height: 30),

            // --- Existing Instructors List Section ---
            Text(
              'Existing Instructors',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('library')
                        .doc('whitelistedUsers')
                        .collection('accounts')
                        .orderBy(
                          'addedAt',
                          descending: false,
                        ) // Order by timestamp if available
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No instructors added yet.'),
                    );
                  }

                  final instructors = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: instructors.length,
                    itemBuilder: (context, index) {
                      final doc = instructors[index];
                      final instructorEmail =
                          doc.id; // Email is the document ID
                      // You can also access other fields if you store them, e.g., doc['addedAt']

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(instructorEmail),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _showEditEmailDialog(instructorEmail),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () =>
                                        _deleteInstructorEmail(instructorEmail),
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
          ],
        ),
      ),
    );
  }
}
