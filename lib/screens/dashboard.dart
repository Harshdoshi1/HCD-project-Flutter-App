import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'dart:math';
import '../constants/app_theme.dart';

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
    _graphAnimationController.forward();
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
            Stack(
              children: [
                // Background container
                Container(
                  width: double.infinity,
                  height: kToolbarHeight + 60,
                  color: const Color(0xFF03A9F4),
                ),
                // Glassmorphic overlay
                GlassmorphicContainer(
                  width: double.infinity,
                  height: kToolbarHeight + 60,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                  ),
                ),
              ],
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
                          _buildGlassChartCard(
                            title: 'SGPA Progression', 
                            height: 356, 
                            chart: _buildAnimatedBarChart()
                          )
                        else if (_activeGraph == 'expertise')
                          _buildGlassChartCard(
                            title: 'Domain Expertise', 
                            height: 356, 
                            chart: _buildAnimatedPieChart()
                          )
                        else if (_activeGraph == 'subjects')
                          _buildGlassChartCard(
                            title: 'Current Semester Subjects', 
                            height: 356, 
                            chart: _buildSpiderChart()
                          )
                        else if (_activeGraph == 'languages')
                          _buildGlassChartCard(
                            title: 'Programming Languages', 
                            height: 356, 
                            chart: _buildLanguagesRadialChart()
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
            Icons.pie_chart, 
            'Expertise', 
            _activeGraph == 'expertise' ? Colors.green : Colors.grey
          ),
        ),
        GestureDetector(
          onTap: () => _switchGraph('subjects'),
          child: _buildDashboardIcon(
            Icons.subject, 
            'Subjects', 
            _activeGraph == 'subjects' ? Colors.deepOrange : Colors.grey
          ),
        ),
        GestureDetector(
          onTap: () => _switchGraph('languages'),
          child: _buildDashboardIcon(
            Icons.code, 
            'Languages', 
            _activeGraph == 'languages' ? Colors.teal : Colors.grey
          ),
        ),
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

  Widget _buildGlassChartCard({required String title, required double height, required Widget chart}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: height,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.bottomCenter,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: chart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBarChart() {
    // Sample SGPA data for 8 semesters
    final List<double> sgpaData = [8.2, 8.5, 9.0, 8.7, 9.2, 8.8, 9.5, 9.3];
    final List<Color> barColors = [
      Colors.blue.shade300,
      Colors.blue.shade400,
      Colors.blue.shade500,
      Colors.blue.shade600,
      Colors.blue.shade700,
      Colors.blue.shade800,
      Colors.blue.shade900,
      Colors.indigo.shade800,
    ];
    
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, right: 20, left: 30),
            child: Column(
              children: [
                // Scale label at the top
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Scale: 1-10',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      minY: 0,
                      barGroups: List.generate(
                        8,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: sgpaData[index] * _graphAnimationController.value,
                              color: barColors[index],
                              width: 18,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 10,
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 2 == 0 && value > 0) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  (value.toInt() + 1).toString(),
                                  style: TextStyle(fontSize: 10, color: barColors[value.toInt()]),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: EdgeInsets.all(8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'SGPA: ${sgpaData[group.x.toInt()].toStringAsFixed(1)}',
                              TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Semester label at the bottom
                Row(
                  children: [
                    Text(
                      'Sem',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPieChart() {
    // Domain expertise data
    final List<Map<String, dynamic>> expertiseData = [
      {'domain': 'Mobile Dev', 'percentage': 35, 'color': Colors.blue},
      {'domain': 'Web Dev', 'percentage': 25, 'color': Colors.green},
      {'domain': 'AI/ML', 'percentage': 20, 'color': Colors.purple},
      {'domain': 'Cloud', 'percentage': 15, 'color': Colors.orange},
      {'domain': 'Others', 'percentage': 5, 'color': Colors.grey},
    ];
    
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _graphAnimationController.value,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    child: PieChart(
                      PieChartData(
                        sections: expertiseData.map((data) => 
                          PieChartSectionData(
                            value: data['percentage'] * _graphAnimationController.value,
                            title: '${data['percentage']}%',
                            titleStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                )
                              ]
                            ),
                            color: data['color'],
                            radius: 70,
                            titlePositionPercentageOffset: 0.55,
                            badgeWidget: _graphAnimationController.value > 0.9 ? 
                              Icon(Icons.star, color: Colors.white, size: 12) : null,
                            badgePositionPercentageOffset: 0.8,
                          )
                        ).toList(),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        centerSpaceColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                flex: 1,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: expertiseData.map((data) => 
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: data['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: data['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            data['domain'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: data['color'],
                            ),
                          ),
                        ],
                      ),
                    )
                  ).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpiderChart() {
    final List<Map<String, dynamic>> subjectsData = [
      {'name': 'HCD', 'score': 85, 'color': Colors.blue},
      {'name': 'CPSI', 'score': 78, 'color': Colors.green},
      {'name': 'DAA', 'score': 92, 'color': Colors.purple},
      {'name': 'AI', 'score': 88, 'color': Colors.orange},
      {'name': 'ML', 'score': 80, 'color': Colors.red},
      {'name': 'Cloud', 'score': 75, 'color': Colors.teal},
      {'name': 'Blockchain', 'score': 82, 'color': Colors.indigo},
    ];
    
    final List<String> subjects = subjectsData.map((data) => data['name'] as String).toList();
    final List<double> marks = subjectsData.map((data) => (data['score'] as int).toDouble()).toList();
    final List<Color> colors = subjectsData.map((data) => data['color'] as Color).toList();
  
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              flex: 3,
              child: Opacity(
                opacity: _graphAnimationController.value,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        dataEntries: marks.map((mark) => 
                          RadarEntry(
                            value: mark * _graphAnimationController.value / 20
                          )
                        ).toList(),
                        fillColor: Colors.blue.withOpacity(0.3 * _graphAnimationController.value),
                        borderColor: Colors.blue,
                        borderWidth: 2,
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    tickCount: 5,
                    ticksTextStyle: TextStyle(color: Colors.transparent, fontSize: 10),
                    tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                    gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                    radarShape: RadarShape.polygon,
                    titlePositionPercentageOffset: 0.1,
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
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  subjects.length,
                  (index) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors[index].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subjects[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors[index],
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${marks[index].toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors[index],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguagesRadialChart() {
    // Programming languages data
    final List<Map<String, dynamic>> languagesData = [
      {'name': 'Python', 'proficiency': 90, 'color': Colors.blue},
      {'name': 'Java', 'proficiency': 85, 'color': Colors.orange},
      {'name': 'C++', 'proficiency': 80, 'color': Colors.purple},
      {'name': 'Dart', 'proficiency': 75, 'color': Colors.teal},
      {'name': 'JavaScript', 'proficiency': 70, 'color': Colors.amber},
      {'name': 'C#', 'proficiency': 65, 'color': Colors.green},
      {'name': 'Assembly', 'proficiency': 40, 'color': Colors.red},
    ];
    
    return AnimatedBuilder(
      animation: _graphAnimationController,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // Background circles
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.withOpacity(0.05),
                            ),
                            child: Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.05),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.withOpacity(0.05),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.withOpacity(0.05),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Radial bars
                    ...List.generate(languagesData.length, (index) {
                      final data = languagesData[index];
                      final angle = 2 * pi * index / languagesData.length;
                      final proficiency = data['proficiency'] / 100;
                      
                      return Center(
                        child: Transform.rotate(
                          angle: angle,
                          child: Stack(
                            children: [
                              // Base line (full length)
                              Center(
                                child: Container(
                                  width: 4,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Colored bar (proficiency length)
                              Center(
                                child: Container(
                                  width: 12,
                                  height: 110 * proficiency * _graphAnimationController.value,
                                  decoration: BoxDecoration(
                                    color: data['color'],
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: data['color'].withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Language labels
                    ...List.generate(languagesData.length, (index) {
                      final data = languagesData[index];
                      final angle = 2 * pi * index / languagesData.length;
                      return Positioned.fill(
                        child: Align(
                          alignment: Alignment(
                            1.1 * cos(angle),
                            1.1 * sin(angle),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: data['color'].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data['name'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: data['color'],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Center text
                    Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Languages',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Proficiency',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: languagesData.map((data) => 
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: data['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: data['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${data['name']}: ${data['proficiency']}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: data['color'],
                          ),
                        ),
                      ],
                    ),
                  )
                ).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
