import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Flexible(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                },
                children: [
                  _buildAcademicRankings(),
                  _buildNonAcademicRankings(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Background container
        Container(
          width: double.infinity,
          height: kToolbarHeight + 80,
          color: const Color(0xFF03A9F4),
        ),
        // Glassmorphic overlay
        GlassmorphicContainer(
          width: double.infinity,
          height: kToolbarHeight + 80,
          borderRadius: 0,
          blur: 20,
          alignment: Alignment.center,
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Rankings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3, color: Colors.white),
                      insets: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    labelPadding: EdgeInsets.symmetric(horizontal: 24),
                    onTap: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    tabs: const [
                      Tab(text: 'Academic'),
                      Tab(text: 'Non-Academic'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicRankings() {
    return _buildRankingsList(
      title: 'Academic Rankings',
      itemBuilder: (context, index) {
        return _buildRankingCard(
          rank: index + 1,
          name: studentNames[index],
          subtitle: 'SGPA: ${(9.5 - index * 0.2).toStringAsFixed(2)}',
        );
      },
    );
  }

  Widget _buildNonAcademicRankings() {
    final activities = ['Sports', 'Cultural', 'Technical', 'Social Service', 'Innovation'];
    return _buildRankingsList(
      title: 'Non-Academic Rankings',
      itemBuilder: (context, index) {
        return _buildRankingCard(
          rank: index + 1,
          name: studentNames[index],
          subtitle: 'Top Activity: ${activities[index % activities.length]}',
        );
      },
    );
  }

  Widget _buildRankingsList({
    required String title,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: studentNames.length,
              itemBuilder: itemBuilder,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard({required int rank, required String name, required String subtitle}) {
    return GestureDetector(
      onTap: () {
        if (name == 'Harsh Doshi') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(toggleTheme: widget.toggleTheme)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailScreen(
                name: name,
                rank: rank.toString(),
                details: subtitle,
              ),
            ),
          );
        }
      },
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 90,
        borderRadius: 12,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
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
        margin: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: rank <= 3 ? Colors.amber : Colors.grey[700],
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
