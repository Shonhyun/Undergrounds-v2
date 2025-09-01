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
  final Map<String, int> programs =
      Platform.isAndroid
          ? {
            "MATH": 2000,
            "ESAS": 2000,
            "EE": 2000,
            "Refresher": 2000,
            "Full Enrollment": 7000,
          }
          : {
            "MATH": 49,
            "ESAS": 49,
            "EE": 49,
            "Refresher": 49,
            "Full Enrollment": 149,
          };

  final Map<String, bool> selectedPrograms = {};

  @override
  void initState() {
    super.initState();
    for (var key in programs.keys) {
      selectedPrograms[key] = false;
    }
  }

  void updateSelection(String selectedProgram, bool value) {
    setState(() {
      if (selectedProgram == "Full Enrollment") {
        selectedPrograms.forEach((key, _) {
          selectedPrograms[key] = (key == "Full Enrollment") ? value : false;
        });
      } else {
        selectedPrograms["Full Enrollment"] = false;
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
        total += programs[key]!;
      }
    });
    return total;
  }

  List<Map<String, dynamic>> getSelectedProgramsWithPrices() {
    return selectedPrograms.entries
        .where((entry) => entry.value)
        .map((entry) => {'name': entry.key, 'price': programs[entry.key]!})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isFullEnrollmentSelected =
        selectedPrograms["Full Enrollment"] ?? false;

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
              "Select a Program to Enroll",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Program Selection List
            Expanded(
              child: ListView(
                children:
                    programs.keys.map((program) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: CheckboxListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Text(
                            "$program (₱${formatPrice(programs[program]!)})",
                            style: const TextStyle(fontSize: 16),
                          ),
                          value: selectedPrograms[program],
                          onChanged: (bool? value) {
                            if (value != null) {
                              updateSelection(program, value);
                            }
                          },
                          activeColor: theme.primaryColor,
                          checkColor: Colors.black,
                          controlAffinity: ListTileControlAffinity.leading,
                          enabled:
                              isFullEnrollmentSelected
                                  ? program == "Full Enrollment"
                                  : true,
                        ),
                      );
                    }).toList(),
              ),
            ),

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
