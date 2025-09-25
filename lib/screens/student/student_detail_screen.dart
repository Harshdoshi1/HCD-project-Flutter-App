import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/student_component_data.dart';
import '../../services/student_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentName;
  final String studentEmail;
  final String studentEnrollment;
  final String studentDetails;
  final VoidCallback toggleTheme;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.studentEnrollment,
    required this.studentDetails,
    required this.toggleTheme,
  });

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  StudentComponentData? componentData;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchStudentComponentData();
  }

  Future<void> _fetchStudentComponentData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final studentService = StudentService();
      final result = await studentService.getStudentComponentMarksAndSubjects(widget.studentEmail);
      setState(() {
        componentData = StudentComponentData.fromJson(result);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

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
          widget.studentName, 
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
                    tag: 'profile-${widget.studentName}',
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
                      _buildInfoRow(context, 'Enrollment', widget.studentEnrollment, Icons.badge),
                      _buildInfoRow(context, 'Department', 'Information & Communication Technology', Icons.business),
                      _buildInfoRow(context, 'Details', widget.studentDetails, Icons.info_outline),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Contact Section
                  _buildGlassCard(
                    context,
                    title: 'Contact',
                    icon: Icons.contact_mail,
                    children: [
                      _buildInfoRow(context, 'Email', widget.studentEmail, Icons.email),
                      _buildInfoRow(context, 'Phone', '+91 9876543210', Icons.phone),
                    ],
                  ),
                  
                  // Loading indicator or error message
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF03A9F4)),
                      ),
                    )
                  else if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildGlassCard(
                        context,
                        title: 'Error',
                        icon: Icons.error_outline,
                        children: [
                          Text('Failed to load data: $error', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    )
                  else if (componentData != null)
                    ..._buildSemesterSections(context),
                  
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
          const Icon(
            Icons.check_circle,
            color: Color(0xFF03A9F4),
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
  
  List<Widget> _buildSemesterSections(BuildContext context) {
    if (componentData == null || componentData!.semesters.isEmpty) {
      return [const Text('No semester data available')];
    }

    final widgets = <Widget>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    for (final semester in componentData!.semesters) {
      // Skip semesters with no subjects
      if (semester.subjects.isEmpty) continue;
      
      widgets.add(const SizedBox(height: 16));
      
      widgets.add(_buildGlassCard(
        context,
        title: 'Semester ${semester.semesterNumber}',
        icon: Icons.menu_book,
        children: [
          // Semester metadata
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoColumn('Date Range:', '${_formatDate(semester.startDate)} - ${_formatDate(semester.endDate)}'),
                if (semester.cpi != null)
                  _buildInfoColumn('CPI:', semester.cpi!.toStringAsFixed(2)),
                if (semester.spi != null)
                  _buildInfoColumn('SPI:', semester.spi!.toStringAsFixed(2)),
                if (semester.rank != null)
                  _buildInfoColumn('Rank:', semester.rank.toString()),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: isDark 
                ? Colors.white.withOpacity(0.2) 
                : Colors.black.withOpacity(0.2),
            height: 24,
          ),
          
          // Subjects
          Text(
            'Subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          
          ...semester.subjects.map((subject) => _buildSubjectCard(context, subject)),
        ],
      ));
    }
    
    return widgets;
  }
  
  Widget _buildSubjectCard(BuildContext context, SubjectData subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark 
          ? Colors.white.withOpacity(0.05) 
          : Colors.black.withOpacity(0.05),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject name and code
            Text(
              subject.subjectName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (subject.subjectCode != null)
              Text(
                subject.subjectCode!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark 
                      ? Colors.white.withOpacity(0.7) 
                      : Colors.black.withOpacity(0.7),
                ),
              ),
            if (subject.credits != null)
              Text(
                'Credits: ${subject.credits}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark 
                      ? Colors.white.withOpacity(0.7) 
                      : Colors.black.withOpacity(0.7),
                ),
              ),
              
            // Component marks and weightage
            if (subject.componentMarks != null || subject.componentWeightage != null) 
              _buildComponentMarksTable(context, subject),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComponentMarksTable(BuildContext context, SubjectData subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold, 
      color: isDark ? Colors.white : Colors.black,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
    );
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Table(
        border: TableBorder.all(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: const Color(0xFF03A9F4).withOpacity(0.1),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Component', style: headerStyle, textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Marks', style: headerStyle, textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Weight', style: headerStyle, textAlign: TextAlign.center),
              ),
            ],
          ),
          
          // Data rows
          if (_hasComponentValues(subject, 'ese'))
            _buildComponentRow(context, 'ESE', 
                subject.componentMarks?.ese, 
                subject.componentWeightage?.ese, 
                cellStyle),
                
          if (_hasComponentValues(subject, 'cse'))
            _buildComponentRow(context, 'CSE', 
                subject.componentMarks?.cse, 
                subject.componentWeightage?.cse, 
                cellStyle),
                
          if (_hasComponentValues(subject, 'ia'))
            _buildComponentRow(context, 'IA', 
                subject.componentMarks?.ia, 
                subject.componentWeightage?.ia, 
                cellStyle),
                
          if (_hasComponentValues(subject, 'tw'))
            _buildComponentRow(context, 'TW', 
                subject.componentMarks?.tw, 
                subject.componentWeightage?.tw, 
                cellStyle),
                
          if (_hasComponentValues(subject, 'viva'))
            _buildComponentRow(context, 'Viva', 
                subject.componentMarks?.viva, 
                subject.componentWeightage?.viva, 
                cellStyle),
        ],
      ),
    );
  }
  
  TableRow _buildComponentRow(BuildContext context, String name, double? marks, double? weightage, TextStyle style) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(name, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(marks != null ? marks.toStringAsFixed(1) : '-', style: style, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(weightage != null ? weightage.toStringAsFixed(1) : '-', style: style, textAlign: TextAlign.center),
        ),
      ],
    );
  }
  
  bool _hasComponentValues(SubjectData subject, String component) {
    if (component == 'ese') {
      return (subject.componentMarks?.ese != null && subject.componentMarks!.ese! > 0) || 
             (subject.componentWeightage?.ese != null && subject.componentWeightage!.ese! > 0);
    } else if (component == 'cse') {
      return (subject.componentMarks?.cse != null && subject.componentMarks!.cse! > 0) || 
             (subject.componentWeightage?.cse != null && subject.componentWeightage!.cse! > 0);
    } else if (component == 'ia') {
      return (subject.componentMarks?.ia != null && subject.componentMarks!.ia! > 0) || 
             (subject.componentWeightage?.ia != null && subject.componentWeightage!.ia! > 0);
    } else if (component == 'tw') {
      return (subject.componentMarks?.tw != null && subject.componentMarks!.tw! > 0) || 
             (subject.componentWeightage?.tw != null && subject.componentWeightage!.tw! > 0);
    } else if (component == 'viva') {
      return (subject.componentMarks?.viva != null && subject.componentMarks!.viva! > 0) || 
             (subject.componentWeightage?.viva != null && subject.componentWeightage!.viva! > 0);
    }
    return false;
  }
  
  Widget _buildInfoColumn(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}