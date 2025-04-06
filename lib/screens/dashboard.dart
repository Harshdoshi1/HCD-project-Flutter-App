import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';

class DashboardScreen extends StatefulWidget {
  final User currentUser;
  const DashboardScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeTextAnimation;
  late Animation<Offset> _slideTextAnimation;
  late AnimationController _animationController;
  final double _barValue = 100; // Example target value for bar chart
  final double _pieValue = 70; // Example target value for pie chart
  String _activeGraph = 'sgpa'; // Default to SGPA graph

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

    _fadeTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideTextAnimation = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: kToolbarHeight + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              color: const Color(0xFF03A9F4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SlideTransition(
                    position: _slideTextAnimation,
                    child: FadeTransition(
                      opacity: _fadeTextAnimation,
                      child: Text(
                        'Welcome, ${widget.currentUser.email}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _slideTextAnimation,
                    child: FadeTransition(
                      opacity: _fadeTextAnimation,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildIconRow(),
                        const SizedBox(height: 20),
                        if (_activeGraph == 'sgpa')
                          _buildChartCard(
                            title: 'SGPA Progression', 
                            height: 250, 
                            chart: _buildAnimatedBarChart()
                          )
                        else if (_activeGraph == 'expertise')
                          _buildChartCard(
                            title: 'Subject Distribution', 
                            height: 250, 
                            chart: _buildAnimatedPieChart()
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () => setState(() => _activeGraph = 'sgpa'),
          child: _buildDashboardIcon(
            Icons.school, 
            'SGPA', 
            _activeGraph == 'sgpa' ? Colors.blue : Colors.grey
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _activeGraph = 'expertise'),
          child: _buildDashboardIcon(
            Icons.star, 
            'Expertise', 
            _activeGraph == 'expertise' ? Colors.orange : Colors.grey
          ),
        ),
        _buildDashboardIcon(Icons.menu_book, 'Subjects', Colors.green),
        _buildDashboardIcon(Icons.work, 'Projects', Colors.purple),
      ],
    );
  }

  Widget _buildDashboardIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required double height, required Widget chart}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: height, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBarChart() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double animatedBarValue = _barValue * _animationController.value;
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 10,
            barGroups: [
              for (var i = 0; i < 8; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: (7.5 + (i % 3)) * _animationController.value,
                    color: Colors.blue,
                    width: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ]),
            ],
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text('S ${value.toInt() + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  interval: 1,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPieChart() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(value: 40 * _animationController.value, title: 'HCD', color: Colors.blue, radius: 50),
              PieChartSectionData(value: 30 * _animationController.value, title: 'CPSI', color: Colors.green, radius: 50),
              PieChartSectionData(value: 30 * _animationController.value, title: 'DAA', color: Colors.orange, radius: 50),
            ],
          ),
        );
      },
    );
  }
}
