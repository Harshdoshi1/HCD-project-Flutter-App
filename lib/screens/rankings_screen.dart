import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import '../services/student_service.dart';
import '../models/student_ranking_model.dart';
import 'student_detail_screen.dart';
import 'student_activities_screen.dart';
import 'student_grades_screen.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key, required this.toggleTheme}) : super(key: key);
  
  final VoidCallback toggleTheme;

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
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

    _fadeController.forward();
    
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
      
      setState(() {
        _students = students;
        _isLoading = false;
      });
      
      print('Fetched ${_students.length} students');
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
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
        title: const Text(
          'Rankings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
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
                // Tab bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.black.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF03A9F4).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        dividerColor: Colors.transparent,
                        labelColor: isDark ? Colors.white : Colors.black,
                        unselectedLabelColor: isDark 
                            ? Colors.white.withOpacity(0.6) 
                            : Colors.black.withOpacity(0.6),
                        tabs: const [
                          Tab(text: 'Academic'),
                          Tab(text: 'Non-Academic'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Search bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: TextStyle(
                            color: isDark 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.black.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.black.withOpacity(0.5),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.5) 
                                        : Colors.black.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      return Center(child: CircularProgressIndicator());
    }
    
    // Show error message if there was an error fetching data
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error loading students',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStudents,
              child: Text('Retry'),
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
            SizedBox(height: 16),
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
              ? 'CPI: ${student.cpi?.toStringAsFixed(2) ?? 'N/A'} | SPI: ${student.spi?.toStringAsFixed(2) ?? 'N/A'} | Sem: ${student.currentSemester}'
              : 'Total CC: ${student.cocurricularPoints} | Total EC: ${student.extracurricularPoints} | HW: ${student.hardwarePoints} | SW: ${student.softwarePoints} | Total: ${student.totalPoints + student.totalActivityPoints}';
                
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
        if (isAcademic) {
          // Academic section: navigate to student grades screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentGradesScreen(student: student),
            ),
          );
        } else {
          // Non-academic section: navigate to student activities
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentActivitiesScreen(student: student),
            ),
          );
        }
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
                  // Rank circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getRankColor(rank).withOpacity(0.2),
                      border: Border.all(
                        color: _getRankColor(rank),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: _getRankColor(rank),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Student details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark 
                                ? Colors.white.withOpacity(0.7) 
                                : Colors.black.withOpacity(0.7),
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
            ),
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
