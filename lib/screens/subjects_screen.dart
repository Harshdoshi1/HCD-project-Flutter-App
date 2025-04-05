import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'subject_detail_screen.dart';

// Move the Subject class to the top level
class Subject {
  final String name;
  final String code;
  final String status; // Passed, Failed, Not declared
  final double grade; // Example grade

  Subject({required this.name, required this.code, required this.status, required this.grade});
}

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
        {'name': 'ICE', 'code': 'MA101'},
        {'name': 'FSSI', 'code': 'PH101'},
        {'name': 'AC', 'code': 'CH101'},
      ]
    },
    {
      'name': 'Semester 2',
      'subjects': [
        {'name': 'OOP', 'code': 'MA201'},
        {'name': 'DLD', 'code': 'EC201'},
        {'name': 'MAVC', 'code': 'CS201'},
      ]
    },
    {
      'name': 'Semester 3',
      'subjects': [
        {'name': 'Data Structure', 'code': 'CS301'},
        {'name': 'DMGT', 'code': 'CS302'},
        {'name': 'Iwt', 'code': 'CS303'},
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            color: const Color(0xFF03A9F4), // Consistent blue
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Text(
                      'My Subjects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                          child: ChoiceChip(
                            label: Text(
                              'Sem $semester',
                              style: TextStyle(
                                color: _selectedSemester == semester
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            selected: _selectedSemester == semester,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSemester = semester;
                                });
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    return Card(
                      color: Theme.of(context).cardTheme.color, // Use theme's card color from cardTheme
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubjectDetailScreen(subject: Subject(
                                name: subject['name'],
                                code: subject['code'],
                                status: 'Not declared', // Placeholder
                                grade: 0.0, // Placeholder
                              )),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          subject['name'],
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Code: ${subject['code']}',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
