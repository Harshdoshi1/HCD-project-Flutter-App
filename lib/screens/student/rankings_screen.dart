import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import '../../services/student_service.dart';
import '../../models/student_ranking_model.dart';
import 'student_detail_screen.dart';
import '../../widgets/glass_card.dart';
// Removed: student_activities_screen.dart and student_grades_screen.dart since we now open profile directly

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key, required this.toggleTheme});
  
  final VoidCallback toggleTheme;

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Helper method to convert number to ordinal
  String _getOrdinalNumber(int number) {
    if (number <= 0) return '${number}th';
    
    final lastDigit = number % 10;
    final lastTwoDigits = number % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 13) {
      return '${number}th';
    }
    
    switch (lastDigit) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
  
  // Student data
  final StudentService _studentService = StudentService();
  List<StudentRanking> _students = [];
  bool _isLoading = true;
  String? _error;
  
  // Filtered lists for different tabs
  List<StudentRanking> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    return _students.where((student) =>
      student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      student.enrollmentNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }
  
  // Get students sorted by hardware + software points
  List<StudentRanking> get _studentsByPoints {
    final List<StudentRanking> sortedList = List.from(_filteredStudents);
    sortedList.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return sortedList;
  }
  
  // Get students sorted by CPI
  List<StudentRanking> get _studentsByCPI {
    final List<StudentRanking> sortedList = List.from(_filteredStudents);
    sortedList.sort((a, b) {
      // Handle null CPI values
      if (a.cpi == null && b.cpi == null) return 0;
      if (a.cpi == null) return 1;
      if (b.cpi == null) return -1;
      return b.cpi!.compareTo(a.cpi!);
    });
    return sortedList;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Initialize glow animation controller
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    
    // Start glow animation with 1 second delay and repeat infinitely
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _glowController.repeat(reverse: true);
      }
    });
    
    // Fetch all students data
    _fetchStudents();
    
    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  // Fetch all students from backend
  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fetch students basic data (academic & points)
      final studentsList = await _studentService.getAllStudents();
      
      // Convert raw data to StudentRanking objects
      final List<StudentRanking> students = [];
      for (var student in studentsList) {
        students.add(StudentRanking.fromJson(student));
      }
      
      // Fetch current semester points (extracurricular & co-curricular)
      final pointsList = await _studentService.getAllStudentsCurrentSemesterPoints();
      
      // If we successfully got points data, merge it with students
      if (pointsList.isNotEmpty) {
        // Create a map for quick lookup by enrollment number
        final pointsMap = <String, Map<String, dynamic>>{};
        for (var point in pointsList) {
          final enrollmentNumber = point['enrollmentNumber'];
          if (enrollmentNumber != null) {
            pointsMap[enrollmentNumber] = point;
          }
        }
        
        // Update each student with their points
        for (int i = 0; i < students.length; i++) {
          final student = students[i];
          final points = pointsMap[student.enrollmentNumber];
          
          if (points != null) {
            // Create a new student object with updated points
            students[i] = StudentRanking(
              id: student.id,
              name: student.name,
              email: student.email,
              enrollmentNumber: student.enrollmentNumber,
              hardwarePoints: student.hardwarePoints,
              softwarePoints: student.softwarePoints,
              cocurricularPoints: points['totalCocurricular'] ?? 0,
              extracurricularPoints: points['totalExtracurricular'] ?? 0,
              cpi: student.cpi,
              spi: student.spi,
              rank: student.rank,
              batch: student.batch,
              currentSemester: student.currentSemester,
            );
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
      
      print('Fetched ${_students.length} students');
    } catch (e) {
      print('Error fetching students: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _searchController.dispose();
    super.dispose();
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
          'Rankings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
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
            child: Column(
              children: [
                // Enhanced Tab bar with premium glass morphism design
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark 
                            ? Colors.white.withOpacity(0.12) 
                            : Colors.white.withOpacity(0.9),
                        isDark 
                            ? Colors.white.withOpacity(0.05) 
                            : Colors.white.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF03A9F4).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.3)
                            : const Color(0xFF03A9F4).withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.8),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF03A9F4).withOpacity(0.8),
                              const Color(0xFF0288D1).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF03A9F4).withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, -2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        indicatorPadding: const EdgeInsets.all(6),
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark 
                            ? Colors.white.withOpacity(0.7) 
                            : Colors.black.withOpacity(0.7),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                        tabs: [
                          Tab(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.school_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Academic'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.emoji_events_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Activities'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Enhanced Search bar with premium design
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark 
                            ? Colors.white.withOpacity(0.08) 
                            : Colors.white.withOpacity(0.9),
                        isDark 
                            ? Colors.white.withOpacity(0.03) 
                            : Colors.white.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.15) 
                          : const Color(0xFF03A9F4).withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.2)
                            : const Color(0xFF03A9F4).withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: isDark 
                            ? Colors.white.withOpacity(0.03)
                            : Colors.white.withOpacity(0.6),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or enrollment...',
                          hintStyle: TextStyle(
                            color: isDark 
                                ? Colors.white.withOpacity(0.6) 
                                : Colors.black.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: isDark 
                                  ? Colors.white.withOpacity(0.7) 
                                  : const Color(0xFF03A9F4),
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: isDark 
                                          ? Colors.white.withOpacity(0.8) 
                                          : Colors.black.withOpacity(0.6),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      _tabController.animateTo(index);
                    },
                    children: [
                      _buildRankingList(true),
                      _buildRankingList(false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(bool isAcademic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get the appropriate student list based on ranking type
    final students = isAcademic ? _studentsByCPI : _studentsByPoints;
    
    // Show loading indicator while data is being fetched
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF03A9F4)),
            const SizedBox(height: 16),
            Text(
              'Loading students...',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    // Show error message if there was an error fetching data
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading students',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Handle empty results
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                ? 'No students found'
                : 'No students match "$_searchQuery"',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final rank = index + 1;
          final name = student.name;
          final subtitle = isAcademic
              ? 'CPI: ${student.cpi?.toStringAsFixed(2) ?? 'N/A'} | SPI: ${student.spi?.toStringAsFixed(2) ?? 'N/A'} | Sem: ${student.currentSemester > 0 ? _getOrdinalNumber(student.currentSemester) : 'N/A'}'
              : 'CC: ${student.cocurricularPoints} | EC: ${student.extracurricularPoints} | HW: ${student.hardwarePoints} | SW: ${student.softwarePoints} | Total: ${student.totalPoints + student.totalActivityPoints}';
                
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildStudentCard(rank, name, subtitle, isDark, student),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(int rank, String name, String subtitle, bool isDark, StudentRanking student) {
    final isAcademic = _tabController.index == 0;
    
    return GestureDetector(
      onTap: () {
        // Open profile page for both tabs
        final details = isAcademic
            ? 'CPI: ${student.cpi?.toStringAsFixed(2) ?? 'N/A'} | SPI: ${student.spi?.toStringAsFixed(2) ?? 'N/A'} | Sem: ${student.currentSemester > 0 ? student.currentSemester : 'N/A'}'
            : 'CC: ${student.cocurricularPoints} | EC: ${student.extracurricularPoints} | HW: ${student.hardwarePoints} | SW: ${student.softwarePoints} | Total: ${student.totalPoints + student.totalActivityPoints}';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(
              studentName: student.name,
              studentEmail: student.email,
              studentEnrollment: student.enrollmentNumber,
              studentDetails: details,
              toggleTheme: widget.toggleTheme,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Row(
                  children: [
                    // Enhanced Rank circle with gradient and glow animation for top 3
                    rank <= 3 
                        ? AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      _getRankColor(rank).withOpacity(0.3),
                                      _getRankColor(rank).withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: _getRankColor(rank),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRankColor(rank).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                    // Animated glow effect
                                    BoxShadow(
                                      color: _getRankColor(rank).withOpacity(_glowAnimation.value * 0.6),
                                      blurRadius: _glowAnimation.value * 20,
                                      spreadRadius: _glowAnimation.value * 4,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      color: _getRankColor(rank),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _getRankColor(rank).withOpacity(0.3),
                                  _getRankColor(rank).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: _getRankColor(rank),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRankColor(rank).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  color: _getRankColor(rank),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(width: 18),
                    // Student details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.75) 
                                  : Colors.black.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Enhanced Arrow icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            isDark 
                                ? Colors.white.withOpacity(0.15) 
                                : const Color(0xFF03A9F4).withOpacity(0.1),
                            isDark 
                                ? Colors.white.withOpacity(0.05) 
                                : const Color(0xFF03A9F4).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.2) 
                              : const Color(0xFF03A9F4).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark 
                            ? Colors.white.withOpacity(0.8) 
                            : const Color(0xFF03A9F4),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            
          ),
        );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) {
      return Colors.amber;
    } else if (rank == 2) {
      return Colors.grey.shade400;
    } else if (rank == 3) {
      return Colors.brown.shade300;
    } else {
      return const Color(0xFF03A9F4);
    }
  }
}
