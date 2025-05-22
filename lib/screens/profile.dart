import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/academic_service_new.dart';
import '../models/student.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final AcademicService _academicService = AcademicService();
  
  Student? _student;
  Map<String, dynamic>? _academicData;
  bool _isLoading = true;

  @override 
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final student = await _authService.getCurrentStudent();
      if (student != null) {
        final academicData = await _academicService.getAcademicDataByEmail(student.email);
        setState(() {
          _student = student;
          _academicData = academicData;
          _isLoading = false;
        });
        debugPrint('Loaded academic data: $academicData');
      }
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF03A9F4),
                  child: const Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Info
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.lightBlue.shade100,
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _student?.name ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _student?.email ?? 'N/A',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Academic Information
                        const Text(
                          'Academic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Enrollment Number', _student?.enrollmentNumber ?? 'N/A'),
                                const SizedBox(height: 8),
                                _buildInfoRow('Batch', _student?.batch ?? 'N/A'),
                                const SizedBox(height: 8),
                                _buildInfoRow('Current CPI', _academicData?['cpi']?.toString() ?? 'N/A'),
                                const SizedBox(height: 8),
                                _buildInfoRow('Current SPI', _academicData?['spi']?.toString() ?? 'N/A'),
                                const SizedBox(height: 8),
                                _buildInfoRow('Current Rank', _academicData?['rank']?.toString() ?? 'N/A'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Points Information
                        const Text(
                          'Activity Points',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Hardware Points', _student?.hardwarePoints?.toString() ?? '0'),
                                const SizedBox(height: 8),
                                _buildInfoRow('Software Points', _student?.softwarePoints?.toString() ?? '0'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Settings
                        ListTile(
                          leading: const Icon(Icons.settings, color: Colors.lightBlue),
                          title: const Text('Settings'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help_outline, color: Colors.lightBlue),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout'),
                          onTap: () async {
                            await _authService.logout();
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                        ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  }
}
