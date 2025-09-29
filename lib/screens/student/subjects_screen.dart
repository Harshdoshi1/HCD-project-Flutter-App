
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/subject.dart';
import '../../models/student_component_data.dart';
import '../../models/student_performance_model.dart';
import '../../services/student_service.dart';
import '../../services/student_analysis_service.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'subject_detail_screen.dart';
import '../../widgets/glass_card.dart';

class SubjectsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const SubjectsScreen({super.key, required this.toggleTheme});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late AnimationController _semesterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // New state variables for API data
  final StudentService _studentService = StudentService();
  final StudentAnalysisService _analysisService = StudentAnalysisService();
  StudentComponentData? _studentData;
  Map<int, StudentPerformanceModel> _allSemesterData = {};
  bool _isLoading = true;
  bool _useNewApi = true; // Flag to switch between old and new API
  String? _error;
  
  // Semester navigation
  int _selectedSemester = 1;
  PageController _pageController = PageController();
  ScrollController _semesterScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true; // persist state when navigating tabs

  // Pull-to-refresh handler
  Future<void> _onRefresh() async {
    try {
      await _fetchStudentData();
    } catch (e) {
      debugPrint('Subjects refresh failed: $e');
    }
  }

  static const List<Map<String, dynamic>> semesters = [
    {
      'name': 'Semester 1',
      'subjects': [
        {
          'name': 'ICE',
          'code': 'MA101',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28.0, 'outOf': 30.0},
            'Viva': {'marks': 22.0, 'outOf': 25.0},
            'Assignment': {'marks': 23.0, 'outOf': 25.0},
            'CSE': {'marks': 18.0, 'outOf': 20.0},
            'ESE': {'marks': 45.0, 'outOf': 50.0},
          },
        },
        {
          'name': 'FSSI',
          'code': 'PH101',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 29.0, 'outOf': 30.0},
            'Viva': {'marks': 24.0, 'outOf': 25.0},
            'Assignment': {'marks': 24.0, 'outOf': 25.0},
            'CSE': {'marks': 19.0, 'outOf': 20.0},
            'ESE': {'marks': 48.0, 'outOf': 50.0},
          },
        },
        {
          'name': 'AC',
          'code': 'CH101',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26.0, 'outOf': 30.0},
            'Viva': {'marks': 20.0, 'outOf': 25.0},
            'Assignment': {'marks': 21.0, 'outOf': 25.0},
            'CSE': {'marks': 17.0, 'outOf': 20.0},
            'ESE': {'marks': 42.0, 'outOf': 50.0},
          },
        },
      ]
    },
    {
      'name': 'Semester 2',
      'subjects': [
        {
          'name': 'OOP',
          'code': 'MA201',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28.0, 'outOf': 30.0},
            'Viva': {'marks': 22.0, 'outOf': 25.0},
            'Assignment': {'marks': 23.0, 'outOf': 25.0},
            'CSE': {'marks': 18.0, 'outOf': 20.0},
            'ESE': {'marks': 45.0, 'outOf': 50.0},
          },
        },
        {
          'name': 'DLD',
          'code': 'EC201',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 9.0, 'outOf': 30.0},
            'Viva': {'marks': 24.0, 'outOf': 25.0},
            'Assignment': {'marks': 24.0, 'outOf': 25.0},
            'CSE': {'marks': 19.0, 'outOf': 20.0},
            'ESE': {'marks': 48.0, 'outOf': 50.0},
          },
        },
        {
          'name': 'MAVC',
          'code': 'CS201',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26.0, 'outOf': 30.0},
            'Viva': {'marks': 20.0, 'outOf': 25.0},
            'Assignment': {'marks': 21.0, 'outOf': 25.0},
            'CSE': {'marks': 17.0, 'outOf': 20.0},
            'ESE': {'marks': 42.0, 'outOf': 50.0},
          },
        },
      ]
    },
    {
      'name': 'Semester 3',
      'subjects': [
        {
          'name': 'Data Structure',
          'code': 'CS301',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28.0, 'outOf': 30.0},
            'Viva': {'marks': 22.0, 'outOf': 25.0},
            'Assignment': {'marks': 23.0, 'outOf': 25.0},
            'CSE': {'marks': 18.0, 'outOf': 20.0},
            'ESE': {'marks': 45.0, 'outOf': 50.0},
          },
        },
        {
          'name': 'DMGT',
          'code': 'CS302',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 28.0, 'outOf': 30.0},
            'Viva': {'marks': 22.0, 'outOf': 25.0},
            'Assignment': {'marks': 23.0, 'outOf': 25.0},
            'CSE': {'marks': 18.0, 'outOf': 20.0},
            'ESE': {'marks': 45.0, 'outOf': 50.0},
          },
        },
        {
          'name': 'Iwt',
          'code': 'CS303',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26.0, 'outOf': 30.0},
            'Viva': {'marks': 20.0, 'outOf': 25.0},
            'Assignment': {'marks': 21.0, 'outOf': 25.0},
            'CSE': {'marks': 17.0, 'outOf': 20.0},
            'ESE': {'marks': 42.0, 'outOf': 50.0},
          },
        },
      ]
    },
  ];

  // Method to fetch student data using new performance API for all semesters
  Future<void> _fetchStudentDataNew() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Get user from provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null || user.enrollmentNumber.isEmpty) {
        throw Exception('User enrollment number not found');
      }
      
      print('Attempting to fetch performance data for enrollment: ${user.enrollmentNumber}');
      
      // First, get basic student data to know how many semesters exist
      await _fetchStudentDataOld();
      
      if (_studentData != null && _studentData!.semesters.isNotEmpty) {
        // Fetch performance data for all available semesters
        _allSemesterData.clear();
        
        for (final semesterData in _studentData!.semesters) {
          try {
            final result = await _analysisService.getSubjectWisePerformance(
              user.enrollmentNumber, 
              semesterData.semesterNumber
            );
            
            _allSemesterData[semesterData.semesterNumber] = StudentPerformanceModel.fromJson(result);
            print('Fetched data for semester ${semesterData.semesterNumber}');
          } catch (e) {
            print('Error fetching semester ${semesterData.semesterNumber}: $e');
            // Continue with other semesters even if one fails
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchStudentDataNew: $e');
      // Fallback to old API if new API fails
      await _fetchStudentDataOld();
    }
  }
  
  // Method to fetch student component marks and subjects data (old API)
  Future<void> _fetchStudentDataOld() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Get user from provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null || user.email == null) {
        throw Exception('User email not found');
      }
      
      print('Attempting to fetch data for email: ${user.email}');
      
      // Fetch component marks and subjects
      final result = await _studentService.getStudentComponentMarksAndSubjects(user.email!);
      
      print('Old API response received: success');
      
      setState(() {
        _studentData = StudentComponentData.fromJson(result);
        _isLoading = false;
        
        // Set initial selected semester
        if (_studentData!.semesters.isNotEmpty) {
          _selectedSemester = _studentData!.semesters.first.semesterNumber;
        }
      });
    } catch (e) {
      print('Error in _fetchStudentDataOld: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Main fetch method that decides which API to use
  Future<void> _fetchStudentData() async {
    if (_useNewApi) {
      await _fetchStudentDataNew();
    } else {
      await _fetchStudentDataOld();
    }
  }
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _semesterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    
    // Fetch student data when screen initializes
    _fetchStudentData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _semesterController.dispose();
    _pageController.dispose();
    _semesterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // keep-alive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Gradient background (matched with parent screen)
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
            child: Column(
              children: [
                // Modern header with semester navigation
                _buildModernHeader(isDark),
                // Subject content
                Expanded(
                  child: _buildSubjectContent(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // Modern header with semester navigation
  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              'My Subjects',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Semester navigation with arrows
          if (_studentData != null && _studentData!.semesters.isNotEmpty)
            _buildSemesterNavigation(isDark),
        ],
      ),
    );
  }

  // Semester navigation with slideable buttons and arrows
  Widget _buildSemesterNavigation(bool isDark) {
    final semesters = _studentData!.semesters;
    
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Left arrow
          _buildNavigationArrow(
            icon: Icons.chevron_left,
            onTap: _selectedSemester > 1 ? () => _changeSemester(_selectedSemester - 1) : null,
          ),
          // Semester buttons
          Expanded(
            child: Container(
              height: 52,
              child: ListView.builder(
                controller: _semesterScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: semesters.length,
                itemBuilder: (context, index) {
                  final semester = semesters[index].semesterNumber;
                  return _buildSemesterButton(semester, isDark);
                },
              ),
            ),
          ),
          // Right arrow
          _buildNavigationArrow(
            icon: Icons.chevron_right,
            onTap: _selectedSemester < semesters.length ? () => _changeSemester(_selectedSemester + 1) : null,
          ),
        ],
      ),
    );
  }

  // Navigation arrow button
  Widget _buildNavigationArrow({required IconData icon, VoidCallback? onTap}) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Icon(
            icon,
            color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  // Individual semester button
  Widget _buildSemesterButton(int semester, bool isDark) {
    final isSelected = _selectedSemester == semester;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _changeSemester(semester),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF03A9F4), Color(0xFF0288D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected 
                    ? Colors.white.withOpacity(0.0)
                    : Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF03A9F4).withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 3),
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                'Sem $semester',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.95),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Change semester with animation
  void _changeSemester(int semester) {
    if (_selectedSemester != semester) {
      setState(() {
        _selectedSemester = semester;
      });
      
      // Animate page change
      _pageController.animateToPage(
        semester - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Auto-scroll semester buttons to center
      _scrollToSelectedSemester();
    }
  }

  // Auto-scroll to center selected semester
  void _scrollToSelectedSemester() {
    if (_studentData != null) {
      final index = _selectedSemester - 1;
      final itemWidth = 100.0; // Approximate width of each button
      final screenWidth = MediaQuery.of(context).size.width;
      final scrollOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      _semesterScrollController.animateTo(
        scrollOffset.clamp(0.0, _semesterScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Subject content with PageView
  Widget _buildSubjectContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }
    
    if (_error != null) {
      return _buildErrorMessage();
    }
    
    if (_studentData == null || _studentData!.semesters.isEmpty) {
      return _buildNoDataMessage();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedSemester = index + 1;
            });
          },
          itemCount: _studentData!.semesters.length,
          itemBuilder: (context, index) {
            final semesterData = _studentData!.semesters[index];
            final performanceData = _allSemesterData[semesterData.semesterNumber];
            
            return _buildSemesterSubjects(semesterData, performanceData, isDark);
          },
        ),
      ),
    );
  }

  // Build subjects for a semester
  Widget _buildSemesterSubjects(SemesterData semesterData, StudentPerformanceModel? performanceData, bool isDark) {
    final subjects = performanceData?.subjects ?? [];
    final fallbackSubjects = semesterData.subjects;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: subjects.isNotEmpty ? subjects.length : fallbackSubjects.length,
        itemBuilder: (context, index) {
          if (subjects.isNotEmpty) {
            return _buildModernSubjectCard(subjects[index], isDark, index);
          } else {
            return _buildFallbackSubjectCard(fallbackSubjects[index], isDark, index);
          }
        },
      ),
    );
  }

  // Modern subject card with animations
  Widget _buildModernSubjectCard(SubjectPerformance subject, bool isDark, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      )),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 16),
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        onTap: () => _navigateToSubjectDetail(subject),
        child: Row(
                    children: [
                      // Grade circle
                      _buildGradeCircle(subject.grade, isDark),
                      const SizedBox(width: 16),
                      // Subject info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.subject,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subject.code,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress bar
                            _buildProgressBar(subject.percentage, isDark),
                          ],
                        ),
                      ),
                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                    ],
                  ),
      ),
      );
  }

  // Grade circle widget
  Widget _buildGradeCircle(String grade, bool isDark) {
    Color gradeColor = _getGradeColor(grade);
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [gradeColor, gradeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withOpacity(0.18),
            blurRadius: 6,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          grade,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Progress bar widget
  Widget _buildProgressBar(double percentage, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getGradeColor(_getGradeFromPercentage(percentage)), _getGradeColor(_getGradeFromPercentage(percentage)).withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Get grade color
  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+': case 'O': return const Color(0xFF4CAF50);
      case 'A': return const Color(0xFF8BC34A);
      case 'B+': return const Color(0xFFCDDC39);
      case 'B': return const Color(0xFFFFEB3B);
      case 'C+': return const Color(0xFFFF9800);
      case 'C': return const Color(0xFFFF5722);
      case 'D': return const Color(0xFFE91E63);
      case 'F': case 'FF': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  // Get grade from percentage
  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    return 'F';
  }

  // Navigate to subject detail
  void _navigateToSubjectDetail(SubjectPerformance subject) {
    final Map<String, dynamic> components = {};
    subject.components.forEach((componentType, componentData) {
      components[componentType.toUpperCase()] = {
        'marks': componentData.marksObtained,
        'outOf': componentData.totalMarks
      };
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailScreen(
          subject: Subject(
            name: subject.subject,
            code: subject.code,
            status: subject.grade == 'F' ? 'Failed' : 'Passed',
            grade: subject.grade,
            components: components,
          ),
        ),
      ),
    );
  }

  // Fallback subject card
  Widget _buildFallbackSubjectCard(SubjectData subject, bool isDark, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      )),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 16),
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        onTap: () => _navigateToFallbackSubjectDetail(subject),
        child: Row(
                    children: [
                      // Grade circle
                      _buildGradeCircle(subject.grades ?? 'NA', isDark),
                      const SizedBox(width: 16),
                      // Subject info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.subjectName,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subject.subjectCode ?? 'N/A',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
  }

  // Navigate to fallback subject detail
  void _navigateToFallbackSubjectDetail(SubjectData subject) {
    final Map<String, dynamic> components = {};
    if (subject.componentMarks != null) {
      final marks = subject.componentMarks!;
      if (marks.ese != null) components['ESE'] = {'marks': marks.ese!, 'outOf': 50.0};
      if (marks.ia != null) components['IA'] = {'marks': marks.ia!, 'outOf': 25.0};
      if (marks.tw != null) components['TW'] = {'marks': marks.tw!, 'outOf': 25.0};
      if (marks.viva != null) components['VIVA'] = {'marks': marks.viva!, 'outOf': 25.0};
      if (marks.cse != null) components['CSE'] = {'marks': marks.cse!, 'outOf': 20.0};
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailScreen(
          subject: Subject(
            name: subject.subjectName,
            code: subject.subjectCode ?? 'N/A',
            status: subject.grades == 'F' ? 'Failed' : 'Passed',
            grade: subject.grades ?? 'NA',
            components: components,
          ),
        ),
      ),
    );
  }

  // Widget for loading state
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF667eea)),
          const SizedBox(height: 16),
          Text(
            'Loading your subjects...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  // Widget for error state
  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading subjects',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStudentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Widget for no data state
  Widget _buildNoDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 60,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects found',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no subjects available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Build subject card from performance API data (legacy method - keeping for compatibility)
  Widget _buildPerformanceSubjectCard(SubjectPerformance subject, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine grade color
    Color gradeColor = Colors.grey;
    final grade = subject.grade;

    if (grade == 'A+' || grade == 'A' || grade == 'O') {
      gradeColor = Colors.green;
    } else if (grade == 'B+' || grade == 'B') {
      gradeColor = Colors.lightGreen;
    } else if (grade == 'C+' || grade == 'C') {
      gradeColor = Colors.amber;
    } else if (grade == 'D') {
      gradeColor = Colors.orange;
    } else if (grade == 'F' || grade == 'FF') {
      gradeColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Convert performance data to format expected by SubjectDetailScreen
          final Map<String, dynamic> components = {};
          subject.components.forEach((componentType, componentData) {
            components[componentType.toUpperCase()] = {
              'marks': componentData.marksObtained,
              'outOf': componentData.totalMarks
            };
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(
                subject: Subject(
                  name: subject.subject,
                  code: subject.code,
                  status: grade == 'F' ? 'Failed' : 'Passed',
                  grade: grade,
                  components: components,
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Grade circle
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gradeColor.withOpacity(0.2),
                            border: Border.all(
                              color: gradeColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              grade,
                              style: TextStyle(
                                color: gradeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Subject details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.subject,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subject.code,
                                style: TextStyle(
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.7) 
                                      : Colors.black.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${subject.percentage.toStringAsFixed(1)}% (${subject.totalMarksObtained.toStringAsFixed(0)}/${subject.totalMarksPossible.toStringAsFixed(0)})',
                                style: TextStyle(
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.6) 
                                      : Colors.black.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.black.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: isDark ? Colors.white : Colors.black,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // (Removed duplicate _buildErrorMessage and _buildNoDataMessage definitions here)

  // Build subject card from API data
  Widget _buildSubjectCardFromApiData(SubjectData subject, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine if the subject has marks
    final hasMarks = subject.componentMarks != null;
    final hasWeightage = subject.componentWeightage != null;
    
    // Default grade
    String grade = 'NA';
    Color gradeColor = Colors.grey;
    
    // Use grades from API if available
    if (subject.grades != null && subject.grades!.isNotEmpty) {
      grade = subject.grades!;
      
      // Assign color based on grade
      if (grade == 'A+' || grade == 'A' || grade == 'O') {
        gradeColor = Colors.green;
      } else if (grade == 'B+' || grade == 'B') {
        gradeColor = Colors.lightGreen;
      } else if (grade == 'C+' || grade == 'C') {
        gradeColor = Colors.amber;
      } else if (grade == 'D') {
        gradeColor = Colors.orange;
      } else if (grade == 'F' || grade == 'FF') {
        gradeColor = Colors.red;
      } else {
        gradeColor = Colors.grey;
      }
    }
    // If no grades from API, calculate grade if we have marks and weightage
    else if (hasMarks && hasWeightage) {
      try {
        // This is a simplified grade calculation with safer null handling
        double totalMarks = 0;
        double totalOutOf = 0;
        
        final marks = subject.componentMarks!;
        final weightage = subject.componentWeightage!;
        
        // Safely add each component, handling null values
        if (marks.ese != null && weightage.ese != null && weightage.ese! > 0) {
          totalMarks += marks.ese!;
          totalOutOf += weightage.ese!;
        }
        if (marks.cse != null && weightage.cse != null && weightage.cse! > 0) {
          totalMarks += marks.cse!;
          totalOutOf += weightage.cse!;
        }
        if (marks.ia != null && weightage.ia != null && weightage.ia! > 0) {
          totalMarks += marks.ia!;
          totalOutOf += weightage.ia!;
        }
        if (marks.tw != null && weightage.tw != null && weightage.tw! > 0) {
          totalMarks += marks.tw!;
          totalOutOf += weightage.tw!;
        }
        if (marks.viva != null && weightage.viva != null && weightage.viva! > 0) {
          totalMarks += marks.viva!;
          totalOutOf += weightage.viva!;
        }
        
        // Prevent division by zero
        if (totalOutOf > 0) {
          final percentage = (totalMarks / totalOutOf) * 100;
          // Guard against NaN
          if (percentage.isNaN) {
            grade = 'NA';
            gradeColor = Colors.grey;
          } else {
            // Assign grade based on percentage
            if (percentage >= 90) {
              grade = 'A+';  
              gradeColor = Colors.green;
            } else if (percentage >= 80) {
              grade = 'A';
              gradeColor = Colors.lightGreen;
            } else if (percentage >= 70) {
              grade = 'B+'; 
              gradeColor = Colors.amber;
            } else if (percentage >= 60) {
              grade = 'B'; 
              gradeColor = Colors.orange;
            } else if (percentage >= 50) {
              grade = 'C'; 
              gradeColor = Colors.deepOrange;
            } else {
              grade = 'F'; 
              gradeColor = Colors.red;
            }
          }
        } else {
          // Handle case where totalOutOf is 0
          grade = 'NA';
          gradeColor = Colors.grey;
        }
      } catch (e) {
        // Handle any errors in grade calculation
        print('Error calculating grade: $e');
        grade = 'NA';
        gradeColor = Colors.grey;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Map component marks to the format expected by SubjectDetailScreen
          final Map<String, dynamic> components = {};
          if (hasMarks && hasWeightage) {
            final marks = subject.componentMarks!;
            final weightage = subject.componentWeightage!;
            
            if (marks.ese != null && weightage.ese != null) {
              components['ESE'] = {'marks': marks.ese!, 'outOf': weightage.ese!};
            }
            if (marks.cse != null && weightage.cse != null) {
              components['CSE'] = {'marks': marks.cse!, 'outOf': weightage.cse!};
            }
            if (marks.ia != null && weightage.ia != null) {
              components['IA'] = {'marks': marks.ia!, 'outOf': weightage.ia!};
            }
            if (marks.tw != null && weightage.tw != null) {
              components['TW'] = {'marks': marks.tw!, 'outOf': weightage.tw!};
            }
            if (marks.viva != null && weightage.viva != null) {
              components['Viva'] = {'marks': marks.viva!, 'outOf': weightage.viva!};
            }
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(
                subject: Subject(
                  name: subject.subjectName,
                  code: subject.subjectCode ?? 'NA',
                  status: grade == 'F' ? 'Failed' : 'Passed',
                  grade: grade,
                  components: components,
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Grade circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withOpacity(0.2),
                        border: Border.all(
                          color: gradeColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Subject details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.subjectName,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject.subjectCode ?? 'No Code',
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.black.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Show percentage if available
                          if (hasMarks && hasWeightage) ...[
                            _buildPercentageDisplay(subject, isDark),
                          ] else ...[
                            Text(
                              'No marks data available',
                              style: TextStyle(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.5) 
                                    : Colors.black.withOpacity(0.5),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Arrow icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white : Colors.black,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, BuildContext context) {
    final String grade = subject['grade'] as String;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color gradeColor;
    
    // Determine grade color
    if (grade == 'A+') {
      gradeColor = Colors.green;
    } else if (grade == 'A') {
      gradeColor = Colors.lightGreen;
    } else if (grade == 'B+') {
      gradeColor = Colors.amber;
    } else {
      gradeColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(
                subject: Subject(
                  name: subject['name'],
                  code: subject['code'],
                  status: subject['grade'] == 'A' || subject['grade'] == 'A+' || subject['grade'] == 'B+' ? 'Passed' : 'Failed',
                  grade: subject['grade'],
                  components: subject['components'],
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Grade circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withOpacity(0.2),
                        border: Border.all(
                          color: gradeColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Subject details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['name'],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject['code'],
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.black.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white : Colors.black,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build percentage display for subject card
  Widget _buildPercentageDisplay(SubjectData subject, bool isDark) {
    final marks = subject.componentMarks!;
    final weightage = subject.componentWeightage!;
    
    // Calculate total marks and percentage
    double totalMarks = 0;
    double totalOutOf = 0;
    
    if (marks.ese != null && weightage.ese != null) {
      totalMarks += marks.ese!;
      totalOutOf += weightage.ese!;
    }
    if (marks.cse != null && weightage.cse != null) {
      totalMarks += marks.cse!;
      totalOutOf += weightage.cse!;
    }
    if (marks.ia != null && weightage.ia != null) {
      totalMarks += marks.ia!;
      totalOutOf += weightage.ia!;
    }
    if (marks.tw != null && weightage.tw != null) {
      totalMarks += marks.tw!;
      totalOutOf += weightage.tw!;
    }
    if (marks.viva != null && weightage.viva != null) {
      totalMarks += marks.viva!;
      totalOutOf += weightage.viva!;
    }
    
    final percentage = totalOutOf > 0 ? (totalMarks / totalOutOf) * 100 : 0;
    
    return Text(
      '${percentage.toStringAsFixed(1)}% (${totalMarks.toStringAsFixed(0)}/${totalOutOf.toStringAsFixed(0)})',
      style: TextStyle(
        color: isDark 
            ? Colors.white.withOpacity(0.6) 
            : Colors.black.withOpacity(0.6),
        fontSize: 12,
      ),
    );
  }

  // Build component marks row similar to React component
  Widget _buildComponentMarksRow(SubjectData subject, bool isDark) {
    final marks = subject.componentMarks!;
    final weightage = subject.componentWeightage!;
    
    final components = <Map<String, dynamic>>[];
    
    // Add components that have both marks and weightage
    if (marks.ese != null && weightage.ese != null) {
      components.add({
        'name': 'ESE',
        'marks': marks.ese!,
        'outOf': weightage.ese!,
        'color': Colors.blue,
      });
    }
    if (marks.ia != null && weightage.ia != null) {
      components.add({
        'name': 'IA',
        'marks': marks.ia!,
        'outOf': weightage.ia!,
        'color': Colors.green,
      });
    }
    if (marks.tw != null && weightage.tw != null) {
      components.add({
        'name': 'TW',
        'marks': marks.tw!,
        'outOf': weightage.tw!,
        'color': Colors.orange,
      });
    }
    if (marks.viva != null && weightage.viva != null) {
      components.add({
        'name': 'Viva',
        'marks': marks.viva!,
        'outOf': weightage.viva!,
        'color': Colors.purple,
      });
    }
    if (marks.cse != null && weightage.cse != null) {
      components.add({
        'name': 'CSE',
        'marks': marks.cse!,
        'outOf': weightage.cse!,
        'color': Colors.red,
      });
    }
    
    if (components.isEmpty) {
      return Text(
        'No component data available',
        style: TextStyle(
          color: isDark 
              ? Colors.white.withOpacity(0.5) 
              : Colors.black.withOpacity(0.5),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Component Marks:',
          style: TextStyle(
            color: isDark 
                ? Colors.white.withOpacity(0.8) 
                : Colors.black.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: components.map((component) {
            final percentage = (component['marks'] / component['outOf'] * 100).round();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: component['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: component['color'].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${component['name']}: ${component['marks']}/${component['outOf']} ($percentage%)',
                style: TextStyle(
                  color: component['color'],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
