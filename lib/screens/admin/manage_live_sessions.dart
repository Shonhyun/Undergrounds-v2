import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageLiveSessionsPage extends StatefulWidget {
  const ManageLiveSessionsPage({super.key});

  @override
  State<ManageLiveSessionsPage> createState() => _ManageLiveSessionsPageState();
}

class _ManageLiveSessionsPageState extends State<ManageLiveSessionsPage> {
  final List<Map<String, dynamic>> _subjects = [
    {'name': 'Math', 'controller': TextEditingController(), 'isEditing': false},
    {'name': 'ESAS', 'controller': TextEditingController(), 'isEditing': false},
    {'name': 'EE', 'controller': TextEditingController(), 'isEditing': false},
    {
      'name': 'Refresher',
      'controller': TextEditingController(),
      'isEditing': false,
    },
  ];

  @override
  void dispose() {
    for (var subject in _subjects) {
      subject['controller'].dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch the saved Zoom links when the page is first loaded
    _fetchSavedLinks();
  }

  // Fetch saved Zoom links from Firestore and update controllers
  Future<void> _fetchSavedLinks() async {
    for (var subject in _subjects) {
      final name = subject['name'];
      final controller = subject['controller'] as TextEditingController;

      try {
        DocumentSnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('subjects')
                .doc(name.toLowerCase())
                .get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final savedLink = data['zoomLink'] ?? '';
          controller.text = savedLink; // Set the saved Zoom link
        }
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch link for $name: $e')),
        );
      }
    }
  }

  // Toggle edit mode and handle saving the link
  void _toggleEditMode(int index) {
    final isEditing = _subjects[index]['isEditing'] as bool;

    if (isEditing) {
      final name = _subjects[index]['name'] as String;
      final controller =
          _subjects[index]['controller'] as TextEditingController;
      _onSavePressed(name, controller);
    }

    setState(() {
      _subjects[index]['isEditing'] = !isEditing;
    });
  }

  // Save the Zoom link to Firestore
  void _onSavePressed(
    String subjectName,
    TextEditingController controller,
  ) async {
    final link = controller.text.trim();

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Zoom link.')),
      );
      return;
    }

    try {
      // Reference to the Firestore document for the subject
      DocumentReference subjectRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectName.toLowerCase()); // Using subject name as the doc ID

      // Save the zoom link to Firestore
      await subjectRef.set(
        {'name': subjectName, 'zoomLink': link},
        SetOptions(merge: true),
      ); // merge: true to avoid overwriting other fields

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved link for $subjectName: $link')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Live Sessions'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final name = subject['name'];
          final controller = subject['controller'] as TextEditingController;
          final isEditing = subject['isEditing'] as bool;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: theme.cardTheme.color,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(name, style: theme.textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.save : Icons.edit,
                          color: isEditing ? Colors.white : Colors.grey,
                        ),
                        tooltip: isEditing ? 'Save' : 'Edit',
                        onPressed: () => _toggleEditMode(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    cursorColor: Colors.grey,
                    readOnly: !isEditing,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Zoom Link',
                      labelStyle: theme.textTheme.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
