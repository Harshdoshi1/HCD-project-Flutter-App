import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  
  const SplashScreen({super.key, required this.toggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
    
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_controller);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );
    
    _blurAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOut,
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: const Color(0xFF03A9F4),
      end: const Color(0xFF00BCD4),
    ).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOut,
      ),
    );
    
    _controller.forward();
    _particleController.forward();
    
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final userDataString = prefs.getString('userData');
      
      // Check if we have saved credentials and user data
      if (isLoggedIn && savedEmail != null && savedPassword != null && userDataString != null) {
        try {
          // Parse and set user data in provider
          final userData = json.decode(userDataString);
          if (!mounted) return;
          
          // Set user data in provider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final user = User.fromJson(userData);
          userProvider.setUser(user);
          
          setState(() {
            _isLoggedIn = true;
          });
          
          debugPrint('Auto-login successful with saved credentials');
        } catch (e) {
          debugPrint('Error parsing saved user data: $e');
          // Clear corrupted data and go to login
          await prefs.clear();
          setState(() {
            _isLoggedIn = false;
          });
        }
      } else {
        setState(() {
          _isLoggedIn = false;
        });
      }
      
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (_isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigation(
                toggleTheme: widget.toggleTheme,
                initialTabIndex: 0,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(toggleTheme: widget.toggleTheme),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error checking session: $e');
      // Fallback to login page if there's an error
      Future.delayed(const Duration(milliseconds: 3000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(toggleTheme: widget.toggleTheme),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
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
        child: Stack(
          children: [
            // Enhanced animated particles in background
            ...List.generate(30, (index) {
              final random = index / 30;
              final size = 6.0 + (index % 12);
              return AnimatedBuilder(
                animation: Listenable.merge([_controller, _particleController]),
                builder: (context, child) {
                  final particleX = (random + 0.3 * _particleController.value) % 1;
                  final particleY = ((random * 3 + 0.2 * _particleController.value) % 1);
                  final opacity = (0.3 + 0.4 * (1 + math.sin(_particleController.value * 2 * 3.14159 + index)) / 2) * _fadeAnimation.value;
                  
                  return Positioned(
                    left: MediaQuery.of(context).size.width * particleX,
                    top: MediaQuery.of(context).size.height * particleY,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: _colorAnimation.value ?? const Color(0xFF03A9F4),
                            borderRadius: BorderRadius.circular(size / 2),
                            boxShadow: [
                              BoxShadow(
                                color: (_colorAnimation.value ?? const Color(0xFF03A9F4)).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Enhanced animated logo with multiple effects
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value * 0.1, // Subtle rotation
                            child: Transform.scale(
                              scale: _logoScaleAnimation.value,
                              child: AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  return Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(35),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_colorAnimation.value ?? const Color(0xFF03A9F4)).withOpacity(0.6),
                                          blurRadius: 25 + 10 * _pulseAnimation.value,
                                          spreadRadius: 5 + 3 * _pulseAnimation.value,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 40,
                                          spreadRadius: -5,
                                          offset: const Offset(-10, -10),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: _colorAnimation.value ?? const Color(0xFF03A9F4),
                                        width: 3,
                                      ),
                                      gradient: RadialGradient(
                                        colors: [
                                          (isDark ? Colors.black : Colors.white).withOpacity(0.9),
                                          (isDark ? Colors.black : Colors.white).withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Icon(
                                          Icons.school,
                                          size: 65,
                                          color: _colorAnimation.value ?? const Color(0xFF03A9F4),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Enhanced app name with gradient and animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedBuilder(
                            animation: _particleController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      _colorAnimation.value ?? const Color(0xFF03A9F4),
                                      const Color(0xFF00BCD4),
                                      _colorAnimation.value ?? const Color(0xFF03A9F4),
                                    ],
                                    stops: [
                                      0.0,
                                      _particleController.value,
                                      1.0,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'The Ictians',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF03A9F4),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Tagline with fade animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Student Performance Analyzer',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Enhanced loading indicator with pulsing effect
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedBuilder(
                            animation: _particleController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _colorAnimation.value ?? const Color(0xFF03A9F4),
                                    ),
                                    strokeWidth: 4,
                                    backgroundColor: (_colorAnimation.value ?? const Color(0xFF03A9F4)).withOpacity(0.2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}