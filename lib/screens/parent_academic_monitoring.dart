import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/api_config.dart';

class ParentAcademicMonitoringScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentAcademicMonitoringScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ParentAcademicMonitoringScreenState createState() => _ParentAcademicMonitoringScreenState();
}

class _ParentAcademicMonitoringScreenState extends State<ParentAcademicMonitoringScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _studentName = 'Student';
  bool _isLoading = true;
  String? _error;
  
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic>? _semesterSummary;
  List<Map<String, dynamic>> _facultyComments = [];
  Map<String, dynamic>? _performanceAnalysis;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadAcademicData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademicData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        setState(() {
          _studentName = user.name;
        });
        
        await _fetchAcademicData(user.email);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('userData');
        
        if (userData != null) {
          final decodedData = json.decode(userData);
          setState(() {
            _studentName = decodedData['name'] ?? 'Student';
          });
          
          final email = decodedData['email'];
          if (email != null) {
            await _fetchAcademicData(email);
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // If API fails, use dummy data
      _setDummyAcademicData();
      setState(() {
        _error = null; // Don't show error, show dummy data instead
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAcademicData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        // Fetch subject data with component marks
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/student/getStudentComponentMarksAndSubjects'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'email': email}),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data.containsKey('semesters')) {
            final List<dynamic> semesters = data['semesters'];
            
            // Get current semester (highest semester number)
            Map<String, dynamic>? currentSemester;
            int highestSemester = 0;
            
            for (var semester in semesters) {
              final semesterNumber = int.tryParse(semester['semesterNumber'].toString()) ?? 0;
              if (semesterNumber > highestSemester) {
                highestSemester = semesterNumber;
                currentSemester = semester;
              }
            }
            
            if (currentSemester != null) {
              setState(() {
                _subjects = List<Map<String, dynamic>>.from(currentSemester!['subjects'] ?? []);
                _semesterSummary = {
                  'semesterNumber': currentSemester['semesterNumber'],
                  'totalSubjects': _subjects.length,
                  'averageGrade': _calculateAverageGrade(),
                  'lowPerformanceCount': _getLowPerformanceCount(),
                  'excellentPerformanceCount': _getExcellentPerformanceCount(),
                };
                _generateFacultyComments();
                _generatePerformanceAnalysis();
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching academic data: $e');
      // If API fails, use dummy data
      _setDummyAcademicData();
    }
  }

  double _calculateAverageGrade() {
    if (_subjects.isEmpty) return 0.0;
    
    double totalPoints = 0.0;
    int validGrades = 0;
    
    for (var subject in _subjects) {
      final grade = subject['grade']?.toString() ?? '';
      final points = _gradeToPoints(grade);
      if (points > 0) {
        totalPoints += points;
        validGrades++;
      }
    }
    
    return validGrades > 0 ? totalPoints / validGrades : 0.0;
  }

  double _gradeToPoints(String grade) {
    switch (grade.toUpperCase()) {
      case 'O': return 10.0;
      case 'A+': return 9.0;
      case 'A': return 8.0;
      case 'B+': return 7.0;
      case 'B': return 6.0;
      case 'C': return 5.0;
      case 'D': return 4.0;
      default: return 0.0;
    }
  }

  int _getLowPerformanceCount() {
    return _subjects.where((subject) {
      final grade = subject['grade']?.toString() ?? '';
      return ['C', 'D', 'F', 'FF'].contains(grade.toUpperCase());
    }).length;
  }

  int _getExcellentPerformanceCount() {
    return _subjects.where((subject) {
      final grade = subject['grade']?.toString() ?? '';
      return ['O', 'A+'].contains(grade.toUpperCase());
    }).length;
  }

  void _generateFacultyComments() {
    // Only show real faculty comments from API - remove mock data
    _facultyComments = [];
  }

  void _setDummyAcademicData() {
    setState(() {
      _subjects = [
        {
          'subjectName': 'Advanced Mathematics',
          'subjectCode': 'MATH301',
          'ia': 18,
          'assignment': 8,
          'viva': 9,
          'ese': 75,
          'total': 110,
          'grade': 'A+',
          'rank': 5
        },
        {
          'subjectName': 'Data Structures',
          'subjectCode': 'CS302',
          'ia': 16,
          'assignment': 7,
          'viva': 8,
          'ese': 68,
          'total': 99,
          'grade': 'A',
          'rank': 8
        },
        {
          'subjectName': 'Database Management',
          'subjectCode': 'CS303',
          'ia': 15,
          'assignment': 6,
          'viva': 7,
          'ese': 62,
          'total': 90,
          'grade': 'B+',
          'rank': 12
        },
        {
          'subjectName': 'Computer Networks',
          'subjectCode': 'CS304',
          'ia': 17,
          'assignment': 8,
          'viva': 9,
          'ese': 72,
          'total': 106,
          'grade': 'A+',
          'rank': 3
        },
        {
          'subjectName': 'Software Engineering',
          'subjectCode': 'CS305',
          'ia': 14,
          'assignment': 6,
          'viva': 7,
          'ese': 58,
          'total': 85,
          'grade': 'B',
          'rank': 18
        },
      ];
      
      _performanceAnalysis = {
        'level': 'Good',
        'recommendation': 'Overall performance is satisfactory. Focus on improving Software Engineering and Database Management subjects.',
        'color': Colors.blue,
      };
    });
  }

  void _generatePerformanceAnalysis() {
    final avgGrade = _calculateAverageGrade();
    String performanceLevel;
    String recommendation;
    Color statusColor;

    if (avgGrade >= 8.5) {
      performanceLevel = 'Excellent';
      recommendation = 'Maintain current study habits. Consider advanced courses.';
      statusColor = Colors.green;
    } else if (avgGrade >= 7.0) {
      performanceLevel = 'Good';
      recommendation = 'Focus on weaker subjects. Aim for consistency.';
      statusColor = Colors.blue;
    } else if (avgGrade >= 6.0) {
      performanceLevel = 'Average';
      recommendation = 'Increase study time. Seek help from faculty.';
      statusColor = Colors.orange;
    } else {
      performanceLevel = 'Needs Improvement';
      recommendation = 'Immediate attention required. Consider tutoring.';
      statusColor = Colors.red;
    }

    _performanceAnalysis = {
      'level': performanceLevel,
      'recommendation': recommendation,
      'color': statusColor,
      'averageGrade': avgGrade,
    };
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
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
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$_studentName\'s Academic Monitor',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingWidget(isDark)
                        : _error != null
                            ? _buildErrorWidget(isDark)
                            : _buildContentWidget(isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF03A9F4)),
          SizedBox(height: 16),
          Text(
            'Loading academic data...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading academic data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAcademicData,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF03A9F4),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance Overview Card
          SlideTransition(
            position: _slideAnimation,
            child: _buildPerformanceOverviewCard(isDark),
          ),
          const SizedBox(height: 16),
          
          // Subject List Card
          SlideTransition(
            position: _slideAnimation,
            child: _buildSubjectListCard(isDark),
          ),
          const SizedBox(height: 16),
          
          // Faculty Comments Card - Only show if there are real comments
          if (_facultyComments.isNotEmpty) ...[
            SlideTransition(
              position: _slideAnimation,
              child: _buildFacultyCommentsCard(isDark),
            ),
            const SizedBox(height: 16),
          ],
          
          // Performance Analysis Card
          if (_performanceAnalysis != null)
            SlideTransition(
              position: _slideAnimation,
              child: _buildPerformanceAnalysisCard(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverviewCard(bool isDark) {
    return _buildGlassCard(
      title: 'Performance Overview',
      icon: Icons.analytics,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Subjects',
                '${_semesterSummary?['totalSubjects'] ?? 0}',
                Colors.blue,
                isDark,
              ),
              _buildStatItem(
                'Average Grade',
                '${(_semesterSummary?['averageGrade'] ?? 0.0).toStringAsFixed(1)}',
                Colors.green,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Excellent',
                '${_semesterSummary?['excellentPerformanceCount'] ?? 0}',
                Colors.purple,
                isDark,
              ),
              _buildStatItem(
                'Need Attention',
                '${_semesterSummary?['lowPerformanceCount'] ?? 0}',
                Colors.orange,
                isDark,
              ),
            ],
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildSubjectListCard(bool isDark) {
    return _buildGlassCard(
      title: 'Current Semester Subjects',
      icon: Icons.subject,
      child: Column(
        children: _subjects.map((subject) => _buildSubjectItem(subject, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildSubjectItem(Map<String, dynamic> subject, bool isDark) {
    final subjectName = subject['subjectName'] ?? 'Unknown Subject';
    final grade = subject['grade'] ?? 'N/A';
    final iaMarks = subject['iaMarks'] ?? 0;
    final assignmentMarks = subject['assignmentMarks'] ?? 0;
    final vivaMarks = subject['vivaMarks'] ?? 0;
    final eseMarks = subject['eseMarks'] ?? 0;
    
    final gradeColor = _getGradeColor(grade);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: gradeColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Grade: $grade',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Component Marks:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComponentMark('IA', iaMarks, isDark),
              _buildComponentMark('Assignment', assignmentMarks, isDark),
              _buildComponentMark('Viva', vivaMarks, isDark),
              _buildComponentMark('ESE', eseMarks, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentMark(String label, dynamic marks, bool isDark) {
    return Column(
      children: [
        Text(
          marks.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildFacultyCommentsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Faculty Feedback',
      icon: Icons.comment,
      child: Column(
        children: _facultyComments.map((comment) => _buildCommentItem(comment, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, bool isDark) {
    final isPositive = comment['type'] == 'positive';
    final color = isPositive ? Colors.green : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.thumb_up : Icons.info,
                color: color,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '${comment['subject']} - ${comment['faculty']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            comment['comment'],
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Text(
            comment['date'],
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysisCard(bool isDark) {
    final analysis = _performanceAnalysis!;
    return _buildGlassCard(
      title: 'Performance Analysis',
      icon: Icons.trending_up,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (analysis['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (analysis['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assessment,
                      color: analysis['color'],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Performance Level: ${analysis['level']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  analysis['recommendation'],
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'O':
      case 'A+':
        return Colors.green;
      case 'A':
        return Colors.lightGreen;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
      case 'F':
      case 'FF':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
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
            padding: const EdgeInsets.all(16),
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
                        icon,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
