import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:learningexamapp/screens/profile/update_profile_page.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfilePage({super.key, this.userData});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _profileData;
  late Future<Map<String, bool>> _enrollmentData;

  @override
  void initState() {
    super.initState();
    _profileData = _fetchProfileData();
    _enrollmentData = _fetchEnrollmentData();
  }

  // Fetch Profile Data (completed exams, average score, etc.)
  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      final userId = widget.userData?['id'];
      if (userId == null) {
        throw Exception('User ID is null');
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('examHistory')
              .get();

      int completedExams = 0;
      double totalScore = 0;
      double totalTimeSpent = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final score = data['correctAnswers'] ?? 0;
        final totalQuestions = data['totalQuestions'] ?? 1;
        final timeTaken = data['timeTaken'] ?? 0;

        if (score > 0) {
          completedExams++;
          totalScore +=
              (score / totalQuestions) * 100; // Calculate percentage score
          totalTimeSpent += timeTaken; // Sum total time spent
        }
      }

      final averageScore =
          completedExams > 0
              ? (totalScore / completedExams).toStringAsFixed(0)
              : '0';
      final formattedTime = formatDuration(totalTimeSpent);

      return {
        'completedExams': completedExams.toString(),
        'averageScore': '$averageScore%',
        'totalTimeSpent': formattedTime,
      };
    } catch (e) {
      print('Error fetching profile data: $e');
      return {
        'completedExams': '0',
        'averageScore': '0%',
        'totalTimeSpent': '0:00',
      };
    }
  }

  // Fetch Enrollment Data
  Future<Map<String, bool>> _fetchEnrollmentData() async {
    try {
      final userId = widget.userData?['id'];
      if (userId == null) {
        throw Exception('User ID is null');
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('enrollments')
              .get();

      final Map<String, bool> enrollmentStatus = {};
      snapshot.docs.forEach((doc) {
        final subject = doc.id; // EE, ESAS, Math, Refresher
        final enrolled = doc.data()['enrolled'] ?? false;
        enrollmentStatus[subject] = enrolled;
      });

      return enrollmentStatus;
    } catch (e) {
      print('Error fetching enrollment data: $e');
      return {'ee': false, 'esas': false, 'math': false, 'refresher': false};
    }
  }

  // Format time duration
  String formatDuration(double seconds) {
    final Duration duration = Duration(seconds: seconds.toInt());
    return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Profile"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile data'));
          }

          final profileData = snapshot.data ?? {};

          return FutureBuilder<Map<String, bool>>(
            future: _enrollmentData,
            builder: (context, enrollmentSnapshot) {
              if (enrollmentSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (enrollmentSnapshot.hasError) {
                return const Center(
                  child: Text('Error loading enrollment data'),
                );
              }

              final enrollmentData = enrollmentSnapshot.data ?? {};

              // Check if the user is a student
              bool isStudent = widget.userData?['role'] == 'student';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            widget.userData?['fullName'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            toBeginningOfSentenceCase(
                                  widget.userData?['role'] ?? '',
                                ) ??
                                '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          if ((widget.userData?['schoolName'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                widget.userData!['schoolName'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => UpdateProfilePage(
                                    userData: widget.userData,
                                  ),
                            ),
                          );

                          // Refresh userData after returning from update page
                          final userId = widget.userData?['id'];
                          if (userId != null) {
                            final userSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .get();

                            if (mounted && userSnapshot.exists) {
                              if (userSnapshot.data() != null) {
                                widget.userData!.addAll(userSnapshot.data()!);
                                // Update the state to reflect changes
                                setState(() {});
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Update Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).secondaryHeaderColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Show all cards if the user is a student
                    if (isStudent) ...[
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ProfileInfoItem(
                                title: "Completed Exams",
                                value: profileData['completedExams'] ?? '0',
                              ),
                              ProfileInfoItem(
                                title: "Average Score",
                                value: profileData['averageScore'] ?? '0%',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ProfileInfoItem(
                                title: "Total Time Spent",
                                value: profileData['totalTimeSpent'] ?? '0:00',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enrollments",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ProfileInfoItem(
                                      title: "EE",
                                      value:
                                          enrollmentData['ee'] ?? false
                                              ? 'Enrolled'
                                              : 'Not Enrolled',
                                    ),
                                  ),
                                  Expanded(
                                    child: ProfileInfoItem(
                                      title: "ESAS",
                                      value:
                                          enrollmentData['esas'] ?? false
                                              ? 'Enrolled'
                                              : 'Not Enrolled',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ProfileInfoItem(
                                      title: "Math",
                                      value:
                                          enrollmentData['math'] ?? false
                                              ? 'Enrolled'
                                              : 'Not Enrolled',
                                    ),
                                  ),
                                  Expanded(
                                    child: ProfileInfoItem(
                                      title: "Refresher",
                                      value:
                                          enrollmentData['refresher'] ?? false
                                              ? 'Enrolled'
                                              : 'Not Enrolled',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileInfoItem extends StatelessWidget {
  final String title;
  final String value;
  const ProfileInfoItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
