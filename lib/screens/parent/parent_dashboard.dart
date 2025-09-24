import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'parent_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../models/student_ranking_model.dart';
import '../../utils/api_config.dart';
import 'parent_academic_monitoring.dart';
import 'parent_communication.dart';

class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentDashboardScreen({super.key, required this.toggleTheme});

  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  String _studentName = 'Student';
  String _parentName = 'Parent';
  String? _enrollmentNumber;
  bool _isLoading = true;
  String? _error;

  // Real academic data from API
  Map<String, dynamic>? _academicData;
  List<dynamic> _recentActivities = [];
  Map<String, dynamic>? _currentSemesterData;
  List<Map<String, dynamic>> _gradeAlerts = [];
  int _totalCocurricularPoints = 0;
  int _totalExtracurricularPoints = 0;


  // Career Goals and Pathways
  final List<Map<String, dynamic>> _careerGoals = [
    {
      'title': 'Technical Skills',
      'description': 'Programming & Development',
      'icon': Icons.code,
      'color': Colors.blue,
      'currentLevel': 'Intermediate',
      'targetLevel': 'Advanced',
    },
    {
      'title': 'Industry Readiness',
      'description': 'Internships & Projects',
      'icon': Icons.work,
      'color': Colors.green,
      'currentLevel': 'Developing',
      'targetLevel': 'Industry Ready',
    },
    {
      'title': 'Leadership Skills',
      'description': 'Club Activities & Events',
      'icon': Icons.groups,
      'color': Colors.orange,
      'currentLevel': 'Participating',
      'targetLevel': 'Leading',
    },
    {
      'title': 'Academic Excellence',
      'description': 'Maintain High CPI/SPI',
      'icon': Icons.school,
      'color': Colors.purple,
      'currentLevel': 'Good',
      'targetLevel': 'Excellent',
    },
  ];


  Future<void> _loadUserData() async {
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
          _enrollmentNumber = user.enrollmentNumber;
          _parentName = "${user.name}'s Parent";
        });
        
        // Load academic data
        await _loadAcademicData(user.email);
        
        // Load activity data
        await _loadActivityData(user.enrollmentNumber);
        
        // Load current semester subjects for grade alerts
        await _loadCurrentSemesterData(user.email);
      } else {
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('userData');
        
        if (userData != null) {
          final decodedData = json.decode(userData);
          setState(() {
            _studentName = decodedData['name'] ?? 'Student';
            _enrollmentNumber = decodedData['enrollmentNumber'];
            _parentName = "$_studentName's Parent";
          });
          
          final email = decodedData['email'];
          if (email != null) {
            await _loadAcademicData(email);
            await _loadActivityData(_enrollmentNumber!);
            await _loadCurrentSemesterData(email);
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAcademicData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/academic/getAcademicDataByEmail'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'email': email}),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _academicData = {
              'currentSemester': data['currentSemester'] ?? 6,
              'latestCPI': data['latestCPI'] ?? 0.0,
              'latestSPI': data['latestSPI'] ?? 0.0,
              'currentRank': data['latestRank'] ?? 0,
              'enrollmentNumber': data['enrollmentNumber'] ?? '',
            };
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading academic data: $e');
    }
  }

  Future<void> _loadActivityData(String enrollmentNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        // Get total activity points
        final pointsResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/events/fetchTotalActivityPoints'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'enrollmentNumber': enrollmentNumber,
          }),
        );
        
        if (pointsResponse.statusCode == 200) {
          final pointsData = json.decode(pointsResponse.body);
          setState(() {
            _totalCocurricularPoints = pointsData['totalCocurricular'] ?? 0;
            _totalExtracurricularPoints = pointsData['totalExtracurricular'] ?? 0;
          });
        }
        
        // Get recent activities
        final activitiesResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/events/fetchEventsbyEnrollandSemester'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'enrollmentNumber': enrollmentNumber,
            'semester': 'all'
          }),
        );
        
        if (activitiesResponse.statusCode == 200) {
          final data = json.decode(activitiesResponse.body);
          if (data is List) {
            setState(() {
              _recentActivities = data.take(3).toList(); // Get last 3 activities
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading activity data: $e');
    }
  }

  Future<void> _loadCurrentSemesterData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
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
            if (semesters.isNotEmpty) {
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
                  _currentSemesterData = currentSemester;
                  _generateGradeAlerts(currentSemester!);
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading current semester data: $e');
    }
  }

  void _generateGradeAlerts(Map<String, dynamic> semesterData) {
    final List<Map<String, dynamic>> alerts = [];
    
    if (semesterData.containsKey('subjects')) {
      final List<dynamic> subjects = semesterData['subjects'];
      
      for (var subject in subjects) {
        final String subjectName = subject['subjectName'] ?? 'Unknown';
        final String grade = subject['grade'] ?? 'NA';
        
        // Check for low grades
        if (grade == 'C' || grade == 'D' || grade == 'F' || grade == 'FF') {
          alerts.add({
            'type': 'warning',
            'title': 'Low Grade Alert',
            'message': '$subjectName: Grade $grade needs attention',
            'color': Colors.orange,
            'icon': Icons.warning,
          });
        }
        
        // Check for excellent performance
        if (grade == 'A+' || grade == 'O') {
          alerts.add({
            'type': 'success',
            'title': 'Excellent Performance',
            'message': '$subjectName: Outstanding grade $grade!',
            'color': Colors.green,
            'icon': Icons.star,
          });
        }
      }
    }
    
    setState(() {
      _gradeAlerts = alerts;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _loadUserData();
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
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF03A9F4),
                  Colors.black,
                ],
                stops: [0.0, 0.4],
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
                    // Welcome message and profile icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _parentName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitoring $_studentName\'s progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ParentProfileScreen(
                                  toggleTheme: widget.toggleTheme,
                                  isDarkMode: isDark,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isLoading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF03A9F4)),
                            SizedBox(height: 16),
                            Text(
                              'Loading student data...',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_error != null)
                      _buildErrorWidget(isDark)
                    else
                      Column(
                        children: [
                          // Grade Alerts Card (if any)
                          if (_gradeAlerts.isNotEmpty) ...[
                            SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildGradeAlertsCard(isDark),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Academic Summary Card
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildAcademicSummaryCard(isDark),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Career Goals Card
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildCareerGoalsCard(isDark),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Recent Activities Card
                          if (_recentActivities.isNotEmpty) ...[
                            SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildRecentActivitiesCard(isDark),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Student Progress Overview
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildProgressOverviewCard(isDark),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Quick Actions Card
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildQuickActionsCard(isDark),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return _buildGlassCard(
      title: 'Error Loading Data',
      icon: Icons.error_outline,
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load student data. Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03A9F4),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildGradeAlertsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Grade Alerts',
      icon: Icons.notifications_active,
      child: Column(
        children: _gradeAlerts.map((alert) => _buildAlertItem(alert, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (alert['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (alert['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            alert['icon'],
            color: alert['color'],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  alert['message'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSummaryCard(bool isDark) {
    final academicData = _academicData ?? {};
    return _buildGlassCard(
      title: 'Academic Summary', // $_studentName\'s
      icon: Icons.school,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Current CPI', '${academicData['latestCPI'] ?? 'N/A'}', Colors.blue, isDark),
              _buildSummaryItem('Current SPI', '${academicData['latestSPI'] ?? 'N/A'}', Colors.green, isDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Class Rank', '${academicData['currentRank'] ?? 'N/A'}', Colors.orange, isDark),
              _buildSummaryItem('Semester', '${academicData['currentSemester'] ?? 'N/A'}', Colors.purple, isDark),
            ],
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildCareerGoalsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Career Development Goals',
      icon: Icons.flag,
      child: Column(
        children: _careerGoals.map((goal) => _buildCareerGoalItem(goal, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildCareerGoalItem(Map<String, dynamic> goal, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (goal['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (goal['color'] as Color).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (goal['color'] as Color).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                goal['icon'],
                color: goal['color'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    goal['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Current: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                      Text(
                        goal['currentLevel'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: goal['color'],
                        ),
                      ),
                      Text(
                        ' → Target: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                      Text(
                        goal['targetLevel'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard(bool isDark) {
    return _buildGlassCard(
      title: 'Recent Activities',
      icon: Icons.event_note,
      child: Column(
        children: [
          if (_recentActivities.isEmpty)
            Text(
              'No recent activities found',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            )
          else
            ..._recentActivities.map((activity) => _buildActivityItem(activity, isDark)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointsItem('Co-curricular', _totalCocurricularPoints, Colors.blue, isDark),
              _buildPointsItem('Extra-curricular', _totalExtracurricularPoints, Colors.green, isDark),
            ],
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['eventName'] ?? 'Event',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${activity['points'] ?? 0} points • ${activity['eventDate'] ?? 'Date not available'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsItem(String label, int points, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            points.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressOverviewCard(bool isDark) {
    return _buildGlassCard(
      title: 'Student Progress Overview',
      icon: Icons.trending_up,
      child: Column(
        children: [
          _buildProgressItem(
            'Academic Performance',
            _getAcademicPerformanceLevel(),
            _getAcademicPerformanceColor(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Activity Participation',
            _getActivityParticipationLevel(),
            _getActivityParticipationColor(),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Overall Development',
            _getOverallDevelopmentLevel(),
            _getOverallDevelopmentColor(),
            isDark,
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildProgressItem(String title, String level, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            level,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _getAcademicPerformanceLevel() {
    final cpi = _academicData?['latestCPI'] ?? 0.0;
    if (cpi >= 9.0) return 'Excellent';
    if (cpi >= 8.0) return 'Very Good';
    if (cpi >= 7.0) return 'Good';
    if (cpi >= 6.0) return 'Average';
    return 'Needs Improvement';
  }

  Color _getAcademicPerformanceColor() {
    final cpi = _academicData?['latestCPI'] ?? 0.0;
    if (cpi >= 9.0) return Colors.green;
    if (cpi >= 8.0) return Colors.lightGreen;
    if (cpi >= 7.0) return Colors.orange;
    if (cpi >= 6.0) return Colors.amber;
    return Colors.red;
  }

  String _getActivityParticipationLevel() {
    final totalPoints = _totalCocurricularPoints + _totalExtracurricularPoints;
    if (totalPoints >= 100) return 'Highly Active';
    if (totalPoints >= 50) return 'Active';
    if (totalPoints >= 20) return 'Moderate';
    if (totalPoints > 0) return 'Low';
    return 'Inactive';
  }

  Color _getActivityParticipationColor() {
    final totalPoints = _totalCocurricularPoints + _totalExtracurricularPoints;
    if (totalPoints >= 100) return Colors.green;
    if (totalPoints >= 50) return Colors.lightGreen;
    if (totalPoints >= 20) return Colors.orange;
    if (totalPoints > 0) return Colors.amber;
    return Colors.red;
  }

  String _getOverallDevelopmentLevel() {
    final academicLevel = _getAcademicPerformanceLevel();
    final activityLevel = _getActivityParticipationLevel();
    
    if (academicLevel == 'Excellent' && (activityLevel == 'Highly Active' || activityLevel == 'Active')) {
      return 'Outstanding';
    }
    if (academicLevel == 'Very Good' || academicLevel == 'Good') {
      return 'Good Progress';
    }
    return 'Developing';
  }

  Color _getOverallDevelopmentColor() {
    final level = _getOverallDevelopmentLevel();
    if (level == 'Outstanding') return Colors.green;
    if (level == 'Good Progress') return Colors.lightGreen;
    return Colors.orange;
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF03A9F4),
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

  Widget _buildGoalItem(Map<String, dynamic> goal, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (goal['color'] as Color).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              goal['icon'],
              color: goal['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  goal['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goal['progress'],
                  backgroundColor: isDark ? Colors.white24 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(goal['color']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (event['color'] as Color).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              event['icon'],
              color: event['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  event['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Quick Actions',
      icon: Icons.dashboard,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Academic Monitor',
                  Icons.school,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentAcademicMonitoringScreen(
                        toggleTheme: widget.toggleTheme,
                      ),
                    ),
                  ),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Communications',
                  Icons.message,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentCommunicationScreen(
                        toggleTheme: widget.toggleTheme,
                      ),
                    ),
                  ),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Monthly Reports',
                  Icons.description,
                  Colors.purple,
                  () => _showReportsDialog(isDark),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Contact Faculty',
                  Icons.contact_phone,
                  Colors.orange,
                  () => _showContactDialog(isDark),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Monthly Reports',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(
                'January 2024 Report',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Monthly progress summary',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Color(0xFF03A9F4)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading January 2024 report...'),
                      backgroundColor: Color(0xFF03A9F4),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(
                'Semester Summary',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Complete semester analysis',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Color(0xFF03A9F4)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading semester summary...'),
                      backgroundColor: Color(0xFF03A9F4),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Contact Faculty',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                'Dr. Sarah Johnson',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Mathematics Department\nHead of Department',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.email, color: Color(0xFF03A9F4)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening email to Dr. Sarah Johnson...'),
                      backgroundColor: Color(0xFF03A9F4),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                'Prof. Michael Chen',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Physics Department\nClass Coordinator',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.email, color: Color(0xFF03A9F4)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening email to Prof. Michael Chen...'),
                      backgroundColor: Color(0xFF03A9F4),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
