import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dashboard.dart';
import 'subjects_screen.dart';
import 'rankings_screen.dart';
import 'profile_screen.dart';
import 'activities_screen.dart';
import 'parent_dashboard.dart';
import 'parent_subjects_ranking.dart';
import 'parent_profile_screen.dart';
import '../models/user_model.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback toggleTheme;
  final int initialTabIndex;
  
  const MainNavigation({
    Key? key, 
    required this.toggleTheme,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  User? _currentUser;
  bool _isParent = false;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _loadUserRole();
  }
  
  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        _currentUser = User.fromJson(userData);
        setState(() {
          _isParent = _currentUser?.role == 'parent';
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Role-based pages
    final List<Widget> pages = _isParent ? [
      ParentDashboardScreen(toggleTheme: widget.toggleTheme),
      ParentSubjectsRankingScreen(toggleTheme: widget.toggleTheme),
      ParentProfileScreen(toggleTheme: widget.toggleTheme, isDarkMode: isDark),
    ] : [
      DashboardScreen(toggleTheme: widget.toggleTheme),
      SubjectsScreen(toggleTheme: widget.toggleTheme),
      RankingsScreen(toggleTheme: widget.toggleTheme),
      ActivitiesScreen(toggleTheme: widget.toggleTheme),
      ProfileScreen(
        toggleTheme: widget.toggleTheme,
      ),
    ];
    
    // Adjust selected index for parent (fewer tabs)
    if (_isParent && _selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                selectedItemColor: const Color(0xFF03A9F4),
                unselectedItemColor: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: _isParent ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.school),
                    label: 'Subjects',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ] : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book),
                    label: 'Subjects',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.leaderboard),
                    label: 'Rankings',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.event),
                    label: 'Activities',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
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