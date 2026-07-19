import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/shared/screens/login_screen.dart';
import 'package:smart_attendee/student_app/screens/student_dashboard_screen.dart';
import 'package:smart_attendee/teacher_app/screens/teacher_dashboard_screen.dart';
import 'package:smart_attendee/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _wordmarkFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // After minimum display time, check auth state and route
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final authService = AuthService();
    final token = await authService.getToken();

    if (!mounted) return;

    if (token != null) {
      // Decode JWT to get role without a network call
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          final role = payload['role'];
          final exp = payload['exp'];

          // Check if token is expired
          if (exp != null) {
            final expiry =
                DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
            if (DateTime.now().isAfter(expiry)) {
              // Token expired — clear it and go to login
              await authService.logout();
              _goToLogin();
              return;
            }
          }

          final roleString = role?.toString().toLowerCase();
          if (roleString == 'student') {
            _goTo(const StudentDashboardScreen());
          } else if (roleString == 'faculty') {
            _goTo(const TeacherDashboardScreen());
          } else {
            _goToLogin();
          }
          return;
        }
      } catch (_) {
        // Malformed token — treat as logged out
        await authService.logout();
      }
    }

    _goToLogin();
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name wordmark
                    FadeTransition(
                      opacity: _wordmarkFade,
                      child: Column(
                        children: [
                          Text(
                            'Smart Attendee',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Smart Attendance Management',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Loading indicator
                    FadeTransition(
                      opacity: _wordmarkFade,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                      ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
