import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learningexamapp/screens/admin/admin_screen.dart';
import 'home/home_screen.dart';
import 'settings_screen.dart';
import 'profile/profile_screen.dart';
import '../utils/common_widgets/custom_bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navBarItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get user document
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      Map<String, dynamic> userData =
          userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};

      // Include the user's ID
      userData['id'] = user.uid;

      // Get enrollments from subcollection
      QuerySnapshot enrollmentDocs =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('enrollments')
              .get();

      Map<String, dynamic> enrollments = {};
      for (var doc in enrollmentDocs.docs) {
        enrollments[doc.id] = doc.data(); // Store each enrollment
      }

      // Add enrollments to userData
      userData['enrollments'] = enrollments;

      if (mounted) {
        setState(() {
          _userData = userData;
        });
        _setupPages();
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  void _setupPages() {
    String? role = _userData?['role']?.toString().trim().toLowerCase();

    if (role == "admin") {
      _pages = [
        AdminPage(userData: _userData),
        const SettingsPage(),
        ProfilePage(userData: _userData),
      ];
      _navBarItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      _pages = [
        HomePage(userData: _userData),
        const SettingsPage(),
        ProfilePage(userData: _userData),
      ];
      _navBarItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    setState(() {});
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _navBarItems,
      ),
    );
  }
}
