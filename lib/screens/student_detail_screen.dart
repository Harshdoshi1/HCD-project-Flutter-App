import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Hero(
              tag: 'profile-$name',
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, size: 60, color: Colors.blue[800]),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Academic Profile',
              icon: Icons.school,
              children: [
                _buildInfoRow('Rank', rank, Icons.leaderboard),
                _buildInfoRow('Department', 'Information & Communication Technology', Icons.business),
                _buildInfoRow('Semester', '6th', Icons.calendar_today),
                _buildInfoRow('CGPA', '9.2/10', Icons.grade),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Contact',
              icon: Icons.contact_mail,
              children: [
                _buildInfoRow('Email', '${name.toLowerCase().replaceAll(' ', '.')}@marwadiuniversity.ac.in', Icons.email),
                _buildInfoRow('Phone', '+91 9876543210', Icons.phone),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Achievements',
              icon: Icons.emoji_events,
              children: [
                _buildAchievementItem('Hackathon Winner 2023'),
                _buildAchievementItem('Best Project Award'),
                _buildAchievementItem('Paper Published in IEEE'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[800], size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}