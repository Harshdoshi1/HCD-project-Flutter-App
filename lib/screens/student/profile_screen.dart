import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/academic_service.dart';
import '../../services/student_service.dart';
import '../../services/profile_service.dart';
import '../splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  // Temporary comment to force recompilation
  const ProfileScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  User? _currentUser;
  File? _profileImage;
  String? _profileImageUrl;
  AcademicData? _academicData;
  String? _academicError;
  
  // Student data
  final StudentService _studentService = StudentService();
  final ProfileService _profileService = ProfileService();
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
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
              } else if (value == 'report') {
                _showReportIssueDialog(context);
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
                        child: const Text(
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
                        child: const Text(
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
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Report an Issue'),
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
                stops: const [0.0, 0.3],
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
                        _buildEditableField('Email', _emailController, _isEditing, theme, isDark, editable: false),
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
                              ,
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
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
      const SnackBar(
        content: Text('Profile changes saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme theme, bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _pickImage : null,
          onLongPress: _isEditing && (_profileImage != null || _profileImageUrl != null) ? _deleteProfileImage : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                backgroundImage: _profileImage != null 
                    ? FileImage(_profileImage!) 
                    : _profileImageUrl != null 
                        ? NetworkImage(_profileImageUrl!) 
                        : null,
                child: _profileImage == null && _profileImageUrl == null
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
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _isEditing 
            ? TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
              )
            : Text(
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && _currentUser?.email != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        dynamic imageData;
        if (kIsWeb) {
          // For web: get bytes directly
          imageData = await image.readAsBytes();
        } else {
          // For mobile: use File
          imageData = File(image.path);
        }

        // Upload image to database
        final result = await _profileService.uploadProfileImage(
          _currentUser!.email,
          imageData,
        );

        Navigator.pop(context); // Close loading dialog

        if (result['imageUrl'] != null) {
          setState(() {
            if (!kIsWeb) {
              _profileImage = File(image.path);
            }
            _profileImageUrl = result['imageUrl'];
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Upload failed');
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog if open
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      if (_currentUser?.email != null) {
        final imageUrl = await _profileService.getProfileImageUrl(_currentUser!.email);
        setState(() {
          _profileImageUrl = imageUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      if (_currentUser?.email != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final success = await _profileService.deleteProfileImage(_currentUser!.email);
        Navigator.pop(context); // Close loading dialog

        if (success) {
          setState(() {
            _profileImage = null;
            _profileImageUrl = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Delete failed');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to delete image: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditing, ColorScheme theme, bool isDark, {bool editable = true}) {
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
          isEditing && editable
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
                    'About Icitians',
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
                  const SizedBox(height: 12),
                  Text(
                    'This is our HCD project created by Team Student performance Analyizer',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      // fontStyle: FontStyle.italic,
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
                    'Under The mentoring and guidance of Prof. CD Parmar sir',
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
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Color(0xFF03A9F4),
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

  void _showReportIssueDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
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
                  mainAxisSize: MainAxisSize.min,
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
                            Icons.bug_report,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Report an Issue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'If you find any issue in the app, please send a screenshot to:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'harshdoshiyt02@gmail.com',
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black54,
                          ),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Clipboard.setData(const ClipboardData(text: 'harshdoshiyt02@gmail.com'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Email copied to clipboard!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Copy Email'),
                        ),
                      ],
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
