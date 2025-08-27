import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/auth_pages/login_screen.dart';
import 'package:learningexamapp/services/auth_service.dart';
import 'package:learningexamapp/utils/common_widgets/app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

Future<String?> getPolicyLink(String documentId) async {
  try {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('policy_links')
            .doc(documentId)
            .get();

    if (doc.exists) {
      return doc.get('url');
    }
    return null;
  } catch (e) {
    print("Error fetching policy link: $e");
    return null;
  }
}

Future<void> launchPolicyLink(BuildContext context, String documentId) async {
  try {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('policy_links')
            .doc(documentId)
            .get();

    if (!doc.exists || !doc.data().toString().contains('url')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$documentId link is not available.')),
      );
      return;
    }

    final String urlString = doc.get('url');
    final Uri url = Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error fetching link: $e')));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Settings"),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("FAQ"),
            onTap: () async {
              await launchPolicyLink(context, "faq");
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text("Terms and Conditions"),
            onTap: () async {
              await launchPolicyLink(context, "terms_conditions");
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Privacy Policy"),
            onTap: () async {
              await launchPolicyLink(context, "privacy_policy");
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text("Delete Account"),
            onTap: () async {
              _showDeleteAccountDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app_rounded),
            title: const Text("Sign Out"),
            onTap: () async {
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to delete your account? All in-app purchases are non-refundable. Once you delete your account, all content, purchases, records, user data, and all data related to your account will permanently be lost. Deleting your account takes effect immediately.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text(
                "Proceed to delete my account",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                // Call the delete account function here
                await AuthService().deleteAccount(context: context);
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Your account has been successfully deleted.",
                    ),
                  ),
                );
                Navigator.pushReplacement(
                  // Navigate to login page
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
