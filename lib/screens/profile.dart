import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.lightBlue,
          child: const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Info
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.lightBlue.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Harsh Doshi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'harsh.doshi116118@marwadiuniversity.ac.in',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Settings or info
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.lightBlue),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.lightBlue),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.help_outline, color: Colors.lightBlue),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.lightBlue),
                  title: const Text('Logout'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
