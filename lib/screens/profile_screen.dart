import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ProfileScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _setFullScreenMode();
  }

  void _setFullScreenMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 12,
                bottom: 12,
                left: 20,
                right: 20,
              ),
              color: AppTheme.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
            
            // Profile Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.secondaryColor,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.onPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Harsh Doshi',
                      style: TextStyle(
                        color: AppTheme.onBackgroundColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Information and Communication Technology',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: widget.toggleTheme,
                        child: const Text('Toggle Theme'),
                      ),
                    ),
                    _buildInfoSection(
                      title: 'Personal Information',
                      items: {
                        'Roll Number': '92200133002',
                        'Batch': '2022-2026',
                        'Email': 'harsh.doshi116118@marwadiuniversity.ac.in',
                        'Phone': '+91 9876543210',
                      },
                    ),
                    _buildInfoSection(
                      title: 'Academic Information',
                      items: {
                        'Current Semester': '5th Semester',
                        'Current CGPA': '8.75',
                        'Department Rank': '5',
                        'Attendance': '85%',
                      },
                    ),
                    _buildInfoSection(
                      title: 'Additional Information',
                      items: {
                        'Skills': 'Flutter, Python, Java',
                        'Certifications': '3',
                        'Projects': '4',
                        'Internships': '1',
                      },
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).viewPadding.bottom + 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required Map<String, String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        color: AppTheme.surfaceColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              const SizedBox(height: 12),
              ...items.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppTheme.onBackgroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}