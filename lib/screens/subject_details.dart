import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Physics',
                style: TextStyle(
                  color: AppTheme.onPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: AppTheme.onPrimaryColor),
              )
            ],
          ),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Some detail card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Newton’s Laws',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'An overview of Newton’s laws of motion. Understand the fundamentals of inertia, F=ma, and action-reaction.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Placeholder for a line chart
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Line Chart Placeholder'),
                  ),
                ),
                const SizedBox(height: 16),
                // Maybe a list of upcoming tasks or lessons
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondaryColor,
                          child: const Icon(
                            Icons.book,
                            color: AppTheme.onPrimaryColor,
                          ),
                        ),
                        title: Text('Chapter ${index + 1}', style: TextStyle(color: AppTheme.onBackgroundColor)),
                        subtitle: const Text('View details', style: TextStyle(color: AppTheme.onBackgroundColor)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
