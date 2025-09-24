import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class ParentActivitiesScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const ParentActivitiesScreen({super.key, required this.toggleTheme});

  @override
  _ParentActivitiesScreenState createState() => _ParentActivitiesScreenState();
}

class _ParentActivitiesScreenState extends State<ParentActivitiesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Assignments', 'Events', 'Announcements', 'Exams'];
  
  // Activity statistics from database
  Map<String, int>? _activityStats;
  bool _isLoadingStats = true;
  String? _statsError;
  
  // Recent activities data from database
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingActivities = true;
  String? _activitiesError;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    
    // Fetch real data from database
    _fetchActivityData();
  }

  // Fetch activity statistics and recent activities from database
  Future<void> _fetchActivityData() async {
    try {
      setState(() {
        _isLoadingStats = true;
        _isLoadingActivities = true;
        _statsError = null;
        _activitiesError = null;
      });
      
      // Simulate API call - replace with actual database call
      await Future.delayed(const Duration(seconds: 2));
      
      // In real implementation, this would be:
      // final stats = await ActivityService.getActivityStatistics();
      // final activities = await ActivityService.getCompletedActivities();
      
      // For now, simulate no data available from database
      setState(() {
        _activityStats = null; // No data available
        _recentActivities = []; // No activities available
        _isLoadingStats = false;
        _isLoadingActivities = false;
        _statsError = 'No activity statistics available from database';
        _activitiesError = 'No completed activities found in database';
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
        _isLoadingActivities = false;
        _statsError = 'Failed to fetch activity statistics';
        _activitiesError = 'Failed to fetch activity data';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get completed/graded activities only from database
  List<Map<String, dynamic>> get _completedActivities {
    // Filter to show only completed/graded activities, not upcoming ones
    return _recentActivities.where((activity) => 
      activity['status'] == 'Completed' || 
      activity['status'] == 'Graded' ||
      activity['grade'] != null
    ).toList();
  }

  List<Map<String, dynamic>> get _filteredActivities {
    final completed = _completedActivities;
    if (_selectedFilter == 'All') {
      return completed;
    }
    return completed.where((activity) => 
      activity['type'].toString().toLowerCase().contains(_selectedFilter.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Student Activities',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SlideTransition(
                              position: _slideAnimation,
                              child: SizedBox(
                                height: 36,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _filterOptions.map((filter) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: _buildFilterChip(filter),
                                      );
                                    }).toList(),
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
              ),
              // Activities content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics containers
                          _buildActivityStatistics(isDark),
                          const SizedBox(height: 24),
                          
                          // Recent Activities section
                          _buildRecentActivitiesSection(isDark),
                          const SizedBox(height: 24),
                          
                          // All Activities section
                          _buildAllActivitiesSection(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF03A9F4).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF03A9F4)
                : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
            width: 1,
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected 
                ? const Color(0xFF03A9F4)
                : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Widget for no activities state
  Widget _buildNoActivitiesMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage,
              size: 60,
              color: isDark 
                  ? Colors.white.withOpacity(0.5) 
                  : Colors.black.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No completed activities',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activitiesError ?? 'No graded activities available from database',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark 
                    ? Colors.white.withOpacity(0.7) 
                    : Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build activity card
  Widget _buildActivityCard(Map<String, dynamic> activity, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueDate = activity['dueDate'] as DateTime;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    
    // Determine urgency color
    Color urgencyColor = Colors.grey;
    if (daysUntilDue <= 1) {
      urgencyColor = Colors.red;
    } else if (daysUntilDue <= 3) {
      urgencyColor = Colors.orange;
    } else if (daysUntilDue <= 7) {
      urgencyColor = Colors.amber;
    } else {
      urgencyColor = Colors.green;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          _showActivityDetails(activity, context);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.black.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Activity icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (activity['color'] as Color).withOpacity(0.2),
                        border: Border.all(
                          color: activity['color'] as Color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Activity details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity['title'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: urgencyColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: urgencyColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  activity['priority'],
                                  style: TextStyle(
                                    color: urgencyColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['subject'],
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.black.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: isDark 
                                    ? Colors.white.withOpacity(0.5) 
                                    : Colors.black.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysUntilDue == 0 
                                    ? 'Due today'
                                    : daysUntilDue == 1
                                        ? 'Due tomorrow'
                                        : 'Due in $daysUntilDue days',
                                style: TextStyle(
                                  color: urgencyColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF03A9F4).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activity['status'],
                                  style: const TextStyle(
                                    color: Color(0xFF03A9F4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Arrow icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white : Colors.black,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityDetails(Map<String, dynamic> activity, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueDate = activity['dueDate'] as DateTime;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.9) 
                  : Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Activity header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (activity['color'] as Color).withOpacity(0.2),
                        border: Border.all(
                          color: activity['color'] as Color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['subject'],
                            style: TextStyle(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.7) 
                                  : Colors.black.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Activity details
                _buildDetailRow('Type', activity['type'], Icons.category, isDark),
                _buildDetailRow('Status', activity['status'], Icons.info_outline, isDark),
                _buildDetailRow('Priority', activity['priority'], Icons.flag, isDark),
                _buildDetailRow(
                  'Due Date', 
                  '${dueDate.day}/${dueDate.month}/${dueDate.year}', 
                  Icons.calendar_today, 
                  isDark
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity['description'],
                  style: TextStyle(
                    color: isDark 
                        ? Colors.white.withOpacity(0.8) 
                        : Colors.black.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03A9F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF03A9F4),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.black.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build activity statistics containers
  Widget _buildActivityStatistics(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Overview',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingStats
            ? _buildLoadingStats(isDark)
            : Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Co-Curricular',
                      _activityStats?['coCurricular']?.toString() ?? 'Unavailable',
                      Icons.school,
                      Colors.blue,
                      isDark,
                      'Sports, Competitions, Academic Events',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Extra-Curricular',
                      _activityStats?['extraCurricular']?.toString() ?? 'Unavailable',
                      Icons.groups,
                      Colors.purple,
                      isDark,
                      'Clubs, Volunteering, Cultural Activities',
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // Build individual stat card
  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
    bool isDark,
    String description,
  ) {
    final isUnavailable = count == 'Unavailable' || _statsError != null;
    
    return GestureDetector(
      onTap: () => _showStatDetails(title, count, description, color, isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnavailable 
                    ? Colors.grey.withOpacity(0.3)
                    : color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnavailable 
                            ? Colors.grey.withOpacity(0.2)
                            : color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isUnavailable ? Icons.error_outline : icon,
                        color: isUnavailable ? Colors.grey : color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnavailable 
                            ? Colors.grey.withOpacity(0.1)
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUnavailable ? 'Unavailable' : 'Active',
                        style: TextStyle(
                          color: isUnavailable ? Colors.grey : color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isUnavailable ? 'N/A' : count,
                  style: TextStyle(
                    color: isUnavailable 
                        ? Colors.grey 
                        : (isDark ? Colors.white : Colors.black),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isUnavailable 
                        ? Colors.grey
                        : (isDark 
                            ? Colors.white.withOpacity(0.8) 
                            : Colors.black.withOpacity(0.8)),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUnavailable 
                      ? 'Data unavailable from database'
                      : 'Activities completed',
                  style: TextStyle(
                    color: isUnavailable 
                        ? Colors.grey
                        : (isDark 
                            ? Colors.white.withOpacity(0.6) 
                            : Colors.black.withOpacity(0.6)),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build recent activities section
  Widget _buildRecentActivitiesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activities',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to full activities list
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF03A9F4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _isLoadingActivities
              ? _buildLoadingActivities(isDark)
              : _completedActivities.isEmpty
                  ? _buildNoRecentActivities(isDark)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _completedActivities.length,
                      itemBuilder: (context, index) {
                        final activity = _completedActivities[index];
                        return _buildRecentActivityCard(activity, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  // Build recent activity card
  Widget _buildRecentActivityCard(Map<String, dynamic> activity, bool isDark) {
    final date = activity['date'] as DateTime;
    final daysAgo = DateTime.now().difference(date).inDays;
    final isUnavailable = activity['status'] == 'Unavailable';
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _showRecentActivityDetails(activity, isDark),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnavailable 
                      ? Colors.grey.withOpacity(0.3)
                      : (activity['color'] as Color).withOpacity(0.3),
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
                        decoration: BoxDecoration(
                          color: isUnavailable 
                              ? Colors.grey.withOpacity(0.2)
                              : (activity['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          color: isUnavailable 
                              ? Colors.grey
                              : activity['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnavailable 
                              ? Colors.grey.withOpacity(0.2)
                              : const Color(0xFF03A9F4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity['type'],
                          style: TextStyle(
                            color: isUnavailable 
                                ? Colors.grey
                                : const Color(0xFF03A9F4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activity['title'],
                    style: TextStyle(
                      color: isUnavailable 
                          ? Colors.grey
                          : (isDark ? Colors.white : Colors.black),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity['description'],
                    style: TextStyle(
                      color: isUnavailable 
                          ? Colors.grey.withOpacity(0.7)
                          : (isDark 
                              ? Colors.white.withOpacity(0.7) 
                              : Colors.black.withOpacity(0.7)),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isUnavailable 
                            ? Colors.grey
                            : (isDark 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.black.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUnavailable 
                            ? 'No data'
                            : daysAgo == 0 
                                ? 'Today'
                                : '$daysAgo days ago',
                        style: TextStyle(
                          color: isUnavailable 
                              ? Colors.grey
                              : (isDark 
                                  ? Colors.white.withOpacity(0.5) 
                                  : Colors.black.withOpacity(0.5)),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (!isUnavailable && activity['points'] > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${activity['points']} pts',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build all activities section
  Widget _buildAllActivitiesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Activities',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingActivities
            ? _buildLoadingActivities(isDark)
            : _filteredActivities.isEmpty
                ? _buildNoActivitiesMessage()
                : Column(
                    children: _filteredActivities.map((activity) {
                      return _buildActivityCard(activity, context);
                    }).toList(),
                  ),
      ],
    );
  }

  // Build loading stats widget
  Widget _buildLoadingStats(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildLoadingStatCard(isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildLoadingStatCard(isDark)),
      ],
    );
  }

  Widget _buildLoadingStatCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build loading activities widget
  Widget _buildLoadingActivities(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF03A9F4),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading activities from database...',
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.black.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Build no recent activities widget
  Widget _buildNoRecentActivities(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            size: 48,
            color: isDark 
                ? Colors.white.withOpacity(0.5) 
                : Colors.black.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No completed activities',
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.black.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _activitiesError ?? 'No graded activities found in database',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.5) 
                  : Colors.black.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Show stat details modal
  void _showStatDetails(String title, String count, String description, Color color, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.9) 
                  : Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count == 'Unavailable' ? 'Data not available' : '$count activities completed',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark 
                        ? Colors.white.withOpacity(0.8) 
                        : Colors.black.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }

  // Show recent activity details
  void _showRecentActivityDetails(Map<String, dynamic> activity, bool isDark) {
    final isUnavailable = activity['status'] == 'Unavailable';
    final date = activity['date'] as DateTime;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.9) 
                  : Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: isUnavailable 
                    ? Colors.grey.withOpacity(0.3)
                    : (activity['color'] as Color).withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isUnavailable 
                          ? Colors.grey.withOpacity(0.3)
                          : (activity['color'] as Color).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnavailable 
                            ? Colors.grey.withOpacity(0.2)
                            : (activity['color'] as Color).withOpacity(0.2),
                        border: Border.all(
                          color: isUnavailable 
                              ? Colors.grey
                              : activity['color'] as Color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: isUnavailable 
                            ? Colors.grey
                            : activity['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'],
                            style: TextStyle(
                              color: isUnavailable 
                                  ? Colors.grey
                                  : (isDark ? Colors.white : Colors.black),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['type'],
                            style: TextStyle(
                              color: isUnavailable 
                                  ? Colors.grey
                                  : (isDark 
                                      ? Colors.white.withOpacity(0.7) 
                                      : Colors.black.withOpacity(0.7)),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...(!isUnavailable ? [
                  _buildDetailRow('Status', activity['status'], Icons.info_outline, isDark),
                  _buildDetailRow(
                    'Date', 
                    '${date.day}/${date.month}/${date.year}', 
                    Icons.calendar_today, 
                    isDark
                  ),
                  if (activity['points'] > 0)
                    _buildDetailRow('Points', '${activity['points']}', Icons.star, isDark),
                ] : [
                  _buildDetailRow('Status', 'Data Unavailable', Icons.error_outline, isDark),
                  _buildDetailRow('Reason', 'Server connection failed', Icons.wifi_off, isDark),
                ]),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity['description'],
                  style: TextStyle(
                    color: isUnavailable 
                        ? Colors.grey
                        : (isDark 
                            ? Colors.white.withOpacity(0.8) 
                            : Colors.black.withOpacity(0.8)),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnavailable 
                          ? Colors.grey
                          : const Color(0xFF03A9F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }
}
