import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditQuestionScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Now primarily relying on 'email'
  final String questionId;
  final Map<String, dynamic> question;

  const EditQuestionScreen({
    super.key,
    required this.userData,
    required this.questionId,
    required this.question,
  });

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final List<TextEditingController> choiceControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  String? selectedSubject;
  String? selectedTopic;
  int? correctAnswerIndex;
  bool isLoading = false;
  bool hasUnsavedChanges = false;

  // List to store whitelisted User Emails
  List<String> whitelistedUserEmails = [];

  final Map<String, List<String>> topicsBySubject = {
    "MATH": ["Algebra", "Geometry", "Calculus"],
    "ESAS": ["Statics", "Dynamics", "Fluid Mechanics"],
    "EE": ["Circuits", "Power Systems", "Machines"],
  };

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    selectedSubject = q['subject'];
    selectedTopic = q['topic'];
    titleController.text = q['title'];
    descriptionController.text = q['description'] ?? '';
    final options = List<String>.from(q['options']);
    for (int i = 0; i < options.length && i < 4; i++) {
      choiceControllers[i].text = options[i];
    }
    correctAnswerIndex = options.indexOf(q['correctAnswer']);
    _fetchWhitelistedUsers(); // Fetch whitelisted users on init
    trackChanges();
  }

  /// Fetches the list of whitelisted user Emails from Firestore.
  /// These emails are expected to be the document IDs in the 'accounts' subcollection.
  /// (Or a field within the document, if you change structure for email storage)
  Future<void> _fetchWhitelistedUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('library')
              .doc('whitelistedUsers')
              .collection('accounts') // Accessing the 'accounts' subcollection
              .get();

      final List<String> fetchedEmails = [];
      for (var doc in querySnapshot.docs) {
        // Assuming the document ID IS the email
        // Or if email is a field, use: doc.data()['email']
        final email = doc.id; // Or doc.data()['email'] as String?
        if (email.isNotEmpty) {
          fetchedEmails.add(email);
        }
      }
      setState(() {
        whitelistedUserEmails = fetchedEmails;
      });
    } catch (e) {
      print(
        "Error fetching whitelisted user emails: $e",
      ); // Log error for debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading whitelisted user emails: $e')),
        );
      }
    }
  }

  void trackChanges() {
    void listener() => setState(() => hasUnsavedChanges = true);

    titleController.addListener(listener);
    descriptionController.addListener(listener);
    for (var c in choiceControllers) {
      c.addListener(listener);
    }
  }

  Future<void> updateQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      final String? currentUserEmail = widget.userData['email'] as String?;
      final bool isWhitelisted =
          currentUserEmail != null &&
          whitelistedUserEmails.contains(currentUserEmail);

      // Determine approval status based on whitelisted status
      bool approvedStatus = isWhitelisted;
      String? approvedBy =
          approvedStatus
              ? (widget.userData['name'] ?? 'System Auto-Approval')
              : null;
      FieldValue? approvedAt =
          approvedStatus ? FieldValue.serverTimestamp() : null;

      // Start building the updated data map
      final Map<String, dynamic> updatedData = {
        'subject': selectedSubject,
        'topic': selectedTopic,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'options': choiceControllers.map((c) => c.text.trim()).toList(),
        'correctAnswer': choiceControllers[correctAnswerIndex!].text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'approved': approvedStatus, // Set based on whitelist status
        'rejected': false, // Always reset rejected status on edit
        if (approvedBy != null)
          'approvedBy': approvedBy, // Conditionally add if auto-approved
        if (approvedAt != null)
          'approvedAt': approvedAt, // Conditionally add if auto-approved
      };

      // Conditionally remove approvedBy and approvedAt if not auto-approved
      if (!approvedStatus) {
        if (widget.question.containsKey('approvedBy')) {
          updatedData['approvedBy'] = FieldValue.delete();
        }
        if (widget.question.containsKey('approvedAt')) {
          updatedData['approvedAt'] = FieldValue.delete();
        }
      }

      // Conditionally remove rejectedBy and rejectedAt if they exist
      if (widget.question.containsKey('rejectedBy')) {
        updatedData['rejectedBy'] = FieldValue.delete();
      }
      if (widget.question.containsKey('rejectedAt')) {
        updatedData['rejectedAt'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('library')
          .doc('questions')
          .collection('items')
          .doc(widget.questionId)
          .update(updatedData);

      if (mounted) {
        setState(() => hasUnsavedChanges = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approvedStatus
                  ? 'Question updated and auto-approved successfully!'
                  : 'Question updated successfully and is awaiting review.',
            ),
          ),
        );
      }
    } catch (e) {
      print("Error updating question: $e"); // For debugging
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating question: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> confirmDiscardChanges() async {
    if (!hasUnsavedChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Discard changes?"),
            content: const Text("You have unsaved changes. Leave anyway?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Stay"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Leave"),
              ),
            ],
          ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: confirmDiscardChanges,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Question"),
          leading: BackButton(
            onPressed: () async {
              if (await confirmDiscardChanges()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Step 1: Select Subject & Topic",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    decoration: const InputDecoration(labelText: "Subject"),
                    items:
                        topicsBySubject.keys
                            .map(
                              (subj) => DropdownMenuItem(
                                value: subj,
                                child: Text(subj),
                              ),
                            )
                            .toList(),
                    validator:
                        (value) =>
                            value == null ? 'Please select a subject' : null,
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                        selectedTopic = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedTopic,
                    decoration: const InputDecoration(labelText: "Topic"),
                    items:
                        (selectedSubject == null
                                ? <String>[]
                                : topicsBySubject[selectedSubject!]!)
                            .map<DropdownMenuItem<String>>(
                              (topic) => DropdownMenuItem<String>(
                                value: topic,
                                child: Text(topic),
                              ),
                            )
                            .toList(),
                    validator:
                        (value) =>
                            value == null ? 'Please select a topic' : null,
                    onChanged: (value) {
                      setState(() {
                        selectedTopic = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Step 2: Edit Question Details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Question Title",
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter a title'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Step 3: Edit Choices",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: choiceControllers[index],
                        decoration: InputDecoration(
                          labelText: "Choice ${index + 1}",
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter choice ${index + 1}'
                                    : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: correctAnswerIndex,
                    decoration: const InputDecoration(
                      labelText: "Correct Answer",
                    ),
                    items: List.generate(
                      4,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text("Choice ${index + 1}"),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null ? 'Select the correct answer' : null,
                    onChanged: (value) {
                      setState(() {
                        correctAnswerIndex = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing this question will reset its approval and rejected status.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: updateQuestion,
                    icon: const Icon(Icons.save),
                    label: const Text("Update Question"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
