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
  late AnimationController _waveController;
  late AnimationController _textController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _waveAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  
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
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
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
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );
    
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.elasticOut,
      ),
    );
    
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _controller.forward();
    _particleController.forward();
    
    // Start text animation after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });
    
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
    _waveController.dispose();
    _textController.dispose();
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
            // Animated wave background
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_waveAnimation.value, isDark),
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                );
              },
            ),
            
            // Enhanced animated particles in background
            ...List.generate(40, (index) {
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
                        // Enhanced app name with gradient and slide animation
                        SlideTransition(
                          position: _textSlideAnimation,
                          child: FadeTransition(
                            opacity: _textFadeAnimation,
                            child: AnimatedBuilder(
                              animation: _particleController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + 0.05 * math.sin(_particleController.value * 2 * math.pi),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: [
                                          _colorAnimation.value ?? const Color(0xFF03A9F4),
                                          const Color(0xFF00BCD4),
                                          const Color(0xFF4FC3F7),
                                          _colorAnimation.value ?? const Color(0xFF03A9F4),
                                        ],
                                        stops: [
                                          0.0,
                                          _particleController.value * 0.5,
                                          _particleController.value,
                                          1.0,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      'The Ictians',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2.5,
                                        shadows: [
                                          Shadow(
                                            color: Color(0xFF03A9F4),
                                            blurRadius: 15,
                                            offset: Offset(0, 3),
                                          ),
                                          Shadow(
                                            color: Color(0xFF00BCD4),
                                            blurRadius: 25,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Tagline with slide and fade animation
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _textController,
                              curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _textController,
                                curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                              ),
                            ),
                            child: Text(
                              'Student Performance Analyzer',
                              style: TextStyle(
                                fontSize: 17,
                                color: isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
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

class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  WavePainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? const Color(0xFF03A9F4) : const Color(0xFF00BCD4)).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.7 + 
          waveHeight * math.sin((x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave
    final paint2 = Paint()
      ..color = (isDark ? const Color(0xFF00BCD4) : const Color(0xFF03A9F4)).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.8 + 
          waveHeight * 0.7 * math.sin((x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi) + math.pi);
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}