import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback toggleTheme;

  const ProfileScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Profile',
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
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.secondaryColor,
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppTheme.onPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Harsh Doshi',
                style: TextStyle(
                  color: AppTheme.onBackgroundColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Information and Communication Technology',
                style: TextStyle(
                  color: AppTheme.onBackgroundColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: toggleTheme,
                child: const Text('Toggle Theme'),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Personal Information',
                items: {
                  'Roll Number': '92200133002',
                  'Batch': '2022-2026',
                  'Email': 'harsh.doshi116118@marwadiuniversity.ac.in',
                  'Phone': '+91 9876543210',
                },
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Academic Information',
                items: {
                  'Current Semester': '5th Semester',
                  'Current CGPA': '8.75',
                  'Department Rank': '5',
                  'Attendance': '85%',
                },
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Additional Information',
                items: {
                  'Skills': 'Flutter, Python, Java',
                  'Certifications': '3',
                  'Projects': '4',
                  'Internships': '1',
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required Map<String, String> items,
  }) {
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.onBackgroundColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: AppTheme.onBackgroundColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
