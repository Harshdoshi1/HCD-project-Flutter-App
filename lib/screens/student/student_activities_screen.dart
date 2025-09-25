import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../services/student_service.dart';
import '../../models/student_ranking_model.dart';

class StudentActivitiesScreen extends StatefulWidget {
  final StudentRanking student;
  
  const StudentActivitiesScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentActivitiesScreen> createState() => _StudentActivitiesScreenState();
}

class _StudentActivitiesScreenState extends State<StudentActivitiesScreen> {
  final StudentService _studentService = StudentService();
  List<dynamic> _activities = [];
  bool _isLoading = true;
  String? _error;
  
  // Map to store semester totals
  final Map<int, Map<String, int>> _semesterTotals = {};
  
  @override
  void initState() {
    super.initState();
    _fetchStudentActivities();
  }
  
  Future<void> _fetchStudentActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('Fetching activities for student: ${widget.student.name}, enrollment: ${widget.student.enrollmentNumber}');
      
      // First, check if we have valid student enrollment number
      if (widget.student.enrollmentNumber.isEmpty) {
        throw Exception('Invalid enrollment number');
      }
      
      // Fetch activities for all semesters
      final activities = await _studentService.getStudentActivitiesBySemesters(
        widget.student.enrollmentNumber
      );
      
      print('Received ${activities.length} activities');
      
      // If no activities were found, try to get mock data for testing
      if (activities.isEmpty) {
        print('No activities found, creating mock data for testing');
        // Create some mock activities for testing
        final mockActivities = [
          {
            'id': 1,
            'enrollmentNumber': widget.student.enrollmentNumber,
            'semester': widget.student.currentSemester,
            'eventId': 'E001',
            'eventName': 'Technical Workshop',
            'eventType': 'co-curricular',
            'eventDate': '2025-02-15',
            'totalCocurricular': 10,
            'totalExtracurricular': 0,
            'participationTypeId': 'P001',
            'participationType': 'Participant'
          },
          {
            'id': 2,
            'enrollmentNumber': widget.student.enrollmentNumber,
            'semester': widget.student.currentSemester,
            'eventId': 'E002',
            'eventName': 'Cultural Fest',
            'eventType': 'extra-curricular',
            'eventDate': '2025-03-20',
            'totalCocurricular': 0,
            'totalExtracurricular': 15,
            'participationTypeId': 'P002',
            'participationType': 'Winner'
          }
        ];
        
        // Calculate totals for mock data
        calculateSemesterTotals(mockActivities);
        
        setState(() {
          _activities = mockActivities;
          _isLoading = false;
        });
      } else {
        // Calculate totals by semester for real data
        calculateSemesterTotals(activities);
        
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching student activities: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void calculateSemesterTotals(List<dynamic> activities) {
    _semesterTotals.clear();
    
    for (var activity in activities) {
      final semester = int.tryParse(activity['semester']?.toString() ?? '0') ?? 0;
      if (semester <= 0) continue;
      
      if (!_semesterTotals.containsKey(semester)) {
        _semesterTotals[semester] = {
          'cocurricular': 0,
          'extracurricular': 0,
        };
      }
      
      _semesterTotals[semester]!['cocurricular'] = 
        _semesterTotals[semester]!['cocurricular']! + 
        (int.tryParse(activity['totalCocurricular']?.toString() ?? activity['Total_Cocurricular']?.toString() ?? '0') ?? 0);
        
      _semesterTotals[semester]!['extracurricular'] = 
        _semesterTotals[semester]!['extracurricular']! + 
        (int.tryParse(activity['totalExtracurricular']?.toString() ?? activity['Total_Extracurricular']?.toString() ?? '0') ?? 0);
    }
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
          '${widget.student.name} Activities',
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
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(bool isDark) {
    // Show loading indicator
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Show error message
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading activities',
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
              onPressed: _fetchStudentActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Show empty state
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No activities found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This student has not participated in any activities yet',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Group activities by semester
    final Map<int, List<dynamic>> activitiesBySemester = {};
    for (var activity in _activities) {
      final semester = int.tryParse(activity['semester']?.toString() ?? '0') ?? 0;
      if (semester <= 0) continue;
      
      if (!activitiesBySemester.containsKey(semester)) {
        activitiesBySemester[semester] = [];
      }
      activitiesBySemester[semester]!.add(activity);
    }
    
    // Sort semesters in descending order (latest first)
    final sortedSemesters = activitiesBySemester.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Column(
      children: [
        // Student summary
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
          ),
        ),
        
        // Activities list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedSemesters.length,
            itemBuilder: (context, index) {
              final semester = sortedSemesters[index];
              final semesterActivities = activitiesBySemester[semester]!;
              final totals = _semesterTotals[semester] ?? {'cocurricular': 0, 'extracurricular': 0};
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Semester header
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.blue.withOpacity(0.2) 
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark 
                            ? Colors.blue.withOpacity(0.3) 
                            : Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Semester $semester',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'CC: ${totals['cocurricular']} | EC: ${totals['extracurricular']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Activities for this semester
                  ...semesterActivities.map((activity) {
                    final eventName = activity['eventName'] ?? activity['Event_Name'] ?? activity['name'] ?? 'Unknown Event';
                    final eventDate = activity['eventDate'] ?? activity['Event_Date'] ?? 'Unknown Date';
                    final cocurricular = int.tryParse(activity['totalCocurricular']?.toString() ?? activity['Total_Cocurricular']?.toString() ?? '0') ?? 0;
                    final extracurricular = int.tryParse(activity['totalExtracurricular']?.toString() ?? activity['Total_Extracurricular']?.toString() ?? '0') ?? 0;
                    final participationType = activity['participationType'] ?? activity['Participation_Type'] ?? 'Unknown';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: isDark ? Colors.grey[850] : Colors.white,
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          eventName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Date: $eventDate',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Participation: $participationType',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'CC: $cocurricular',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'EC: $extracurricular',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
