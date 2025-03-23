import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key, required this.toggleTheme}) : super(key: key);

  final VoidCallback toggleTheme;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.primary,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: theme.onPrimary),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildProfileHeader(theme),
                const SizedBox(height: 16),
                _buildAnimatedInfoCard('Personal Information', [
                  _buildInfoRow('Email', 'harshdoshi@university.com'),
                  _buildInfoRow('Phone', '+91 9876543210'),
                  _buildInfoRow('Batch', '2021-2025'),
                ], theme),
                _buildAnimatedInfoCard('Academic Information', [
                  _buildInfoRow('Department', 'Information & Communication Technology'),
                  _buildInfoRow('Semester', '5th'),
                  _buildInfoRow('CGPA', '8.8'),
                  _buildInfoRow('Rank', 'Top 10'),
                  _buildInfoRow('Attendance', '85%'),
                ], theme),
                _buildAnimatedInfoCard('Additional Information', [
                  _buildInfoRow('Skills', 'Flutter, Dart, Firebase, UI/UX Design'),
                  _buildInfoRow('Certifications', 'Google Flutter Certification'),
                  _buildInfoRow('Projects', 'Hostel Management App, Resume Builder'),
                  _buildInfoRow('Internships', 'Software Developer Intern at XYZ Tech'),
                ], theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: theme.secondaryContainer,
          child: Icon(Icons.person, size: 50, color: theme.onSecondaryContainer),
        ),
        const SizedBox(height: 12),
        Text(
          'Harsh Doshi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.onBackground,
          ),
        ),
        Text(
          'ICT2025002',
          style: TextStyle(
            fontSize: 16,
            color: theme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedInfoCard(String title, List<Widget> children, ColorScheme theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              const Divider(),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
