import 'package:flutter/material.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Assignments'),
      ),
      body: Column(
        children: [
          // Card box section
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Assignment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Due Soon', '3', Colors.orange),
                        _buildStatCard('Completed', '5', Colors.green),
                        _buildStatCard('Total', '8', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Upcoming assignments list
          Expanded(
            child: ListView(
              children: [
                _buildAssignmentTile('HCD Project', 'Due: April 10', Icons.assignment, Colors.red),
                _buildAssignmentTile('CPSI Lab Report', 'Due: April 12', Icons.science, Colors.blue),
                _buildAssignmentTile('DAA Algorithm', 'Due: April 15', Icons.code, Colors.green),
                _buildAssignmentTile('AI Presentation', 'Due: April 18', Icons.slideshow, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title),
      ],
    );
  }

  Widget _buildAssignmentTile(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        // Handle assignment tap
      },
    );
  }
}