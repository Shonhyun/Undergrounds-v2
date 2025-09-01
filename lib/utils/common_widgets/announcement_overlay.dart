import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// Define the Announcement class to hold announcement data
class Announcement {
  final String text;
  final String?
  imageUrl; // Nullable as not all announcements will have an image

  Announcement({required this.text, this.imageUrl});
}

// Helper function to detect URLs and make them clickable
Widget _buildClickableText(String text) {
  // Regular expression to detect URLs
  final urlRegex = RegExp(
    r'(https?://[^\s]+)|(www\.[^\s]+)',
    caseSensitive: false,
  );
  
  if (!urlRegex.hasMatch(text)) {
    // No URLs found, return plain text
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
    );
  }

  // Split text by URLs and build clickable widgets
  final parts = text.split(urlRegex);
  final matches = urlRegex.allMatches(text);
  
  List<InlineSpan> spans = [];
  int matchIndex = 0;
  
  for (int i = 0; i < parts.length; i++) {
    // Add the text part
    if (parts[i].isNotEmpty) {
      spans.add(TextSpan(
        text: parts[i],
        style: const TextStyle(fontSize: 18),
      ));
    }
    
    // Add the URL part if available
    if (matchIndex < matches.length) {
      final match = matches.elementAt(matchIndex);
      final url = match.group(0)!;
      
      // Ensure URL has proper scheme
      String fullUrl = url;
      if (url.startsWith('www.')) {
        fullUrl = 'https://$url';
      }
      
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
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
      matchIndex++;
    }
  }
  
  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(children: spans),
  );
}

class AnnouncementOverlay extends StatefulWidget {
  final ValueNotifier<bool> isVisible;

  const AnnouncementOverlay({super.key, required this.isVisible});

  @override
  AnnouncementOverlayState createState() => AnnouncementOverlayState();
}

class AnnouncementOverlayState extends State<AnnouncementOverlay> {
  int currentPage = 0;
  bool isChecked = false;
  final PageController _pageController = PageController();
  Timer? _timer;
  int remainingTime = 30; // Time in seconds for each slide

  List<Announcement> announcements =
      []; // List to hold fetched Announcement objects
  bool isLoading = true; // State to track if announcements are being loaded

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements(); // Start fetching announcements when the widget initializes
    _startAutoScroll(); // Start the timer for auto-scrolling
  }

  // Fetches announcements from Firestore
  Future<void> _fetchAnnouncements() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('announcements').get();
      
      // Create a list of announcements with position data
      final announcementsWithPosition = querySnapshot.docs.map((doc) {
        final data = doc.data(); // Get the map of data from the document
        final text = data['text'] as String? ?? '';
        final imageUrl = data['image_url'] as String?;
        final position = data['position'] as int? ?? 0; // Get position, default to 0
        
        // Debug: Print announcement data
        debugPrint('Announcement text: $text');
        debugPrint('Announcement imageUrl: $imageUrl');
        debugPrint('Announcement position: $position');
        debugPrint('Contains URL: ${text.contains('http') || text.contains('www')}');
        
        return {
          'announcement': Announcement(
            text: text,
            imageUrl: imageUrl,
          ),
          'position': position,
          'documentId': doc.id,
        };
      }).toList();
      
      // Sort announcements by position (Slide 1 first, Slide 2 second, etc.)
      announcementsWithPosition.sort((a, b) {
        final aPos = a['position'] as int? ?? 0;
        final bPos = b['position'] as int? ?? 0;
        return aPos.compareTo(bPos);
      });
      
      setState(() {
        // Extract just the Announcement objects in the correct order
        announcements = announcementsWithPosition
            .map((item) => item['announcement'] as Announcement)
            .toList();
        isLoading = false; // Set loading to false once data is fetched
      });
      
      debugPrint('Announcements loaded in order: ${announcementsWithPosition.map((item) => 'Position ${item['position']}: ${item['documentId']}').join(', ')}');
    } catch (e) {
      // Handle errors during fetching, e.g., show a SnackBar
      if (mounted) {
        // Only show SnackBar if the widget is still in the widget tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch announcements: $e')),
        );
      }
      setState(() {
        isLoading = false; // Set loading to false even on error
      });
    }
  }

  // Starts the timer for automatic page scrolling
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        // If the widget is no longer in the tree, cancel the timer
        _timer?.cancel();
        return;
      }
      if (remainingTime > 0) {
        // Decrement remaining time
        setState(() {
          remainingTime--;
        });
      } else {
        // If time runs out, move to the next page
        if (currentPage < announcements.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            currentPage++; // Update current page index
            remainingTime = 30; // Reset timer for the new page
          });
        } else {
          // If it's the last page, stop the auto-scrolling
          _timer?.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    _pageController.dispose(); // Dispose the PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isVisible,
      builder: (_, showOverlay, __) {
        if (!showOverlay) {
          return const SizedBox.shrink(); // Hide the overlay if not visible
        }
        return Positioned.fill(
          child: Container(
            color: Color.fromARGB(
              (0.8 * 255).toInt(),
              0,
              0,
              0,
            ), // Semi-transparent black background for the overlay
            child: Center(
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.9, // 90% of screen width
                height:
                    MediaQuery.of(context).size.height *
                    0.8, // 80% of screen height
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color, // Background color from theme
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
                child:
                    isLoading
                        ? const Center(
                          child:
                              CircularProgressIndicator(), // Show loading indicator while fetching
                        )
                        : Column(
                          mainAxisSize:
                              MainAxisSize.min, // Take minimum vertical space
                          children: [
                            const Text(
                              "Announcement",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Next slide in: $remainingTime s",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    currentPage = index;
                                    remainingTime =
                                        30; // Reset timer on manual page change
                                  });
                                },
                                itemCount: announcements.length,
                                itemBuilder: (context, index) {
                                  final announcement =
                                      announcements[index]; // Get the current announcement
                                  final String? currentImageUrl =
                                      announcement
                                          .imageUrl; // Get its image URL

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Center(
                                      child:
                                          currentImageUrl != null &&
                                                  currentImageUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                imageUrl:
                                                    currentImageUrl, // The URL of the image
                                                placeholder:
                                                    (context, url) =>
                                                        const CircularProgressIndicator(), // Widget to show while loading
                                                errorWidget: (
                                                  context,
                                                  url,
                                                  error,
                                                ) {
                                                  // Widget to show if image fails to load
                                                  print(
                                                    'Error loading image: $url, Error: $error',
                                                  ); // Log the error for debugging
                                                  return const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.broken_image,
                                                        size: 80,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                                fit:
                                                    BoxFit
                                                        .contain, // How the image should fit within its bounds
                                              )
                                              : _buildClickableText(
                                                // Fallback to text if no image URL
                                                announcement.text,
                                              ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(announcements.length, (
                                index,
                              ) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        currentPage == index
                                            ? theme
                                                .primaryColor // Active dot color
                                            : Colors.grey, // Inactive dot color
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  activeColor: theme.primaryColor,
                                  checkColor: Colors.black,
                                  onChanged:
                                      currentPage == announcements.length - 1
                                          ? (value) {
                                            // Only allow checkbox interaction on the last page
                                            setState(() {
                                              isChecked = value ?? false;
                                            });
                                          }
                                          : null, // Disable checkbox if not on the last page
                                ),
                                const Expanded(
                                  child: Text(
                                    "I have read and understood all announcements.",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed:
                                  isChecked
                                      ? () =>
                                          widget.isVisible.value =
                                              false // Close overlay if checkbox is checked
                                      : null, // Disable button if checkbox is not checked
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Proceed"),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        );
      },
    );
  }
}
