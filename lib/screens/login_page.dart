import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'main_navigation.dart';
import '../services/auth_service.dart';

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
  final _authService = AuthService();
  
  final _emailController = TextEditingController();
  final _enrollmentController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
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
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _enrollmentController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _authService.login(
          _emailController.text,
          _enrollmentController.text,
          context,
        );

        if (!mounted) return;

        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        
        // Save the complete user data as JSON string
        final user = response['user'];
        await prefs.setString('userData', json.encode(user.toJson()));
        await prefs.setBool('isLoggedIn', true);
        
        setState(() {
          _isLoading = false;
        });

        // Navigate to main screen
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              initialTabIndex: 0,
              toggleTheme: widget.toggleTheme ?? () {},
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
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
              hintText: 'youremail@marwadieducation.edu.in',
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
          
          // Enrollment Number Field
          TextFormField(
            controller: _enrollmentController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: 'Enrollment Number',
              prefixIcon: Icon(
                Icons.numbers,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your enrollment number';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Show forgot password dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset functionality will be implemented in future updates'),
                  ),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF03A9F4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Login Button
          SizedBox(
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
