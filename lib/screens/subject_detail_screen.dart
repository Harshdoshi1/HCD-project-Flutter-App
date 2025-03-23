import 'package:flutter/material.dart';
import 'subjects_screen.dart'; // Import the Subject class

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({Key? key, required this.subject}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Code: ${subject.code}'),
            Text('Grade: ${subject.grade}'),
            Text('Status: ${subject.status}'),
          ],
        ),
      ),
    );
  }
}
