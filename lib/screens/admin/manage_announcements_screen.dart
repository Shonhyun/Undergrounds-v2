import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper function to detect URLs and make them clickable
Widget _buildClickableText(String text, TextStyle? style) {
  // Regular expression to detect URLs
  final urlRegex = RegExp(
    r'(https?://[^\s]+)|(www\.[^\s]+)',
    caseSensitive: false,
  );
  
  if (!urlRegex.hasMatch(text)) {
    // No URLs found, return plain text with better styling
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
      text,
        style: style?.copyWith(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey.shade800,
        ) ?? TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
        textAlign: TextAlign.left,
        maxLines: null,
        softWrap: true,
      ),
    );
  }

  // Find all matches with their positions
  final matches = urlRegex.allMatches(text);
  List<InlineSpan> spans = [];
  int lastIndex = 0;
  
  for (final match in matches) {
    // Add text before the URL
    if (match.start > lastIndex) {
      final beforeText = text.substring(lastIndex, match.start);
      if (beforeText.isNotEmpty) {
        spans.add(TextSpan(
          text: beforeText,
          style: style?.copyWith(
            fontSize: 16,
            height: 1.5,
            color: Colors.grey.shade800,
          ) ?? TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.grey.shade800,
          ),
        ));
      }
    }
    
    // Add the clickable URL
    final url = match.group(0)!;
    String fullUrl = url;
    if (url.startsWith('www.')) {
      fullUrl = 'https://$url';
    }
    
    spans.add(TextSpan(
      text: url,
      style: style?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: Colors.blue.shade700,
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue.shade700,
        fontWeight: FontWeight.w500,
      ) ?? TextStyle(
        fontSize: 16,
        height: 1.5,
        color: Colors.blue.shade700,
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue.shade700,
        fontWeight: FontWeight.w500,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          try {
            final uri = Uri.parse(fullUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            // Handle URL launch errors silently
            debugPrint('Failed to launch URL: $e');
          }
        },
    ));
    
    lastIndex = match.end;
  }
  
  // Add remaining text after the last URL
  if (lastIndex < text.length) {
    final afterText = text.substring(lastIndex);
    if (afterText.isNotEmpty) {
      spans.add(TextSpan(
        text: afterText,
        style: style?.copyWith(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey.shade800,
        ) ?? TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
      ));
    }
  }
  
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
      softWrap: true,
    ),
  );
}

// Modal widget for adding new slides
class AddSlideModal extends StatefulWidget {
  final Function(String? text, String? imageUrl) onSlideAdded;

  const AddSlideModal({
    super.key,
    required this.onSlideAdded,
  });

  @override
  AddSlideModalState createState() => AddSlideModalState();
}

class AddSlideModalState extends State<AddSlideModal> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _hasContent = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkContent() {
    setState(() {
      _hasContent = _textController.text.trim().isNotEmpty || _selectedImage != null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _checkContent();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final String fileName = 'announcement_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child('announcements/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });
      
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _addSlide() async {
    if (!_hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to the slide')),
      );
      return;
    }

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) return; // Upload failed
    }

    final String? text = _textController.text.trim().isEmpty ? null : _textController.text.trim();
    
    widget.onSlideAdded(text, imageUrl);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Slide',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content Type Selection
            Text(
              'Choose content type:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Text Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text Content',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  onChanged: (_) => _checkContent(),
                  maxLines: 4,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter announcement text...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    hintMaxLines: 2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Image Selection Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Content',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (_selectedImage != null) ...[
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Change Image'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () {
                            setState(() {
                              _selectedImage = null;
                              _checkContent();
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            if (_isUploading) ...[
              const SizedBox(height: 20),
              Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasContent && !_isUploading ? _addSlide : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Slide'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ManageAnnouncementsPage extends StatefulWidget {
  const ManageAnnouncementsPage({super.key});

  @override
  ManageAnnouncementsPageState createState() => ManageAnnouncementsPageState();
}

class ManageAnnouncementsPageState extends State<ManageAnnouncementsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final Map<String, bool> _editMode = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, File?> _selectedImages = {};
  final Map<String, double> _uploadProgress = {};
  final Map<String, bool> _isSaving = {};
  bool _positionsFixed = false; // Track if positions have been fixed

  @override
  void initState() {
    super.initState();
    _migrateExistingSlides(); // Migrate existing slides to have position field
    // Also ensure positions are set up after a short delay
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        await _checkIfPositionsAreFixed();
        _ensureAllSlidesHavePositions([]);
      }
    });
  }

  // Migrate existing slides to have position field
  Future<void> _migrateExistingSlides() async {
    try {
      debugPrint('Starting migration of existing slides...');
      
      // Get all slides without position field
      final slidesWithoutPosition = await _firestore
          .collection('announcements')
          .where('position', isNull: true)
          .get();
      
      debugPrint('Found ${slidesWithoutPosition.docs.length} slides without position field');
      
      if (slidesWithoutPosition.docs.isNotEmpty) {
        // Get the current highest position to continue from there
        final existingSlides = await _firestore
            .collection('announcements')
            .where('position', isNull: false)
            .orderBy('position', descending: true)
            .limit(1)
            .get();
        
        int startPosition = 0;
        if (existingSlides.docs.isNotEmpty) {
          startPosition = (existingSlides.docs.first.data()['position'] as int? ?? 0) + 1;
        }
        
        debugPrint('Starting position assignment from $startPosition');
        
        final batch = _firestore.batch();
        for (int i = 0; i < slidesWithoutPosition.docs.length; i++) {
          batch.update(slidesWithoutPosition.docs[i].reference, {'position': startPosition + i});
        }
        await batch.commit();
        
        debugPrint('Successfully migrated ${slidesWithoutPosition.docs.length} slides with positions starting from $startPosition');
      } else {
        debugPrint('All slides already have position fields');
      }
      
      // Also check if any slides have invalid position values and fix them
      await _fixInvalidPositions();
      
      // Set flag that positions are fixed
      setState(() {
        _positionsFixed = true;
      });
      
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }

  // Function to add a new slide with modal
  void _addSlide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddSlideModal(
                onSlideAdded: (String? text, String? imageUrl) async {
        try {
          // Get the current highest position
          final currentSlides = await _firestore
              .collection('announcements')
              .orderBy('position', descending: true)
              .limit(1)
              .get();
          
          int newPosition = 0;
          if (currentSlides.docs.isNotEmpty) {
            final highestPosition = currentSlides.docs.first.data()['position'] as int? ?? 0;
            newPosition = highestPosition + 1;
          }
          
      await _firestore.collection('announcements').add({
            'text': text ?? '',
            'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
            'position': newPosition,
          });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Slide added successfully!')),
                );
              }
    } catch (e) {
      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add slide: $e')),
                );
              }
            }
          },
        );
      },
    );
  }

  // Function to fix invalid position values
  Future<void> _fixInvalidPositions() async {
    try {
      debugPrint('Checking for invalid position values...');
      
      // Get all slides and check for invalid positions
      final allSlides = await _firestore
          .collection('announcements')
          .get();
      
      final slidesWithInvalidPositions = allSlides.docs.where((doc) {
        final data = doc.data();
        final position = data['position'];
        return position == null || position < 0;
      }).toList();
      
      if (slidesWithInvalidPositions.isNotEmpty) {
        debugPrint('Found ${slidesWithInvalidPositions.length} slides with invalid positions');
        
        // Assign new sequential positions starting from 0
        final batch = _firestore.batch();
        for (int i = 0; i < slidesWithInvalidPositions.length; i++) {
          batch.update(slidesWithInvalidPositions[i].reference, {'position': i});
        }
        await batch.commit();
        
        debugPrint('Fixed positions for ${slidesWithInvalidPositions.length} slides');
      } else {
        debugPrint('All slides have valid position values');
      }
      
      // Set flag that positions are fixed
      setState(() {
        _positionsFixed = true;
      });
    } catch (e) {
      debugPrint('Error fixing invalid positions: $e');
    }
  }

  // Function to check if all slides already have position fields
  Future<void> _checkIfPositionsAreFixed() async {
    try {
      final slides = await _firestore
          .collection('announcements')
          .get();
      
      if (slides.docs.isNotEmpty) {
        final allHavePositions = slides.docs.every((doc) {
          final data = doc.data();
          final position = data['position'];
          return position != null && position is int && position >= 0;
        });
        
        if (allHavePositions) {
          setState(() {
            _positionsFixed = true;
          });
          debugPrint('All slides already have valid position fields');
        } else {
          debugPrint('Some slides are missing position fields');
        }
      }
    } catch (e) {
      debugPrint('Error checking position status: $e');
    }
  }

  // Function to ensure all slides have positions
  void _ensureAllSlidesHavePositions(List<QueryDocumentSnapshot> slides) {
    // Check if any slides are missing positions
    final slidesWithoutPosition = slides.where((slide) {
      final data = slide.data() as Map<String, dynamic>?;
      return data != null && data['position'] == null;
    }).toList();
    
    if (slidesWithoutPosition.isNotEmpty) {
      // Run migration in background
      _migrateExistingSlides();
    }
  }

  // Function to reorder slides
  Future<void> _reorderSlides(int oldIndex, int newIndex) async {
    try {
      debugPrint('Starting reorder: oldIndex=$oldIndex, newIndex=$newIndex');
      
      // First, try to get slides ordered by position
      QuerySnapshot slides;
      try {
        slides = await _firestore
            .collection('announcements')
            .orderBy('position', descending: false)
            .get();
        debugPrint('Found ${slides.docs.length} slides ordered by position');
      } catch (e) {
        debugPrint('Failed to order by position, trying without order: $e');
        // Fallback: get slides without ordering if position field is missing
        slides = await _firestore
            .collection('announcements')
            .get();
        debugPrint('Found ${slides.docs.length} slides without ordering');
      }
      
      if (slides.docs.isEmpty) {
        debugPrint('No slides found for reordering');
        return;
      }
      
      // Adjust newIndex for ReorderableListView behavior
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      // Ensure indices are within bounds
      if (oldIndex < 0 || oldIndex >= slides.docs.length || 
          newIndex < 0 || newIndex >= slides.docs.length) {
        debugPrint('Invalid indices: oldIndex=$oldIndex, newIndex=$newIndex, totalSlides=${slides.docs.length}');
        return;
      }
      
      final movedSlide = slides.docs[oldIndex];
      final movedId = movedSlide.id;
      
      debugPrint('Moving slide from position $oldIndex to $newIndex (ID: $movedId)');
      
      // Create a new list with updated positions
      final List<Map<String, dynamic>> updatedPositions = [];
      
      // Calculate new positions for all slides
      for (int i = 0; i < slides.docs.length; i++) {
        final slide = slides.docs[i];
        int newPosition;
        
        if (i == oldIndex) {
          // This is the moved slide
          newPosition = newIndex;
        } else if (i < oldIndex && i >= newIndex) {
          // Slides that need to move up (increase position)
          newPosition = i + 1;
        } else if (i > oldIndex && i <= newIndex) {
          // Slides that need to move down (decrease position)
          newPosition = i - 1;
        } else {
          // Slides that don't change position
          newPosition = i;
        }
        
        updatedPositions.add({
          'id': slide.id,
          'position': newPosition,
        });
      }
      
      // Update all slides with new positions
      final batch = _firestore.batch();
      for (final update in updatedPositions) {
        batch.update(
          _firestore.collection('announcements').doc(update['id']),
          {'position': update['position']}
        );
      }
      
      await batch.commit();
      
      debugPrint('Successfully reordered slides. New positions: ${updatedPositions.map((e) => '${e['id']}:${e['position']}').join(', ')}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slides reordered successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error reordering slides: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reorder slides: $e')),
        );
      }
    }
  }

  // Function to update slide text or image
  Future<void> _updateSlide(
    String documentId,
    String? newText, // Can be null if only image is present
    String? newImageUrl, // Can be null if only text is present
  ) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        // If there's an image, set image_url and clear text
        updateData['image_url'] = newImageUrl;
        updateData['text'] = '';
      } else if (newText != null && newText.isNotEmpty) {
        // If there's text, set text and clear image_url
        updateData['text'] = newText;
        updateData['image_url'] = null;
      } else {
        // If both are empty, set both to null/empty
        updateData['text'] = '';
        updateData['image_url'] = null;
      }

      await _firestore
          .collection('announcements')
          .doc(documentId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Slide updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update slide: $e')));
      }
    } finally {
      setState(() {
        _selectedImages[documentId] = null;
        _uploadProgress[documentId] = 0.0;
        _isSaving[documentId] = false;
        _editMode[documentId] = false;
      });
    }
  }

  // Function to delete a slide and its associated image from Storage
  void _deleteSlide(String documentId, String? imageUrl) async {
    // Show confirmation dialog
    final bool confirmDelete =
        await showDialog(
          context: context, // Use the context from the StatefulWidget
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                'Are you sure you want to delete this slide? This action cannot be undone.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User canceled
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Highlight the delete action
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true); // User confirmed
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false; // In case dialog is dismissed by tapping outside

    if (!confirmDelete) {
      return; // If user cancels, stop the deletion process
    }

    // If confirmed, proceed with deletion
    try {
      setState(() {
        _isSaving[documentId] = true;
      });

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final fileRef = _storage.refFromURL(imageUrl);
        await fileRef.delete();
      }

      await _firestore.collection('announcements').doc(documentId).delete();

      setState(() {
        _editMode.remove(documentId);
        _textControllers.remove(documentId);
        _selectedImages.remove(documentId);
        _uploadProgress.remove(documentId);
        _isSaving.remove(documentId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Slide deleted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete slide: $e')));
      }
    } finally {
      setState(() {
        _isSaving[documentId] = false;
      });
    }
  }

  // Function to pick an image from gallery or camera
  Future<void> _pickImage(String documentId, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImages[documentId] = File(pickedFile.path);
          _textControllers[documentId]
              ?.clear(); // Clear text when image is picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // Function to upload the selected image to Firebase Storage
  Future<String?> _uploadImage(String documentId, File imageFile) async {
    try {
      String fileName =
          'announcement_${documentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child(
        'files/announcements/images/$fileName',
      );

      UploadTask uploadTask = storageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress[documentId] =
                snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    }
  }

  // Function to clear a selected image from the UI (before actual update)
  void _clearSelectedImage(String documentId) {
    setState(() {
      _selectedImages[documentId] = null;
      _uploadProgress[documentId] = 0.0;
      // When image is cleared, enable text field and clear its content
      _textControllers[documentId]?.clear();
    });
  }

  // Function to explicitly remove an image from a slide in Firestore and Storage
  void _removeImageFromSlide(String documentId, String? currentImageUrl) async {
    if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      try {
        setState(() {
          _isSaving[documentId] = true;
        });

        final fileRef = _storage.refFromURL(currentImageUrl);
        await fileRef.delete();

        await _firestore.collection('announcements').doc(documentId).update({
          'image_url': null,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image removed from slide!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to remove image: $e')));
        }
      } finally {
        setState(() {
          _isSaving[documentId] = false;
          // After removal, ensure text field is enabled and clear any existing text (optional, but good for clean state)
          _textControllers[documentId]?.clear();
        });
      }
    }
  }

  // Toggles edit mode and handles saving changes
  void _toggleEditMode(
    String documentId,
    String initialText,
    String? initialImageUrl,
  ) async {
    final bool currentlyInEditMode = _editMode[documentId] ?? false;
    final bool isSavingThisSlide = _isSaving[documentId] ?? false;

    if (currentlyInEditMode) {
      if (isSavingThisSlide) {
        return;
      }

      setState(() {
        _isSaving[documentId] = true;
      });

      String? newText = _textControllers[documentId]?.text.trim();
      String? newImageUrl; // Initialize to null, then determine based on logic

      // **CRITICAL LOGIC REVISION HERE**
      if (_selectedImages[documentId] != null) {
        // Case 1: A new image was selected. Upload it and discard any text.
        setState(() {
          _uploadProgress[documentId] = -1.0; // Indicate upload started
        });
        newImageUrl = await _uploadImage(
          documentId,
          _selectedImages[documentId]!,
        );
        newText = ''; // Explicitly clear text if an image is chosen
      } else if (newText != null && newText.isNotEmpty) {
        // Case 2: No new image, but text is present in the controller.
        // This implies the user wants this to be a text slide.
        newImageUrl = null; // Explicitly clear image if text is chosen
      } else if (initialImageUrl != null && initialImageUrl.isNotEmpty) {
        // Case 3: No new image, no new text, but there was an initial image.
        // This means the user just opened and saved an existing image slide without changes.
        newImageUrl = initialImageUrl;
        newText = ''; // Ensure text remains clear for an image slide
      } else {
        // Case 4: Both text and image are empty (or user cleared both).
        newText = '';
        newImageUrl = null;
      }

      // Check if content has actually changed before updating Firestore
      final bool textChanged = newText != initialText;
      final bool imageUrlChanged = newImageUrl != initialImageUrl;

      // Handle old image deletion if replaced or removed
      if (initialImageUrl != null && initialImageUrl.isNotEmpty) {
        if (newImageUrl == null || (newImageUrl != initialImageUrl)) {
          // If old image is being removed (newImageUrl is null) or replaced
          try {
            final oldFileRef = _storage.refFromURL(initialImageUrl);
            await oldFileRef.delete();
          } catch (e) {
            print('Error deleting old image from storage: $e');
            // Continue with update even if old image deletion fails
          }
        }
      }

      if (textChanged || imageUrlChanged) {
        await _updateSlide(documentId, newText, newImageUrl);
      } else {
        // If nothing changed, just exit edit mode and reset saving state
        setState(() {
          _isSaving[documentId] = false;
          _editMode[documentId] = false;
          _selectedImages[documentId] = null;
          _uploadProgress[documentId] = 0.0;
        });
      }
    } else {
      // Logic for entering edit mode
      if (!_textControllers.containsKey(documentId)) {
        _textControllers[documentId] = TextEditingController(text: initialText);
      }
      _selectedImages[documentId] = null;
      _uploadProgress[documentId] = 0.0;
      _isSaving[documentId] = false;

      setState(() {
        _editMode[documentId] = true;
      });
    }
  }

  @override
  void dispose() {
    _textControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions for drag and drop
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '💡 Drag and drop slides to reorder them. The order will be saved automatically.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('announcements')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading slides: ${snapshot.error}'),
                    );
                  }

                  final slides = snapshot.data?.docs ?? [];

                  if (slides.isEmpty) {
                    return const Center(
                      child: Text(
                        'No slides found. Click "Add Slide" to begin.',
                      ),
                    );
                  }

                  // Sort slides by position, fallback to created_at if position is missing
                  slides.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    
                    final aPosition = aData['position'] as int?;
                    final bPosition = bData['position'] as int?;
                    
                    // If both have position, sort by position
                    if (aPosition != null && bPosition != null) {
                      return aPosition.compareTo(bPosition);
                    }
                    
                    // If only one has position, prioritize the one with position
                    if (aPosition != null) return -1;
                    if (bPosition != null) return 1;
                    
                    // If neither has position, sort by created_at
                    final aCreatedAt = aData['created_at'] as Timestamp?;
                    final bCreatedAt = bData['created_at'] as Timestamp?;
                    
                    if (aCreatedAt != null && bCreatedAt != null) {
                      return aCreatedAt.compareTo(bCreatedAt);
                    }
                    
                    return 0;
                  });

                  // Ensure all slides have positions (run migration if needed)
                  _ensureAllSlidesHavePositions(slides);

                  return ReorderableListView.builder(
                    itemCount: slides.length,
                    onReorder: _reorderSlides,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      final documentId = slide.id;
                      final slideData = slide.data() as Map<String, dynamic>;
                      final slideText = slideData['text'] as String? ?? '';
                      final slideImageUrl = slideData['image_url'] as String?;
                      final isEditMode = _editMode[documentId] ?? false;
                      final isSavingThisSlide = _isSaving[documentId] ?? false;

                      if (!_textControllers.containsKey(documentId)) {
                        _textControllers[documentId] = TextEditingController(
                          text: slideText,
                        );
                      }

                      final File? pendingImage = _selectedImages[documentId];
                      final double uploadProgress =
                          _uploadProgress[documentId] ?? 0.0;
                      final bool isUploading =
                          uploadProgress > 0 && uploadProgress < 1;
                      final bool uploadStartedButNotProgressing =
                          uploadProgress == -1.0;

                      // Determine active content for display/editing control
                      final bool hasAnyImageContent =
                          pendingImage != null ||
                          (slideImageUrl != null && slideImageUrl.isNotEmpty);
                      final bool hasAnyTextContent =
                          (_textControllers[documentId]?.text.trim() ?? '')
                              .isNotEmpty;

                      return Card(
                        key: ValueKey(documentId),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: theme.cardTheme.color,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Drag handle
                                      Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                      ),
                                  Text(
                                    'Slide ${index + 1}',
                                    style: theme.textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isEditMode ? Icons.check : Icons.edit,
                                        ),
                                        onPressed:
                                            isSavingThisSlide
                                                ? null
                                                : () => _toggleEditMode(
                                                  documentId,
                                                  slideText,
                                                  slideImageUrl,
                                                ),
                                        color: theme.iconTheme.color,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed:
                                            isSavingThisSlide
                                                ? null
                                                : () => _deleteSlide(
                                                  documentId,
                                                  slideImageUrl,
                                                ),
                                        color: theme.iconTheme.color,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              isEditMode
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Text Field Section
                                      // Only show text input options if no image content is currently active
                                      if (!hasAnyImageContent)
                                        Column(
                                          children: [
                                            TextField(
                                              controller:
                                                  _textControllers[documentId],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Enter announcement text',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey.shade300,
                                                  fontSize: 16,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.grey.shade600),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.grey.shade600),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                                ),
                                                filled: true,
                                                fillColor: Colors.grey.shade800,
                                                enabled: !isSavingThisSlide,
                                              ),
                                              maxLines: null,
                                              onChanged: (text) {
                                                // Clear selected image if user starts typing and there's a pending image
                                                if (text.isNotEmpty &&
                                                    pendingImage != null) {
                                                  _clearSelectedImage(
                                                    documentId,
                                                  );
                                                }
                                                // No need to remove from DB here; that's handled on save
                                                setState(() {
                                                  // Rebuild to update UI based on text presence
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            // Show "Pick Image" buttons only if text field is empty/not being used AND not saving
                                            if (!hasAnyTextContent &&
                                                !isSavingThisSlide)
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        () => _pickImage(
                                                          documentId,
                                                          ImageSource.gallery,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.photo_library,
                                                    ),
                                                    label: const Text(
                                                      'Gallery',
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        () => _pickImage(
                                                          documentId,
                                                          ImageSource.camera,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.camera_alt,
                                                    ),
                                                    label: const Text('Camera'),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      // Image Section
                                      // Only show image display/remove options if image content is currently active
                                      if (hasAnyImageContent)
                                        Column(
                                          children: [
                                            if (pendingImage != null)
                                              Image.file(
                                                pendingImage,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            else if (slideImageUrl != null &&
                                                slideImageUrl.isNotEmpty)
                                              CachedNetworkImage(
                                                imageUrl: slideImageUrl,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) =>
                                                        const CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            const SizedBox(height: 5),
                                            TextButton(
                                              onPressed:
                                                  isSavingThisSlide
                                                      ? null
                                                      : () {
                                                        _clearSelectedImage(
                                                          documentId,
                                                        ); // Clear local selection
                                                        if (slideImageUrl !=
                                                                null &&
                                                            slideImageUrl
                                                                .isNotEmpty) {
                                                          _removeImageFromSlide(
                                                            documentId,
                                                            slideImageUrl,
                                                          ); // Remove from DB
                                                        }
                                                        // IMPORTANT: Clearing image implies user wants to switch to text or empty
                                                        _textControllers[documentId]
                                                            ?.text = '';
                                                      },
                                              child: const Text('Remove Image'),
                                            ),
                                          ],
                                        ),
                                      // Loading Indicators (always visible if saving)
                                      if (isSavingThisSlide &&
                                          (uploadStartedButNotProgressing ||
                                              isUploading))
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: null,
                                          ),
                                        ),
                                      if (isSavingThisSlide && isUploading)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Column(
                                            children: [
                                              LinearProgressIndicator(
                                                value: uploadProgress,
                                              ),
                                              Center(
                                                child: Text(
                                                  'Uploading: ${(uploadProgress * 100).toStringAsFixed(0)}%',
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (slideImageUrl != null &&
                                          slideImageUrl.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Center(
                                            child: CachedNetworkImage(
                                              imageUrl: slideImageUrl,
                                              height: 150,
                                              fit: BoxFit.contain,
                                              placeholder:
                                                  (context, url) =>
                                                      const CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.error,
                                                        size: 50,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      if (slideText.isNotEmpty)
                                        _buildClickableText(
                                          slideText,
                                          theme.textTheme.bodyMedium,
                                        )
                                      else if (slideImageUrl == null ||
                                          slideImageUrl.isEmpty)
                                        Text(
                                          'No content available',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      if (slideText.isNotEmpty &&
                                          (slideImageUrl != null &&
                                              slideImageUrl.isNotEmpty))
                                        const SizedBox(height: 8),
                                    ],
                                  ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addSlide,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.iconTheme.color,
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Add New Slide'),
                ),
                if (!_positionsFixed) ...[
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () async {
                      await _migrateExistingSlides();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Position migration completed!')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('Fix Positions'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
