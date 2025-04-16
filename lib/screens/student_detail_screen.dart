import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class StudentDetailScreen extends StatelessWidget {
  final String name;
  final String rank;
  final String details;

  const StudentDetailScreen({
    Key? key,
    required this.name,
    required this.rank,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          name, 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF03A9F4),
                  isDark ? Colors.black : Colors.white,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile image
                  Hero(
                    tag: 'profile-$name',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF03A9F4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF03A9F4).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Academic Profile Section
                  _buildGlassCard(
                    context,
                    title: 'Academic Profile',
                    icon: Icons.school,
                    children: [
                      _buildInfoRow(context, 'Rank', rank, Icons.leaderboard),
                      _buildInfoRow(context, 'Department', 'Information & Communication Technology', Icons.business),
                      _buildInfoRow(context, 'Semester', '6th', Icons.calendar_today),
                      _buildInfoRow(context, 'CGPA', '9.2/10', Icons.grade),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Contact Section
                  _buildGlassCard(
                    context,
                    title: 'Contact',
                    icon: Icons.contact_mail,
                    children: [
                      _buildInfoRow(context, 'Email', '${name.toLowerCase().replaceAll(' ', '.')}@marwadiuniversity.ac.in', Icons.email),
                      _buildInfoRow(context, 'Phone', '+91 9876543210', Icons.phone),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Achievements Section
                  _buildGlassCard(
                    context,
                    title: 'Achievements',
                    icon: Icons.emoji_events,
                    children: [
                      _buildAchievementItem(context, 'Hackathon Winner 2023'),
                      _buildAchievementItem(context, 'Best Project Award'),
                      _buildAchievementItem(context, 'Paper Published in IEEE'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Skills Section
                  _buildGlassCard(
                    context,
                    title: 'Skills',
                    icon: Icons.code,
                    children: [
                      _buildSkillsRow(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon, 
                    color: const Color(0xFF03A9F4), 
                    size: 24
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Divider(
                color: isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.2),
                height: 24,
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF03A9F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF03A9F4),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(BuildContext context, String achievement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF03A9F4),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              achievement,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skills = ['Flutter', 'Dart', 'Firebase', 'UI/UX', 'Java', 'Python'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => Chip(
        backgroundColor: const Color(0xFF03A9F4).withOpacity(0.1),
        side: BorderSide(
          color: const Color(0xFF03A9F4).withOpacity(0.3),
        ),
        label: Text(
          skill,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }
}