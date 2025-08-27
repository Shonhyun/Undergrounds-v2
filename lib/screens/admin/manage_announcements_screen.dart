import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

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

  // Function to add a new slide
  void _addSlide() async {
    try {
      await _firestore.collection('announcements').add({
        'text': '',
        'image_url': null,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add slide: $e')));
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('announcements')
                        .orderBy(
                          'created_at',
                          descending: false,
                        ) // Changed to created_at
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

                  return ListView.builder(
                    itemCount: slides.length,
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
                                  Text(
                                    'Slide ${index + 1}',
                                    style: theme.textTheme.titleMedium,
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
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Enter announcement text',
                                                labelStyle:
                                                    theme.textTheme.bodyMedium,
                                                border:
                                                    const OutlineInputBorder(),
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
                                        Text(
                                          slideText,
                                          style: theme.textTheme.bodyMedium,
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
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
            Center(
              child: ElevatedButton(
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
            ),
          ],
        ),
      ),
    );
  }
}
