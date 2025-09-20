import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'parent_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentDashboardScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _studentName = 'Student';
  String _parentName = 'Parent';

  // Simplified academic data for parents
  final Map<String, dynamic> _academicSummary = {
    'currentSemester': 6,
    'latestCPI': 8.5,
    'latestSPI': 8.2,
    'currentRank': 15,
    'totalStudents': 120,
  };

  // ICT Department Goals
  final List<Map<String, dynamic>> _ictGoals = [
    {
      'title': 'Internships',
      'description': '100% placement assistance',
      'icon': Icons.work,
      'color': Colors.blue,
      'progress': 0.85,
    },
    {
      'title': 'Workshops',
      'description': 'Industry-relevant training',
      'icon': Icons.school,
      'color': Colors.green,
      'progress': 0.92,
    },
    {
      'title': 'Placements',
      'description': 'Top company partnerships',
      'icon': Icons.business,
      'color': Colors.orange,
      'progress': 0.78,
    },
  ];

  // Upcoming events (simplified for parents)
  final List<Map<String, dynamic>> _upcomingEvents = [
    {
      'title': 'Parent-Teacher Meeting',
      'date': 'Apr 25, 2025',
      'icon': Icons.people,
      'color': Colors.purple,
    },
    {
      'title': 'Final Examinations',
      'date': 'May 15, 2025',
      'icon': Icons.assignment,
      'color': Colors.red,
    },
    {
      'title': 'Results Declaration',
      'date': 'May 30, 2025',
      'icon': Icons.grade,
      'color': Colors.green,
    },
  ];

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? '';
      
      if (userEmail.isNotEmpty) {
        // Extract student name from email for parent
        final nameMatch = RegExp(r'^([a-zA-Z]+)').firstMatch(userEmail.split('@').first);
        if (nameMatch != null && nameMatch.group(0) != null) {
          setState(() {
            _studentName = nameMatch.group(0)!;
            _studentName = _studentName[0].toUpperCase() + _studentName.substring(1);
            _parentName = "$_studentName's Parent";
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
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
                    // Welcome message and profile icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _parentName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitoring $_studentName\'s progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
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
                              backgroundColor: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: isDark ? Colors.white : Colors.black54,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Academic Summary Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildAcademicSummaryCard(isDark),
                    ),
                    const SizedBox(height: 16),
                    
                    // ICT Department Goals Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildICTGoalsCard(isDark),
                    ),
                    const SizedBox(height: 16),
                    
                    // Upcoming Events Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildUpcomingEventsCard(isDark),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSummaryCard(bool isDark) {
    return _buildGlassCard(
      title: '$_studentName\'s Academic Summary',
      icon: Icons.school,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Current CPI', '${_academicSummary['latestCPI']}', Colors.blue, isDark),
              _buildSummaryItem('Current SPI', '${_academicSummary['latestSPI']}', Colors.green, isDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Class Rank', '${_academicSummary['currentRank']}', Colors.orange, isDark),
              _buildSummaryItem('Semester', '${_academicSummary['currentSemester']}', Colors.purple, isDark),
            ],
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildICTGoalsCard(bool isDark) {
    return _buildGlassCard(
      title: 'ICT Department Goals',
      icon: Icons.flag,
      child: Column(
        children: _ictGoals.map((goal) => _buildGoalItem(goal, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildUpcomingEventsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Important Dates',
      icon: Icons.event,
      child: Column(
        children: _upcomingEvents.map((event) => _buildEventItem(event, isDark)).toList(),
      ),
      isDark: isDark,
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
}
