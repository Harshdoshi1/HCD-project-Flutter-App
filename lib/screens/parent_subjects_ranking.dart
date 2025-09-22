import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

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
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _subjectData = [];
  Map<String, dynamic>? _semesterSummary;

  Future<void> _loadSubjectData() async {
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
        
        await _fetchSubjectData(user.email);
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
            await _fetchSubjectData(email);
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSubjectData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        final response = await http.post(
          Uri.parse('https://hcdbackend.vercel.app/api/student/getStudentComponentMarksAndSubjects'),
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
            
            if (currentSemester != null && currentSemester.containsKey('subjects')) {
              final List<dynamic> subjects = currentSemester['subjects'];
              final List<Map<String, dynamic>> processedSubjects = [];
              
              for (int i = 0; i < subjects.length; i++) {
                final subject = subjects[i];
                final Color subjectColor = _getSubjectColor(i);
                
                processedSubjects.add({
                  'subject': subject['subjectName'] ?? 'Unknown Subject',
                  'code': subject['subjectCode'] ?? 'N/A',
                  'grade': subject['grade'] ?? 'N/A',
                  'color': subjectColor,
                  'totalMarks': subject['totalMarks'] ?? 0,
                  'obtainedMarks': subject['obtainedMarks'] ?? 0,
                  'facultyComments': subject['facultyComments'] ?? 'No comments available',
                });
              }
              
              setState(() {
                _subjectData = processedSubjects;
                _semesterSummary = {
                  'semesterNumber': currentSemester!['semesterNumber'],
                  'spi': currentSemester['spi'] ?? 0.0,
                  'totalSubjects': subjects.length,
                };
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching subject data: $e');
    }
  }

  Color _getSubjectColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

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
    _loadSubjectData();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFf0f4f8), const Color(0xFFe8f4f8)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget(isDark)
                  : Column(
                      children: [
                        _buildHeader(isDark),
                        Expanded(
                          child: _buildSubjectsList(isDark),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final spi = _semesterSummary?['spi'] ?? 0.0;
    final totalSubjects = _semesterSummary?['totalSubjects'] ?? 0;
    final semesterNumber = _semesterSummary?['semesterNumber'] ?? 'Current';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.9),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                '${_studentName}\'s Academic Performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Semester $semesterNumber Overview',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'SPI',
                    spi.toStringAsFixed(2),
                    Icons.trending_up,
                    Colors.green,
                    isDark,
                  ),
                  _buildStatCard(
                    'Subjects',
                    totalSubjects.toString(),
                    Icons.book,
                    Colors.blue,
                    isDark,
                  ),
                  _buildStatCard(
                    'Performance',
                    _getPerformanceLevel(spi),
                    Icons.star,
                    _getPerformanceColor(spi),
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsList(bool isDark) {
    if (_subjectData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              'No subjects found',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _subjectData.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildSubjectCard(_subjectData[index], isDark),
        );
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, bool isDark) {
    final totalMarks = subject['totalMarks'] ?? 100;
    final obtainedMarks = subject['obtainedMarks'] ?? 0;
    final percentage = totalMarks > 0 ? (obtainedMarks / totalMarks * 100).toInt() : 0;
    final Color gradeColor = _getGradeColor(subject['grade']);
    final facultyComments = subject['facultyComments'] ?? 'No comments available';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        border: Border.all(
          color: subject['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                      subject['code'],
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
                  color: gradeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gradeColor.withOpacity(0.5)),
                ),
                child: Text(
                  subject['grade'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score: $obtainedMarks/$totalMarks',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: subject['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(subject['color']),
            minHeight: 6,
          ),
          if (facultyComments != 'No comments available') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faculty Comments:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    facultyComments,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load subject data',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadSubjectData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  String _getPerformanceLevel(double spi) {
    if (spi >= 9.0) return 'Excellent';
    if (spi >= 8.0) return 'Very Good';
    if (spi >= 7.0) return 'Good';
    if (spi >= 6.0) return 'Average';
    return 'Needs Improvement';
  }

  Color _getPerformanceColor(double spi) {
    if (spi >= 9.0) return Colors.green;
    if (spi >= 8.0) return Colors.lightGreen;
    if (spi >= 7.0) return Colors.orange;
    if (spi >= 6.0) return Colors.amber;
    return Colors.red;
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'O':
      case 'A+':
        return Colors.green;
      case 'A':
        return Colors.lightGreen;
      case 'B+':
        return Colors.blue;
      case 'B':
        return Colors.orange;
      case 'C+':
        return Colors.amber;
      case 'C':
        return Colors.deepOrange;
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }
}
