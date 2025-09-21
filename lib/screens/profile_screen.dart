import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../services/academic_service.dart';
import '../services/student_service.dart';
import 'splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  // Temporary comment to force recompilation
  const ProfileScreen({
    Key? key,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  User? _currentUser;
  File? _profileImage;
  AcademicData? _academicData;
  String? _academicError;
  
  // Student data
  final StudentService _studentService = StudentService();
  Map<String, dynamic>? _studentCPIData;
  bool _isLoadingStudentData = false;
  String? _studentDataError;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+91 9313670684');
  
  // Profile state variables
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    
    // Retrieve user from provider
    _currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.name;
      _emailController.text = _currentUser!.email;
      
      // Fetch student CPI/SPI data
      _fetchStudentData();
    }
  }
  
  // Fetch student academic data
  Future<void> _fetchStudentData() async {
    setState(() {
      _isLoadingStudentData = true;
      _studentDataError = null;
    });
    
    try {
      // Fetch student CPI/SPI data using email
      final studentData = await _studentService.getStudentAcademicDataByEmail(_currentUser!.email);
      
      setState(() {
        _studentCPIData = studentData;
        _isLoadingStudentData = false;
      });
      
      print('Student data fetched successfully: $_studentCPIData');
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() {
        _studentDataError = e.toString();
        _isLoadingStudentData = false;
      });
    }
    
    _loadProfileImage();
    // Load academic data after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAcademicData();
    });
  }

  bool _isEditing = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update user data when it changes
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    if (userProvider.user != _currentUser) {
      setState(() {
        _currentUser = userProvider.user;
        if (_currentUser != null) {
          _nameController.text = _currentUser!.name;
          _emailController.text = _currentUser!.email;
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      // Clear user data from provider
      Provider.of<UserProvider>(context, listen: false).clearUser();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (!mounted) return;
      
      // Navigate to splash screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => SplashScreen(toggleTheme: widget.toggleTheme),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    final theme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.notifications,
            color: Colors.white,
          ),
          onPressed: () {
            _showNotifications(context);
          },
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _toggleEditMode();
              } else if (value == 'theme') {
                widget.toggleTheme();
              } else if (value == 'about') {
                _showAboutDialog(context);
              } else if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark ? Colors.black : Colors.white,
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Profile'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'theme',
                child: ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text('Change Theme'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
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
                stops: [0.0, 0.3],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(theme, isDark),
                    const SizedBox(height: 24),
                    _buildAnimatedInfoCard(
                      'Personal Information',
                      Icons.person,
                      [
                        _buildEditableField('Email', _emailController, _isEditing, theme, isDark),
                        _buildEditableField('Phone', _phoneController, _isEditing, theme, isDark),
                      ],
                      theme,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedInfoCard(
                      'Academic Information',
                      Icons.school,
                      [
                        if (_academicError != null)
                          _buildInfoRow('Error', _academicError!, theme, isDark)
                        else if (_academicData != null) ...[
                          _buildInfoRow('Enrollment', _academicData!.enrollmentNumber, theme, isDark),
                          _buildInfoRow('Current Semester', '${_academicData!.currentSemester}', theme, isDark),
                          _buildInfoRow('Latest CPI', _academicData!.latestCPI.toStringAsFixed(2), theme, isDark),
                          _buildInfoRow('Latest SPI', _academicData!.latestSPI.toStringAsFixed(2), theme, isDark),
                          _buildInfoRow('Current Rank', _academicData!.latestRank.toString(), theme, isDark),
                          const SizedBox(height: 16),
                          Text(
                            'Semester-wise Performance',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_academicData!.semesterData.entries
                              .where((entry) => entry.value.semesterNumber > 0)
                              .toList()
                              ..sort((a, b) => a.value.semesterNumber.compareTo(b.value.semesterNumber)))
                              .map<Widget>((entry) => Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Semester ${entry.value.semesterNumber}',
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'SPI: ${entry.value.spi.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: isDark ? Colors.white60 : Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              'CPI: ${entry.value.cpi.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: isDark ? Colors.white60 : Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              'Rank: ${entry.value.rank}',
                                              style: TextStyle(
                                                color: isDark ? Colors.white60 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ] else
                          _buildInfoRow('Status', 'Loading academic data...', theme, isDark),
                      ],
                      theme,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save changes to backend would go here
      }
    });
  }

  void _saveChanges() {
    // Here you would typically save to a backend
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile changes saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme theme, bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _changeProfilePicture : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: isDark ? Colors.white70 : Colors.black54,
                      )
                    : null,
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _nameController.text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          _currentUser?.enrollmentNumber ?? 'N/A',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      // Save the profile image path
      await _saveProfileImagePath(image.path);
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');
      if (imagePath != null && !kIsWeb) {
        final file = File(imagePath);
        if (await file.exists()) {
          setState(() {
            _profileImage = file;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> _saveProfileImagePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', path);
    } catch (e) {
      debugPrint('Error saving profile image path: $e');
    }
  }

  Widget _buildAnimatedInfoCard(String title, IconData icon, List<Widget> children, ColorScheme theme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditing, ColorScheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          isEditing
              ? TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _loadAcademicData() async {
    if (!mounted) return;
    
    setState(() {
      _academicError = null;
    });

    debugPrint('Loading academic data...');
    if (_currentUser?.email == null) {
      debugPrint('No email available');
      setState(() {
        _academicError = 'No user email available';
      });
      return;
    }
    
    try {
      debugPrint('Current user email: ${_currentUser!.email}');
      final academicService = AcademicService();
      final academicData = await academicService.getAcademicDataByEmail(_currentUser!.email);
      
      if (!mounted) return;
      
      setState(() {
        // academicData is always non-null now (our service returns default values)
        _academicData = academicData;
        _academicError = null;
        debugPrint('Academic data updated for enrollment: ${academicData.enrollmentNumber}');
      });
    } catch (e) {
      debugPrint('Error loading academic data: $e');
      if (!mounted) return;
      setState(() {
        _academicError = 'Failed to load academic data: $e';
      });
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black 
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationItem(
                    'SE mid sem marks graded', 
                    'Your score: 85/100', 
                    Icons.assignment_turned_in,
                    Colors.green,
                  ),
                  _buildNotificationItem(
                    'OT mid sem marks graded', 
                    'Your score: 78/100', 
                    Icons.assignment_turned_in,
                    Colors.blue,
                  ),
                  _buildNotificationItem(
                    'CP club organized event on Saturday', 
                    'Competitive Programming Contest at 10 AM', 
                    Icons.event,
                    Colors.orange,
                  ),
                  _buildNotificationItem(
                    'New Hackathon is coming up', 
                    'Register before April 25th', 
                    Icons.code,
                    Colors.purple,
                  ),
                  _buildNotificationItem(
                    'AWT Assignment due tomorrow', 
                    'Submit on the portal before midnight', 
                    Icons.assignment_late,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Text(
        '${DateTime.now().difference(DateTime.now().subtract(Duration(days: 2))).inDays}d ago',
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black45,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                  ? Colors.black.withOpacity(0.6) 
                  : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About The Ictians',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This app is designed and created by:',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Harsh Doshi',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rishit Rathod',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Krish Mamtora',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Under guidance of Prof. CD Parmar sir',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CLOSE',
                        style: TextStyle(
                          color: const Color(0xFF03A9F4),
                          fontWeight: FontWeight.bold,
                        ),
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
}
