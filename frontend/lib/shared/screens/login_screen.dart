import 'package:flutter/material.dart';
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/student_app/screens/home_screen.dart';
import 'package:smart_attendee/teacher_app/screens/teacher_dashboard_screen.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'faculty1@example.com');
  final _passwordController = TextEditingController(text: 'faculty123');
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

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.mediumGray),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 36,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reset Password',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Password resets are managed by your institution administrator.\n\nPlease contact your admin with your registered email to get a new password.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Got it',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightGray, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: Responsive.getPadding(context),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: Responsive.getSpacing(context) * 5),
                    // Logo and Title Section
                    Container(
                      padding: EdgeInsets.all(Responsive.getSpacing(context) * 2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: Responsive.getIconSize(context, 50),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: Responsive.getSpacing(context) * 3),
                    Text(
                      'SmartAttendee',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: Responsive.getFontSize(context, 32),
                      ),
                    ),
                    SizedBox(height: Responsive.getSpacing(context)),
                    Text(
                      'Smart Attendance Management System',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.darkGray,
                        fontSize: Responsive.getFontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: Responsive.getSpacing(context) * 6),
                    
                    // Login Form Card
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: Responsive.getFontSize(context, 24),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Responsive.getSpacing(context)),
                          Text(
                            'Sign in to continue',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.darkGray,
                              fontSize: Responsive.getFontSize(context, 14),
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
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                  fontSize: Responsive.getFontSize(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: Responsive.getSpacing(context) * 4),
                    
                    // Demo Credentials Card
                    CustomCard(
                      backgroundColor: AppTheme.lightGray,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.darkGray,
                                size: Responsive.getIconSize(context, 20),
                              ),
                              SizedBox(width: Responsive.getSpacing(context)),
                              Text(
                                'Demo Credentials',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: Responsive.getFontSize(context, 18),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.getSpacing(context) * 1.5),
                          Container(
                            padding: Responsive.getCardPadding(context),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Responsive.getSpacing(context)),
                              border: Border.all(color: AppTheme.mediumGray),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Faculty: ',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: Responsive.getFontSize(context, 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'faculty1@example.com / faculty123',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: Responsive.getFontSize(context, 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Responsive.getSpacing(context) / 2),
                                Row(
                                  children: [
                                    Text(
                                      'Student: ',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: Responsive.getFontSize(context, 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'student1@example.com / student123',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: Responsive.getFontSize(context, 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: Responsive.getSpacing(context) * 5),
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