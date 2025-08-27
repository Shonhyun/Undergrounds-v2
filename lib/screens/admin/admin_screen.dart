import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/admin/exams/manage_subjects_exams_screen.dart';
import 'package:learningexamapp/screens/admin/library/manage_library_menu_screen.dart';
import 'package:learningexamapp/screens/admin/manage_announcements_screen.dart';
import 'package:learningexamapp/screens/admin/manage_files_screen.dart';
import 'package:learningexamapp/screens/admin/manage_live_sessions.dart';
import 'package:learningexamapp/screens/admin/users/manage_users_screen.dart';
import 'package:learningexamapp/utils/common_widgets/dashboard_card.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class AdminPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const AdminPage({super.key, this.userData});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Admin Dashboard"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Admin!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    title: "Manage Live Sessions",
                    icon: Icons.video_camera_front,
                    onTap: () {
                      Navigator.push(context, slideForward(ManageLiveSessionsPage()));
                    },
                  ),
                  DashboardCard(
                    title: "Manage PDFs & Videos",
                    icon: Icons.cloud_upload,
                    onTap: () {
                      Navigator.push(context, slideForward(ManageFilesPage()));
                    },
                  ),
                  DashboardCard(
                    title: "Manage Exams",
                    icon: Icons.edit_document,
                    onTap: () {
                      Navigator.push(context, slideForward(ManageSubjectsPage()));
                    },
                  ),
                  DashboardCard(
                    title: "Manage User Accounts",
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(context, slideForward(ManageUserAccountsPage()));
                    },
                  ),
                  DashboardCard(
                    title: "Manage Announcements",
                    icon: Icons.campaign,
                    onTap: () {
                      Navigator.push(context, slideForward(ManageAnnouncementsPage()));
                    },
                  ),
                  DashboardCard(
                    title: "Manage Library",
                    icon: Icons.local_library,
                    onTap: () {
                      Navigator.push(context, slideForward(ManageLibraryMenuScreen(userData: userData)));
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
