import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CreateQuestionsScreen({super.key, required this.userData});

  @override
  State<CreateQuestionsScreen> createState() => _CreateQuestionsScreenState();
}

class _CreateQuestionsScreenState extends State<CreateQuestionsScreen> {
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;

  String? selectedSubject;
  String? selectedTopic;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final List<TextEditingController> choiceControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  int? correctAnswerIndex;

  final Map<String, List<String>> topicsBySubject = {
    "MATH": [
      "Algebra",
      "Prob and Stats",
      "Trigonometry",
      "Plane and Solid Geometry",
      "Analytical Geometry",
      "Differential Calculus",
      "Integral Calculus",
      "Differential Equations",
      "Advance Engineering Mathematics",
      "Numerical Methods",
    ],
    "ESAS": [
      "Engineering Economy",
      "Chemistry",
      "Physics",
      "Engineering Mechanics - Statics",
      "Engineering Mechanics - Dynamics",
      "Strength of Materials",
      "Fluid Mechanics",
      "Thermodynamics",
      "Computer Fundamentals",
      "EE Laws",
      "PEC",
    ],
    "EE": [
      "DC Circuits",
      "Electrostatics",
      "Electromagnetics",
      "AC Circuits 1 (Single Phase Systems)",
      "AC Circuits 2 (Polyphase Systems)",
      "Electrical Transients",
      "DC Machines 1 (DC Generator)",
      "DC Machines 2 (DC Motors)",
      "AC Machines 1 (Alternators & Synch Motors)",
      "AC Machines 2 (Induction Motors)",
      "AC Machines 3 (Transformers)",
      "Power Plant Engineering",
      "Illumination",
      "Electronics and Communication",
      "Power System",
    ],
    "Refresher": ["MATH Refresher", "ESAS Refresher", "EE Refresher"],
  };
  // --- Change 1: List to store whitelisted User Emails ---
  List<String> whitelistedUserEmails = [];

  @override
  void initState() {
    super.initState();
    _fetchWhitelistedUsers(); // Fetch whitelisted users on init
  }

  /// Fetches the list of whitelisted user Emails from Firestore.
  /// These emails are expected to be the document IDs in the 'accounts' subcollection.
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
        // --- Change 2: Assuming the Document ID IS the email ---
        // If email is a field inside the document, you'd use: doc.data()['email'] as String?
        final email = doc.id;
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

  bool areAllChoicesFilled() {
    return choiceControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  int get stepNumber {
    if (selectedSubject == null) return 1;
    if (selectedTopic == null) return 2;
    if (titleController.text.isEmpty) return 3;
    return 4;
  }

  void animateToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void showConfirmationDialog() {
    // Basic validation before showing confirmation
    if (selectedSubject == null ||
        selectedTopic == null ||
        titleController.text.trim().isEmpty ||
        !areAllChoicesFilled() ||
        correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields and select a correct answer.",
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Submission"),
            content: const Text(
              "Are you sure you want to submit this question?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  submitQuestion(); // Call the function to submit the question
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void submitQuestion() async {
    // Re-validate just in case user bypassed dialog or external call
    if (selectedSubject == null ||
        selectedTopic == null ||
        titleController.text.trim().isEmpty ||
        !areAllChoicesFilled() ||
        correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot submit. Please complete all question details."),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // --- Change 3: Get user email for whitelist check ---
      final String? currentUserEmail = widget.userData?['email'] as String?;
      final String? currentUserId =
          widget.userData?['id'] as String?; // Keep authorId as UID

      final bool isWhitelisted =
          currentUserEmail != null &&
          whitelistedUserEmails.contains(currentUserEmail);

      // Determine approval status based on whitelisted status
      bool approvedStatus = isWhitelisted;
      String? approvedBy =
          approvedStatus
              ? (widget.userData?['name'] ?? 'System Auto-Approval')
              : null;
      FieldValue? approvedAt =
          approvedStatus ? FieldValue.serverTimestamp() : null;

      final questionData = {
        'subject': selectedSubject,
        'topic': selectedTopic,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'options':
            choiceControllers
                .map((controller) => controller.text.trim())
                .toList(),
        'correctAnswer': choiceControllers[correctAnswerIndex!].text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'approved': approvedStatus, // Set based on whitelist status
        'rejected':
            false, // Newly created questions are never rejected initially
        'authorId': currentUserId,
        if (approvedBy != null)
          'approvedBy': approvedBy, // Conditionally add if auto-approved
        if (approvedAt != null)
          'approvedAt': approvedAt, // Conditionally add if auto-approved
      };

      // Add the question to Firestore
      await FirebaseFirestore.instance
          .collection('library')
          .doc('questions')
          .collection('items')
          .add(questionData);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approvedStatus
                ? "Question submitted and auto-approved!"
                : "Question submitted for review!",
          ),
        ),
      );

      // Reset the form fields
      resetForm();

      if (mounted) {
        // Ensure widget is still in tree before popping
        Navigator.of(context).pop(); // Close the form screen
      }
    } catch (e) {
      // If any error occurs, show an error message
      print("Error submitting question: $e"); // For debugging
      if (mounted) {
        // Ensure widget is still in tree before showing SnackBar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        // Ensure widget is still in tree before calling setState
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void resetForm() {
    setState(() {
      selectedSubject = null;
      selectedTopic = null;
      titleController.clear();
      descriptionController.clear();
      for (var controller in choiceControllers) {
        controller.clear();
      }
      correctAnswerIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            AppBar(
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Create Your Own Question",
                style: theme.appBarTheme.titleTextStyle,
              ),
              centerTitle: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              iconTheme: theme.appBarTheme.iconTheme,
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      "Progress: Step $stepNumber of 4",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1: Subject
                    const Text(
                      "Step 1: Select a Subject",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      hint: const Text("Choose Subject"),
                      items:
                          topicsBySubject.keys
                              .map(
                                (subj) => DropdownMenuItem(
                                  value: subj,
                                  child: Text(subj),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                          selectedTopic = null;
                        });
                        animateToBottom();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Step 2: Topic
                    const Text(
                      "Step 2: Select a Topic",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTopic,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      hint: const Text("Choose Topic"),
                      disabledHint: const Text("Choose Subject First"),
                      items:
                          selectedSubject == null
                              ? []
                              : topicsBySubject[selectedSubject!]!
                                  .map(
                                    (topic) => DropdownMenuItem(
                                      value: topic,
                                      child: Text(topic),
                                    ),
                                  )
                                  .toList(),
                      onChanged:
                          selectedSubject == null
                              ? null
                              : (value) {
                                setState(() {
                                  selectedTopic = value;
                                });
                                animateToBottom();
                              },
                    ),

                    const SizedBox(height: 24),

                    // Step 3: Question
                    const Text(
                      "Step 3: Enter Your Question",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Question Title",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: titleController,
                      enabled: selectedTopic != null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter title",
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionController,
                      enabled: selectedTopic != null,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Add more details (optional)",
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Step 4: Choices
                    const Text(
                      "Step 4: Add Multiple Choices",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: TextFormField(
                          controller: choiceControllers[index],
                          enabled: titleController.text.isNotEmpty,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: "Choice ${index + 1}",
                            hintText: "Enter option ${index + 1}",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    if (areAllChoicesFilled()) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "Correct Answer",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: correctAnswerIndex,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        hint: const Text("Select the correct choice"),
                        items: List.generate(
                          4,
                          (index) => DropdownMenuItem(
                            value: index,
                            child: Text("Choice ${index + 1}"),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            correctAnswerIndex = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed:
                          stepNumber < 4 || correctAnswerIndex == null
                              ? null
                              : () => showConfirmationDialog(),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        "Submit Question",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
