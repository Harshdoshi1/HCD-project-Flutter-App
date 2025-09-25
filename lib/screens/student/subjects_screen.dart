
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

class SubjectsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const SubjectsScreen({super.key, required this.toggleTheme});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> with SingleTickerProviderStateMixin {
  int _selectedSemester = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // New state variables for API data
  final StudentService _studentService = StudentService();
  final StudentAnalysisService _analysisService = StudentAnalysisService();
  StudentComponentData? _studentData;
  StudentPerformanceModel? _performanceData;
  bool _isLoading = true;
  bool _useNewApi = true; // Flag to switch between old and new API
  String? _error;

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

  // Method to fetch student data using new performance API
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
      
      // Fetch performance data for current semester
      final result = await _analysisService.getSubjectWisePerformance(
        user.enrollmentNumber, 
        _selectedSemester
      );
      
      print('Performance API response received: ${result.toString()}');
      
      setState(() {
        _performanceData = StudentPerformanceModel.fromJson(result);
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
        
        // Set the selected semester to 1 if there are semesters available
        if (_studentData != null && _studentData!.semesters.isNotEmpty) {
          _selectedSemester = 1;
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    
    // Fetch student data when screen initializes
    _fetchStudentData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'My Subjects',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SlideTransition(
                              position: _slideAnimation,
                              child: SizedBox(
                                height: 36, // Reduced height for the semester pills
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _isLoading || _studentData == null || _performanceData == null
                                    ? List.generate(1, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: _buildSemesterChip(1),
                                        );
                                      })
                                    : _performanceData != null
                                    ? List.generate(_performanceData!.student.currentSemester, (index) {
                                        final semester = index + 1;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: _buildSemesterChip(semester),
                                        );
                                      })
                                    : _studentData != null
                                    ? List.generate(_studentData!.semesters.length, (index) {
                                        final semester = _studentData!.semesters[index].semesterNumber;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: _buildSemesterChip(semester),
                                        );
                                      })
                                    : [],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Subject list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _isLoading 
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                _buildLoadingIndicator(),
                              ],
                            )
                          : _error != null
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    _buildErrorMessage(),
                                  ],
                                )
                              : _performanceData != null
                                  ? _buildPerformanceSubjectsList()
                                  : (_studentData == null || _studentData!.semesters.isEmpty)
                                      ? ListView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            _buildNoDataMessage(),
                                          ],
                                        )
                                      : ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _selectedSemester <= _studentData!.semesters.length
                                              ? _getSubjectsForSelectedSemester().length
                                              : 0,
                                          itemBuilder: (context, index) {
                                            if (_selectedSemester > _studentData!.semesters.length) return const SizedBox();
                                            final subject = _getSubjectsForSelectedSemester()[index];
                                            return _buildSubjectCardFromApiData(subject, context);
                                          },
                                        ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterChip(int semester) {
    final isSelected = _selectedSemester == semester;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSemester = semester;
        });
        // Refetch data for the new semester if using new API
        if (_useNewApi) {
          _fetchStudentDataNew();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5))
                : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
            width: 1,
          ),
        ),
        child: Text(
          'Sem $semester',
          style: TextStyle(
            color: isSelected 
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Helper method to get subjects for the selected semester
  List<SubjectData> _getSubjectsForSelectedSemester() {
    if (_studentData == null) return [];
    
    // Find the semester that matches the selected semester number
    final selectedSemesterData = _studentData!.semesters.firstWhere(
      (sem) => sem.semesterNumber == _selectedSemester,
      orElse: () => _studentData!.semesters.isNotEmpty ? _studentData!.semesters.first : SemesterData(
        semesterId: 0,
        semesterNumber: 0,
        startDate: '',
        endDate: '',
        subjects: [],
      ),
    );
    
    return selectedSemesterData.subjects;
  }
  
  // Widget for loading state
  Widget _buildLoadingIndicator() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF03A9F4)),
                const SizedBox(height: 16),
                Text(
                  'Loading your subjects...',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget for error state
  Widget _buildErrorMessage() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load subjects',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchStudentData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03A9F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Widget for performance subjects list (new API)
  Widget _buildPerformanceSubjectsList() {
    if (_performanceData == null || _performanceData!.subjects.isEmpty) {
      return _buildNoDataMessage();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _performanceData!.subjects.length,
      itemBuilder: (context, index) {
        final subject = _performanceData!.subjects[index];
        return _buildPerformanceSubjectCard(subject, context);
      },
    );
  }
  
  // Build subject card from performance API data
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
  
  // Widget for no data state
  Widget _buildNoDataMessage() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
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
                'There are no subjects available for this semester',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
