import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'profile_screen.dart';
import 'student_detail_screen.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key, required this.toggleTheme}) : super(key: key);
  
  final VoidCallback toggleTheme;

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  final List<String> academicSubtitles = [
    'CGPA: 9.8 | Dept: ICT',
    'CGPA: 9.7 | Dept: ICT',
    'CGPA: 9.6 | Dept: ICT',
    'CGPA: 9.5 | Dept: ICT',
    'CGPA: 9.4 | Dept: ICT',
    'CGPA: 9.3 | Dept: ICT',
    'CGPA: 9.2 | Dept: ICT',
    'CGPA: 9.1 | Dept: ICT',
    'CGPA: 9.0 | Dept: ICT',
  ];

  final List<String> nonAcademicSubtitles = [
    'Hackathons: 12 | Projects: 8',
    'Hackathons: 10 | Projects: 9',
    'Hackathons: 9 | Projects: 7',
    'Hackathons: 8 | Projects: 8',
    'Hackathons: 7 | Projects: 6',
    'Hackathons: 6 | Projects: 7',
    'Hackathons: 5 | Projects: 5',
    'Hackathons: 4 | Projects: 6',
    'Hackathons: 3 | Projects: 4',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Rankings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
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
                          Tab(text: 'Academic'),
                          Tab(text: 'Non-Academic'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      _tabController.animateTo(index);
                    },
                    children: [
                      _buildRankingList(true),
                      _buildRankingList(false),
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

  Widget _buildRankingList(bool isAcademic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: studentNames.length,
        itemBuilder: (context, index) {
          final rank = index + 1;
          final name = studentNames[index];
          final subtitle = isAcademic ? academicSubtitles[index] : nonAcademicSubtitles[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildStudentCard(rank, name, subtitle, isDark),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(int rank, String name, String subtitle, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(
              name: name,
              rank: '#$rank',
              details: subtitle,
            ),
          ),
        );
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
                  // Rank circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getRankColor(rank).withOpacity(0.2),
                      border: Border.all(
                        color: _getRankColor(rank),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: _getRankColor(rank),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Student details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark 
                                ? Colors.white.withOpacity(0.7) 
                                : Colors.black.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) {
      return Colors.amber;
    } else if (rank == 2) {
      return Colors.grey.shade400;
    } else if (rank == 3) {
      return Colors.brown.shade300;
    } else {
      return const Color(0xFF03A9F4);
    }
  }
}
