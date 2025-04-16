import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:hac_flutter_hcd/models/subject.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> with SingleTickerProviderStateMixin {
  int _selectedSemester = 1;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const List<Map<String, dynamic>> semesters = [
    {
      'name': 'Semester 1',
      'subjects': [
        {
          'name': 'ICE',
          'code': 'MA101',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28, 'outOf': 30},
            'Viva': {'marks': 22, 'outOf': 25},
            'Assignment': {'marks': 23, 'outOf': 25},
            'CSE': {'marks': 18, 'outOf': 20},
            'ESE': {'marks': 45, 'outOf': 50},
          },
        },
        {
          'name': 'FSSI',
          'code': 'PH101',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 29, 'outOf': 30},
            'Viva': {'marks': 24, 'outOf': 25},
            'Assignment': {'marks': 24, 'outOf': 25},
            'CSE': {'marks': 19, 'outOf': 20},
            'ESE': {'marks': 48, 'outOf': 50},
          },
        },
        {
          'name': 'AC',
          'code': 'CH101',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26, 'outOf': 30},
            'Viva': {'marks': 20, 'outOf': 25},
            'Assignment': {'marks': 21, 'outOf': 25},
            'CSE': {'marks': 17, 'outOf': 20},
            'ESE': {'marks': 42, 'outOf': 50},
          },
        },
      ]
    },
    {
      'name': 'Semester 2',
      'subjects': [
        {
          'name': 'OOP',
          'code': 'MA201',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28, 'outOf': 30},
            'Viva': {'marks': 22, 'outOf': 25},
            'Assignment': {'marks': 23, 'outOf': 25},
            'CSE': {'marks': 18, 'outOf': 20},
            'ESE': {'marks': 45, 'outOf': 50},
          },
        },
        {
          'name': 'DLD',
          'code': 'EC201',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 29, 'outOf': 30},
            'Viva': {'marks': 24, 'outOf': 25},
            'Assignment': {'marks': 24, 'outOf': 25},
            'CSE': {'marks': 19, 'outOf': 20},
            'ESE': {'marks': 48, 'outOf': 50},
          },
        },
        {
          'name': 'MAVC',
          'code': 'CS201',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26, 'outOf': 30},
            'Viva': {'marks': 20, 'outOf': 25},
            'Assignment': {'marks': 21, 'outOf': 25},
            'CSE': {'marks': 17, 'outOf': 20},
            'ESE': {'marks': 42, 'outOf': 50},
          },
        },
      ]
    },
    {
      'name': 'Semester 3',
      'subjects': [
        {
          'name': 'Data Structure',
          'code': 'CS301',
          'grade': 'A',
          'components': {
            'IA': {'marks': 28, 'outOf': 30},
            'Viva': {'marks': 22, 'outOf': 25},
            'Assignment': {'marks': 23, 'outOf': 25},
            'CSE': {'marks': 18, 'outOf': 20},
            'ESE': {'marks': 45, 'outOf': 50},
          },
        },
        {
          'name': 'DMGT',
          'code': 'CS302',
          'grade': 'A+',
          'components': {
            'IA': {'marks': 29, 'outOf': 30},
            'Viva': {'marks': 24, 'outOf': 25},
            'Assignment': {'marks': 24, 'outOf': 25},
            'CSE': {'marks': 19, 'outOf': 20},
            'ESE': {'marks': 48, 'outOf': 50},
          },
        },
        {
          'name': 'Iwt',
          'code': 'CS303',
          'grade': 'B+',
          'components': {
            'IA': {'marks': 26, 'outOf': 30},
            'Viva': {'marks': 20, 'outOf': 25},
            'Assignment': {'marks': 21, 'outOf': 25},
            'CSE': {'marks': 17, 'outOf': 20},
            'ESE': {'marks': 42, 'outOf': 50},
          },
        },
      ]
    },
  ];

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF03A9F4),
                  Colors.black,
                ],
                stops: [0.0, 0.3],
              ),
            ),
          ),
          Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                height: kToolbarHeight + 80,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'My Subjects',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SlideTransition(
                              position: _slideAnimation,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(semesters.length, (index) {
                                    final semester = index + 1;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: _buildSemesterChip(semester),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Subject list
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: (_selectedSemester <= semesters.length)
                          ? (semesters[_selectedSemester - 1]['subjects'] as List).length
                          : 0,
                      itemBuilder: (context, index) {
                        if (_selectedSemester > semesters.length) return const SizedBox();
                        final subjects = semesters[_selectedSemester - 1]['subjects'] as List;
                        final subject = subjects[index] as Map<String, dynamic>;
                        return _buildSubjectCard(subject, context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterChip(int semester) {
    final isSelected = _selectedSemester == semester;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSemester = semester;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.white.withOpacity(0.5) 
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          'Sem $semester',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, BuildContext context) {
    final String grade = subject['grade'] as String;
    Color gradeColor;
    
    // Determine grade color
    if (grade == 'A+') {
      gradeColor = Colors.green;
    } else if (grade == 'A') {
      gradeColor = Colors.lightGreen;
    } else if (grade == 'B+') {
      gradeColor = Colors.amber;
    } else {
      gradeColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(
                subject: Subject(
                  name: subject['name'],
                  code: subject['code'],
                  status: subject['grade'] == 'A' || subject['grade'] == 'A+' || subject['grade'] == 'B+' ? 'Passed' : 'Failed',
                  grade: subject['grade'],
                  components: subject['components'],
                ),
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Grade circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withOpacity(0.2),
                        border: Border.all(
                          color: gradeColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Subject details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject['code'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
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
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
