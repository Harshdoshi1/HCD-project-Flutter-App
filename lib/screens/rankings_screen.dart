import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key}) : super(key: key);

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<String> studentNames = [
    'Harsh Doshi',
    'Krish Mamtora',
    'Rishit Rathod',
    'Ritesh Sanchala',
    'Fenil Vadher',
    'Umnag Hirani',
    'Jay Mangukiya',
    'Aryan Mahida',
    'Harshvardhan Soni'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.only(
            top: kToolbarHeight - 20,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Rankings',
                    style: TextStyle(
                      color: AppTheme.onPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: _slideAnimation,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.onPrimaryColor,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Academic'),
                    Tab(text: 'Non-Academic'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAcademicRankings(),
              _buildNonAcademicRankings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicRankings() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: studentNames.length,
          itemBuilder: (context, index) {
            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: index < 3 ? AppTheme.secondaryColor : Colors.grey[700],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.onPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  studentNames[index],
                  style: const TextStyle(
                    color: AppTheme.onBackgroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'SGPA: ${(9.5 - index * 0.2).toStringAsFixed(2)}',
                      style: TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                    Text(
                      'Department: Computer Science',
                      style: TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNonAcademicRankings() {
    final activities = [
      {'name': 'Sports', 'points': 150},
      {'name': 'Cultural', 'points': 120},
      {'name': 'Technical', 'points': 100},
      {'name': 'Social Service', 'points': 90},
      {'name': 'Innovation', 'points': 85},
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: studentNames.length,
          itemBuilder: (context, index) {
            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: index < 3 ? AppTheme.secondaryColor : Colors.grey[700],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.onPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  studentNames[index],
                  style: const TextStyle(
                    color: AppTheme.onBackgroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Activity Points: ${300 - index * 25}',
                      style: TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                    Text(
                      'Top Activity: ${activities[index % activities.length]['name']}',
                      style: TextStyle(color: AppTheme.onBackgroundColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
