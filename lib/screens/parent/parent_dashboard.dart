import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/blooms_taxonomy_model.dart';
import '../../providers/user_provider.dart';
import '../../services/academic_service.dart';
import '../../services/profile_service.dart';
import '../../services/student_analysis_service.dart';
import '../../services/student_service.dart';
import '../../utils/api_config.dart';
import '../splash_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentDashboardScreen({super.key, required this.toggleTheme});

  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  // Activity points for the logged-in user
  int _cocurricularPoints = 0;
  int _extracurricularPoints = 0;
  bool _isLoadingActivityPoints = true;
  List<dynamic> _activities = [];
  String? _enrollmentNumber;  
  final AcademicService _academicService = AcademicService();
  final ProfileService _profileService = ProfileService();
  String? _profileImageUrl;
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
  BloomsTaxonomyModel? _bloomsModel;
  List<Map<String, dynamic>> _bloomsData = [];
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
          _bloomsModel = BloomsTaxonomyModel.fromJson(result);
          _isLoadingBlooms = false;
          
          // Extract available subjects for dropdown
          _availableSubjects = _bloomsModel?.bloomsDistribution
              .map((subject) => subject.subject)
              .toList() ?? [];
          
          // Set default selected subject
          if (_availableSubjects.isNotEmpty && _selectedSubjectForBlooms == null) {
            _selectedSubjectForBlooms = _availableSubjects.first;
          }
          
          // Convert model data to chart format
          _updateBloomsChartData();
          
          print('Loaded Bloom\'s data for ${_availableSubjects.length} subjects');
        });
      }
    } catch (e) {
      print('Error loading Bloom\'s data: $e');
      if (mounted) {
        setState(() {
          _isLoadingBlooms = false;
          _bloomsModel = null;
          _bloomsData = [];
          _availableSubjects = [];
        });
      }
    }
  }

  // Convert Bloom's taxonomy model data to chart format
  void _updateBloomsChartData() {
    if (_bloomsModel == null || _selectedSubjectForBlooms == null) {
      _bloomsData = [];
      return;
    }

    // Find the selected subject's data
    final subjectData = _bloomsModel!.bloomsDistribution
        .firstWhere((subject) => subject.subject == _selectedSubjectForBlooms,
            orElse: () => _bloomsModel!.bloomsDistribution.first);

    // Convert to chart format using the actual model structure
    _bloomsData = subjectData.bloomsLevels.map((level) {
      // Calculate percentage based on obtained vs possible marks
      double percentage = level.possible > 0 ? (level.obtained / level.possible) * 100 : 0.0;
      return {
        'level': level.level,
        'percentage': percentage,
      };
    }).toList();
  }

  // Load profile image from database
  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      
      if (userEmail != null && userEmail.isNotEmpty) {
        final imageUrl = await _profileService.getProfileImageUrl(userEmail);
        if (mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImageUrl = null;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      await _loadUserData();
    } catch (e) {
      debugPrint('Parent dashboard refresh failed: $e');
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
    
    // Load user data, SPI data, activity points, blooms data and profile image
    _loadUserData();
    _loadSPIData();
    _loadActivityPoints();
    _loadBloomsData();
    _loadProfileImage();
    
    // Set random daily quote
    _dailyQuote = _dailyQuotes[DateTime.now().day % _dailyQuotes.length];
  }

  Future<void> _logout() async {
    try {
      // Clear user data from provider
      Provider.of<UserProvider>(context, listen: false).clearUser();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (!mounted) return;
      
      // Navigate to splash screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => SplashScreen(toggleTheme: widget.toggleTheme),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                  ? Colors.black.withOpacity(0.6) 
                  : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About The Ictians',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This app is designed and created by:',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Harsh Doshi',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rishit Rathod',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Krish Mamtora',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Under guidance of Prof. CD Parmar sir',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFF03A9F4),
                          fontWeight: FontWeight.bold,
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
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
                              'Welcome,',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text('${_userName}\'s Parents', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(
                                '"$_dailyQuote"',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5), fontStyle: FontStyle.italic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                              boxShadow: [BoxShadow(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              size: 24,
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'theme') {
                              widget.toggleTheme();
                            } else if (value == 'about') {
                              _showAboutDialog(context);
                            } else if (value == 'logout') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                  title: Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _logout();
                                      },
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'theme',
                              child: ListTile(
                                leading: Icon(Icons.brightness_6),
                                title: Text('Change Theme'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'about',
                              child: ListTile(
                                leading: Icon(Icons.info),
                                title: Text('About'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: ListTile(
                                leading: Icon(Icons.logout),
                                title: Text('Logout'),
                              ),
                            ),
                          ],
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Subject slider with arrow navigation for Bloom's chart
                    if (title == 'Bloom\'s Taxonomy Analysis')
                      Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        height: 40,
                        child: _availableSubjects.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
                                      fontSize: 12
                                    ),
                                  ),
                                ),
                              )
                            : _availableSubjects.length == 1
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _availableSubjects.first.length > 18 
                                            ? '${_availableSubjects.first.substring(0, 18)}...' 
                                            : _availableSubjects.first,
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
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
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.chevron_left,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
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
                                                  style: TextStyle(
                                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
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
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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

  Widget _buildGlassInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.1) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.2) ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
              width: 1,
            ),
          ),
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
                      Icons.info_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Academic Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildInfoRow(
                    'Current CPI', 
                    _semesterSPIData.isNotEmpty 
                      ? _semesterSPIData.last['cpi'].toStringAsFixed(2)
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
                      ? '${_semesterSPIData.last['rank']}'
                      : 'N/A'
                  ),
                  _buildInfoRow(
                    'Overall Points', 
                    '${_cocurricularPoints + _extracurricularPoints}'
                  ),
                ],
              ),
            ],
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
      case 'Bloom\'s Taxonomy Analysis':
        return Icons.psychology;
      case 'All Semester SPIs':
        return Icons.insert_chart;
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
        return _buildBloomsTaxonomyChart();
    }
  }

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
    
    if (_bloomsModel == null || _bloomsModel!.bloomsDistribution.isEmpty) {
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
              'Complete assessments to see cognitive skill analysis',
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
    final selectedSubjectData = _bloomsModel!.bloomsDistribution.firstWhere(
      (subject) => subject.subject == _selectedSubjectForBlooms,
      orElse: () => _bloomsModel!.bloomsDistribution.first,
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
              .map((level) => level.marks)
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
                  final marks = bloomLevel.marks;
                  final score = bloomLevel.score;
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
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
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
                    toY: bloomLevel.marks * value,
                    color: colors[index % colors.length],
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxMarks,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
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
    
    final totalPoints = _cocurricularPoints + _extracurricularPoints;
    final cocurricularPercentage = (_cocurricularPoints / totalPoints * 100).toStringAsFixed(1);
    final extracurricularPercentage = (_extracurricularPoints / totalPoints * 100).toStringAsFixed(1);
    
    const Color cocurricularColor = Color(0xFF4CAF50);
    const Color extracurricularColor = Color(0xFF2196F3);
    
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 130,
            child: Center(
              child: SizedBox(
                width: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 25,
                            sections: [
                              PieChartSectionData(
                                color: cocurricularColor,
                                value: _cocurricularPoints.toDouble() * value,
                                title: '',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 0),
                                badgeWidget: null,
                              ),
                              PieChartSectionData(
                                color: extracurricularColor,
                                value: _extracurricularPoints.toDouble() * value,
                                title: '',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 0),
                                badgeWidget: null,
                              ),
                            ],
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 750),
                          swapAnimationCurve: Curves.easeInOutQuint,
                        ),
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
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(
                  color: cocurricularColor,
                  title: 'Cocurricular',
                  points: _cocurricularPoints,
                  percentage: cocurricularPercentage,
                ),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
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
                  if (value >= 0 && value < _semesterSPIData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'S${_semesterSPIData[value.toInt()]['semester']}',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 10,
                    ),
                  );
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
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: List.generate(_semesterSPIData.length, (index) {
            final data = _semesterSPIData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data['spi'].toDouble(),
                  color: const Color(0xFF03A9F4),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 10,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }),
          maxY: 10,
          minY: 0,
        ),
        swapAnimationDuration: const Duration(milliseconds: 750),
        swapAnimationCurve: Curves.easeInOutQuint,
      ),
    );
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
}