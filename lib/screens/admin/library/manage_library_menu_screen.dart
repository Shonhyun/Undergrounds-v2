import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/admin/library/manage_instructors_screen.dart';
import 'package:learningexamapp/screens/admin/library/manage_library_screen.dart';
import 'package:learningexamapp/utils/common_widgets/dashboard_card.dart';
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class ManageLibraryMenuScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ManageLibraryMenuScreen({super.key, required this.userData});

  @override
  State<ManageLibraryMenuScreen> createState() =>
      _ManageLibraryMenuScreenState();
}

class _ManageLibraryMenuScreenState extends State<ManageLibraryMenuScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ClipRRect(
              child: AppBar(
                // The BackButton will now automatically pop the current route
                // No need for onPressed: widget.onBack
                leading: const BackButton(),
                title: Text(
                  "Admin Library",
                  style: theme.appBarTheme.titleTextStyle,
                ),
                centerTitle: true,
                backgroundColor: theme.appBarTheme.backgroundColor,
                elevation: 0,
                iconTheme: theme.appBarTheme.iconTheme,
                automaticallyImplyLeading: true,
              ),
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${widget.userData?['fullName'] ?? 'Admin'}!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          DashboardCard(
                            title: "Manage Questions",
                            icon: Icons.assignment,
                            onTap: () {
                              Navigator.push(context, slideForward(ManageLibraryQuestionsScreen(userData: widget.userData)));
                            },
                          ),
                          DashboardCard(
                            title: "Manage Instructors",
                            icon: Icons.school,
                            onTap: () {
                              Navigator.push(context, slideForward(ManageInstructorsScreen()));
                            },
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
