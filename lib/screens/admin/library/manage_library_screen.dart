import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum to define filtering options
enum QuestionFilter { pending, approved, rejected }

class ManageLibraryQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ManageLibraryQuestionsScreen({super.key, this.userData});

  @override
  State<ManageLibraryQuestionsScreen> createState() =>
      _ManageLibraryQuestionsScreen();
}

class _ManageLibraryQuestionsScreen
    extends State<ManageLibraryQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  QuestionFilter _currentFilter = QuestionFilter.pending; // Default to pending

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  // Helper to format date/timestamp consistently
  String formatDate(dynamic timestamp) {
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      // Handle cases where timestamp might be a String if data was manually entered
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Invalid Date'; // Fallback for unparseable strings
      }
    } else {
      return ''; // Fallback for unexpected types
    }
    return DateFormat.yMMMMd().add_jm().format(date);
  }

  Future<void> _fetchQuestions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('library')
          .doc('questions')
          .collection('items');

      // Apply filter based on _currentFilter
      if (_currentFilter == QuestionFilter.pending) {
        query = query
            .where('approved', isEqualTo: false)
            .where(
              'rejected',
              isEqualTo: false,
            ); // Pending means not approved AND not rejected
      } else if (_currentFilter == QuestionFilter.approved) {
        query = query.where('approved', isEqualTo: true);
      } else if (_currentFilter == QuestionFilter.rejected) {
        query = query.where('rejected', isEqualTo: true);
      }
      // Removed the 'all' filter condition. If you wish to fetch all data again, you
      // would need to add a new filter option for it or change the default behavior.

      final querySnapshot = await query.get();

      final List<Map<String, dynamic>> fetchedQuestions = [];
      final Set<String> authorIds = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final authorId = data['authorId'];
        if (authorId != null) {
          authorIds.add(authorId);
        }
        fetchedQuestions.add({...data, 'id': doc.id}); // Include document ID
      }

      // Fetch user data for all unique author IDs
      final Map<String, String> authorIdToName = {};
      final Map<String, String> authorIdToSchool = {};

      for (final id in authorIds) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          authorIdToName[id] = userData?['fullName'] ?? 'Unknown Author';
          authorIdToSchool[id] = userData?['schoolName'] ?? 'Unknown School';
        } else {
          authorIdToName[id] = 'Unknown Author';
          authorIdToSchool[id] = 'Unknown School';
        }
      }

      // Enrich questions with author and school names
      final List<Map<String, dynamic>> enrichedQuestions =
          fetchedQuestions.map((q) {
            final authorId = q['authorId'];
            final authorName = authorIdToName[authorId] ?? 'Unknown Author';
            final schoolName = authorIdToSchool[authorId] ?? 'Unknown School';
            return {...q, 'author': authorName, 'schoolName': schoolName};
          }).toList();

      // Sort by createdAt, newest first by default for admin view
      enrichedQuestions.sort((a, b) {
        final dynamic createdAtA = a['createdAt'];
        final dynamic createdAtB = b['createdAt'];

        DateTime dateA;
        DateTime dateB;

        if (createdAtA is Timestamp) {
          dateA = createdAtA.toDate();
        } else if (createdAtA is String) {
          try {
            dateA = DateTime.parse(createdAtA);
          } catch (e) {
            dateA = DateTime(0); // Fallback for invalid date strings
          }
        } else {
          dateA = DateTime(0);
        }

        if (createdAtB is Timestamp) {
          dateB = createdAtB.toDate();
        } else if (createdAtB is String) {
          try {
            dateB = DateTime.parse(createdAtB);
          } catch (e) {
            dateB = DateTime(0); // Fallback for invalid date strings
          }
        } else {
          dateB = DateTime(0);
        }
        return dateB.compareTo(dateA); // Newest first
      });

      if (!mounted) return;
      setState(() {
        _questions = enrichedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching questions: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
      });
    }
  }

  // New method to handle rejecting a question
  Future<void> _rejectQuestion(String docId) async {
    final bool? confirmReject = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rejection'),
          content: const Text(
            'Are you sure you want to reject this question? It will no longer be pending.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmReject != true) {
      return; // If user cancels, stop here
    }

    try {
      final String adminName =
          widget.userData?['fullName'] ??
          'Admin User'; // Placeholder admin name
      final Timestamp now = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('library')
          .doc('questions')
          .collection('items')
          .doc(docId)
          .update({
            'approved': false, // A rejected question cannot be approved
            'rejected': true, // Mark as rejected
            'approvedAt':
                FieldValue.delete(), // Remove approvedAt if it existed
            'approvedBy':
                FieldValue.delete(), // Remove approvedBy if it existed
            'rejectedAt': now, // Set rejection timestamp
            'rejectedBy': adminName, // Set who rejected it
            'updatedAt': now, // Always update updatedAt
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question rejected successfully!')),
      );
      _fetchQuestions(); // Refresh the list after update
    } catch (e) {
      print("Error rejecting question: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject question: $e')));
    }
  }

  // Modified method to handle approval and revocation
  Future<void> _updateQuestionApproval(String docId, bool approve) async {
    // Determine action for confirmation dialog
    String title = approve ? 'Confirm Approval' : 'Confirm Revocation';
    String content =
        approve
            ? 'Are you sure you want to approve this question?'
            : 'Are you sure you want to revoke approval for this question?';
    String actionButtonText = approve ? 'Approve' : 'Revoke';
    Color actionButtonColor = approve ? Colors.green : Colors.red;

    final bool? confirmAction = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                actionButtonText,
                style: TextStyle(color: actionButtonColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmAction != true) {
      return; // If user cancels, stop here
    }

    try {
      final String adminName =
          widget.userData?['fullName'] ??
          'Admin User'; // Placeholder admin name
      final Timestamp now = Timestamp.now();

      // If approving: set approved to true, rejected to false, update approvedAt/By
      // If revoking: set approved to false, rejected to false, remove approvedAt/By
      await FirebaseFirestore.instance
          .collection('library')
          .doc('questions')
          .collection('items')
          .doc(docId)
          .update({
            'approved': approve,
            'rejected': false, // Approving or revoking means it's not rejected
            'approvedAt': approve ? now : FieldValue.delete(),
            'approvedBy': approve ? adminName : FieldValue.delete(),
            'rejectedAt':
                FieldValue.delete(), // Remove rejectedAt if it existed
            'rejectedBy':
                FieldValue.delete(), // Remove rejectedBy if it existed
            'updatedAt': now,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Question ${approve ? "approved" : "revoked"} successfully!',
          ),
        ),
      );
      _fetchQuestions(); // Refresh the list after update
    } catch (e) {
      print("Error updating approval status: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update approval status: $e')),
      );
    }
  }

  Future<void> _deleteQuestion(String docId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this question? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('library')
            .doc('questions')
            .collection('items')
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted successfully!')),
        );
        _fetchQuestions(); // Refresh the list after deletion
      } catch (e) {
        print("Error deleting question: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete question: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text("Manage Library Questions"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<QuestionFilter>(
              segments: const <ButtonSegment<QuestionFilter>>[
                ButtonSegment<QuestionFilter>(
                  value: QuestionFilter.pending,
                  label: Text('Pending'),
                  icon: Icon(Icons.hourglass_empty),
                ),
                ButtonSegment<QuestionFilter>(
                  value: QuestionFilter.approved,
                  label: Text('Approved'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment<QuestionFilter>(
                  value: QuestionFilter.rejected,
                  label: Text('Rejected'),
                  icon: Icon(Icons.cancel_outlined),
                ),
                // Removed the 'All' ButtonSegment here
              ],
              selected: <QuestionFilter>{_currentFilter},
              onSelectionChanged: (Set<QuestionFilter> newSelection) {
                setState(() {
                  _currentFilter = newSelection.first;
                });
                _fetchQuestions(); // Fetch questions again with the new filter
              },
              style: SegmentedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _questions.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "No ${_currentFilter.name} questions found.",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        final String docId = q['id'];
                        final bool isApproved = q['approved'] ?? false;
                        final bool isRejected = q['rejected'] ?? false;

                        String statusText;
                        Color statusColor;

                        if (isApproved) {
                          statusText = 'Approved';
                          statusColor = Colors.green.shade600;
                        } else if (isRejected) {
                          statusText = 'Rejected';
                          statusColor = Colors.red.shade600;
                        } else {
                          statusText = 'Pending';
                          statusColor = Colors.orange.shade600;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Badge
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Subject & Topic
                                Text(
                                  "${q['subject'] ?? 'Unknown'} • ${q['topic'] ?? 'Unknown'}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Question Title
                                Text(
                                  q['title'] ?? 'No Title',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),

                                if ((q['description'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    q['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                // Author and School
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        q['schoolName'] != null &&
                                                q['schoolName']
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty
                                            ? "By Engr. ${q['author'] ?? 'Unknown'}, ${q['schoolName']}"
                                            : "By Engr. ${q['author'] ?? 'Unknown'}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                  height: 25,
                                  thickness: 1,
                                  color: colorScheme.outline,
                                ),

                                // Choices
                                Text(
                                  "Choices:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(q['options'] as List<dynamic>?)?.map((
                                      choice,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                          horizontal: 8.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                choice.toString(),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList() ??
                                    [
                                      Text(
                                        "No choices available",
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                const SizedBox(height: 12),

                                // Correct Answer
                                Text(
                                  "Correct Answer: ${q['correctAnswer'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Divider(
                                  height: 25,
                                  thickness: 1,
                                  color: colorScheme.outline,
                                ),

                                // Dates and Approval/Rejection info
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Created: ${formatDate(q['createdAt'] ?? '')}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (q['updatedAt'] != null)
                                      Text(
                                        "Modified: ${formatDate(q['updatedAt'])}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                                if (isApproved && q['approvedBy'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Approved By: ${q['approvedBy']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (q['approvedAt'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Approved On: ${formatDate(q['approvedAt'])}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (isRejected && q['rejectedBy'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Rejected By: ${q['rejectedBy']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (q['rejectedAt'] != null)
                                        Text(
                                          "Rejected On: ${formatDate(q['rejectedAt'])}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 20),

                                // Action Buttons
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Approve / Revoke / Reject buttons logic
                                    if (isApproved) // If currently approved, show Revoke
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _updateQuestionApproval(
                                                docId,
                                                false,
                                              ), // Revoke approval
                                          icon: const Icon(Icons.undo),
                                          label: const Text("Revoke"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                colorScheme.errorContainer,
                                            foregroundColor:
                                                colorScheme.onErrorContainer,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      )
                                    else // If not approved (either pending or rejected)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _updateQuestionApproval(
                                                docId,
                                                true,
                                              ), // Approve
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Approve",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor:
                                                colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    // Reject button (always available if not currently rejected)
                                    if (!isRejected)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _rejectQuestion(docId),
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Reject",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _deleteQuestion(docId),
                                        icon: const Icon(Icons.delete_forever),
                                        label: const Text("Delete"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.error,
                                          foregroundColor: colorScheme.onError,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
