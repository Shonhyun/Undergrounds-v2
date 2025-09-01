import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:learningexamapp/screens/file_viewers/pdf_viewer_page.dart'; // Import your PDF viewer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

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
  bool isRefreshing = false;
  StreamSubscription<QuerySnapshot>? _subscription;
  Map<String, String> _urlCache = {};
  static const String _cacheKey = 'pdf_materials_cache_';

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeUpdates() {
    // Listen to Firestore for real-time updates on file metadata
    _subscription = FirebaseFirestore.instance
        .collection('file_metadata')
        .doc(widget.courseName.toLowerCase())
        .collection('pdfs')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _loadPdfFiles(); // Refresh when metadata changes
      }
    });
  }

  Future<void> _loadPdfFiles() async {
    if (isRefreshing) return; // Prevent multiple simultaneous loads
    
    setState(() {
      if (pdfFiles.isEmpty) isLoading = true;
      isRefreshing = true;
    });

    // First, try to load from cache for instant display
    await _loadFromCache();

    String courseName = widget.courseName;
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      ListResult result =
          await storage.ref('files/subjects/$courseName/pdfs').listAll();

      List<Map<String, dynamic>> loadedFiles = [];

      // Load metadata in parallel for better performance
      List<Future<Map<String, dynamic>>> metadataFutures = result.items.map((item) async {
        try {
          FullMetadata metadata = await item.getMetadata();
          return {
            'name': item.name,
            'isFree': metadata.customMetadata?['isFree'] == 'true',
            'lastModified': metadata.updated ?? DateTime.now(),
            'size': metadata.size,
            'ref': item,
          };
        } catch (e) {
          print("Error loading metadata for ${item.name}: $e");
          return {
            'name': item.name,
            'isFree': false,
            'lastModified': DateTime.now(),
            'size': 0,
            'ref': item,
          };
        }
      }).toList();

      // Wait for all metadata to load in parallel
      List<Map<String, dynamic>> metadataResults = await Future.wait(metadataFutures);

      // Sort by last modified date
      metadataResults.sort((a, b) => b['lastModified'].compareTo(a['lastModified']));

      loadedFiles = metadataResults;

      // Cache the new data
      await _cacheData(loadedFiles);

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          pdfFiles = loadedFiles;
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      print("Error loading PDFs: $e");

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  // Load data from local cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKey + widget.courseName.toLowerCase();
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final List<Map<String, dynamic>> cachedFiles = decoded.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
        
        if (mounted) {
          setState(() {
            pdfFiles = cachedFiles;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading from cache: $e");
    }
  }

  // Cache data to local storage
  Future<void> _cacheData(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKey + widget.courseName.toLowerCase();
      
      // Convert data to cacheable format (remove ref objects)
      final List<Map<String, dynamic>> cacheableData = data.map((item) {
        final Map<String, dynamic> cacheable = Map.from(item);
        cacheable.remove('ref'); // Remove Firebase ref objects
        return cacheable;
      }).toList();
      
      await prefs.setString(cacheKey, jsonEncode(cacheableData));
    } catch (e) {
      print("Error caching data: $e");
    }
  }

  // Lazy load download URL only when needed
  Future<String> _getDownloadUrl(String fileName) async {
    if (_urlCache.containsKey(fileName)) {
      return _urlCache[fileName]!;
    }

    try {
      String courseName = widget.courseName;
      String url = await FirebaseStorage.instance
          .ref('files/subjects/$courseName/pdfs/$fileName')
          .getDownloadURL();
      
      _urlCache[fileName] = url;
      return url;
    } catch (e) {
      print("Error getting download URL for $fileName: $e");
      return '';
    }
  }

  Future<void> _refreshMaterials() async {
    _urlCache.clear(); // Clear cache on refresh
    await _loadPdfFiles();
  }

  @override
  Widget build(BuildContext context) {
    bool isEnrolled =
        widget.userData?['enrollments']?[widget.courseName
            .toLowerCase()]['enrolled'] ??
        false;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onBack),
        title: Text("${widget.courseName} - PDF Materials"),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          IconButton(
            icon: Icon(isRefreshing ? Icons.refresh : Icons.refresh),
            onPressed: isRefreshing ? null : _refreshMaterials,
          ),
        ],
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
                      subtitle: Text(
                        'Size: ${_formatFileSize(pdfFiles[index]['size'] ?? 0)}',
                        style: TextStyle(
                          color: canAccess ? Colors.white70 : Colors.grey,
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
                              ? () async {
                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Get download URL
                                String pdfUrl = await _getDownloadUrl(pdfFiles[index]['name']);
                                
                                // Hide loading indicator
                                Navigator.pop(context);
                                
                                if (pdfUrl.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PDFViewerPage(
                                            fileUrl: pdfUrl,
                                            fileName: pdfFiles[index]['name'],
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error loading PDF. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                              : () {
                                // Show snackbar explaining why the material is locked
                                String reason = isFree 
                                    ? 'This material is not available yet.'
                                    : 'You need to enroll in this course to access this material.';
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(reason),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      },
                                    ),
                                  ),
                                );
                              },
                    ),
                  );
                },
              ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
