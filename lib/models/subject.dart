class Subject {
  final String name;
  final String code;
  final String status;
  final String grade;
  final Map<String, dynamic> components;

  Subject({
    required this.name,
    required this.code,
    required this.status,
    required this.grade,
    required this.components,
  });

  double get totalMarks => components.values.fold(
        0, 
        (sum, component) => sum + (component['marks'] ?? 0)
      );

  double get maxMarks => components.values.fold(
        0, 
        (sum, component) => sum + (component['outOf'] ?? 0)
      );

  double get percentage => maxMarks > 0 ? (totalMarks / maxMarks) * 100 : 0;

  String get performanceLevel {
    if (percentage >= 85) return 'Excellent';
    if (percentage >= 70) return 'Good';
    if (percentage >= 55) return 'Average';
    return 'Needs Improvement';
  }
}
