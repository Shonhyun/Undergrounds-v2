import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learningexamapp/screens/home/exams/exam_list_screen.dart';
import 'package:learningexamapp/screens/home/pdf_screen.dart';
import 'package:learningexamapp/screens/home/video_screen.dart';
import 'package:learningexamapp/utils/common_widgets/dashboard_card.dart';
import 'package:url_launcher/url_launcher.dart';

class CoursePage extends StatefulWidget {
  final String courseName;
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  const CoursePage({
    super.key,
    required this.courseName,
    required this.userData,
    required this.onBack,
  });

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  String? zoomLink;
  bool isLoading = true;

  Future<void> fetchZoomLink() async {
    final subjectId = widget.courseName.trim().toLowerCase();

    if (subjectId.isEmpty) {
      if (!mounted) return;
      setState(() {
        zoomLink = null;
        isLoading = false;
      });
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('subjects')
              .doc(subjectId)
              .get();

      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          zoomLink = doc.data()?['zoomLink'];
          isLoading = false;
        });
      } else {
        setState(() {
          zoomLink = null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        zoomLink = null;
        isLoading = false;
      });
    }
  }

  Future<void> launchLiveSession() async {
    if (zoomLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live session link is not available.')),
      );
      return;
    }

    final Uri url = Uri.parse(zoomLink!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $zoomLink')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Avoid calling fetchZoomLink() inside build. Move to initState or use a state check to prevent repeated calls.
    fetchZoomLink();

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
                title: Text(
                  widget.courseName,
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
                      "Hello, ${widget.userData?['fullName'] ?? 'User'}!",
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
                            title: "LIVE SESSION",
                            icon: Icons.live_tv,
                            onTap: launchLiveSession,
                          ),
                          DashboardCard(
                            title: "PDF MATERIALS",
                            icon: Icons.picture_as_pdf,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PDFScreen(
                                        courseName: widget.courseName,
                                        userData: widget.userData,
                                        onBack: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "VIDEO MATERIALS",
                            icon: Icons.video_library,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => VideoScreen(
                                        courseName: widget.courseName,
                                        userData: widget.userData,
                                        onBack: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: "EXAMS",
                            icon: Icons.assignment,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ExamListScreen(
                                        courseName: widget.courseName,
                                        userData: widget.userData,
                                        onBack: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                ),
                              );
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
