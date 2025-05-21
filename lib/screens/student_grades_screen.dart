import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/student_service.dart';
import '../models/student_component_data.dart';
import '../models/student_ranking_model.dart';

class StudentGradesScreen extends StatefulWidget {
  final StudentRanking student;
  
  const StudentGradesScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  StudentComponentData? _studentData;
  bool _isLoading = true;
  String? _error;
  
  // Selected semester
  int _selectedSemester = 1;
  
  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    _controller.forward();
    
    // Fetch student data
    _fetchStudentData();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _fetchStudentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fetch student component data using their email
      final Map<String, dynamic> result = await _studentService.getStudentComponentMarksAndSubjects(widget.student.email);
      
      // Convert the Map<String, dynamic> to a StudentComponentData object
      final StudentComponentData studentData = StudentComponentData.fromJson(result);
      
      setState(() {
        _studentData = studentData;
        _isLoading = false;
        
        // Set default selected semester to the student's current semester
        if (_studentData != null && _studentData!.semesters.isNotEmpty) {
          // Try to find the current semester
          final currentSemester = widget.student.currentSemester;
          final hasSemester = _studentData!.semesters.any((s) => s.semesterNumber == currentSemester);
          if (hasSemester) {
            _selectedSemester = currentSemester;
          }
        }
      });
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Get subjects for the selected semester
  List<SubjectData> _getSubjectsForSelectedSemester() {
    if (_studentData == null) return [];
    
    // Find the semester that matches the selected semester number
    final selectedSemesterData = _studentData!.semesters.firstWhere(
      (sem) => sem.semesterNumber == _selectedSemester,
      orElse: () => _studentData!.semesters.isNotEmpty 
          ? _studentData!.semesters.first 
          : SemesterData(
              semesterId: 0,
              semesterNumber: 0,
              startDate: '',
              endDate: '',
              subjects: [],
            ),
    );
    
    return selectedSemesterData.subjects;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Grades - ${widget.student.name}',
          style: const TextStyle(
            fontSize: 20,
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
                // Student info card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDark ? Colors.grey[900] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF03A9F4).withOpacity(0.2),
                            radius: 28,
                            child: Text(
                              widget.student.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF03A9F4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.student.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enrollment: ${widget.student.enrollmentNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Current Semester: ${widget.student.currentSemester}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Academic data summary
                if (_studentData != null && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: isDark ? Colors.grey[850] : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAcademicStat('CPI', widget.student.cpi?.toStringAsFixed(2) ?? 'N/A', isDark),
                            _buildAcademicStat('SPI', widget.student.spi?.toStringAsFixed(2) ?? 'N/A', isDark),
                            _buildAcademicStat('Rank', widget.student.rank?.toString() ?? 'N/A', isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Semester selector
                if (_studentData != null && _studentData!.semesters.isNotEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _studentData!.semesters.length,
                        itemBuilder: (context, index) {
                          final semester = _studentData!.semesters[index].semesterNumber;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildSemesterChip(semester),
                          );
                        },
                      ),
                    ),
                  ),
                
                // Main content
                Expanded(
                  child: _buildMainContent(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAcademicStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
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
  
  Widget _buildMainContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: const Color(0xFF03A9F4)),
            const SizedBox(height: 16),
            Text(
              'Loading grades...',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
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
    
    if (_studentData == null || _studentData!.semesters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No academic data found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      );
    }
    
    final subjects = _getSubjectsForSelectedSemester();
    
    if (subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects found for Semester $_selectedSemester',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _buildSubjectCard(subject, isDark);
        },
      ),
    );
  }
  
  Widget _buildSubjectCard(SubjectData subject, bool isDark) {
    String grade = subject.grades ?? 'N/A';
    Color gradeColor = Colors.grey;
    
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
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? Colors.grey[850] : Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subjectName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (subject.subjectCode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Code: ${subject.subjectCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                  if (subject.credits != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Credits: ${subject.credits}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradeColor.withOpacity(0.2),
                border: Border.all(
                  color: gradeColor,
                  width: 2,
                ),
              ),
              child: Text(
                grade,
                style: TextStyle(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
