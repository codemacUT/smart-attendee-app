import 'package:flutter/material.dart';
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/student_app/screens/home_screen.dart';
import 'package:smart_attendee/teacher_app/screens/teacher_dashboard_screen.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['role'];
        if (role == 'Student') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          );
        } else if (role == 'Faculty') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.45,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.mediumGray),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 32,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reset Password',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Password resets are managed by your institution.\n\nPlease contact your administrator to regain access.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
                fontSize: Responsive.getFontSize(context, 13),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Got it',
                type: ButtonType.primary,
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showTopToast(String message, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Demo Access (Top Right)
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    final isFaculty = value == 'faculty';
                                    
                                    setState(() {
                                      _emailController.text = isFaculty ? 'faculty1@example.com' : 'student1@example.com';
                                      _passwordController.text = isFaculty ? 'faculty123' : 'student123';
                                    });
                                    
                                    _showTopToast(
                                      '${isFaculty ? 'Faculty' : 'Student'} demo credentials applied',
                                      isFaculty ? Icons.badge_outlined : Icons.school,
                                    );
                                  },
                                  offset: const Offset(0, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: Theme.of(context).colorScheme.surface,
                                  elevation: 8,
                                  tooltip: 'Demo Credentials',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                    color: Colors.transparent,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline, 
                                          size: Responsive.getIconSize(context, 16),
                                          color: AppTheme.darkGray,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Demo Access',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.darkGray,
                                            fontWeight: FontWeight.w600,
                                            fontSize: Responsive.getFontSize(context, 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (context) {
                                    final color = Theme.of(context).textTheme.bodyMedium?.color;
                                    return [
                                      PopupMenuItem(
                                        value: 'faculty',
                                        height: 36,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.badge_outlined, size: 16, color: color),
                                            const SizedBox(width: 8),
                                            Text('Faculty Demo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'student',
                                        height: 36,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.school, size: 16, color: color),
                                            const SizedBox(width: 8),
                                            Text('Student Demo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Hero Section (Logo + Title + Tagline)
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const Spacer(flex: 2),
                              Container(
                                padding: EdgeInsets.all(Responsive.getSpacing(context) * 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  size: Responsive.getIconSize(context, 72),
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 2.5),
                              Text(
                                'Smart Attendee',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  fontSize: Responsive.getFontSize(context, 32),
                                ),
                              ),
                              SizedBox(height: Responsive.getSpacing(context)),
                              Text(
                                'Secure • Automated • Location-Verified Attendance',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.darkGray.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.getFontSize(context, 12),
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24), // Minimum gap to prevent slamming when keyboard opens
                              const Spacer(flex: 2),
                            ],
                          ),
                        ),
                      ),
                      
                      // Bottom Split Section (Login Form)
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            Responsive.getSpacing(context) * 3,
                            Responsive.getSpacing(context) * 4,
                            Responsive.getSpacing(context) * 3,
                            Responsive.getSpacing(context) * 4 + MediaQuery.of(context).padding.bottom,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign in to continue',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: Responsive.getFontSize(context, 20),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 4),
                              
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email / ID',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: Responsive.getIconSize(context, 20),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getSpacing(context),
                                    vertical: Responsive.getSpacing(context),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 16),
                                ),
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 2.5),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    size: Responsive.getIconSize(context, 20),
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: Responsive.getIconSize(context, 20),
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getSpacing(context),
                                    vertical: Responsive.getSpacing(context),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 16),
                                ),
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 4),
                              
                              // Login Button
                              CustomButton(
                                text: 'Sign In',
                                icon: Icons.login_rounded,
                                onPressed: _isLoading ? null : _login,
                                isLoading: _isLoading,
                                type: ButtonType.gradient,
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 2.5),
                              
                              // Forgot Password
                              Center(
                                child: TextButton(
                                  onPressed: _showForgotPasswordSheet,
                                  child: Text(
                                    'Forgot Password?',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white.withValues(alpha: 0.7) 
                                          : AppTheme.primaryBlack.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                      fontSize: Responsive.getFontSize(context, 14),
                                    ),
                                  ),
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
          );
        },
      ),
    ));
  }
}
