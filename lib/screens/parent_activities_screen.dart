import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

class ParentActivitiesScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentActivitiesScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ParentActivitiesScreenState createState() => _ParentActivitiesScreenState();
}

class _ParentActivitiesScreenState extends State<ParentActivitiesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _studentName = 'Student';
  bool _isLoading = true;
  String? _error;
  String? _enrollmentNumber;
  int? _currentSemester;

  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _clubInvolvement = [];
  Map<String, int> _activitySummary = {
    'totalCocurricular': 0,
    'totalExtracurricular': 0,
    'eventsParticipated': 0,
    'clubsJoined': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadActivitiesData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadActivitiesData() async {
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
          _enrollmentNumber = user.enrollmentNumber;
          _currentSemester = user.currentSemester;
        });
        
        await _fetchActivitiesData(user.enrollmentNumber);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('userData');
        
        if (userData != null) {
          final decodedData = json.decode(userData);
          setState(() {
            _studentName = decodedData['name'] ?? 'Student';
            _enrollmentNumber = decodedData['enrollmentNumber'];
            _currentSemester = decodedData['currentSemester'];
          });
          
          if (_enrollmentNumber != null) {
            await _fetchActivitiesData(_enrollmentNumber!);
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
    }
  }

  Future<void> _fetchActivitiesData(String enrollmentNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && _currentSemester != null) {
        // Fetch activity points
        final pointsResponse = await http.post(
          Uri.parse('https://hcdbackend.vercel.app/api/events/fetchTotalActivityPoints'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'enrollmentNumber': enrollmentNumber}),
        );
        
        if (pointsResponse.statusCode == 200) {
          final pointsData = json.decode(pointsResponse.body);
          setState(() {
            _activitySummary['totalCocurricular'] = pointsData['totalCocurricularPoints'] ?? 0;
            _activitySummary['totalExtracurricular'] = pointsData['totalExtracurricularPoints'] ?? 0;
          });
        }

        // Fetch events by enrollment and semester
        final eventsResponse = await http.post(
          Uri.parse('https://hcdbackend.vercel.app/api/events/fetchEventsbyEnrollandSemester'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'enrollmentNumber': enrollmentNumber,
            'semester': _currentSemester,
          }),
        );
        
        if (eventsResponse.statusCode == 200) {
          final eventsData = json.decode(eventsResponse.body);
          if (eventsData != null && eventsData['events'] != null) {
            final List<dynamic> events = eventsData['events'];
            
            _processEventsData(events);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching activities data: $e');
    }
  }

  void _processEventsData(List<dynamic> events) {
    final List<Map<String, dynamic>> achievements = [];
    final Set<String> clubs = {};
    
    for (var event in events) {
      // Create achievement entries
      achievements.add({
        'title': event['eventName'] ?? 'Unknown Event',
        'type': event['eventType'] ?? 'Activity',
        'date': event['eventDate'] ?? '',
        'points': event['points'] ?? 0,
        'description': event['eventDescription'] ?? 'No description available',
        'category': event['eventType']?.toLowerCase().contains('co') == true ? 'Co-curricular' : 'Extra-curricular',
      });
      
      // Track unique clubs/organizations
      if (event['organizingClub'] != null && event['organizingClub'].toString().isNotEmpty) {
        clubs.add(event['organizingClub']);
      }
    }
    
    // Sort achievements by date (most recent first)
    achievements.sort((a, b) {
      if (a['date'] == null || b['date'] == null) return 0;
      return b['date'].compareTo(a['date']);
    });
    
    // Create club involvement data
    final List<Map<String, dynamic>> clubInvolvement = clubs.map((club) {
      final clubEvents = events.where((event) => event['organizingClub'] == club).toList();
      final totalPoints = clubEvents.fold<int>(0, (sum, event) => sum + ((event['points'] ?? 0) as int));
      
      return {
        'clubName': club,
        'eventsCount': clubEvents.length,
        'totalPoints': totalPoints,
        'lastActivity': clubEvents.isNotEmpty ? clubEvents.first['eventDate'] : '',
      };
    }).toList();
    
    setState(() {
      _achievements = achievements.take(10).toList(); // Show latest 10 achievements
      _clubInvolvement = clubInvolvement;
      _activitySummary['eventsParticipated'] = events.length;
      _activitySummary['clubsJoined'] = clubs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$_studentName\'s Activities',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget(isDark)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(isDark),
                          const SizedBox(height: 20),
                          _buildAchievementTimeline(isDark),
                          const SizedBox(height: 20),
                          _buildClubInvolvement(isDark),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
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
            'Failed to load activities data',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadActivitiesData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.9),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Co-curricular Points',
                      _activitySummary['totalCocurricular'].toString(),
                      Icons.school,
                      Colors.blue,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Extra-curricular Points',
                      _activitySummary['totalExtracurricular'].toString(),
                      Icons.sports,
                      Colors.green,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Events Participated',
                      _activitySummary['eventsParticipated'].toString(),
                      Icons.event,
                      Colors.orange,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Clubs Joined',
                      _activitySummary['clubsJoined'].toString(),
                      Icons.group,
                      Colors.purple,
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTimeline(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_achievements.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No achievements yet',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  return _buildAchievementItem(_achievements[index], isDark);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement, bool isDark) {
    final Color categoryColor = achievement['category'] == 'Co-curricular' 
        ? Colors.blue 
        : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievement['category'] == 'Co-curricular' 
                  ? Icons.school 
                  : Icons.sports,
              color: categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: categoryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (achievement['date'] != null && achievement['date'].isNotEmpty)
                  Text(
                    _formatDate(achievement['date']),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${achievement['points']} pts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubInvolvement(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Club Involvement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_clubInvolvement.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No club activities yet',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clubInvolvement.length,
                itemBuilder: (context, index) {
                  return _buildClubItem(_clubInvolvement[index], isDark);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubItem(Map<String, dynamic> club, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.group,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club['clubName'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${club['eventsCount']} events participated',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${club['totalPoints']} pts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
