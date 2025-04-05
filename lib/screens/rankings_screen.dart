import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key}) : super(key: key);

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
          Expanded(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: kToolbarHeight - 10,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      color: AppTheme.primaryColor, // Fixed theme reference
      child: Column(
        children: [
          const Text(
            'Rankings',
            style: TextStyle(
              color: AppTheme.onPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 4, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: studentNames.length,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard({required int rank, required String name, required String subtitle}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: rank <= 3 ? AppTheme.secondaryColor : Colors.grey[700],
          child: Text(
            '$rank',
            style: const TextStyle(
              color: AppTheme.onPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}
