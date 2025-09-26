import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'main_navigation.dart';
import '../services/auth_service.dart';
import '../utils/api_config.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? toggleTheme;
  
  const LoginPage({super.key, this.toggleTheme});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useLocalTestingMode = false;
  final _authService = AuthService();
  String _selectedRole = 'student'; // Default role
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    // Load local testing mode preference and saved credentials
    _loadLocalTestingModePreference();
    _loadSavedCredentials();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    _animationController.forward();
  }
  
  // Load local testing mode preference from SharedPreferences
  Future<void> _loadLocalTestingModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useLocalTestingMode = prefs.getBool('use_local_mock_data') ?? false;
    });
    // Also set it in the API config
    ApiConfig.useLocalMockData = _useLocalTestingMode;
  }
  
  // Save local testing mode preference to SharedPreferences
  Future<void> _saveLocalTestingModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_local_mock_data', value);
    // Also update the API config
    await ApiConfig.setUseLocalMockData(value);
  }
  
  // Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final savedRole = prefs.getString('saved_role');
    
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        if (savedRole != null) {
          _selectedRole = savedRole;
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      // Save the current local testing mode setting
      await _saveLocalTestingModePreference(_useLocalTestingMode);
      
      // Save login credentials for auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setString('saved_role', _selectedRole);
      
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _authService.login(
          _emailController.text,
          _passwordController.text,
          context,
        );

        if (!mounted) return;

        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token'] ?? 'mock-token');
        
        // Save the complete user data as JSON string
        final user = response['user'];
        if (user != null) {
          // Create a new user data map with the correct role
          final userData = {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'enrollmentNumber': user.enrollmentNumber,
            'currentSemester': user.currentSemester,
            'role': _selectedRole, // Use the selected role from UI
            'hardwarePoints': user.hardwarePoints,
            'softwarePoints': user.softwarePoints,
            'batch': user.batch,
          };
          
          // If parent role, add student info
          if (_selectedRole == 'parent') {
            final emailParts = _emailController.text.split('@');
            if (emailParts.isNotEmpty) {
              final nameMatch = RegExp(r'^([a-zA-Z]+)').firstMatch(emailParts.first);
              if (nameMatch != null) {
                final studentName = nameMatch.group(0)!;
                userData['studentName'] = studentName[0].toUpperCase() + studentName.substring(1);
                userData['studentEnrollment'] = user.enrollmentNumber;
              }
            }
          }
          
          await prefs.setString('userData', json.encode(userData));
          print('=== LOGIN DEBUG ===');
          print('Selected role: $_selectedRole');
          print('Saved user data: ${json.encode(userData)}');
          print('==================');
        } else {
          print('Warning: User object is null in login response');
          // Store basic info to prevent crashes - handle parent role
          final userData = {
            'id': '1',
            'name': _selectedRole == 'parent' ? 'Parent' : 'Test User',
            'email': _emailController.text,
            'password': _passwordController.text,
            'currentSemester': 6,
            'role': _selectedRole,
          };
          
          // If parent role, extract student name from email
          if (_selectedRole == 'parent') {
            final emailParts = _emailController.text.split('@');
            if (emailParts.isNotEmpty) {
              final nameMatch = RegExp(r'^([a-zA-Z]+)').firstMatch(emailParts.first);
              if (nameMatch != null) {
                final studentName = nameMatch.group(0)!;
                userData['studentName'] = studentName[0].toUpperCase() + studentName.substring(1);
                userData['studentEnrollment'] = 'AUTO_GENERATED';
              }
            }
          }
          
          await prefs.setString('userData', json.encode(userData));
        }
        await prefs.setBool('isLoggedIn', true);
        
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Successful'),
            content: const Text('Welcome back!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainNavigation(
                        initialTabIndex: 0,
                        toggleTheme: widget.toggleTheme ?? () {},
                      ),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error dialog with custom message for timeout
        if (!mounted) return;
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Check if it's a timeout error
        if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
          errorMessage = 'Please check your internet connection and try again.';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Login',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: _selectedRole == 'parent' 
                  ? 'parent.email@marwadiuniversity.ac.in'
                  : 'student.email@marwadiuniversity.ac.in',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF03A9F4),
                  width: 2,
                ),
              ),
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.black.withOpacity(0.7),
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.3),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Role Selection
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedRole == 'parent' ? Colors.orange : const Color(0xFF03A9F4),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: (_selectedRole == 'parent' ? Colors.orange : const Color(0xFF03A9F4)).withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Row(
                    children: [
                      Text(
                        'Login as: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.7) 
                            : Colors.black.withOpacity(0.7),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'parent' ? Colors.orange : const Color(0xFF03A9F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedRole.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'student';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'student',
                                  groupValue: _selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                  activeColor: const Color(0xFF03A9F4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Student',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'parent';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'parent',
                                  groupValue: _selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                  activeColor: const Color(0xFF03A9F4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Parent',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF03A9F4),
                  width: 2,
                ),
              ),
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.3),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          
          const SizedBox(height: 8),
          
          // Login Button
          Center(
            child: SizedBox(
              width: 200, // Fixed width to center the button
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _performLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03A9F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Enable edge-to-edge mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF03A9F4),
              isDark ? Colors.black : Colors.white,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and App Name
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF03A9F4).withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF03A9F4),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school,
                              size: 50,
                              color: Color(0xFF03A9F4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'The Ictians',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF03A9F4),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student Performance Analyzer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Login Form
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark 
                                ? Colors.black.withOpacity(0.6) 
                                : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark 
                                  ? Colors.white.withOpacity(0.2) 
                                  : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: _buildForm(),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // App Info
                      Text(
                        'The Ictians App v1.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
