import 'package:flutter/material.dart';
import 'package:hac_flutter_hcd/screens/subjects_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({
    Key? key,
    required this.subject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: const Color(0xFF03A9F4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPerformanceCard(theme),
            const SizedBox(height: 24),
            _buildComponentsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.code,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(subject.status),
                  backgroundColor: subject.status == 'Passed'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: subject.status == 'Passed'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatItem('Grade', subject.grade, _getGradeColor(subject.grade)),
                const SizedBox(width: 12),
                _buildStatItem('Percentage', '${subject.percentage.toStringAsFixed(1)}%',
                    _getPerformanceColor(subject.percentage)),
                const SizedBox(width: 12),
                _buildStatItem('Marks', '${subject.totalMarks.toInt()}/${subject.maxMarks.toInt()}',
                    const Color(0xFF03A9F4)),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: subject.percentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              color: _getPerformanceColor(subject.percentage),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance: ${subject.performanceLevel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getPerformanceColor(subject.percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${subject.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getPerformanceColor(subject.percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: subject.components.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final component = subject.components.entries.elementAt(index);
            final percentage = (component.value['marks'] / component.value['outOf']) * 100;
            return _buildComponentCard(component.key, component.value, percentage, theme);
          },
        ),
      ],
    );
  }

  Widget _buildComponentCard(
    String name,
    Map<String, dynamic> data,
    double percentage,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['marks']}/${data['outOf']} marks',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        color: _getPerformanceColor(percentage),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Chip(
                  label: Text('${percentage.toStringAsFixed(1)}%'),
                  backgroundColor: _getPerformanceColor(percentage).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getPerformanceColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.lightGreen;
    if (percentage >= 55) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.lightGreen;
      case 'C+':
      case 'C':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}