import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import 'splash_screen.dart';

class ParentProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ParentProfileScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _ParentProfileScreenState createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _studentName = 'Student';
  String _parentName = 'Parent';
  String _studentEmail = '';
  String _studentEnrollment = '';
  bool _isLoading = true;
  String? _error;

  // Real student academic data from API
  Map<String, dynamic> _studentAcademicData = {
    'currentSemester': 0,
    'latestCPI': 0.0,
    'latestSPI': 0.0,
    'currentRank': 0,
    'totalStudents': 0,
    'branch': 'Information & Communication Technology',
    'batch': 'Loading...',
    'admissionYear': 'Loading...',
  };

  Map<String, dynamic> _activitySummary = {
    'totalCocurricular': 0,
    'totalExtracurricular': 0,
    'eventsParticipated': 0,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        setState(() {
          _studentName = user.name;
          _parentName = "${user.name}'s Parent";
          _studentEmail = user.email;
          _studentEnrollment = user.enrollmentNumber;
        });
        
        await _fetchAcademicData(user.email);
        await _fetchActivityData(user.enrollmentNumber);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('userData');
        
        if (userData != null) {
          final decodedData = json.decode(userData);
          setState(() {
            _studentName = decodedData['name'] ?? 'Student';
            _parentName = "${_studentName}'s Parent";
            _studentEmail = decodedData['email'] ?? '';
            _studentEnrollment = decodedData['enrollmentNumber'] ?? 'N/A';
          });
          
          final email = decodedData['email'];
          final enrollmentNumber = decodedData['enrollmentNumber'];
          
          if (email != null) {
            await _fetchAcademicData(email);
          }
          if (enrollmentNumber != null) {
            await _fetchActivityData(enrollmentNumber);
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _fetchAcademicData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        final response = await http.post(
          Uri.parse('https://hcdbackend.vercel.app/api/academic/getAcademicDataByEmail'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'email': email}),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null) {
            setState(() {
              _studentAcademicData = {
                'currentSemester': data['currentSemester'] ?? 0,
                'latestCPI': data['cpi'] ?? 0.0,
                'latestSPI': data['spi'] ?? 0.0,
                'currentRank': data['rank'] ?? 0,
                'totalStudents': data['totalStudents'] ?? 0,
                'branch': data['branch'] ?? 'Information & Communication Technology',
                'batch': data['batch'] ?? '2022-2026',
                'admissionYear': data['admissionYear'] ?? '2022',
              };
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching academic data: $e');
    }
  }

  Future<void> _fetchActivityData(String enrollmentNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        final response = await http.post(
          Uri.parse('https://hcdbackend.vercel.app/api/events/fetchTotalActivityPoints'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'enrollmentNumber': enrollmentNumber}),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null) {
            setState(() {
              _activitySummary = {
                'totalCocurricular': data['totalCocurricularPoints'] ?? 0,
                'totalExtracurricular': data['totalExtracurricularPoints'] ?? 0,
                'eventsParticipated': (data['totalCocurricularPoints'] ?? 0) + (data['totalExtracurricularPoints'] ?? 0) > 0 ? 1 : 0,
              };
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching activity data: $e');
    }
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: widget.isDarkMode ? Brightness.light : Brightness.dark,
    ));

    final theme = Theme.of(context).colorScheme;
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$_studentName\'s Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
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
                    backgroundColor: isDark ? Colors.black : Colors.white,
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
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
                        child: Text(
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
                stops: [0.0, 0.3],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: const Color(0xFF03A9F4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading student information...',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load student data',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadUserData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildProfileHeader(theme, isDark),
                              const SizedBox(height: 24),
                              _buildAnimatedInfoCard(
                                'Student Information',
                                Icons.person,
                                [
                                  _buildInfoRow('Student Name', _studentName, theme, isDark),
                                  _buildInfoRow('Email', _studentEmail, theme, isDark),
                                  _buildInfoRow('Enrollment', _studentEnrollment, theme, isDark),
                                  _buildInfoRow('Branch', _studentAcademicData['branch'], theme, isDark),
                                  _buildInfoRow('Batch', _studentAcademicData['batch'], theme, isDark),
                                ],
                                theme,
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildAnimatedInfoCard(
                                'Academic Performance',
                                Icons.school,
                                [
                                  _buildInfoRow('Current Semester', '${_studentAcademicData['currentSemester']}', theme, isDark),
                                  _buildInfoRow('Current CPI', _studentAcademicData['latestCPI'].toStringAsFixed(2), theme, isDark),
                                  _buildInfoRow('Current SPI', _studentAcademicData['latestSPI'].toStringAsFixed(2), theme, isDark),
                                  _buildInfoRow('Class Rank', '${_studentAcademicData['currentRank']} / ${_studentAcademicData['totalStudents']}', theme, isDark),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Academic performance is updated after each semester',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                theme,
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildAnimatedInfoCard(
                                'Activity Summary',
                                Icons.event,
                                [
                                  _buildInfoRow('Co-curricular Points', '${_activitySummary['totalCocurricular']}', theme, isDark),
                                  _buildInfoRow('Extra-curricular Points', '${_activitySummary['totalExtracurricular']}', theme, isDark),
                                  _buildInfoRow('Total Activity Points', '${(_activitySummary['totalCocurricular'] ?? 0) + (_activitySummary['totalExtracurricular'] ?? 0)}', theme, isDark),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Activity points reflect participation in college events and clubs',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                theme,
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildAnimatedInfoCard(
                                'Parent Access Information',
                                Icons.family_restroom,
                                [
                                  _buildInfoRow('Access Level', 'View Only', theme, isDark),
                                  _buildInfoRow('Login Role', 'Parent', theme, isDark),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.security,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Parent Account Features:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '• View academic performance and grades\n• Monitor activity participation\n• Check achievement timeline\n• Read-only access to all information',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                theme,
                                isDark,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme theme, bool isDark) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          child: Icon(
            Icons.family_restroom,
            size: 60,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _parentName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          'Parent Account',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedInfoCard(String title, IconData icon, List<Widget> children, ColorScheme theme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme theme, bool isDark) {
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
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = widget.isDarkMode;
    
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
                    'About Parent Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Ictians Parent Portal allows parents to monitor their child\'s academic progress with read-only access to:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Academic performance and grades\n• Attendance records\n• Upcoming events and deadlines\n• ICT department goals and achievements',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0 - Parent Portal',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: const Color(0xFF03A9F4),
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
}
