import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:learningexamapp/screens/file_viewers/video_player_page.dart'; // Import your video player
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';

class VideoScreen extends StatelessWidget {
  final String courseName;
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  VideoScreen({
    super.key,
    required this.courseName,
    required this.userData,
    required this.onBack,
  });

  Future<List<Map<String, dynamic>>> _loadVideoFiles() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    List<Map<String, dynamic>> loadedFiles = [];
    String subjectName = courseName.toUpperCase();

    try {
      ListResult result =
          await storage.ref('files/subjects/$subjectName/videos').listAll();

      for (var item in result.items) {
        FullMetadata metadata = await item.getMetadata();
        DateTime lastModified =
            metadata.updated ?? DateTime.now(); // Get last modified date

        loadedFiles.add({
          'name': item.name,
          'isFree': metadata.customMetadata?['isFree'] == 'true',
          'url': await item.getDownloadURL(), // Fetch the download URL
          'lastModified': lastModified, // Store last modified date
        });
      }

      // Sort the files by last modified date in descending order (most recent first)
      loadedFiles.sort(
        (a, b) => b['lastModified'].compareTo(a['lastModified']),
      );
    } catch (e) {
      print("Error loading videos: $e");
    }

    return loadedFiles;
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    // Extract enrollment status from userData
    bool isEnrolled =
        userData?['enrollments']?[courseName.toLowerCase()]['enrolled'] ??
        false;

    return Scaffold(
      appBar: buildAppBar(
        context,
        "${courseName} - Video Materials",
        leading: BackButton(onPressed: onBack),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadVideoFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading videos: ${snapshot.error}'),
            );
          }

          List<Map<String, dynamic>> videoFiles = snapshot.data ?? [];

          // If no videos are available, show a message
          if (videoFiles.isEmpty) {
            return Center(
              child: Text(
                'No video materials available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videoFiles.length,
            itemBuilder: (context, index) {
              bool isFree = videoFiles[index]['isFree'];
              bool canAccess = isFree || isEnrolled;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.play_circle_fill,
                    color: canAccess ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    videoFiles[index]['name'],
                    style: TextStyle(
                      color: canAccess ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing:
                      canAccess
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey,
                          ),
                  onTap:
                      canAccess
                          ? () {
                            // Get the video URL and file name
                            String videoUrl = videoFiles[index]['url'];
                            String videoFileName = videoFiles[index]['name'];

                            // Navigate to the VideoPlayerPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => VideoPlayerPage(
                                      fileUrl: videoUrl,
                                      fileName: videoFileName,
                                    ),
                              ),
                            );
                          }
                          : null, // Disable tap if not accessible
                ),
              );
            },
          );
        },
      ),
    );
  }
}
