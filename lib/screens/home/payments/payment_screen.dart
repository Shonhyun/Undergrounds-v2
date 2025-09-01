import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:learningexamapp/screens/main_screen.dart';

class PaymentScreen extends StatelessWidget {
  final VoidCallback onBack;
  final List<Map<String, dynamic>>
  selectedPrograms; // Updated to accept a list of maps
  final bool isTesting;
  final Map<String, dynamic>? userData; // Add userData parameter

  const PaymentScreen({
    super.key,
    required this.onBack,
    required this.selectedPrograms,
    this.isTesting = false,
    this.userData, // Add userData parameter
  });

  // Define your product IDs for various subjects/packages
  static const Map<String, String> productIds = {
    'MATH': 'math',
    'ESAS': 'esas',
    'EE': 'ee',
    'REFRESHER': 'refresher',
    'FULL ENROLLMENT': 'full_enrollment',
  };

  Future<void> _initiateApplePay(BuildContext context, String productId) async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In-app purchases are not available.')),
      );
      return;
    }

    final Set<String> ids = {productId};

    final ProductDetailsResponse response = await InAppPurchase.instance
        .queryProductDetails(ids);

    if (response.notFoundIDs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product not found.')));
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  double getTotalPrice() {
    return selectedPrograms.fold(
      0.0,
      (total, program) => total + program['price'],
    );
  }

  void _showPaymentConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Details Section
              const Text(
                'Student Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Name: ${userData?['fullName'] ?? 'N/A'}'),
              Text('Email: ${userData?['email'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              
              // Selected Programs Section
              const Text(
                'Selected Programs:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...selectedPrograms.map((program) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(program['name']),
                    Text('₱${program['price'].toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              
              // Total Amount
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '₱${getTotalPrice().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Confirmation Message
              const Text(
                'Please confirm that you have completed your payment process. This action cannot be undone.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirm Payment'),
              onPressed: () {
                Navigator.of(context).pop();
                
                // Show snackbar message about admin approval
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Submitted Successfully!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Your payment is now under admin approval. You will receive access to materials once approved.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                
                // Navigate to MainScreen after showing the message
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = isTesting ? !Platform.isIOS : Platform.isIOS;
    final isAndroid = isTesting ? !Platform.isAndroid : Platform.isAndroid;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: AppBar(
            title: Text("Payment", style: theme.textTheme.bodyLarge),
            centerTitle: true,
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            iconTheme: theme.appBarTheme.iconTheme,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment Instructions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: const Text(
                "After payment, please wait for your account to refresh to access all features.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            if (isAndroid)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "GCash Number:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 5,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "0926 553 7411",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.red),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: "0926 553 7411"),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'GCash number copied to clipboard!',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),

            Center(
              child: Column(
                children: [
                  const Text(
                    "Payment Method",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (isAndroid)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Image.asset("assets/images/qr_payment.jpeg"),
                      ),
                    )
                  else if (isIOS)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Pay securely using your preffered App Store payment method for in-app purchases",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            if (isIOS)
              Column(
                children:
                    selectedPrograms.map((program) {
                      // Convert the program name to lowercase for comparison
                      final lowerCaseProgram = program['name'].toLowerCase();
                      // Find the matching product ID by checking lowercase keys
                      final matchingProductId = productIds.entries.firstWhere(
                        (entry) => entry.key.toLowerCase() == lowerCaseProgram,
                        orElse:
                            () => MapEntry(
                              '',
                              '',
                            ), // Provide a default value if not found
                      );

                      // Check if a valid product ID was found
                      if (matchingProductId.key.isNotEmpty) {
                        final productId = matchingProductId.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  program['name'], // Display program name
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ), // Space between text and button
                              Text(
                                "₱${program['price']}", // Display price
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ), // Space between price and button
                              ElevatedButton(
                                onPressed:
                                    () => _initiateApplePay(context, productId),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  backgroundColor: theme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  "Pay Now",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink(); // Return an empty widget if no match
                      }
                    }).toList(),
              ),

            const SizedBox(height: 20),

            // Display total price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "₱${getTotalPrice().toStringAsFixed(2)}", // Display total price
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showPaymentConfirmationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Done",
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
