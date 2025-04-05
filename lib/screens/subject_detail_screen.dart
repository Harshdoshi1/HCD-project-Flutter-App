import 'package:flutter/material.dart';
import 'package:hac_flutter_hcd/screens/subjects_screen.dart';
import '../constants/app_theme.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({Key? key, required this.subject}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: const Color(0xFF03A9F4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Code: ${subject.code}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: subject.status == 'Passed' 
                      ? Colors.green.withOpacity(0.2) 
                      : subject.status == 'Failed' 
                        ? Colors.red.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subject.status,
                    style: TextStyle(
                      color: subject.status == 'Passed' 
                        ? Colors.green 
                        : subject.status == 'Failed' 
                          ? Colors.red 
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Overall Grade: ${subject.grade}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Grade Components:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    color: Color(0xFF03A9F4),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Component',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Marks',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Out of',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ...subject.components.entries.map((entry) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(entry.key),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(entry.value['marks'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(entry.value['outOf'].toString()),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
