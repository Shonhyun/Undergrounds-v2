import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/admin/exams/manage_exams_screen.dart';
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class ManageSubjectsPage extends StatelessWidget {
  final List<String> subjects = ['Math', 'ESAS', 'EE', 'Refresher'];

  ManageSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Subjects')),
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(subjects[index]),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(context, slideForward(ManageExamsPage(subject: subjects[index])));
            },
          );
        },
      ),
    );
  }
}
