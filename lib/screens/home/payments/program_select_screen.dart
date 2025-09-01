import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/home/payments/toc_screen.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';
import 'package:intl/intl.dart';

class ProgramSelectScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? userData; // Add userData parameter

  const ProgramSelectScreen({
    super.key, 
    required this.onBack,
    this.userData, // Add userData parameter
  });

  @override
  PaymentsScreenState createState() => PaymentsScreenState();
}

class PaymentsScreenState extends State<ProgramSelectScreen> {
  // Updated programs structure with both Online Review and Mock Boards
  final Map<String, Map<String, int>> programCategories = {
    'Online Review Enrollment': {
      'Math': 2499,
      'Esas': 2499,
      'Ee': 2499,
      'Refresher': 2499,
      'Full enrollment': 7999,
    },
    'Mock Boards Enrollment': {
      'Math': 149,
      'Esas': 149,
      'Ee': 149,
      'All mock boards': 399,
    },
  };

  final Map<String, bool> selectedPrograms = {};

  @override
  void initState() {
    super.initState();
    // Initialize all programs as unselected
    for (var category in programCategories.values) {
      for (var program in category.keys) {
        selectedPrograms[program] = false;
      }
    }
  }

  void updateSelection(String selectedProgram, bool value) {
    setState(() {
      // Handle Full enrollment selection
      if (selectedProgram == "Full enrollment") {
        // Deselect all other Online Review programs
        for (var program in programCategories['Online Review Enrollment']!.keys) {
          selectedPrograms[program] = (program == "Full enrollment") ? value : false;
        }
      } else if (selectedProgram == "All mock boards") {
        // Deselect individual mock board programs when "All mock boards" is selected
        for (var program in programCategories['Mock Boards Enrollment']!.keys) {
          selectedPrograms[program] = (program == "All mock boards") ? value : false;
        }
      } else {
        // Handle individual program selection
        if (programCategories['Online Review Enrollment']!.containsKey(selectedProgram)) {
          // If selecting an individual Online Review program, deselect "Full enrollment"
          selectedPrograms["Full enrollment"] = false;
        } else if (programCategories['Mock Boards Enrollment']!.containsKey(selectedProgram)) {
          // If selecting an individual Mock Board program, deselect "All mock boards"
          selectedPrograms["All mock boards"] = false;
        }
        selectedPrograms[selectedProgram] = value;
      }
    });
  }

  String formatPrice(int price) {
    final formatter = NumberFormat("#,###");
    return formatter.format(price);
  }

  int getTotal() {
    int total = 0;
    selectedPrograms.forEach((key, value) {
      if (value) {
        // Find the price for the selected program
        for (var category in programCategories.values) {
          if (category.containsKey(key)) {
            total += category[key]!;
            break;
          }
        }
      }
    });
    return total;
  }

  List<Map<String, dynamic>> getSelectedProgramsWithPrices() {
    return selectedPrograms.entries
        .where((entry) => entry.value)
        .map((entry) {
          // Find the price for the selected program
          for (var category in programCategories.values) {
            if (category.containsKey(entry.key)) {
              return {'name': entry.key, 'price': category[entry.key]!};
            }
          }
          return {'name': entry.key, 'price': 0};
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: buildAppBar(
        context,
        "Payments",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Programs to Enroll",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Program Selection List
            Expanded(
              child: ListView(
                children: programCategories.entries.map((categoryEntry) {
                  String categoryName = categoryEntry.key;
                  Map<String, int> programs = categoryEntry.value;
                  bool isMockBoardCategory = categoryName == 'Mock Boards Enrollment';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isMockBoardCategory ? Colors.grey.shade600 : theme.primaryColor,
                              ),
                            ),
                            if (isMockBoardCategory)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "(Coming Soon)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Programs in this category
                      ...programs.keys.map((program) {
                        bool isDisabled = isMockBoardCategory; // Disable all Mock Board options
                        
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: isDisabled ? Colors.grey.shade200 : null, // Grey out disabled options
                          child: CheckboxListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            title: Text(
                              "$program (₱${formatPrice(programs[program]!)})",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDisabled ? Colors.grey.shade600 : null,
                              ),
                            ),
                            subtitle: isDisabled 
                              ? const Text(
                                  "Not available yet",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : null,
                            value: selectedPrograms[program],
                            onChanged: isDisabled ? null : (bool? value) {
                              if (value != null) {
                                updateSelection(program, value);
                              }
                            },
                            activeColor: theme.primaryColor,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      }).toList(),
                      
                      // Add spacing between categories
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Mock Boards Warning (Android only)
            if (Platform.isAndroid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  "⚠️ Mock Board Exams are provided based on the review schedule, normally towards the date of the actual board exams. Please do not purchase or enroll in any Mock Board Exam item yet. Wait for the Undergrounds Admin to announce when Mock Board Exams are available.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Total Price Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Due:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151), // Neutral dark gray
                    ),
                  ),
                  Text(
                    "₱${formatPrice(getTotal())}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    getTotal() > 0
                        ? () {
                          List<Map<String, dynamic>> selectedProgramsList =
                              getSelectedProgramsWithPrices();
                          // Assuming you have a previous list of selected programs
                          List<Map<String, dynamic>> existingProgramsList =
                              []; // Replace with your existing list if needed
                          existingProgramsList.addAll(
                            selectedProgramsList,
                          ); // Add new selections to the existing list
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TermsAndConditionsScreen(
                                    onBack: () {
                                      Navigator.pop(context);
                                    },
                                    selectedPrograms: existingProgramsList,
                                    userData: widget.userData, // Pass userData
                                  ),
                            ),
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: theme.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Continue to Payment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
