import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/api_config.dart';

class ActivitiesScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ActivitiesScreen({super.key, required this.toggleTheme});

  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  String? _enrollmentNumber;
  String? _studentName;
  int? _currentSemester;
  List<dynamic> _activities = [];
  int _totalCurrentCocurricular = 0;
  int _totalCurrentExtracurricular = 0;
  int _selectedTabIndex = 0; // 0 for co-curricular, 1 for extra-curricular
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _getUserData() async {
    try {
      // Get user data from provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? user = userProvider.user;
      
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (user != null && token != null) {
        print('User data from provider: ${user.name}, ${user.enrollmentNumber}');
        
        setState(() {
          _enrollmentNumber = user.enrollmentNumber;
          _studentName = user.name;
          _currentSemester = user.currentSemester;
        });
        
        if (_enrollmentNumber != null && _enrollmentNumber!.isNotEmpty) {
          await _fetchActivities();
        } else {
          setState(() {
            _error = 'Enrollment number not found in user data.';
            _isLoading = false;
          });
        }
      } else {
        // If user is not in provider, try to get it from SharedPreferences as fallback
        final userData = prefs.getString('userData');
        
        if (userData != null && token != null) {
          final decodedData = json.decode(userData);
          print('User data from SharedPreferences: $decodedData');
          
          setState(() {
            _enrollmentNumber = decodedData['enrollmentNumber'];
            _studentName = decodedData['name'];
            _currentSemester = decodedData['currentSemester'] ?? decodedData['semester'] ?? 4;
          });
          
          await _fetchActivities();
        } else {
          setState(() {
            _error = 'User data or token not found. Please log in again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        _error = 'Error getting user data: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        setState(() {
          _error = 'Authentication token not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      
      print('Fetching activities for enrollment number: $_enrollmentNumber');
      
      // First, fetch the total activity points from the endpoint
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
        
        print('Total points response status: ${pointsResponse.statusCode}');
        print('Total points response body: ${pointsResponse.body}');
        
        if (pointsResponse.statusCode == 200) {
          final pointsData = json.decode(pointsResponse.body);
          
          setState(() {
            _totalCurrentCocurricular = pointsData['totalCocurricular'] != null ? 
                int.parse(pointsData['totalCocurricular'].toString()) : 0;
            _totalCurrentExtracurricular = pointsData['totalExtracurricular'] != null ? 
                int.parse(pointsData['totalExtracurricular'].toString()) : 0;
          });
        }
      } catch (e) {
        print('Error fetching total points: $e');
        // Will fallback to calculating from events if this fails
      }
      
      // Get all semesters' activities
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
      
      // For testing - if no activities are found, create some mock data
      List<dynamic> activitiesList = [];
      
      if (allResponse.statusCode == 200) {
        final data = json.decode(allResponse.body);
        
        if (data is List && data.isNotEmpty) {
          activitiesList = data;
        } else if (data is Map && data.containsKey('message')) {
          // If there's a message but activities weren't found, add some mock data for testing
          print('Adding mock activities for testing');
          activitiesList = [
            {
              'id': 1,
              'enrollmentNumber': _enrollmentNumber,
              'semester': 4,
              'eventId': 'E001',
              'eventName': 'Debate Competition',
              'eventType': 'co-curricular',
              'eventDate': '2025-03-15',
              'totalCocurricular': 10,
              'totalExtracurricular': 0,
              'participationTypeId': 'P001',
              'participationType': 'Participant'
            },
            {
              'id': 2,
              'enrollmentNumber': _enrollmentNumber,
              'semester': 4,
              'eventId': 'E002',
              'eventName': 'Coding Marathon',
              'eventType': 'co-curricular',
              'eventDate': '2025-04-20',
              'totalCocurricular': 15,
              'totalExtracurricular': 0,
              'participationTypeId': 'P002',
              'participationType': 'Winner'
            },
            {
              'id': 3,
              'enrollmentNumber': _enrollmentNumber,
              'semester': 4,
              'eventId': 'E003',
              'eventName': 'Annual Sports Meet',
              'eventType': 'extra-curricular',
              'eventDate': '2025-02-10',
              'totalCocurricular': 0,
              'totalExtracurricular': 10,
              'participationTypeId': 'P001',
              'participationType': 'Participant'
            },
            {
              'id': 4,
              'enrollmentNumber': _enrollmentNumber,
              'semester': 6,
              'eventId': 'E004',
              'eventName': 'College Fest',
              'eventType': 'extra-curricular',
              'eventDate': '2025-05-01',
              'totalCocurricular': 0,
              'totalExtracurricular': 20,
              'participationTypeId': 'P003',
              'participationType': 'Organizer'
            }
          ];
          
          // Update totals based on mock data if we didn't get real totals
          if (_totalCurrentCocurricular == 0 && _totalCurrentExtracurricular == 0) {
            int totalCC = 0;
            int totalEC = 0;
            
            for (var activity in activitiesList) {
              if (activity['semester'] == _currentSemester) {
                totalCC += int.parse(activity['totalCocurricular']?.toString() ?? '0');
                totalEC += int.parse(activity['totalExtracurricular']?.toString() ?? '0');
              }
            }
            
            setState(() {
              _totalCurrentCocurricular = totalCC;
              _totalCurrentExtracurricular = totalEC;
            });
          }
        }
      }
      
      setState(() {
        _activities = activitiesList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching activities: $e');
      setState(() {
        _error = 'Error fetching activities: $e';
        _isLoading = false;
      });
    }
  }
  
  // Get co-curricular activities only
  List<dynamic> get _coCurricularActivities {
    return _activities.where((activity) => 
      activity['eventType'] == 'co-curricular').toList();
  }
  
  // Get extra-curricular activities only
  List<dynamic> get _extraCurricularActivities {
    return _activities.where((activity) => 
      activity['eventType'] == 'extra-curricular').toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
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
                // App bar with back button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'My Activities',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.wb_sunny : Icons.nightlight_round,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: widget.toggleTheme,
                      ),
                    ],
                  ),
                ),

                // Student info card
                if (_studentName != null && _enrollmentNumber != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentName ?? 'Student',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enrollment: $_enrollmentNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Semester: $_currentSemester',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CC/EC buttons
                Container(
                  margin: const EdgeInsets.all(16.0),
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      // Co-curricular button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 0;
                              _tabController.animateTo(0);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: _selectedTabIndex == 0
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                'Co-Curricular',
                                style: TextStyle(
                                  color: _selectedTabIndex == 0
                                    ? Colors.blue
                                    : isDark ? Colors.white70 : Colors.black54,
                                  fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Extra-curricular button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 1;
                              _tabController.animateTo(1);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: _selectedTabIndex == 1
                                ? Colors.green.withOpacity(0.2)
                                : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                'Extra-Curricular',
                                style: TextStyle(
                                  color: _selectedTabIndex == 1
                                    ? Colors.green
                                    : isDark ? Colors.white70 : Colors.black54,
                                  fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Points summary
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Total Co-Curricular',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalCurrentCocurricular',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: isDark ? Colors.white30 : Colors.black12,
                      ),
                      Column(
                        children: [
                          Text(
                            'Total Extra-Curricular',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalCurrentExtracurricular',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.black.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF03A9F4).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        dividerColor: Colors.transparent,
                        labelColor: isDark ? Colors.white : Colors.black,
                        unselectedLabelColor: isDark 
                            ? Colors.white.withOpacity(0.6) 
                            : Colors.black.withOpacity(0.6),
                        tabs: const [
                          Tab(text: 'Co-Curricular'),
                          Tab(text: 'Extra-Curricular'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildErrorWidget()
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildActivityList(_coCurricularActivities, "Co-Curricular"),
                                _buildActivityList(_extraCurricularActivities, "Extra-Curricular"),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Activities',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchActivities();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(List<dynamic> activities, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type Activities Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity, isDark);
      },
    );
  }
  
  Widget _buildActivityCard(dynamic activity, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark 
          ? Colors.white.withOpacity(0.1) 
          : Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark 
              ? Colors.white.withOpacity(0.2) 
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity['eventName'] ?? activity['Event_Name'] ?? activity['name'] ?? 'Unknown Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: activity['eventType'] == 'co-curricular'
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (activity['eventType'] ?? activity['Event_Type']) == 'co-curricular' 
                            ? 'CC: ${activity['totalCocurricular'] ?? activity['Total_Cocurricular'] ?? 0}' 
                            : 'EC: ${activity['totalExtracurricular'] ?? activity['Total_Extracurricular'] ?? 0}',
                        style: TextStyle(
                          color: (activity['eventType'] ?? activity['Event_Type']) == 'co-curricular'
                              ? Colors.blue
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Participation: ${activity['participationType'] ?? activity['Participation_Type'] ?? 'General'}',
                  style: TextStyle(
                    color: isDark 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semester: ${activity['semester'] ?? 'N/A'}',
                  style: TextStyle(
                    color: isDark 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${(activity['eventDate'] ?? activity['Event_Date']) != null ? _formatDate(activity['eventDate'] ?? activity['Event_Date']) : 'N/A'}',
                  style: TextStyle(
                    color: isDark 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
