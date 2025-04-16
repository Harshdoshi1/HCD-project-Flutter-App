import 'package:flutter/material.dart';
import 'dart:ui';
import 'dashboard.dart';
import 'subjects_screen.dart';
import 'rankings_screen.dart';
import 'profile_screen.dart';

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
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> pages = [
      DashboardScreen(toggleTheme: widget.toggleTheme),
      SubjectsScreen(toggleTheme: widget.toggleTheme),
      RankingsScreen(toggleTheme: widget.toggleTheme),
      ProfileScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: isDark,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
              selectedItemColor: const Color(0xFF03A9F4),
              unselectedItemColor: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
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
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}