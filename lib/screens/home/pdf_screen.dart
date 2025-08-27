import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:learningexamapp/screens/file_viewers/pdf_viewer_page.dart'; // Import your PDF viewer
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';

class PDFScreen extends StatefulWidget {
  final String courseName;
  final Map<String, dynamic>? userData;
  final VoidCallback onBack;

  const PDFScreen({
    Key? key,
    required this.courseName,
    required this.userData,
    required this.onBack,
  }) : super(key: key);

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  List<Map<String, dynamic>> pdfFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    String courseName = widget.courseName;
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      ListResult result =
          await storage.ref('files/subjects/$courseName/pdfs').listAll();

      List<Map<String, dynamic>> loadedFiles = [];

      for (var item in result.items) {
        FullMetadata metadata = await item.getMetadata();
        DateTime lastModified =
            metadata.updated ?? DateTime.now(); // Get the last modified date

        loadedFiles.add({
          'name': item.name,
          'isFree': metadata.customMetadata?['isFree'] == 'true',
          'url': await item.getDownloadURL(), // Fetch the download URL
          'lastModified': lastModified,
        });
      }

      // Sort the files by last modified date in descending order (most recent first)
      loadedFiles.sort(
        (a, b) => b['lastModified'].compareTo(a['lastModified']),
      );

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          pdfFiles = loadedFiles;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading PDFs: $e");

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEnrolled =
        widget.userData?['enrollments']?[widget.courseName
            .toLowerCase()]['enrolled'] ??
        false;

    return Scaffold(
      appBar: buildAppBar(
        context,
        "${widget.courseName} - PDF Materials",
        leading: BackButton(onPressed: widget.onBack),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : pdfFiles.isEmpty
              ? Center(
                child: Text(
                  'No PDF materials available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pdfFiles.length,
                itemBuilder: (context, index) {
                  bool isFree = pdfFiles[index]['isFree'];
                  bool canAccess = isFree || isEnrolled;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: canAccess ? Colors.red : Colors.grey,
                      ),
                      title: Text(
                        pdfFiles[index]['name'],
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
                                // Navigate to the PDF viewer screen
                                String pdfUrl = pdfFiles[index]['url'];
                                String pdfFileName = pdfFiles[index]['name'];

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PDFViewerPage(
                                          fileUrl: pdfUrl,
                                          fileName: pdfFileName,
                                        ),
                                  ),
                                );
                              }
                              : null, // Disable tap if not accessible
                    ),
                  );
                },
              ),
    );
  }
}
