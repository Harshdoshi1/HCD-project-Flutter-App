import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import '../providers/user_provider.dart';
import '../services/academic_service.dart';
import 'profile_screen.dart';
import '../constants/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const DashboardScreen({Key? key, required this.toggleTheme}) : super(key: key);

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
  String _activeGraph = 'sgpa';
  late AnimationController _graphAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  Future<void> _loadUserData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        setState(() {
          _userName = user.name;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

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
              Uri.parse('http://localhost:5001/api/events/fetchTotalActivityPoints'),
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
          
          // Then, fetch detailed activities data
          try {
            final response = await http.post(
              Uri.parse('http://localhost:5001/api/events/fetchEventsbyEnrollandSemester'),
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
              } else if (data is Map) {
                // Handle case when API returns a map instead of a list
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
            print('Error fetching activities: $e');
            setState(() {
              _isLoadingActivityPoints = false;
            });
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

  @override
  void initState() {
    super.initState();
    _loadSPIData();
    _loadActivityPoints();
    _graphAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _graphAnimationController, 
        curve: Curves.easeIn
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _graphAnimationController, curve: Curves.easeOut),
    );

    _graphAnimationController.forward();
    
    // Set random daily quote
    _dailyQuote = _dailyQuotes[DateTime.now().day % _dailyQuotes.length];
    
    // Load user data from shared preferences
    _loadUserData();
  }

  @override
  void dispose() {
    _graphAnimationController.dispose();
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
                stops: [0.0, 0.3],
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
                          Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Text(
                              '"${_dailyQuote}"',
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
                          setState(() {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  toggleTheme: widget.toggleTheme,
                                ),
                              ),
                            );
                          });
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
        _buildIconButton('Subjects', Icons.radar, _activeGraph == 'subjects', () => _switchGraph('subjects')),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF03A9F4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForTitle(title),
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                    badgeWidget: Text(
                      data['domain'],
                      style: TextStyle(
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
                              style: TextStyle(
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF03A9F4),
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
                _buildInfoRow('Current CGPA', '8.8'),
                _buildInfoRow('Current Semester', '6th'),
                _buildInfoRow('Academic Rank', '5th'),
                _buildInfoRow('Non-Academic Rank', '3rd'),
                _buildInfoRow('Overall Rank', '4th'),
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
      case 'subjects':
        return 'Subject Performance';
      case 'activities':
        return 'Activity Points';
      case 'semesters':
        return 'All Semester SPIs';
      default:
        return 'Performance Overview';
    }
  }

  Widget _getActiveChart() {
    switch (_activeGraph) {
      case 'subjects':
        return _buildAnimatedRadarChart(); 
      case 'activities':
        return _buildActivityPointsChart();
      case 'semesters':
        return _buildSemesterSPIChart();
      default:
        return _buildAnimatedRadarChart(); // Default to subjects chart
    }
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
              child: Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey[400]),
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
    
    // Group activities by type
    final coCurricularActivities = _activities.where((activity) => activity['eventType'] == 'co-curricular').toList();
    final extraCurricularActivities = _activities.where((activity) => activity['eventType'] == 'extra-curricular').toList();
    
    // Colors for the pie chart sections with gradient effects
    final Color cocurricularColor = const Color(0xFF4CAF50); // Green
    final Color extracurricularColor = const Color(0xFF2196F3); // Blue
    
    // Calculate percentages
    final totalPoints = _cocurricularPoints + _extracurricularPoints;
    final cocurricularPercentage = (_cocurricularPoints / totalPoints * 100).toStringAsFixed(1);
    final extracurricularPercentage = (_extracurricularPoints / totalPoints * 100).toStringAsFixed(1);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Enhanced pie chart with card wrapper
          Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Activity Points Distribution',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Animated pie chart
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Animated pie chart
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                sections: [
                                  PieChartSectionData(
                                    color: cocurricularColor,
                                    value: _cocurricularPoints.toDouble() * value,
                                    title: '$cocurricularPercentage%',
                                    radius: 90,
                                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    badgeWidget: _cocurricularPoints > _extracurricularPoints ? 
                                        _buildBadge(Icons.emoji_events, cocurricularColor) : null,
                                    badgePositionPercentageOffset: 1.1,
                                  ),
                                  PieChartSectionData(
                                    color: extracurricularColor,
                                    value: _extracurricularPoints.toDouble() * value,
                                    title: '$extracurricularPercentage%',
                                    radius: 90,
                                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    badgeWidget: _extracurricularPoints > _cocurricularPoints ? 
                                        _buildBadge(Icons.emoji_events, extracurricularColor) : null,
                                    badgePositionPercentageOffset: 1.1,
                                  ),
                                ],
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 750),
                              swapAnimationCurve: Curves.easeInOutQuint,
                            ),
                            
                            // Center total counter
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                  ),
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Enhanced legend cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Co-curricular card
                      _buildLegendCard(
                        'Co-curricular',
                        _cocurricularPoints,
                        cocurricularColor,
                        Icons.school,
                        '$cocurricularPercentage%',
                      ),
                      
                      // Extra-curricular card
                      _buildLegendCard(
                        'Extra-curricular',
                        _extracurricularPoints,
                        extracurricularColor,
                        Icons.sports_soccer,
                        '$extracurricularPercentage%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Total points display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cocurricularColor.withOpacity(0.8), extracurricularColor.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              'Total: ${_cocurricularPoints + _extracurricularPoints} points',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          
          // Activity Breakdown
          Text(
            'Activities Breakdown',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Co-curricular Activities
          if (coCurricularActivities.isNotEmpty) ...[  
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Co-curricular Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: coCurricularActivities.length,
              itemBuilder: (context, index) {
                final activity = coCurricularActivities[index];
                return _buildActivityItem(
                  activity['eventName'] ?? 'Unknown Activity',
                  activity['eventDate'] != null ? DateTime.parse(activity['eventDate']).toString().substring(0, 10) : 'Unknown Date',
                  activity['participationType'] ?? 'Participant',
                  int.parse(activity['totalCocurricular']?.toString() ?? '0'),
                  cocurricularColor,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Extra-curricular Activities
          if (extraCurricularActivities.isNotEmpty) ...[  
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Extra-curricular Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: extraCurricularActivities.length,
              itemBuilder: (context, index) {
                final activity = extraCurricularActivities[index];
                return _buildActivityItem(
                  activity['eventName'] ?? 'Unknown Activity',
                  activity['eventDate'] != null ? DateTime.parse(activity['eventDate']).toString().substring(0, 10) : 'Unknown Date',
                  activity['participationType'] ?? 'Participant',
                  int.parse(activity['totalExtracurricular']?.toString() ?? '0'),
                  extracurricularColor,
                );
              },
            ),
          ],
          
          // If no activities are available
          if (_activities.isEmpty) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No detailed activity data available',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildAnimatedRadarChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        return SizedBox(
          height: 150, // Decreased from 200 to make it even smaller
          child: CustomPaint(
            painter: RadarChartPainter(
              subjects: ['HCD', 'OT', 'SE', 'AWT', 'CC', 'AJ'],
              scores: [
                85 * _graphAnimationController.value,
                75 * _graphAnimationController.value,
                80 * _graphAnimationController.value,
                70 * _graphAnimationController.value,
                65 * _graphAnimationController.value,
                85 * _graphAnimationController.value,
              ],
              maxScore: 100,
              backgroundColor: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
              lineColor: const Color(0xFF03A9F4),
              fillColor: const Color(0xFF03A9F4).withOpacity(0.2),
              colors: [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red, Colors.teal],
              context: context,
            ),
            size: const Size(double.infinity, 150), // Decreased from 200 to make it even smaller
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
                          text: '${(rod.toY * value).toStringAsFixed(1)}',
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
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
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
    final radius = size.width * 0.35; // Decreased from 0.4
    
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