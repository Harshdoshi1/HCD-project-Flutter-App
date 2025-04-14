import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'dashboard.dart';
import 'subjects_screen.dart';
import 'rankings_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback toggleTheme;

  const MainNavigation({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Define the widget options dynamically to ensure toggleTheme is passed correctly
    final List<Widget> _widgetOptions = <Widget>[
      DashboardScreen(),
      SubjectsScreen(),
      RankingsScreen(toggleTheme: widget.toggleTheme),
      ProfileScreen(toggleTheme: widget.toggleTheme), // Pass toggleTheme here
    ];

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: ClipRRect(
        child: GlassmorphicContainer(
          width: MediaQuery.of(context).size.width,
          height: 80,
          borderRadius: 0,
          blur: 20,
          alignment: Alignment.bottomCenter,
          border: 0,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.1),
            ],
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
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
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue[800],
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}