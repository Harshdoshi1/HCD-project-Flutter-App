import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../providers/user_provider.dart';
import '../../../services/academic_service.dart';
import '../../utils/api_config.dart';

class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ParentDashboardScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with TickerProviderStateMixin {
  
  // Loading states
  bool _isLoading = true;
  
  // User data
  String _userName = '';
  String _studentName = '';
  String _enrollmentNumber = '';
  int? _currentSemester;
  String _dailyQuote = 'Education is the most powerful weapon which you can use to change the world.';
  
  // Academic data
  Map<String, dynamic> _academicData = {};
  
  // Activity data
  List<Map<String, dynamic>> _recentActivities = [];
  
  // Animation controllers
  late AnimationController _graphAnimationController;
  late PageController _subjectPageController;

  @override
  void initState() {
    super.initState();
    _graphAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _subjectPageController = PageController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user != null) {
        setState(() {
          _userName = user.name;
          _studentName = user.name;
          _enrollmentNumber = user.enrollmentNumber;
          _currentSemester = user.currentSemester;
        });

        // Load academic data
        final academicService = AcademicService();
        final academicData = await academicService.getAcademicDataByEmail(user.email);
        
        setState(() {
          _academicData = {
            'cpi': academicData.latestCPI,
            'spi': academicData.latestSPI,
            'semester': academicData.currentSemester,
            'rank': academicData.latestRank,
          };
        });

        // Fetch activities
        await _fetchActivities();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return;

      print('Fetching activities for enrollment number: $_enrollmentNumber');

      // Use the same approach as parent_activities_screen.dart
      // First get all semesters' activities
      final allResponse = await http.post(
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

      print('All semesters response status: ${allResponse.statusCode}');
      print('All semesters response body: ${allResponse.body}');

      if (allResponse.statusCode == 200) {
        final data = json.decode(allResponse.body);
        
        if (data is List && data.isNotEmpty) {
          // Extract event IDs from the response
          Set<String> eventIds = {};
          
          for (var item in data) {
            // Extract event IDs (CSV format)
            if (item['eventId'] != null) {
              final ids = item['eventId'].toString().split(',').map((id) => id.trim()).where((id) => id.isNotEmpty);
              eventIds.addAll(ids);
            }
          }
          
          print('Extracted event IDs: $eventIds');
          
          if (eventIds.isNotEmpty) {
            // Convert to comma-separated string as required by the API
            final eventIdsString = eventIds.join(',');
            print('Sending event IDs as string: $eventIdsString');
            
            // Fetch event details from EventMaster table
            final eventDetailsResponse = await http.post(
              Uri.parse(ApiConfig.getUrl('events/fetchEventsByIds')),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'eventIds': eventIdsString
              }),
            );
            
            print('Event details response: ${eventDetailsResponse.body}');
            
            if (eventDetailsResponse.statusCode == 200) {
              final eventDetailsData = json.decode(eventDetailsResponse.body);
              
              if (eventDetailsData['success'] == true && eventDetailsData['data'] is List) {
                List<Map<String, dynamic>> activities = [];
                
                // Process event details and create activity list
                for (var event in eventDetailsData['data']) {
                  
                  // Get individual event points from the event master table
                  final eventType = (event['eventType'] ?? event['Event_Type'] ?? 'unknown').toString().toLowerCase();
                  int eventCocurricularPoints = 0;
                  int eventExtracurricularPoints = 0;
                  String activityType = 'general';
                  
                  // Determine points based on event type
                  if (eventType.contains('co-curricular') || eventType.contains('cocurricular')) {
                    eventCocurricularPoints = int.parse(event['cocurricularPoints']?.toString() ?? event['points']?.toString() ?? '0');
                    activityType = 'co-curricular';
                  } else if (eventType.contains('extra-curricular') || eventType.contains('extracurricular')) {
                    eventExtracurricularPoints = int.parse(event['extracurricularPoints']?.toString() ?? event['points']?.toString() ?? '0');
                    activityType = 'extra-curricular';
                  } else {
                    // If type is unclear, try to get both
                    eventCocurricularPoints = int.parse(event['cocurricularPoints']?.toString() ?? '0');
                    eventExtracurricularPoints = int.parse(event['extracurricularPoints']?.toString() ?? '0');
                    
                    // If both are 0, use general points field
                    if (eventCocurricularPoints == 0 && eventExtracurricularPoints == 0) {
                      final generalPoints = int.parse(event['points']?.toString() ?? '0');
                      if (eventType.contains('co') || eventType.contains('technical') || eventType.contains('academic')) {
                        eventCocurricularPoints = generalPoints;
                        activityType = 'co-curricular';
                      } else {
                        eventExtracurricularPoints = generalPoints;
                        activityType = 'extra-curricular';
                      }
                    } else if (eventCocurricularPoints > 0) {
                      activityType = 'co-curricular';
                    } else if (eventExtracurricularPoints > 0) {
                      activityType = 'extra-curricular';
                    }
                  }
                  
                  // Use the individual event points for display
                  int displayPoints = eventCocurricularPoints > 0 ? eventCocurricularPoints : eventExtracurricularPoints;
                  
                  activities.add({
                    'title': event['eventName'] ?? event['Event_Name'] ?? 'Activity',
                    'date': event['eventDate'] ?? event['Event_Date'] ?? 'No date',
                    'type': activityType,
                    'points': displayPoints,
                    'description': event['description'] ?? event['Description'] ?? '',
                    'venue': event['eventVenue'] ?? event['venue'] ?? '',
                    'participationType': event['participationType'] ?? event['position'] ?? 'Participant',
                  });
                }
                
                // Sort by date (most recent first) and take only 5
                activities.sort((a, b) {
                  try {
                    DateTime dateA = DateTime.parse(a['date']);
                    DateTime dateB = DateTime.parse(b['date']);
                    return dateB.compareTo(dateA);
                  } catch (e) {
                    return 0;
                  }
                });
                
                setState(() {
                  _recentActivities = activities.take(5).toList();
                });
                
                print('Successfully loaded ${_recentActivities.length} recent activities');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching activities: $e');
    }
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
                  // Header with welcome message and 3-dot menu
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${_userName.isNotEmpty ? _userName : 'Parent'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_studentName.isNotEmpty)
                              Text(
                                _studentName,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            SizedBox(height: 4),
                            Text(
                              _dailyQuote,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          onSelected: (value) {
                            if (value == 'theme') {
                              widget.toggleTheme();
                            } else if (value == 'about') {
                              _showAboutDialog(context);
                            } else if (value == 'logout') {
                              _showLogoutDialog(context);
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
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 100),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _buildAcademicSummary(),
                    SizedBox(height: 16),
                    _buildRecentActivities(),
                    SizedBox(height: 16),
                    _buildQuickActions(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicSummary() {
    return _buildGlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Current CPI',
                  _academicData['cpi']?.toString() ?? 'N/A',
                  Icons.school,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Current SPI',
                  _academicData['spi']?.toString() ?? 'N/A',
                  Icons.grade,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Semester',
                  _academicData['semester']?.toString() ?? 'N/A',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Rank',
                  _academicData['rank']?.toString() ?? 'N/A',
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return _buildGlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16),
          _recentActivities.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No recent activities',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    final bool isCoCurricular = activity['type'] == 'co-curricular';
                    final Color activityColor = isCoCurricular ? Colors.blue : Colors.orange;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            activityColor.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activityColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activityColor.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: activityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: activityColor.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                isCoCurricular ? Icons.school : Icons.sports,
                                color: activityColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['title'] ?? 'Activity',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _formatDate(activity['date'] ?? 'No date'),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (activity['venue'] != null && activity['venue'].toString().isNotEmpty) ...[
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            activity['venue'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green, Colors.green.shade400],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '+${activity['points']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'points',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      if (dateString == 'No date') return dateString;
      
      DateTime date = DateTime.parse(dateString);
      List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildQuickActions() {
    return _buildGlassmorphicCard(
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Contact CC',
              Icons.phone,
              Colors.green,
              () {
                // Contact CC functionality
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              'Contact HOD',
              Icons.person,
              Colors.purple,
              () {
                // Contact HOD functionality
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.black : Colors.white,
        title: Text(
          'About',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Parent Dashboard v1.0\n\nThis app helps parents monitor their child\'s academic progress and activities.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();
      
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
