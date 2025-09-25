import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import '../../providers/user_provider.dart';
import '../../services/academic_service.dart';
import '../../services/student_service.dart';
import '../../services/student_analysis_service.dart';
import '../../models/blooms_taxonomy_model.dart';
import 'profile_screen.dart';
import '../../constants/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const DashboardScreen({super.key, required this.toggleTheme});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Activity points for the logged-in user
  int _cocurricularPoints = 0;
  int _extracurricularPoints = 0;
  bool _isLoadingActivityPoints = true;
  List<dynamic> _activities = [];
  String? _enrollmentNumber;  
  final AcademicService _academicService = AcademicService();
  List<SemesterSPI>? _spiData;
  List<Map<String, dynamic>> _semesterSPIData = [];
  bool _isLoadingSemesterSPI = true;
  bool _isLoadingSPI = true;
  String _activeGraph = 'blooms';
  late AnimationController _graphAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Subject data for radar chart
  bool _isLoadingSubjectData = true;
  List<String> _currentSemesterSubjects = [];
  List<double> _currentSemesterScores = [];
  List<Color> _subjectColors = [];
  int _currentSemesterNumber = 0;
  final Map<String, double> _gradeToScore = {
    'AA': 100.0, 'AB': 90.0, 'BB': 80.0, 
    'BC': 70.0, 'CC': 60.0, 'CD': 50.0, 
    'DD': 40.0, 'FF': 0.0, 'NA': 0.0
  };
  
  // Bloom's taxonomy data
  final StudentAnalysisService _analysisService = StudentAnalysisService();
  BloomsTaxonomyModel? _bloomsData;
  bool _isLoadingBlooms = true;
  String? _selectedSubjectForBlooms;
  List<String> _availableSubjects = [];
  late PageController _subjectPageController;
  
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
  
  // Helper methods for subject navigation
  void _previousSubject() {
    if (_availableSubjects.isNotEmpty) {
      final currentIndex = _availableSubjects.indexOf(_selectedSubjectForBlooms ?? '');
      final newIndex = currentIndex > 0 ? currentIndex - 1 : _availableSubjects.length - 1;
      setState(() {
        _selectedSubjectForBlooms = _availableSubjects[newIndex];
      });
      _subjectPageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _nextSubject() {
    if (_availableSubjects.isNotEmpty) {
      final currentIndex = _availableSubjects.indexOf(_selectedSubjectForBlooms ?? '');
      final newIndex = (currentIndex + 1) % _availableSubjects.length;
      setState(() {
        _selectedSubjectForBlooms = _availableSubjects[newIndex];
      });
      _subjectPageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _switchGraph(String newGraph) {
    if (_activeGraph != newGraph) {
      setState(() {
        _activeGraph = newGraph;
        _graphAnimationController.reset();
        _graphAnimationController.forward();
      });
    }
  }

  // Academic events
  final List<Map<String, dynamic>> academicEvents = [
    {
      'title': 'HCD Hackathon',
      'date': 'Apr 20, 2025',
      'icon': Icons.code,
      'color': Colors.blue,
    },
    {
      'title': 'Midsem 2',
      'date': 'Apr 25, 2025',
      'icon': Icons.assignment,
      'color': Colors.red,
    },
    {
      'title': 'Viva',
      'date': 'May 2, 2025',
      'icon': Icons.record_voice_over,
      'color': Colors.orange,
    },
    {
      'title': 'Endsem',
      'date': 'May 15, 2025',
      'icon': Icons.school,
      'color': Colors.purple,
    },
    {
      'title': 'AI Hackathon Day 2',
      'date': 'May 22, 2025',
      'icon': Icons.psychology,
      'color': Colors.teal,
    },
    {
      'title': 'AWT Project',
      'date': 'May 28, 2025',
      'icon': Icons.web,
      'color': Colors.indigo,
    },
  ];

  // Non-academic events
  final List<Map<String, dynamic>> nonAcademicEvents = [
    {
      'title': 'SSIP Hackathon',
      'date': 'Apr 18, 2025',
      'icon': Icons.lightbulb,
      'color': Colors.amber,
    },
    {
      'title': 'Patent Filing',
      'date': 'Apr 30, 2025',
      'icon': Icons.description,
      'color': Colors.green,
    },
    {
      'title': 'Frolic',
      'date': 'May 5, 2025',
      'icon': Icons.celebration,
      'color': Colors.pink,
    },
    {
      'title': 'Confidance',
      'date': 'May 10, 2025',
      'icon': Icons.music_note,
      'color': Colors.deepPurple,
    },
    {
      'title': 'IEEE Event',
      'date': 'May 20, 2025',
      'icon': Icons.groups,
      'color': Colors.blue,
    },
  ];

  // Clubs
  final List<Map<String, dynamic>> clubs = [
    {
      'name': 'Competitive Programming Club',
      'role': 'Member',
      'icon': Icons.code,
      'color': Colors.blue,
      'joined': true,
      'link': 'https://mu.ac.in/cp-club',
      'description': 'A community of competitive programmers who participate in coding contests and practice algorithmic problem solving.',
      'code': 'CP001',
    },
    {
      'name': 'Data Science Club',
      'role': 'Core Member',
      'icon': Icons.analytics,
      'color': Colors.green,
      'joined': true,
      'link': 'https://mu.ac.in/ds-club',
      'description': 'Focused on data analysis, machine learning, and AI applications across various domains.',
      'code': 'DS002',
    },
    {
      'name': 'Cloud & DevOps Club',
      'role': 'Participant',
      'icon': Icons.cloud,
      'color': Colors.indigo,
      'joined': false,
      'link': 'https://mu.ac.in/cloud-club',
      'description': 'Learn about cloud infrastructure, CI/CD pipelines, and modern deployment strategies.',
      'code': 'CD003',
    },
    {
      'name': 'Circuitology Club',
      'role': 'Member',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
      'joined': true,
      'link': 'https://mu.ac.in/circuit-club',
      'description': 'Explore electronics, circuit design, and hardware programming through hands-on projects.',
      'code': 'CC004',
    },
  ];

  // Daily quotes
  final List<String> _dailyQuotes = [
    "The only way to do great work is to love what you do.",
    "Education is the passport to the future.",
    "Success is not final, failure is not fatal: It is the courage to continue that counts.",
    "The future belongs to those who believe in the beauty of their dreams.",
    "The best way to predict the future is to create it.",
    "Strive not to be a success, but rather to be of value.",
    "Learning is a treasure that will follow its owner everywhere.",
  ];
  
  late String _dailyQuote;
  String _userName = 'User';

  Future<void> _loadSPIData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user != null) {
        debugPrint('Fetching SPI data for: ${user.email}');
        final spiData = await _academicService.getStudentSPI(user.email);
        // Even if spiData is empty, we don't throw an exception
        if (!mounted) return;
        setState(() {
          _spiData = spiData; // This will be an empty list if no data was found
          _isLoadingSPI = false;
          debugPrint('SPI data loaded successfully: ${spiData.length} items');
        });
        
        // Also load semester SPI data for bar chart
        _loadSemesterSPIData(user.enrollmentNumber);
      } else {
        debugPrint('User is null, cannot load SPI data');
        if (!mounted) return;
        setState(() {
          _spiData = [];
          _isLoadingSPI = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading SPI data: $e');
      if (!mounted) return;
      setState(() {
        _spiData = []; // Set to empty list on error
        _isLoadingSPI = false;
      });
    }
  }
  
  Future<void> _loadSemesterSPIData(String enrollmentNumber) async {
    try {
      debugPrint('Fetching semester SPI data for enrollment: $enrollmentNumber');
      final data = await _academicService.getSemesterSPIByEnrollment(enrollmentNumber);
      
      if (!mounted) return;
      
      setState(() {
        _semesterSPIData = data;
        _isLoadingSemesterSPI = false;
        debugPrint('Semester SPI data loaded: ${data.length} semesters');
      });
    } catch (e) {
      debugPrint('Error loading semester SPI data: $e');
      if (!mounted) return;
      setState(() {
        _semesterSPIData = [];
        _isLoadingSemesterSPI = false;
      });
    }
  }

  Future<void> _loadSubjectData(String email) async {
    print('Starting _loadSubjectData for email: $email');
    setState(() {
      _isLoadingSubjectData = true;
    });
    
    try {
      // Clear previous data
      _currentSemesterSubjects.clear();
      _currentSemesterScores.clear();
      _subjectColors.clear();
      
      // Define fallback color list
      final List<Color> baseColors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.amber,
        Colors.pink,
        Colors.indigo,
        Colors.cyan,
      ];

      // Use the API to get actual subject data
      print('Fetching subject data from API for email: $email');
      final studentService = StudentService();
      final response = await studentService.getStudentComponentMarksAndSubjects(email);
      
      if (response.containsKey('semesters') && response['semesters'] is List) {
        final List<dynamic> semesters = response['semesters'];
        
        if (semesters.isNotEmpty) {
          print('API returned ${semesters.length} semesters');
          
          // Find current semester (highest semester number)
          int highestSemester = 0;
          Map<String, dynamic>? currentSemesterData;
          
          for (var semesterData in semesters) {
            if (semesterData.containsKey('semesterNumber')) {
              final int semesterNumber = int.tryParse(semesterData['semesterNumber'].toString()) ?? 0;
              if (semesterNumber > highestSemester) {
                highestSemester = semesterNumber;
                currentSemesterData = semesterData;
              }
            }
          }
          
          // Set current semester number
          _currentSemesterNumber = highestSemester;
          
          // Process subject data for the current semester
          if (currentSemesterData != null && 
              currentSemesterData.containsKey('subjects') && 
              currentSemesterData['subjects'] is List) {
            
            final List<dynamic> subjects = currentSemesterData['subjects'];
            print('Found ${subjects.length} subjects for semester $_currentSemesterNumber');
            
            // Process each subject
            for (int i = 0; i < subjects.length; i++) {
              var subject = subjects[i];
              if (subject is Map<String, dynamic>) {
                String subjectName = subject['subjectName'] ?? subject['name'] ?? 'Unknown';
                String grade = subject['grade'] ?? 'NA';
                
                // Skip subjects with no grade
                if (grade == 'NA' || grade.isEmpty) continue;
                
                // Convert grade to score
                double score = _gradeToScore[grade] ?? 0.0;
                
                // Add subject to lists
                _currentSemesterSubjects.add(subjectName);
                _currentSemesterScores.add(score);
                
                // Add color for the subject (cycling through baseColors)
                _subjectColors.add(baseColors[i % baseColors.length]);
                
                print('Added subject: $subjectName with grade: $grade, score: $score');
              }
            }
          }
        }
      }
      
      // If no data was found from API, we don't use any fallback hardcoded data
      if (_currentSemesterSubjects.isEmpty) {
        print('No data from API, no fallback data will be used');
        // Keep the lists empty to show the "No subject data available" message
      }
    } catch (e) {
      print('Error in _loadSubjectData: $e');
      // Keep lists empty on error to show "No Data" message
      _currentSemesterSubjects = [];
      _currentSemesterScores = [];
      _subjectColors = [];
      _currentSemesterNumber = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubjectData = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        setState(() {
          _userName = user.name;
          _enrollmentNumber = user.enrollmentNumber;
        });
        
        // Now that we have the enrollment number, fetch additional data
        if (_enrollmentNumber != null) {
          await _loadSemesterSPIData(_enrollmentNumber!);
          
          // Load subject data for radar chart
          await _loadSubjectData(user.email!);
                }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Fetch event details from event master table
  Future<Map<String, dynamic>?> _fetchEventDetails(String eventId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('events/getEventById/$eventId')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching event details for ID $eventId: $e');
    }
    return null;
  }

  // Fetch student points data and get event details
  Future<void> _loadActivityPoints() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        setState(() {
          _enrollmentNumber = user.enrollmentNumber;
        });
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token != null && _enrollmentNumber != null) {
          // First, fetch the total activity points from the new endpoint
          try {
            final pointsResponse = await http.post(
              Uri.parse(ApiConfig.getUrl('events/fetchTotalActivityPoints')),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'enrollmentNumber': _enrollmentNumber,
              }),
            );
            
            if (pointsResponse.statusCode == 200) {
              final pointsData = json.decode(pointsResponse.body);
              
              print('Total activity points response: $pointsData');
              
              setState(() {
                _cocurricularPoints = pointsData['totalCocurricular'] != null ? 
                    int.parse(pointsData['totalCocurricular'].toString()) : 0;
                _extracurricularPoints = pointsData['totalExtracurricular'] != null ? 
                    int.parse(pointsData['totalExtracurricular'].toString()) : 0;
              });
            }
          } catch (e) {
            print('Error fetching total activity points: $e');
            // If we can't get points from the new endpoint, fallback to user data
            final userData = prefs.getString('userData');
            if (userData != null) {
              final userMap = json.decode(userData);
              setState(() {
                _cocurricularPoints = userMap['totalCocurricular'] ?? userMap['cocurricularPoints'] ?? 0;
                _extracurricularPoints = userMap['totalExtracurricular'] ?? userMap['extracurricularPoints'] ?? 0;
              });
            }
          }
          
          // Fetch student points data with CSV event IDs
          try {
            final studentPointsResponse = await http.post(
              Uri.parse(ApiConfig.getUrl('events/getStudentPointsWithEvents')),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'enrollmentNumber': _enrollmentNumber,
              }),
            );
            
            if (studentPointsResponse.statusCode == 200) {
              final studentPointsData = json.decode(studentPointsResponse.body);
              print('Student points data: $studentPointsData');
              
              List<dynamic> enrichedActivities = [];
              
              if (studentPointsData is List) {
                for (var semesterData in studentPointsData) {
                  final eventIds = semesterData['eventIds']?.toString() ?? '';
                  final semester = semesterData['semester'];
                  final cocurricularPoints = semesterData['cocurricularPoints'] ?? 0;
                  final extracurricularPoints = semesterData['extracurricularPoints'] ?? 0;
                  
                  if (eventIds.isNotEmpty) {
                    // Parse CSV event IDs
                    final eventIdList = eventIds.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
                    
                    // Fetch details for each event ID
                    for (String eventId in eventIdList) {
                      final eventDetails = await _fetchEventDetails(eventId, token);
                      
                      if (eventDetails != null) {
                        enrichedActivities.add({
                          'id': eventId,
                          'eventId': eventId,
                          'eventName': eventDetails['eventName'] ?? eventDetails['Event_Name'] ?? 'Unknown Event',
                          'eventType': eventDetails['eventType'] ?? eventDetails['Event_Type'] ?? 'unknown',
                          'eventDate': eventDetails['eventDate'] ?? eventDetails['Event_Date'],
                          'description': eventDetails['description'] ?? eventDetails['Description'],
                          'semester': semester,
                          'totalCocurricular': cocurricularPoints,
                          'totalExtracurricular': extracurricularPoints,
                          'participationType': 'Participant', // Default since we don't have this in points table
                        });
                      }
                    }
                  }
                }
              }
              
              setState(() {
                _activities = enrichedActivities;
                _isLoadingActivityPoints = false;
              });
              
              print('Loaded ${enrichedActivities.length} enriched activities');
            } else {
              // Fallback to old method if new endpoint doesn't exist
              await _loadActivityPointsFallback(token);
            }
          } catch (e) {
            print('Error fetching student points data: $e');
            // Fallback to old method
            await _loadActivityPointsFallback(token);
          }
        } else {
          setState(() {
            _isLoadingActivityPoints = false;
          });
        }
      } else {
        setState(() {
          _cocurricularPoints = 0;
          _extracurricularPoints = 0;
          _isLoadingActivityPoints = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity points: $e');
      setState(() {
        _isLoadingActivityPoints = false;
      });
    }
  }

  // Fallback method using old endpoint
  Future<void> _loadActivityPointsFallback(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('events/fetchEventsbyEnrollandSemester')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'enrollmentNumber': _enrollmentNumber,
          'semester': 'all'
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          setState(() {
            _activities = data;
            _isLoadingActivityPoints = false;
          });
        } else {
          setState(() {
            _isLoadingActivityPoints = false;
          });
        }
      } else {
        setState(() {
          _isLoadingActivityPoints = false;
        });
      }
    } catch (e) {
      print('Error in fallback method: $e');
      setState(() {
        _isLoadingActivityPoints = false;
      });
    }
  }

  // Helper method to calculate grid interval for Y-axis
  double _calculateGridInterval(double maxMarks) {
    if (maxMarks <= 20) {
      return 5.0;
    } else if (maxMarks <= 50) {
      return 10.0;
    } else if (maxMarks <= 100) {
      return 20.0;
    } else {
      return (maxMarks / 5).ceilToDouble();
    }
  }

  // Load Bloom's taxonomy data
  Future<void> _loadBloomsData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null || user.enrollmentNumber.isEmpty) {
        setState(() {
          _isLoadingBlooms = false;
        });
        return;
      }
      
      setState(() {
        _isLoadingBlooms = true;
      });
      
      // Use current semester (default to 1)
      int currentSemester = 1;
      if (_semesterSPIData.isNotEmpty) {
        currentSemester = _semesterSPIData.last['semester'] ?? 1;
      }
      
      print('Loading Bloom\'s data for enrollment: ${user.enrollmentNumber}, semester: $currentSemester');
      
      final result = await _analysisService.getBloomsTaxonomyDistribution(
        user.enrollmentNumber, 
        currentSemester
      );
      
      if (mounted) {
        setState(() {
          _bloomsData = BloomsTaxonomyModel.fromJson(result);
          _isLoadingBlooms = false;
          
          // Extract available subjects for dropdown
          _availableSubjects = _bloomsData?.bloomsDistribution
              .map((subject) => subject.subject)
              .toList() ?? [];
          
          // Set default selected subject
          if (_availableSubjects.isNotEmpty && _selectedSubjectForBlooms == null) {
            _selectedSubjectForBlooms = _availableSubjects.first;
          }
          
          print('Loaded Bloom\'s data for ${_availableSubjects.length} subjects');
        });
      }
    } catch (e) {
      print('Error loading Bloom\'s data: $e');
      if (mounted) {
        setState(() {
          _isLoadingBlooms = false;
          _bloomsData = null;
          _availableSubjects = [];
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _graphAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _graphAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _graphAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Initialize page controller for subject slider
    _subjectPageController = PageController();
    
    // Define subject colors
    _subjectColors = [
      Colors.blue, Colors.green, Colors.purple, 
      Colors.orange, Colors.red, Colors.teal,
      Colors.pink, Colors.amber, Colors.indigo,
      Colors.cyan, Colors.deepOrange, Colors.lightGreen,
    ];
    
    // Start animation
    _graphAnimationController.forward();
    
    // Load user data, SPI data, activity points and blooms data
    _loadUserData();
    _loadSPIData();
    _loadActivityPoints();
    _loadBloomsData();
    
    // Set random daily quote
    _dailyQuote = _dailyQuotes[DateTime.now().day % _dailyQuotes.length];
  }
  @override
  void dispose() {
    _graphAnimationController.dispose();
    _subjectPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
                  Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          // Content
          SafeArea(
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
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Text(
                              '"$_dailyQuote"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                toggleTheme: widget.toggleTheme,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: FutureBuilder<SharedPreferences>(
                            future: SharedPreferences.getInstance(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                final prefs = snapshot.data!;
                                final userEmail = prefs.getString('userEmail') ?? '';
                                final imagePath = prefs.getString('${userEmail}_profileImage');
                                
                                if (imagePath != null && imagePath.isNotEmpty) {
                                  final file = File(imagePath);
                                  return CircleAvatar(
                                    radius: 24,
                                    backgroundImage: FileImage(file),
                                  );
                                }
                              }
                              
                              return CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Charts section
                  _buildChartsSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        // Graph selection row
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildIconRow(),
          ),
        ),
                  const SizedBox(height: 24),
        // Main chart
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildGlassChartCard(
              title: _getChartTitle(),
              height: 300,
              chart: _getActiveChart(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Info card
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildGlassInfoCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildIconRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconButton('Bloom\'s', Icons.psychology, _activeGraph == 'blooms', () => _switchGraph('blooms')),
        _buildIconButton('Activities', Icons.pie_chart, _activeGraph == 'activities', () => _switchGraph('activities')),
        _buildIconButton('Semesters', Icons.insert_chart, _activeGraph == 'semesters', () => _switchGraph('semesters')),
      ],
    );
  }

  Widget _buildIconButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5) 
                : Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.2) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassChartCard({required String title, required double height, required Widget chart}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.2) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
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
                        _getIconForTitle(title),
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Subject slider with arrow navigation for Bloom's chart
                    if (title == 'Bloom\'s Taxonomy Analysis')
                      Container(
                        constraints: const BoxConstraints(maxWidth: 250),
                        height: 40,
                        child: _availableSubjects.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Loading...',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              )
                            : _availableSubjects.length == 1
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _availableSubjects.first.length > 18 
                                            ? '${_availableSubjects.first.substring(0, 18)}...' 
                                            : _availableSubjects.first,
                                        style: const TextStyle(
                                          color: Colors.white, 
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      // Left arrow
                                      GestureDetector(
                                        onTap: _previousSubject,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.chevron_left,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Subject slider
                                      Expanded(
                                        child: Container(
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: PageView.builder(
                                            controller: _subjectPageController,
                                            onPageChanged: (index) {
                                              setState(() {
                                                _selectedSubjectForBlooms = _availableSubjects[index];
                                              });
                                            },
                                            itemCount: _availableSubjects.length,
                                            itemBuilder: (context, index) {
                                              final subject = _availableSubjects[index];
                                              return Center(
                                                child: Text(
                                                  subject.length > 15 
                                                      ? '${subject.substring(0, 15)}...' 
                                                      : subject,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Right arrow
                                      GestureDetector(
                                        onTap: _nextSubject,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: chart),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDomainExpertiseChart() {
    // Domain expertise data
    final List<Map<String, dynamic>> expertiseData = [
      {'domain': 'Mobile', 'value': 30, 'color': Colors.blue},
      {'domain': 'ML', 'value': 25, 'color': Colors.purple},
      {'domain': 'Web', 'value': 20, 'color': Colors.amber},
      {'domain': 'Cloud', 'value': 15, 'color': Colors.green},
      {'domain': 'Other', 'value': 10, 'color': Colors.red},
    ];
    
    // Track touched section for hover effect
    int? touchedIndex;
    
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _graphAnimationController,
        curve: Curves.easeIn,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 240, // Reduced height to fit better in card
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                startDegreeOffset: 270, // Start from top
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                  enabled: true,
                ),
                sections: List.generate(expertiseData.length, (index) {
                  final data = expertiseData[index];
                  final isTouched = index == touchedIndex;
                  final fontSize = isTouched ? 18.0 : 14.0;
                  final radius = isTouched ? 90.0 : 80.0;
                  
                  return PieChartSectionData(
                    color: data['color'],
                    value: data['value'].toDouble() * value, // Animate value
                    title: isTouched ? '${data['value']}%' : '',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                    badgeWidget: Text(
                      data['domain'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    badgePositionPercentageOffset: .8,
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 750),
              swapAnimationCurve: Curves.easeInOutQuint,
            );
          }
        ),
      ),
    );
  }

  Widget _buildProgrammingLanguagesChart() {
    final languages = ['Dart', 'Python', 'JS', 'Java', 'C++', 'C#', 'C'];
    final values = [95.0, 88.0, 80.0, 75.0, 70.0, 65.0, 60.0];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
    ];
    
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _graphAnimationController,
        curve: Curves.easeIn,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 240,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${languages[groupIndex]}: ${values[groupIndex].toInt()}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < languages.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              languages[value.toInt()],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (value == 0) {
                          text = '0';
                        } else if (value == 5) {
                          text = '5';
                        } else if (value == 10) {
                          text = '10';
                        } else {
                          return const SizedBox();
                        }
                        return Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(languages.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index] * value,
                        color: colors[index],
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 750),
              swapAnimationCurve: Curves.easeInOutQuint,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> events) {
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.symmetric(horizontal: 10), // Added horizontal padding
      itemBuilder: (context, index) {
        final event = events[index];
        return GestureDetector(
          onTap: () {
            _showEventDetails(context, event);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.2) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Added padding
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (event['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      event['icon'],
                      color: (event['color'] as Color),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    event['title'],
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    event['date'],
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAcademic = academicEvents.contains(event);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (event['color'] as Color).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          event['icon'],
                          color: event['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              event['date'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAcademic ? 'Marks' : 'Points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          isAcademic ? '50 marks' : '100 points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03A9F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClubsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clubs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              return GestureDetector(
                onTap: () {
                  _showClubDetails(context, club);
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.2) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (club['color'] as Color).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        club['icon'],
                                        color: club['color'],
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      club['name'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      club['role'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (club['joined'])
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                                      width: 1,
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
              );
            },
          ),
        ),
      ],
    );
  }

  void _showClubDetails(BuildContext context, Map<String, dynamic> club) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (club['color'] as Color).withOpacity(0.4),
                          isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (club['color'] as Color).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            club['icon'],
                            color: club['color'],
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                club['name'],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (club['joined'] as bool)
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (club['joined'] as bool) ? 'Joined' : 'Not Joined',
                                      style: TextStyle(
                                        color: (club['joined'] as bool)
                                            ? Colors.green
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Code: ${club['code']}',
                                    style: TextStyle(
                                      color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                      fontSize: 12,
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
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            club['description'],
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Club Link',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            club['link'],
                            style: const TextStyle(
                              color: Color(0xFF03A9F4),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your Role',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            club['role'],
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.2) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
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
                      child: const Icon(
                        Icons.dashboard,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingSemesterSPI)
                  const Center(child: CircularProgressIndicator())
                else if (_semesterSPIData.isEmpty)
                  const Text('No academic data available')
                else ...[
                  _buildInfoRow(
                    'Current CGPA', 
                    _semesterSPIData.isNotEmpty 
                      ? _semesterSPIData.last['cpi'].toStringAsFixed(2)
                      : 'N/A'
                  ),
                  _buildInfoRow(
                    'Current Semester', 
                    _semesterSPIData.isNotEmpty 
                      ? '${_semesterSPIData.last['semester']}th'
                      : 'N/A'
                  ),
                  _buildInfoRow(
                    'Current SPI', 
                    _semesterSPIData.isNotEmpty 
                      ? _semesterSPIData.last['spi'].toStringAsFixed(2)
                      : 'N/A'
                  ),
                  _buildInfoRow(
                    'Academic Rank', 
                    _semesterSPIData.isNotEmpty 
                      ? '${_semesterSPIData.last['rank']}th'
                      : 'N/A'
                  ),
                  _buildInfoRow(
                    'Overall Points', 
                    '${_cocurricularPoints + _extracurricularPoints}'
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.7) 
                : Colors.black.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Current Semester Subjects':
        return Icons.radar;
      case 'Activity Points':
        return Icons.pie_chart;
      default:
        return Icons.analytics;
    }
  }

  String _getChartTitle() {
    switch (_activeGraph) {
      case 'blooms':
        return 'Bloom\'s Taxonomy Analysis';
      case 'activities':
        return 'Activity Points';
      case 'semesters':
        return 'All Semester SPIs';
      default:
        return 'Bloom\'s Taxonomy Analysis';
    }
  }

  Widget _getActiveChart() {
    switch (_activeGraph) {
      case 'blooms':
        return _buildBloomsTaxonomyChart();
      case 'activities':
        return _buildActivityPointsChart();
      case 'semesters':
        return _buildSemesterSPIChart();
      default:
        return _buildBloomsTaxonomyChart(); // Default to blooms chart
    }
  }
  
  // Helper method to build a legend item for the activity points chart
  Widget _buildLegendItem({
    required Color color,
    required String title,
    required int points,
    required String percentage,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Color indicator
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        // Text info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              '$points pts ($percentage%)',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActivityPointsChart() {
    if (_isLoadingActivityPoints) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading activity data...'),
          ],
        ),
      );
    }
    
    // If both points are 0, show a message
    if (_cocurricularPoints == 0 && _extracurricularPoints == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity points available',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Participate in activities to earn points',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    // Calculate percentages
    final totalPoints = _cocurricularPoints + _extracurricularPoints;
    final cocurricularPercentage = (_cocurricularPoints / totalPoints * 100).toStringAsFixed(1);
    final extracurricularPercentage = (_extracurricularPoints / totalPoints * 100).toStringAsFixed(1);
    
    // Colors for the pie chart sections
    const Color cocurricularColor = Color(0xFF4CAF50); // Green
    const Color extracurricularColor = Color(0xFF2196F3); // Blue
    
    return Container(
      width: double.infinity,
      height: 250, // Adjusted overall height to fix overflow
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          // Animated pie chart
          SizedBox(
            height: 130,
            child: Center(
              child: SizedBox(
                width: 200, // Limited width for pie chart
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated pie chart
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 25, // Even smaller center space
                            sections: [
                              PieChartSectionData(
                                color: cocurricularColor,
                                value: _cocurricularPoints.toDouble() * value,
                                title: '',  // Remove percentage from slice
                                radius: 45, // Reduced radius to match smaller width
                                titleStyle: const TextStyle(fontSize: 0), // Hide title in pie
                                badgeWidget: null, // Removed trophy badge
                              ),
                              PieChartSectionData(
                                color: extracurricularColor,
                                value: _extracurricularPoints.toDouble() * value,
                                title: '', // Remove percentage from slice
                                radius: 45, // Reduced radius to match smaller width
                                titleStyle: const TextStyle(fontSize: 0), // Hide title in pie
                                badgeWidget: null, // Removed trophy badge
                              ),
                            ],
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 750),
                          swapAnimationCurve: Curves.easeInOutQuint,
                        ),
                        
                        // Center total counter
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(totalPoints * value).toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text(
                                'TOTAL',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Legend - more compact horizontal layout
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cocurricular legend item
                _buildLegendItem(
                  color: cocurricularColor,
                  title: 'Cocurricular',
                  points: _cocurricularPoints,
                  percentage: cocurricularPercentage,
                ),
                // Extracurricular legend item
                _buildLegendItem(
                  color: extracurricularColor,
                  title: 'Extracurricular',
                  points: _extracurricularPoints,
                  percentage: extracurricularPercentage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Badge widget for the pie chart
  Widget _buildBadge(IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.bounceInOut,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(icon, color: color, size: 16),
    );
  }
  
  // Legend card for pie chart
  Widget _buildLegendCard(String title, int points, Color color, IconData icon, String percentage) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points pts',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(String name, String date, String type, int points, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Date: $date',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Type: $type',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                '$points pts',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build semester SPI bar chart
  Widget _buildSemesterSPIChart() {
    if (_isLoadingSemesterSPI) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_semesterSPIData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No semester data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Sort data by semester
    _semesterSPIData.sort((a, b) => (a['semester'] as int).compareTo(b['semester'] as int));
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final semester = _semesterSPIData[groupIndex]['semester'];
                final spi = _semesterSPIData[groupIndex]['spi'];
                final cpi = _semesterSPIData[groupIndex]['cpi'];
                return BarTooltipItem(
                  'Semester $semester\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: 'SPI: ${spi.toStringAsFixed(2)}\n', style: const TextStyle(color: Colors.yellow)),
                    TextSpan(text: 'CPI: ${cpi.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent)),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _semesterSPIData.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        'S${_semesterSPIData[value.toInt()]['semester']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          maxY: 10, // Maximum SPI is 10
          barGroups: List.generate(_semesterSPIData.length, (index) {
            final data = _semesterSPIData[index];
            final spi = data['spi'] as double;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: spi,
                  color: _getSPIColor(spi),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 10,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 750),
      ),
    );
  }
  
  // Get a color based on SPI value
  Color _getSPIColor(double spi) {
    if (spi >= 9) return Colors.greenAccent;
    if (spi >= 8) return Colors.green;
    if (spi >= 7) return Colors.lime;
    if (spi >= 6) return Colors.amber;
    if (spi >= 5) return Colors.orange;
    return Colors.redAccent;
  }

  // Helper method to convert score back to grade for display
  String _getGradeFromScore(double score) {
    if (score >= 95) return 'AA';
    if (score >= 85) return 'AB';
    if (score >= 75) return 'BB';
    if (score >= 65) return 'BC';
    if (score >= 55) return 'CC';
    if (score >= 45) return 'CD';
    if (score >= 35) return 'DD';
    if (score > 0) return 'FF';
    return 'NA';
  }

  Widget _buildAnimatedRadarChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

  // Show loading indicator while fetching subject data
  if (_isLoadingSubjectData) {
    return const Center(
      child: SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
  
  // If there's no subject data available, show a message
  if (_currentSemesterSubjects.isEmpty) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No subject data available',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
            Text(
              'Please check your academic records',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Reset animation if needed
  if (!_graphAnimationController.isAnimating && _graphAnimationController.value == 0) {
    _graphAnimationController.forward();
  }

  // Create animated radar chart with actual subject data
  return AnimatedBuilder(
    animation: _graphAnimationController,
    builder: (context, child) {
      // Create animated scores for the radar chart
      final List<double> animatedScores = _currentSemesterScores.map((score) {
        return score * _graphAnimationController.value;
      }).toList();
      
      return SizedBox(
        height: 200, // Increased height for better visibility and legend
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: RadarChartPainter(
                  subjects: _currentSemesterSubjects,
                  scores: animatedScores,
                  maxScore: 100,
                  backgroundColor: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                  lineColor: const Color(0xFF03A9F4),
                  fillColor: const Color(0xFF03A9F4).withOpacity(0.2),
                  colors: _subjectColors,
                  context: context,
                ),
                size: const Size(double.infinity, 140),
              ),
            ),
            if (_currentSemesterNumber > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${_getOrdinalNumber(_currentSemesterNumber)} Semester Subject Performance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            // Add subject grade legend
            if (_currentSemesterSubjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12.0,
                  runSpacing: 4.0,
                  children: List.generate(
                    _currentSemesterSubjects.length,
                    (index) {
                      final grade = _getGradeFromScore(_currentSemesterScores[index]);
                      return Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        backgroundColor: _subjectColors[index].withOpacity(0.1),
                        side: BorderSide(color: _subjectColors[index], width: 1),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _subjectColors[index],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentSemesterSubjects[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($grade)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}  

  Widget _buildAnimatedBarChart() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _graphAnimationController,
            curve: Curves.easeIn,
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String semester;
                    switch (group.x.toInt()) {
                      case 0:
                        semester = 'Sem 1';
                        break;
                      case 1:
                        semester = 'Sem 2';
                        break;
                      case 2:
                        semester = 'Sem 3';
                        break;
                      case 3:
                        semester = 'Sem 4';
                        break;
                      case 4:
                        semester = 'Sem 5';
                        break;
                      case 5:
                        semester = 'Sem 6';
                        break;
                      default:
                        semester = '';
                    }
                    return BarTooltipItem(
                      '$semester\n',
                      TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: (rod.toY * value).toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.yellow : Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'Sem 1';
                          break;
                        case 1:
                          text = 'Sem 2';
                          break;
                        case 2:
                          text = 'Sem 3';
                          break;
                        case 3:
                          text = 'Sem 4';
                          break;
                        case 4:
                          text = 'Sem 5';
                          break;
                        case 5:
                          text = 'Sem 6';
                          break;
                        default:
                          text = '';
                          break;
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 16,
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      if (value == 0) {
                        text = '0';
                      } else if (value == 5) {
                        text = '5.0';
                      } else if (value == 10) {
                        text = '10.0';
                      }
                      return Text(
                        text,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 2.5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black87),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black87),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: [
                _buildBarGroup(0, 6.5 * value),
                _buildBarGroup(1, 8.5 * value),
                _buildBarGroup(2, 2.9 * value),
                _buildBarGroup(3, 9.1 * value),
                _buildBarGroup(4, 8.9 * value),
                _buildBarGroup(5, 9.3 * value),
              ],
            ),
          ),
        );
      },
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    // Define colors based on SGPA value
    Color getBarColor(double sgpa) {
      if (sgpa >= 7.0) return Colors.green;
      if (sgpa >= 4.0) return Colors.orange;
      return Colors.red;
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: getBarColor(y),
          width: 22,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black87),
          ),
        ),
      ],
    );
  }

  // Events section removed as requested

  // Build Bloom's taxonomy chart with subject dropdown
  Widget _buildBloomsTaxonomyChart() {
    if (_isLoadingBlooms) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF03A9F4)),
            SizedBox(height: 16),
            Text('Loading Bloom\'s taxonomy data...'),
          ],
        ),
      );
    }
    
    if (_bloomsData == null || _bloomsData!.bloomsDistribution.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 60,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Bloom\'s taxonomy data available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete assessments to see your cognitive skill analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    // Find selected subject data
    final selectedSubjectData = _bloomsData!.bloomsDistribution.firstWhere(
      (subject) => subject.subject == _selectedSubjectForBlooms,
      orElse: () => _bloomsData!.bloomsDistribution.first,
    );
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Calculate max marks for Y-axis
        double maxMarks = 100.0; // Default fallback
        if (selectedSubjectData.bloomsLevels.isNotEmpty) {
          final marksList = selectedSubjectData.bloomsLevels
              .map((level) => level.marks ?? 0.0)
              .where((marks) => marks > 0)
              .toList();
          
          if (marksList.isNotEmpty) {
            maxMarks = marksList.reduce((a, b) => a > b ? a : b);
            // Add some padding to max value
            maxMarks = (maxMarks * 1.1).ceilToDouble();
          }
        }
        
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxMarks,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black.withOpacity(0.8),
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final bloomLevel = selectedSubjectData.bloomsLevels[groupIndex];
                  final marks = bloomLevel.marks ?? 0.0;
                  final score = bloomLevel.score ?? 0;
                  return BarTooltipItem(
                    '${bloomLevel.level}\n${marks.toStringAsFixed(1)} marks\n($score%)',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < selectedSubjectData.bloomsLevels.length) {
                      final level = selectedSubjectData.bloomsLevels[value.toInt()].level;
                      // Create shorter labels to prevent collision
                      String shortLabel = '';
                      switch (level.toLowerCase()) {
                        case 'remember':
                          shortLabel = 'Rem';
                          break;
                        case 'understand':
                          shortLabel = 'Und';
                          break;
                        case 'apply':
                          shortLabel = 'App';
                          break;
                        case 'analyze':
                          shortLabel = 'Ana';
                          break;
                        case 'evaluate':
                          shortLabel = 'Eva';
                          break;
                        case 'create':
                          shortLabel = 'Cre';
                          break;
                        default:
                          shortLabel = level.length > 3 ? level.substring(0, 3) : level;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          shortLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _calculateGridInterval(maxMarks),
                  getTitlesWidget: (value, meta) {
                    // Show labels at regular intervals
                    double interval = _calculateGridInterval(maxMarks);
                    if (value % interval == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              horizontalInterval: _calculateGridInterval(maxMarks),
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: List.generate(selectedSubjectData.bloomsLevels.length, (index) {
              final bloomLevel = selectedSubjectData.bloomsLevels[index];
              final colors = [
                Colors.red,      // Remember
                Colors.orange,   // Understand  
                Colors.yellow,   // Apply
                Colors.green,    // Analyze
                Colors.blue,     // Evaluate
                Colors.purple,   // Create
              ];
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: (bloomLevel.marks ?? 0.0) * value,
                    color: colors[index % colors.length],
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxMarks,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              );
            }),
          ),
          swapAnimationDuration: const Duration(milliseconds: 750),
          swapAnimationCurve: Curves.easeInOutQuint,
        );
      },
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<String> subjects;
  final List<double> scores;
  final double maxScore;
  final Color backgroundColor;
  final Color fillColor;
  final Color lineColor;
  final List<Color>? colors;
  final BuildContext context;
  
  // Define paint objects once to avoid recreating them
  late final Paint _backgroundPaint;
  late final Paint _fillPaint;
  late final Paint _linePaint;
  late final Paint _axisPaint;
  late final Paint _pointOutlinePaint;
  late final Paint _pointFillPaint;

  RadarChartPainter({
    required this.subjects,
    required this.scores,
    required this.maxScore,
    required this.backgroundColor,
    required this.fillColor,
    required this.lineColor,
    this.colors,
    required this.context,
  }) {
    // Initialize Paint objects
    _backgroundPaint = Paint()..color = backgroundColor;
    
    _fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    _linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    _axisPaint = Paint()
      ..color = Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.3) ?? 
               (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.black87)
      ..strokeWidth = 1;
    
    _pointOutlinePaint = Paint()
      ..color = Theme.of(context).textTheme.bodyLarge!.color ?? 
               (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    
    _pointFillPaint = Paint()
      ..color = lineColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25; // Decreased from 0.35 to make the chart smaller
    
    // Draw background
    canvas.drawCircle(center, radius, _backgroundPaint);
    
    // Draw concentric circles
    for (int i = 1; i <= 5; i++) {
      final circleRadius = radius * (i / 5);
      final concCirclePaint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.1) : Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, circleRadius, concCirclePaint);
    }
    
    // Draw polygon for each data point
    final points = <Offset>[];
    final sides = subjects.length;
    
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final scoreRatio = scores[i] / maxScore;
      final pointRadius = radius * scoreRatio;
      
      final dx = center.dx + pointRadius * math.cos(angle);
      final dy = center.dy + pointRadius * math.sin(angle);
      
      points.add(Offset(dx, dy));
    }
    
    // Draw filled polygon
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, _fillPaint);
    
    // Draw polygon outline
    canvas.drawPath(path, _linePaint);
    
    // Draw axis lines and labels
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      
      canvas.drawLine(center, Offset(dx, dy), _axisPaint);
      
      // Draw subject labels with offset adjustment if provided
      double offsetX = 0;
      double offsetY = 0;
      
      if (colors != null && i < colors!.length) {
        offsetX = radius * 0.2 * 0.5;
      }
      
      final labelDx = center.dx + (radius + 20) * math.cos(angle) + offsetX;
      final labelDy = center.dy + (radius + 20) * math.sin(angle) + offsetY;
      
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.text = TextSpan(
        text: subjects[i],
        style: TextStyle(
          color: colors != null ? colors![i] : Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelDx - textPainter.width / 2,
          labelDy - textPainter.height / 2,
        ),
      );
    }
    
    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, _pointOutlinePaint);
      canvas.drawCircle(point, 3, _pointFillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}