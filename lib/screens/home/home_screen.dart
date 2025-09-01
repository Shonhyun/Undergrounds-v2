import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/home/course_screen.dart';
import 'package:learningexamapp/screens/home/exam_scores_screen.dart';
import 'package:learningexamapp/screens/home/library/library_home_screen.dart';
import 'package:learningexamapp/screens/home/payments/program_select_screen.dart';
import 'package:learningexamapp/utils/common_widgets/dashboard_card.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _previousPageIndex = 0; // Used for back slide animation
  int _pageIndex = 0;
  String _selectedCourse = '';

  void _goToCoursePage(String courseName) {
    setState(() {
      _previousPageIndex = _pageIndex;
      _pageIndex = 1;
      _selectedCourse = courseName;
    });
  }

  void _goToExamScoresPage() {
    setState(() {
      _previousPageIndex = _pageIndex;
      _pageIndex = 2;
    });
  }

  void _goToProgramSelectPage() {
    setState(() {
      _previousPageIndex = _pageIndex;
      _pageIndex = 3;
    });
  }

  void _goToLibraryHomePage() {
    setState(() {
      _previousPageIndex = _pageIndex;
      _pageIndex = 4;
    });
  }

  void _goBack() {
    setState(() {
      _previousPageIndex = _pageIndex;
      _pageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Logic for slide + fade animation when clicking a button in the gridview
      body: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 1000,
        ), // Adjust for slide duration
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isPageForward = _pageIndex > _previousPageIndex;

          final beginOffset =
              isPageForward
                  ? const Offset(
                    1.0,
                    0.0,
                  ) // Slides in from right if user is inside a homepage
                  : const Offset(
                    -1.0,
                    0.0,
                  ); // Slides in from left if user is in the subpage

          final slideAnimation = Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },

        // Indexed stack logic for navigation
        child: IndexedStack(
          key: ValueKey<int>(_pageIndex), // Triggers animation
          index: _pageIndex,
          children: [
            HomeDashboard(
              userData: widget.userData,
              onCourseTap: _goToCoursePage,
              onExamScoresTap: _goToExamScoresPage,
              goToProgramSelectPage: _goToProgramSelectPage,
              goToLibraryHomePage:
                  _goToLibraryHomePage, // Pass the callback to navigate to the library
            ),
            CoursePage(
              courseName: _selectedCourse,
              userData: widget.userData,
              onBack: _goBack,
            ),
            ExamScoresScreen(onBack: _goBack, userData: widget.userData),
            ProgramSelectScreen(onBack: _goBack, userData: widget.userData),
            LibraryHomeScreen(
              userData: widget.userData,
              onBack: _goBack,
              libraryName: '',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Function(String) onCourseTap;
  final VoidCallback onExamScoresTap;
  final VoidCallback goToProgramSelectPage;
  final VoidCallback goToLibraryHomePage; // Add callback for Library navigation

  const HomeDashboard({
    required this.userData,
    required this.onCourseTap,
    required this.onExamScoresTap,
    required this.goToProgramSelectPage,
    required this.goToLibraryHomePage, // Pass the callback
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Home"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${userData?['fullName'] ?? 'User'}!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  DashboardCard(
                    title: "LIBRARY",
                    icon: Icons.local_library,
                    onTap:
                        goToLibraryHomePage, // Trigger the Library page navigation
                  ),
                  DashboardCard(
                    title: "MATH",
                    icon: Icons.calculate,
                    onTap: () => onCourseTap("MATH"),
                  ),
                  DashboardCard(
                    title: "ESAS",
                    icon: Icons.rule,
                    onTap: () => onCourseTap("ESAS"),
                  ),
                  DashboardCard(
                    title: "EE",
                    icon: Icons.electrical_services,
                    onTap: () => onCourseTap("EE"),
                  ),
                  DashboardCard(
                    title: "REFRESHER",
                    icon: Icons.refresh,
                    onTap: () => onCourseTap("REFRESHER"),
                  ),
                  DashboardCard(
                    title: "PAYMENTS",
                    icon: Icons.bar_chart,
                    onTap: goToProgramSelectPage,
                  ),
                  DashboardCard(
                    title: "EXAM SCORES",
                    icon: Icons.score,
                    onTap: onExamScoresTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
