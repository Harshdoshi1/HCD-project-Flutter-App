
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import '../models/subject.dart';
import '../models/student_component_data.dart';
import '../services/student_service.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const SubjectsScreen({Key? key, required this.toggleTheme}) : super(key: key);

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
  StudentComponentData? _studentData;
  bool _isLoading = true;
  String? _error;

  static const List<Map<String, dynamic>> semesters = [
    {
      'name': 'Semester 1',
      'subjects': [
        {
          'name': 'ICE',
          'code': 'MA101',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28, 'outOf': 30},
            'Viva': {'marks': 22, 'outOf': 25},
            'Assignment': {'marks': 23, 'outOf': 25},
            'CSE': {'marks': 18, 'outOf': 20},
            'ESE': {'marks': 45, 'outOf': 50},
          },
        },
        {
          'name': 'FSSI',
          'code': 'PH101',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 29, 'outOf': 30},
            'Viva': {'marks': 24, 'outOf': 25},
            'Assignment': {'marks': 24, 'outOf': 25},
            'CSE': {'marks': 19, 'outOf': 20},
            'ESE': {'marks': 48, 'outOf': 50},
          },
        },
        {
          'name': 'AC',
          'code': 'CH101',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26, 'outOf': 30},
            'Viva': {'marks': 20, 'outOf': 25},
            'Assignment': {'marks': 21, 'outOf': 25},
            'CSE': {'marks': 17, 'outOf': 20},
            'ESE': {'marks': 42, 'outOf': 50},
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
            'IA': {'marks': 28, 'outOf': 30},
            'Viva': {'marks': 22, 'outOf': 25},
            'Assignment': {'marks': 23, 'outOf': 25},
            'CSE': {'marks': 18, 'outOf': 20},
            'ESE': {'marks': 45, 'outOf': 50},
          },
        },
        {
          'name': 'DLD',
          'code': 'EC201',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 9, 'outOf': 30},
            'Viva': {'marks': 24, 'outOf': 25},
            'Assignment': {'marks': 24, 'outOf': 25},
            'CSE': {'marks': 19, 'outOf': 20},
            'ESE': {'marks': 48, 'outOf': 50},
          },
        },
        {
          'name': 'MAVC',
          'code': 'CS201',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26, 'outOf': 30},
            'Viva': {'marks': 20, 'outOf': 25},
            'Assignment': {'marks': 21, 'outOf': 25},
            'CSE': {'marks': 17, 'outOf': 20},
            'ESE': {'marks': 42, 'outOf': 50},
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
            'IA': {'marks': 28, 'outOf': 30},
            'Viva': {'marks': 22, 'outOf': 25},
            'Assignment': {'marks': 23, 'outOf': 25},
            'CSE': {'marks': 18, 'outOf': 20},
            'ESE': {'marks': 45, 'outOf': 50},
          },
        },
        {
          'name': 'DMGT',
          'code': 'CS302',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 29, 'outOf': 30},
            'Viva': {'marks': 24, 'outOf': 25},
            'Assignment': {'marks': 24, 'outOf': 25},
            'CSE': {'marks': 19, 'outOf': 20},
            'ESE': {'marks': 48, 'outOf': 50},
          },
        },
        {
          'name': 'Iwt',
          'code': 'CS303',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26, 'outOf': 30},
            'Viva': {'marks': 20, 'outOf': 25},
            'Assignment': {'marks': 21, 'outOf': 25},
            'CSE': {'marks': 17, 'outOf': 20},
            'ESE': {'marks': 42, 'outOf': 50},
          },
        },
      ]
    },
  ];

  // Method to fetch student component marks and subjects data
  Future<void> _fetchStudentData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Use a hardcoded email for testing
      final email = "ritesh.sanchla115960@marwadiuniversity.ac.in";
      
      // Print debugging information
      print('Attempting to fetch data for email: $email');
      
      // Fetch component marks and subjects
      final result = await _studentService.getStudentComponentMarksAndSubjects(email);
      
      // Print response for debugging
      print('API response received: ${result != null ? 'success' : 'null'}');
      
      setState(() {
        _studentData = StudentComponentData.fromJson(result);
        _isLoading = false;
        
        // Set the selected semester to 1 if there are semesters available
        if (_studentData != null && _studentData!.semesters.isNotEmpty) {
          _selectedSemester = 1;
        }
      });
    } catch (e) {
      print('Error in _fetchStudentData: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
                height: kToolbarHeight + 80,
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
                            const SizedBox(height: 16),
                            SlideTransition(
                              position: _slideAnimation,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _isLoading || _studentData == null
                                  ? List.generate(1, (index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: _buildSemesterChip(1),
                                      );
                                    })
                                  : List.generate(_studentData!.semesters.length, (index) {
                                      final semester = _studentData!.semesters[index].semesterNumber;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: _buildSemesterChip(semester),
                                      );
                                    }),
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
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isLoading 
                    ? _buildLoadingIndicator()
                    : _error != null
                    ? _buildErrorMessage()
                    : _studentData == null || _studentData!.semesters.isEmpty
                    ? _buildNoDataMessage()
                    : ListView.builder(
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
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: const Color(0xFF03A9F4)),
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
    );
  }
  
  // Widget for error state
  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
    );
  }
  
  // Widget for no data state
  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
          totalMarks += marks.ese!.toDouble();
          totalOutOf += weightage.ese!.toDouble();
        }
        if (marks.cse != null && weightage.cse != null && weightage.cse! > 0) {
          totalMarks += marks.cse!.toDouble();
          totalOutOf += weightage.cse!.toDouble();
        }
        if (marks.ia != null && weightage.ia != null && weightage.ia! > 0) {
          totalMarks += marks.ia!.toDouble();
          totalOutOf += weightage.ia!.toDouble();
        }
        if (marks.tw != null && weightage.tw != null && weightage.tw! > 0) {
          totalMarks += marks.tw!.toDouble();
          totalOutOf += weightage.tw!.toDouble();
        }
        if (marks.viva != null && weightage.viva != null && weightage.viva! > 0) {
          totalMarks += marks.viva!.toDouble();
          totalOutOf += weightage.viva!.toDouble();
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
              components['ESE'] = {'marks': marks.ese, 'outOf': weightage.ese};
            }
            if (marks.cse != null && weightage.cse != null) {
              components['CSE'] = {'marks': marks.cse, 'outOf': weightage.cse};
            }
            if (marks.ia != null && weightage.ia != null) {
              components['IA'] = {'marks': marks.ia, 'outOf': weightage.ia};
            }
            if (marks.tw != null && weightage.tw != null) {
              components['TW'] = {'marks': marks.tw, 'outOf': weightage.tw};
            }
            if (marks.viva != null && weightage.viva != null) {
              components['Viva'] = {'marks': marks.viva, 'outOf': weightage.viva};
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
}
