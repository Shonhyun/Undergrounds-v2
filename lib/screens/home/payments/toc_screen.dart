import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'payment_screen.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final List<Map<String, dynamic>> selectedPrograms;
  final Map<String, dynamic>? userData; // Add userData parameter

  const TermsAndConditionsScreen({
    super.key,
    required this.onBack,
    required this.selectedPrograms,
    this.userData, // Add userData parameter
  });

  @override
  TermsAndConditionsScreenState createState() =>
      TermsAndConditionsScreenState();
}

class TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool isAgreed = false;
  bool isScrolledToBottom = false;
  ScrollController _scrollController = ScrollController();

  // Store fetched terms
  List<String> paymentPolicies = [];
  bool isLoading = true; // To track loading state

  // Android-specific payment instructions
  final List<String> androidPaymentInstructions = [
    "Payments made through the mobile app shall be paid to the provided GCash QR or Account.",
    "After payment, take a screenshot of your proof of payment (GCash transaction or App Store receipt).",
    "Proceed to the enrollment using the Google Form posted by Engr. Clibourn Quiapo.",
    "Fill out the form and upload your payment screenshot for validation.",
    "Wait for Engr. Clibourn Quiapo to review and activate your account.",
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchPaymentPolicies(); // Fetch data once during init
  }

  // Fetch payment policies from Firebase
  void _fetchPaymentPolicies() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('policy_links')
              .doc('terms_and_conditions')
              .get();

      if (doc.exists) {
        setState(() {
          paymentPolicies = List<String>.from(doc['payment_policies'] ?? []);
          isLoading = false;
        });
      } else {
        // If no Firebase data, use default Android instructions for Android
        setState(() {
          if (Platform.isAndroid) {
            paymentPolicies = androidPaymentInstructions;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching policies: $e");
      setState(() {
        // Fallback to Android instructions for Android devices
        if (Platform.isAndroid) {
          paymentPolicies = androidPaymentInstructions;
        }
        isLoading = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        isScrolledToBottom = true;
      });
    } else {
      setState(() {
        isScrolledToBottom = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildAppBar(
        context,
        "Terms & Conditions",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Please read and accept the Terms & Conditions before proceeding.",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Terms & Conditions Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Body text: Displaying payment policies
                            for (int i = 0; i < paymentPolicies.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  '${i + 1}. ${paymentPolicies[i]}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Checkbox for agreement
                      Row(
                        children: [
                          Checkbox(
                            value: isAgreed && isScrolledToBottom,
                            onChanged:
                                isScrolledToBottom
                                    ? (bool? value) {
                                      setState(() {
                                        isAgreed = value ?? false;
                                      });
                                    }
                                    : null,
                            activeColor: theme.primaryColor,
                            checkColor: Colors.black,
                          ),
                          const Text(
                            "I agree to the Terms & Conditions",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Proceed Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isAgreed
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PaymentScreen(
                                              onBack: () {
                                                Navigator.pop(context);
                                              },
                                              selectedPrograms:
                                                  widget.selectedPrograms,
                                              userData: widget.userData, // Pass userData
                                            ),
                                      ),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: theme.primaryColor,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Proceed with Payment",
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
              ),
    );
  }
}
