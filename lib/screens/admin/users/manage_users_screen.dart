import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:learningexamapp/screens/admin/users/update_user_screen.dart';
import 'package:learningexamapp/theme/elevation_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:string_similarity/string_similarity.dart';

class ManageUserAccountsPage extends StatefulWidget {
  const ManageUserAccountsPage({super.key});

  @override
  State<ManageUserAccountsPage> createState() => _ManageUserAccountsPageState();
}

class _ManageUserAccountsPageState extends State<ManageUserAccountsPage> {
  // Choices for dropdown menus
  List<String> allSubjects = ['All', 'Math', 'ESAS', 'EE', 'Refresher'];
  List<String> enrollmentOptions = ['All', 'Enrolled', 'Unenrolled'];

  // For fetchUsers();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = false;

  // For filtering
  String _searchQuery = '';
  String _subjectFilter = 'All';
  bool _isBannedFilter = false;
  String _enrollmentFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    // Load cached users if available
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedUsers = prefs.getString('cachedUsers');

    if (cachedUsers != null) {
      // If cached data is available, use it
      List<dynamic> cachedList = json.decode(cachedUsers);
      users =
          cachedList.map((user) => Map<String, dynamic>.from(user)).toList();
      filteredUsers = users; // Initialize filtered users
      setState(() {
        isLoading = false;
      });
      return; // Exit early since we have cached data
    }

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedUsers = [];

        for (final doc in querySnapshot.docs) {
          String userId = doc.id;
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

          Timestamp? timestamp = userData["dateJoined"] as Timestamp?;
          String formattedDate =
              timestamp != null
                  ? DateFormat('MM/dd/yyyy').format(timestamp.toDate())
                  : "Unknown";

          List<String> enrollmentIds = await fetchUserEnrollmentIds(userId);
          bool isEnrolled = enrollmentIds.isNotEmpty;

          fetchedUsers.add({
            "uid": userId,
            "fullName": userData["fullName"] ?? "No name",
            "email": userData["email"] ?? "No Email",
            "dateJoined": formattedDate,
            "isBanned": userData["isBanned"] ?? false,
            "enrollmentIds": enrollmentIds,
            "isEnrolled": isEnrolled,
          });
        }

        // Cache the fetched users
        await prefs.setString('cachedUsers', json.encode(fetchedUsers));

        setState(() {
          users = fetchedUsers;
          filteredUsers = fetchedUsers; // Initialize filtered users
          isLoading = false;
        });
      } else {
        setState(() {
          users.clear();
          filteredUsers.clear();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching users: $e");
    }
  }

  void searchUsers(String query) {
    setState(() {
      _searchQuery = query.trim();
      _filterUsers();
    });
  }

  void _filterUsers() {
    filteredUsers =
        users.where((user) {
          final matchesSearchQuery = _stringSimilaritySearch(
            user['fullName'],
            _searchQuery,
          );
          final matchesSubjectFilter =
              _subjectFilter == 'All' ||
              user['enrollmentIds'].contains(_subjectFilter.toLowerCase());

          final matchesBannedFilter = user['isBanned'] == _isBannedFilter;

          final matchesEnrollmentFilter =
              _enrollmentFilter == 'All' ||
              user['isEnrolled'] == (_enrollmentFilter == 'Enrolled');

          return matchesSearchQuery &&
              matchesSubjectFilter &&
              matchesBannedFilter &&
              matchesEnrollmentFilter;
        }).toList();
  }

  bool _stringSimilaritySearch(String fullName, String searchQuery) {
    if (searchQuery.isEmpty) return true;

    // Calculate the similarity score using the Jaro-Winkler algorithm
    final similarity = StringSimilarity.compareTwoStrings(
      fullName.toLowerCase(),
      searchQuery.toLowerCase(),
    );

    // Only consider matches that are 80% similar or higher
    return similarity >= 0.8; // 80% similarity
  }

  Future<List<String>> fetchUserEnrollmentIds(String userId) async {
    QuerySnapshot enrollmentSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('enrollments')
            .where('enrolled', isEqualTo: true)
            .get();

    return enrollmentSnapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage User Accounts'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search query
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: ElevationColors.dark01dp,
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                searchUsers(value);
              },
            ),
            const SizedBox(height: 16),
            // Dropdown and Banned Switch
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDropdown(
                    label: "Subject",
                    value: _subjectFilter,
                    options: allSubjects,
                    onChanged: (value) {
                      setState(() {
                        _subjectFilter = value!;
                      });
                      _filterUsers();
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    label: "Enrollment",
                    value: _enrollmentFilter,
                    options: enrollmentOptions,
                    onChanged: (value) {
                      setState(() {
                        _enrollmentFilter = value!;
                      });
                      _filterUsers();
                    },
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Switch(
                        value: _isBannedFilter,
                        onChanged: (value) {
                          setState(() {
                            _isBannedFilter = value;
                          });
                          _filterUsers();
                        },
                        activeColor: Colors.red,
                      ),
                      Text(
                        'Banned',
                        style: TextStyle(
                          color:
                              _isBannedFilter
                                  ? Colors.red
                                  : theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('First time loading, this may take a moment…'),
                  ],
                ),
              )
            else
              Expanded(
                // User List
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return GestureDetector(
                      onTap: () async {
                        bool? updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateUserPage(user: user),
                          ),
                        );

                        if (updated == true) {
                          fetchUsers();
                        }
                      },
                      child: Card(
                        color:
                            user['isBanned']
                                ? Colors.red.shade900
                                : ElevationColors.dark02dp,
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade300,
                            child: Text(
                              user['fullName'][0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            user['fullName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email'],
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Subjects: ${user['enrollmentIds'].isNotEmpty ? user['enrollmentIds'].map((id) => id[0].toUpperCase() + id.substring(1)).join(", ") : "Unenrolled"}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              Text(
                                'Date Joined: ${user['dateJoined']}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                          trailing:
                              user['isBanned']
                                  ? const Icon(Icons.block, color: Colors.red)
                                  : const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Dropdown method
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: ElevationColors.dark02dp,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      items:
          options.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
    );
  }
}
