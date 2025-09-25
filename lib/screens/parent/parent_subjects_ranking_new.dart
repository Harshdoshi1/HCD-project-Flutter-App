import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/subject.dart';
import '../../models/student_component_data.dart';
import '../../services/student_service.dart';
import '../student/subject_detail_screen.dart';

class ParentSubjectsRankingScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentSubjectsRankingScreen({super.key, required this.toggleTheme});

  @override
  _ParentSubjectsRankingScreenState createState() => _ParentSubjectsRankingScreenState();
}

class _ParentSubjectsRankingScreenState extends State<ParentSubjectsRankingScreen> with SingleTickerProviderStateMixin {
  int _selectedSemester = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // New state variables for API data
  final StudentService _studentService = StudentService();
  StudentComponentData? _studentData;
  bool _isLoading = true;
  String? _error;

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

  Future<void> _fetchStudentData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _studentService.getStudentComponentMarksAndSubjects('');
      
      setState(() {
        _studentData = StudentComponentData.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SubjectData> _getFilteredSubjects() {
    if (_studentData?.semesters == null) return [];
    
    final semester = _studentData!.semesters.firstWhere(
      (s) => s.semesterNumber == _selectedSemester,
      orElse: () => _studentData!.semesters.first,
    );
    
    return semester.subjects;
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Student Subjects',
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
          child: Column(
            children: [
              // Semester selection chips
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final semester = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildSemesterChip(semester),
                    );
                  },
                ),
              ),
              
              // Main content
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _error != null
                        ? _buildErrorMessage()
                        : _buildSubjectsList(),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF03A9F4) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF03A9F4) 
                : (isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            width: 1,
          ),
        ),
        child: Text(
          'Sem $semester',
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF03A9F4),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your subjects...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStudentData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03A9F4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 60,
            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no subjects available for this semester',
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    final subjects = _getFilteredSubjects();
    
    if (subjects.isEmpty) {
      return _buildNoDataMessage();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            return _buildSubjectCardFromApiData(subjects[index], context);
          },
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
}
