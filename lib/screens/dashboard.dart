import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Blue Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.blue[900],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MBA 6th Semester',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatItem('Statistics', '4.14'),
                            _buildStatItem('Lithouse', 'Geography'),
                            _buildStatItem('Hitney', 'Algerico'),
                            _buildStatItem('Due', '69%'),
                            _buildStatItem('Right', '85%'),
                            _buildStatItem('Wrong', '15%'),
                            _buildStatItem('28Jun', '13'),
                            _buildStatItem('Tesika learned', 'Classes 8'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // White Charts Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildChartCard(
                            title: 'SGPA Progression',
                            height: 250,
                            chart: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 10,
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [
                                    BarChartRodData(
                                      toY: 8.2,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 1, barRods: [
                                    BarChartRodData(
                                      toY: 8.5,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 2, barRods: [
                                    BarChartRodData(
                                      toY: 7.8,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 3, barRods: [
                                    BarChartRodData(
                                      toY: 8.9,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 4, barRods: [
                                    BarChartRodData(
                                      toY: 8.3,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 5, barRods: [
                                    BarChartRodData(
                                      toY: 9.1,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 6, barRods: [
                                    BarChartRodData(
                                      toY: 8.7,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 7, barRods: [
                                    BarChartRodData(
                                      toY: 9.0,
                                      color: Colors.blue,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ]),
                                ],
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) => Text(
                                        'S ${value.toInt() + 1}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                      interval: 1,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(enabled: true),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChartCard(
                            title: 'Subject Distribution',
                            height: 200,
                            chart: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: 69,
                                    title: 'Geography',
                                    color: Colors.blue,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: 85,
                                    title: 'Algerico',
                                    color: Colors.green,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: 15,
                                    title: 'Others',
                                    color: Colors.orange,
                                    radius: 50,
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required double height, required Widget chart}) {
    List<double> sgpaValues = [8.2, 8.5, 7.8, 8.9, 8.3, 9.1, 8.7, 9.0];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: Stack(
                children: [
                  chart,
                  for (var i = 0; i < 8; i++)
                    Positioned(
                      left: (i * (height / 8)) + (height / 16) - 10,
                      top: height - 20,
                      child: Text(
                        '${sgpaValues[i]}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}