import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/home/library/browse_author_screen.dart';
import 'package:learningexamapp/screens/home/library/browse_subject_screen.dart';
import 'package:learningexamapp/screens/home/library/browse_date_screen.dart';
import 'package:learningexamapp/screens/home/library/create_questions_screen.dart';
import 'package:learningexamapp/screens/home/library/my_questions_screen.dart';
import 'package:learningexamapp/utils/common_widgets/dashboard_card.dart';
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class LibraryHomeScreen extends StatefulWidget {
  final String libraryName;
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  const LibraryHomeScreen({
    super.key,
    required this.libraryName,
    required this.userData,
    required this.onBack,
  });

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
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
                leading: BackButton(onPressed: widget.onBack),
                title: Text("Library", style: theme.appBarTheme.titleTextStyle),
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
                      "Hello, ${widget.userData?['fullName'] ?? 'User'}!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Library Dashboard",
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
                            title: "CREATE YOUR OWN QUESTION",
                            icon: Icons.create,
                            onTap: () {
                              Navigator.push(
                                context,
                                slideForward(CreateQuestionsScreen(userData: widget.userData,)),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "BROWSE BY AUTHOR",
                            icon: Icons.person,
                            onTap: () {
                              Navigator.push(
                                context,
                                slideForward(BrowseByAuthorScreen(userData: widget.userData,)),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "MY QUESTIONS",
                            icon: Icons.question_answer,
                            onTap: () {
                              Navigator.push(
                                context,
                                slideForward(MyQuestionsScreen(userData: widget.userData,))
                              );
                            },
                          ),
                          DashboardCard(
                            title: "BROWSE BY SUBJECT",
                            icon: Icons.subject,
                            onTap: () {
                              Navigator.push(
                                context,
                                slideForward(BrowseBySubjectScreen(userData: widget.userData,))
                              ); // Navigate to Browse by Subject screen
                            },
                          ),
                          DashboardCard(
                            title: "BROWSE BY DATE",
                            icon: Icons.date_range,
                            onTap: () {
                              Navigator.push(
                                context,
                                slideForward(BrowseByDateScreen(userData: widget.userData,))
                              ); // Navigate to Browse by Date screen
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
