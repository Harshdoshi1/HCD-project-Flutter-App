import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class ParentSubjectsRankingScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentSubjectsRankingScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ParentSubjectsRankingScreenState createState() => _ParentSubjectsRankingScreenState();
}

class _ParentSubjectsRankingScreenState extends State<ParentSubjectsRankingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _studentName = 'Student';

  // Simplified subject data for parents
  final List<Map<String, dynamic>> _subjectRankings = [
    {
      'subject': 'Software Engineering',
      'code': 'SE',
      'marks': 85,
      'maxMarks': 100,
      'rank': 12,
      'totalStudents': 120,
      'grade': 'A',
      'color': Colors.green,
    },
    {
      'subject': 'Operating System',
      'code': 'OS',
      'marks': 78,
      'maxMarks': 100,
      'rank': 18,
      'totalStudents': 120,
      'grade': 'B+',
      'color': Colors.blue,
    },
    {
      'subject': 'Database Management',
      'code': 'DBMS',
      'marks': 92,
      'maxMarks': 100,
      'rank': 5,
      'totalStudents': 120,
      'grade': 'A+',
      'color': Colors.purple,
    },
    {
      'subject': 'Computer Networks',
      'code': 'CN',
      'marks': 82,
      'maxMarks': 100,
      'rank': 15,
      'totalStudents': 120,
      'grade': 'A',
      'color': Colors.orange,
    },
    {
      'subject': 'Web Technology',
      'code': 'WT',
      'marks': 88,
      'maxMarks': 100,
      'rank': 8,
      'totalStudents': 120,
      'grade': 'A+',
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    // Extract student name from stored preferences (simplified)
    setState(() {
      _studentName = 'Harsh'; // This would be loaded from preferences
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$_studentName\'s Subjects',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                stops: [0.0, 0.3],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Summary Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildSummaryCard(isDark),
                    ),
                    const SizedBox(height: 20),
                    
                    // Subject Rankings
                    Text(
                      'Subject Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subject Cards
                    ...List.generate(
                      _subjectRankings.length,
                      (index) => SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.1 * (index + 1)),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.1 * index,
                            0.1 * index + 0.5,
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSubjectCard(_subjectRankings[index], isDark),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Info Note
                    _buildInfoNote(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final averageMarks = _subjectRankings.fold<double>(0, (sum, subject) => sum + subject['marks']) / _subjectRankings.length;
    final averageRank = _subjectRankings.fold<double>(0, (sum, subject) => sum + subject['rank']) / _subjectRankings.length;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03A9F4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.analytics,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overall Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Average Score',
                      '${averageMarks.toStringAsFixed(1)}%',
                      Colors.green,
                      isDark,
                    ),
                    _buildSummaryItem(
                      'Average Rank',
                      '${averageRank.toStringAsFixed(0)}',
                      Colors.blue,
                      isDark,
                    ),
                    _buildSummaryItem(
                      'Total Subjects',
                      '${_subjectRankings.length}',
                      Colors.purple,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isDark) {
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, bool isDark) {
    final percentage = (subject['marks'] / subject['maxMarks'] * 100).toInt();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (subject['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        subject['code'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subject['color'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['subject'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Grade: ${subject['grade']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: subject['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem(
                      'Marks',
                      '${subject['marks']}/${subject['maxMarks']}',
                      isDark,
                    ),
                    _buildDetailItem(
                      'Rank',
                      '${subject['rank']}/${subject['totalStudents']}',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                LinearProgressIndicator(
                  value: subject['marks'] / subject['maxMarks'],
                  backgroundColor: isDark ? Colors.white24 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(subject['color']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parent View - Read Only',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is a simplified view for parents. Detailed academic records and grade breakdowns are available to students only.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
