import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/api_config.dart';

class ParentCommunicationScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentCommunicationScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ParentCommunicationScreenState createState() => _ParentCommunicationScreenState();
}

class _ParentCommunicationScreenState extends State<ParentCommunicationScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _studentName = 'Student';
  bool _isLoading = true;
  String? _error;
  
  List<Map<String, dynamic>> _facultyMessages = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _monthlyReports = [];

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
    _loadCommunicationData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunicationData() async {
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
        });
        
        await _fetchCommunicationData(user.email, user.enrollmentNumber);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('userData');
        
        if (userData != null) {
          final decodedData = json.decode(userData);
          setState(() {
            _studentName = decodedData['name'] ?? 'Student';
          });
          
          final email = decodedData['email'];
          final enrollment = decodedData['enrollmentNumber'];
          if (email != null && enrollment != null) {
            await _fetchCommunicationData(email, enrollment);
          }
        }
      }
      
      // Generate mock data for demonstration
      _generateMockData();
      
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

  Future<void> _fetchCommunicationData(String email, String enrollment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        // In a real implementation, you would fetch from actual endpoints
        // For now, we'll use mock data
        debugPrint('Fetching communication data for: $email');
      }
    } catch (e) {
      debugPrint('Error fetching communication data: $e');
    }
  }

  void _generateMockData() {
    // Only show real announcements - remove mock faculty messages
    _facultyMessages = [];

    // Keep only general announcements that would be real
    _announcements = [
      {
        'id': '1',
        'title': 'No New Announcements',
        'content': 'Check back later for college announcements and updates.',
        'date': DateTime.now().toString().split(' ')[0],
        'category': 'General',
        'priority': 'low',
        'author': 'System',
      },
    ];

    // Remove mock monthly reports - these should come from real API
    _monthlyReports = [];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
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
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Communication Center',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingWidget(isDark)
                        : _error != null
                            ? _buildErrorWidget(isDark)
                            : _buildContentWidget(isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF03A9F4)),
          SizedBox(height: 16),
          Text(
            'Loading communications...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
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
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading communications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCommunicationData,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF03A9F4),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Faculty Messages Card - Only show if there are messages
          if (_facultyMessages.isNotEmpty) ...[
            SlideTransition(
              position: _slideAnimation,
              child: _buildFacultyMessagesCard(isDark),
            ),
            const SizedBox(height: 16),
          ],
          
          // Announcements Card
          SlideTransition(
            position: _slideAnimation,
            child: _buildAnnouncementsCard(isDark),
          ),
          const SizedBox(height: 16),
          
          // Monthly Reports Card - Only show if there are reports
          if (_monthlyReports.isNotEmpty) ...[
            SlideTransition(
              position: _slideAnimation,
              child: _buildMonthlyReportsCard(isDark),
            ),
            const SizedBox(height: 16),
          ],
          
          // Show message when no real data is available
          if (_facultyMessages.isEmpty && _monthlyReports.isEmpty) ...[
            SlideTransition(
              position: _slideAnimation,
              child: _buildNoDataCard(isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFacultyMessagesCard(bool isDark) {
    final unreadCount = _facultyMessages.where((msg) => !msg['read']).length;
    
    return _buildGlassCard(
      title: 'Faculty Messages',
      icon: Icons.message,
      badge: unreadCount > 0 ? unreadCount.toString() : null,
      child: Column(
        children: _facultyMessages.map((message) => _buildMessageItem(message, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isDark) {
    final isUnread = !message['read'];
    final isHighPriority = message['priority'] == 'high';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread 
            ? (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05))
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread 
              ? Colors.blue.withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isHighPriority)
                Icon(
                  Icons.priority_high,
                  color: Colors.red,
                  size: 16,
                ),
              if (isHighPriority) SizedBox(width: 4),
              Expanded(
                child: Text(
                  message['from'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              if (isUnread)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            message['subject'],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message['message'],
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message['faculty'],
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
                ),
              ),
              Text(
                message['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Announcements',
      icon: Icons.campaign,
      child: Column(
        children: _announcements.map((announcement) => _buildAnnouncementItem(announcement, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildAnnouncementItem(Map<String, dynamic> announcement, bool isDark) {
    final categoryColor = _getCategoryColor(announcement['category']);
    final isHighPriority = announcement['priority'] == 'high';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Text(
                  announcement['category'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ),
              if (isHighPriority) ...[
                SizedBox(width: 8),
                Icon(
                  Icons.priority_high,
                  color: Colors.red,
                  size: 16,
                ),
              ],
              Spacer(),
              Text(
                announcement['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            announcement['title'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            announcement['content'],
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'By: ${announcement['author']}',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportsCard(bool isDark) {
    return _buildGlassCard(
      title: 'Monthly & Semester Reports',
      icon: Icons.description,
      child: Column(
        children: _monthlyReports.map((report) => _buildReportItem(report, isDark)).toList(),
      ),
      isDark: isDark,
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['type'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      report['month'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _downloadReport(report),
                icon: Icon(Icons.download, size: 16),
                label: Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF03A9F4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            report['summary'],
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Generated: ${report['generated']}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadReport(Map<String, dynamic> report) {
    // In a real implementation, this would download the actual report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${report['type']} for ${report['month']}...'),
        backgroundColor: Color(0xFF03A9F4),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Colors.blue;
      case 'general':
        return Colors.green;
      case 'events':
        return Colors.purple;
      case 'facilities':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNoDataCard(bool isDark) {
    return _buildGlassCard(
      title: 'Communication Status',
      icon: Icons.info_outline,
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No faculty messages or reports available at this time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for updates from faculty and administration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.45),
            ),
          ),
        ],
      ),
      isDark: isDark,
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
    String? badge,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
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
                        icon,
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
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
