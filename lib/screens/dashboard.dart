import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import './assignments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
  late AnimationController _graphAnimationController;
  String _activeGraph = 'sgpa'; // Default to SGPA graph

  void _switchGraph(String newGraph) {
    if (_activeGraph != newGraph) {
      setState(() {
        _activeGraph = newGraph;
        _graphAnimationController.reset();
        _graphAnimationController.forward();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _graphAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: Curves.easeIn
      ),
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
    _graphAnimationController.dispose();
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
                        'Welcome, Harsh Doshi',
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
                            title: 'Domain Expertise', 
                            height: 250, 
                            chart: _buildAnimatedPieChart()
                          )
                        else if (_activeGraph == 'subjects')
                          _buildChartCard(
                            title: 'Current Semester Subjects', 
                            height: 250, 
                            chart: _buildSpiderChart()
                          ),
                        _buildAssignmentList(),
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
          onTap: () => _switchGraph('sgpa'),
          child: _buildDashboardIcon(
            Icons.school, 
            'SGPA', 
            _activeGraph == 'sgpa' ? Colors.blue : Colors.grey
          ),
        ),
        GestureDetector(
          onTap: () => _switchGraph('expertise'),
          child: _buildDashboardIcon(
            Icons.star, 
            'Expertise', 
            _activeGraph == 'expertise' ? Colors.deepPurple : Colors.grey
          ),
        ),
        GestureDetector(
          onTap: () => _switchGraph('subjects'),
          child: _buildDashboardIcon(
            Icons.menu_book, 
            'Subjects', 
            _activeGraph == 'subjects' ? Colors.deepOrange : Colors.grey
          ),
        ),
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
      animation: _graphAnimationController,
      builder: (context, child) {
        _graphAnimationController.forward();
        return FadeTransition(
          opacity: _fadeAnimation,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10,
              barGroups: [
                for (var i = 0; i < 8; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (7.5 + (i % 3)) * _graphAnimationController.value,
                        color: Colors.blue,
                        width: 10,
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade200, Colors.blue.shade400],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  ),
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
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPieChart() {
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        _graphAnimationController.forward();
        return Opacity(
          opacity: _graphAnimationController.value,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: 45,
                  title: '45%',
                  titlePositionPercentageOffset: 0.6,
                  color: Colors.blueAccent,
                  radius: 100,
                  showTitle: true,
                  titleStyle: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                PieChartSectionData(
                  value: 55,
                  title: '55%',
                  titlePositionPercentageOffset: 0.6,
                  color: Colors.greenAccent,
                  radius: 100,
                  showTitle: true,
                  titleStyle: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
              centerSpaceRadius: 0,
              sectionsSpace: 0,
              startDegreeOffset: 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpiderChart() {
    final List<String> subjects = [
      'HCD', 'CPSI', 'DAA', 'AI', 'ML', 'Cloud', 'Blockchain'
    ];
    final List<double> marks = [85, 78, 92, 88, 80, 75, 82];
  
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        _graphAnimationController.forward();
        return Opacity(
          opacity: _graphAnimationController.value,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  dataEntries: marks.map((mark) => 
                    RadarEntry(
                      value: mark * _graphAnimationController.value
                    )
                  ).toList(),
                  fillColor: Colors.blue.withOpacity(0.3 * _graphAnimationController.value),
                  borderColor: Colors.blue,
                  borderWidth: 2,
                ),
              ],
              borderData: FlBorderData(show: false),
              radarBackgroundColor: Colors.transparent,
              tickCount: 5,
              ticksTextStyle: TextStyle(color: Colors.grey, fontSize: 10),
              radarShape: RadarShape.polygon,
              titleTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              getTitle: (index, angle) => RadarChartTitle(
                text: subjects[index],
                angle: angle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentList() {
    final List<Map<String, dynamic>> assignments = [
      {'title': 'HCD Project', 'due': 'Due: April 10', 'icon': Icons.assignment, 'color': Colors.red},
      {'title': 'CPSI Lab Report', 'due': 'Due: April 12', 'icon': Icons.science, 'color': Colors.blue},
      {'title': 'DAA Algorithm', 'due': 'Due: April 15', 'icon': Icons.code, 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Upcoming Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: assignments.map((assignment) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: assignment['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(assignment['icon'], color: assignment['color']),
              ),
              title: Text(assignment['title']),
              subtitle: Text(assignment['due']),
              trailing: const Icon(Icons.arrow_forward),
            )).toList(),
          ),
        ),
      ],
    );
  }
}