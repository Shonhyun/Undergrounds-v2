import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:learningexamapp/screens/file_viewers/pdf_viewer_page.dart';
import 'package:learningexamapp/screens/file_viewers/video_player_page.dart';

class ManageFilesPage extends StatefulWidget {
  const ManageFilesPage({super.key});

  @override
  State<ManageFilesPage> createState() => _ManageFilesPageState();
}

class _ManageFilesPageState extends State<ManageFilesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> subjects = [
    {'name': 'MATH'},
    {'name': 'ESAS'},
    {'name': 'EE'},
    {'name': 'REFRESHER'},
  ];

  int _selectedSubjectIndex = 0;

  List<Map<String, dynamic>> pdfFiles = [];
  List<Map<String, dynamic>> videoFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    await _loadPdfFiles();
    await _loadVideoFiles();
  }

  Future<void> _loadPdfFiles() async {
    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      ListResult result =
          await storage.ref('files/subjects/$subjectName/pdfs').listAll();

      List<Map<String, dynamic>> loadedFiles = [];

      for (var item in result.items) {
        FullMetadata metadata = await item.getMetadata();
        DateTime lastModified =
            metadata.updated ?? DateTime.now(); // Get last modified date

        loadedFiles.add({
          'name': item.name,
          'isFree': metadata.customMetadata?['isFree'] == 'true',
          'lastModified': lastModified, // Store last modified date
        });
      }

      // Sort the files by last modified date in descending order (most recent first)
      loadedFiles.sort(
        (a, b) => b['lastModified'].compareTo(a['lastModified']),
      );

      setState(() {
        pdfFiles = loadedFiles;
      });
    } catch (e) {
      print("Error loading PDFs: $e");
    }
  }

  Future<void> _loadVideoFiles() async {
    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      ListResult result =
          await storage.ref('files/subjects/$subjectName/videos').listAll();

      List<Map<String, dynamic>> loadedFiles = [];

      for (var item in result.items) {
        FullMetadata metadata = await item.getMetadata();
        DateTime lastModified =
            metadata.updated ?? DateTime.now(); // Get last modified date

        loadedFiles.add({
          'name': item.name,
          'isFree': metadata.customMetadata?['isFree'] == 'true',
          'lastModified': lastModified, // Store last modified date
        });
      }

      // Sort the files by last modified date in descending order (most recent first)
      loadedFiles.sort(
        (a, b) => b['lastModified'].compareTo(a['lastModified']),
      );

      setState(() {
        videoFiles = loadedFiles;
      });
    } catch (e) {
      print("Error loading Videos: $e");
    }
  }

  Future<void> _uploadPdfFile() async {
    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      if (!fileName.toLowerCase().endsWith('.pdf')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only PDF files are allowed.')),
        );
        return;
      }

      if (pdfFiles.any((f) => f['name'] == fileName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A file named "$fileName" already exists. Please rename it and try again.',
            ),
          ),
        );
        return;
      }

      _showLoadingDialog("Uploading PDF... Please wait.");

      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref = storage.ref(
          'files/subjects/$subjectName/pdfs/$fileName',
        );

        SettableMetadata metadata = SettableMetadata(
          customMetadata: {'isFree': 'false'},
        );

        UploadTask uploadTask = ref.putFile(file, metadata);

        await uploadTask.whenComplete(() async {
          Navigator.pop(context);
          FullMetadata uploadedMetadata = await ref.getMetadata();
          setState(() {
            pdfFiles.add({
              'name': fileName,
              'isFree': uploadedMetadata.customMetadata?['isFree'] == 'true',
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF "$fileName" uploaded successfully.')),
          );
        });
      } catch (e) {
        Navigator.pop(context);
        print("Error uploading PDF: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading PDF: $e')));
      }
    }
  }

  Future<void> _uploadVideoFile() async {
    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      if (videoFiles.any((f) => f['name'] == fileName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A file named "$fileName" already exists. Please rename it and try again.',
            ),
          ),
        );
        return;
      }

      _showLoadingDialog("Uploading Video... Please wait.");

      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref = storage.ref(
          'files/subjects/$subjectName/videos/$fileName',
        );

        SettableMetadata metadata = SettableMetadata(
          customMetadata: {'isFree': 'false'},
        );

        UploadTask uploadTask = ref.putFile(file, metadata);

        await uploadTask.whenComplete(() async {
          Navigator.pop(context);
          FullMetadata uploadedMetadata = await ref.getMetadata();
          setState(() {
            videoFiles.add({
              'name': fileName,
              'isFree': uploadedMetadata.customMetadata?['isFree'] == 'true',
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video "$fileName" uploaded successfully.')),
          );
        });
      } catch (e) {
        Navigator.pop(context);
        print("Error uploading video: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading video: $e')));
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteFile(String fileName, String type) async {
    bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete File'),
                content: Text('Are you sure you want to delete "$fileName"?'),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  TextButton(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmDelete) return;

    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      Reference fileRef = storage.ref(
        'files/subjects/$subjectName/$type/$fileName',
      );
      await fileRef.delete();

      setState(() {
        if (type == 'pdfs') {
          pdfFiles.removeWhere((f) => f['name'] == fileName);
        } else {
          videoFiles.removeWhere((f) => f['name'] == fileName);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type file "$fileName" deleted.')),
      );
    } catch (e) {
      print("Error deleting file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
    }
  }

  Future<void> _showEditDialog(String fileName, String type) async {
    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      Reference fileRef = storage.ref(
        'files/subjects/$subjectName/$type/$fileName',
      );
      FullMetadata metadata = await fileRef.getMetadata();
      bool isFree = metadata.customMetadata?['isFree'] == 'true';

      bool? result = await showDialog<bool>(
        context: context,
        builder: (context) {
          bool tempIsFree = isFree;
          return AlertDialog(
            title: const Text('Edit File Settings'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SwitchListTile(
                  title: const Text('Is this file free?'),
                  value: tempIsFree,
                  onChanged: (value) {
                    setState(() {
                      tempIsFree = value;
                    });
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, tempIsFree),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (result != null && result != isFree) {
        await fileRef.updateMetadata(
          SettableMetadata(customMetadata: {'isFree': result.toString()}),
        );

        _loadFiles(); // reload to reflect changes

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File "$fileName" is now marked as ${result ? 'Free' : 'Not Free'}.',
            ),
          ),
        );
      }
    } catch (e) {
      print("Error editing file metadata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update file access: $e")),
      );
    }
  }

  void _selectSubject(int index) {
    setState(() {
      _selectedSubjectIndex = index;
    });
    _loadFiles();
  }

  void _openFile(String fileName, String type) async {
    String subjectName = subjects[_selectedSubjectIndex]['name'];
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      String url =
          await storage
              .ref('files/subjects/$subjectName/$type/$fileName')
              .getDownloadURL();

      if (type == 'pdfs') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PDFViewerPage(fileUrl: url, fileName: fileName),
          ),
        );
      } else if (type == 'videos') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VideoPlayerPage(fileUrl: url, fileName: fileName),
          ),
        );
      }
    } catch (e) {
      print('Error opening file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
    }
  }

  Widget _buildFileList(List<Map<String, dynamic>> files, String type) {
    IconData icon = type == 'pdfs' ? Icons.picture_as_pdf : Icons.video_library;
    Color iconColor = type == 'pdfs' ? Colors.red : Colors.blue;

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = file['name'];
        final isFree = file['isFree'] == true;

        return Card(
          elevation: 3.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            leading: Icon(icon, color: iconColor),
            title: GestureDetector(
              onTap: () => _openFile(fileName, type),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFree)
                    Container(
                      margin: const EdgeInsets.only(left: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Text(
                        'Free',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(fileName, type);
                } else if (value == 'delete') {
                  _deleteFile(fileName, type);
                }
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Files'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: Colors.transparent),
          tabs: const [Tab(text: 'PDFs'), Tab(text: 'Videos')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              elevation: 5.0,
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: theme.cardTheme.color,
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedSubjectIndex,
                  onChanged: (int? newIndex) {
                    if (newIndex != null) {
                      _selectSubject(newIndex);
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  items: List.generate(subjects.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        subjects[index]['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                  isExpanded: true,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFileList(pdfFiles, 'pdfs'),
                _buildFileList(videoFiles, 'videos'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _tabController.index == 0 ? _uploadPdfFile : _uploadVideoFile,
        child: const Icon(Icons.upload_file),
        backgroundColor: _tabController.index == 0 ? Colors.red : Colors.blue,
        tooltip: _tabController.index == 0 ? 'Upload PDF' : 'Upload Video',
      ),
    );
  }
}
