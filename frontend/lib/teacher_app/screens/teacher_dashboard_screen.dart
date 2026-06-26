import 'package:flutter/material.dart';
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/services/faculty_service.dart';
import 'package:smart_attendee/shared/screens/login_screen.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';
import 'package:smart_attendee/shared/widgets/loading_indicator.dart';
import 'package:smart_attendee/teacher_app/screens/qr_display_screen.dart';
import 'package:smart_attendee/utils/responsive.dart';
import 'package:smart_attendee/utils/theme.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with TickerProviderStateMixin {
  final FacultyService _facultyService = FacultyService();
  final AuthService _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _facultyName;
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];

  dynamic _selectedClass;
  dynamic _selectedSubject;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _fetchDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profileFuture = _facultyService.getFacultyProfile();
      final analyticsFuture = _facultyService.getFacultyAnalytics();
      final results = await Future.wait([profileFuture, analyticsFuture]);

      final profile = results[0];
      final analyticsData = results[1];
      final assignedClasses = analyticsData['classes'] as List<dynamic>? ?? [];

      setState(() {
        _facultyName = profile['name'];
        _classes = assignedClasses;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onClassSelected(dynamic selectedClass) {
    if (selectedClass == null) return;
    setState(() {
      _selectedClass = selectedClass;
      _subjects = selectedClass['subjects'] as List<dynamic>? ?? [];
      _selectedSubject = null;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
          child: _isLoading
              ? const LoadingIndicator(
                  message: 'Loading your dashboard...',
                  size: 50,
                )
              : _errorMessage != null
                  ? _buildErrorState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // ── Gradient Header ──────────────────────────
                            _buildHeader(),
                            // ── Content ──────────────────────────────────
                            Expanded(
                              child: SingleChildScrollView(
                                padding: Responsive.getPadding(context),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: Responsive.getSpacing(context)),

                                    // Class Selection Card
                                    _buildSectionLabel(context, 'Select Class'),
                                    CustomCard(
                                      margin: EdgeInsets.zero,
                                      padding: EdgeInsets.symmetric(horizontal: Responsive.getSpacing(context) * 1.5, vertical: 4),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<dynamic>(
                                          value: _selectedClass,
                                          borderRadius: BorderRadius.circular(16),
                                          dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
                                          isExpanded: true,
                                          hint: Text(
                                            'Choose a class',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          items: _classes
                                              .map<DropdownMenuItem<dynamic>>(
                                                (cls) => DropdownMenuItem<dynamic>(
                                                  value: cls,
                                                  child: Text(
                                                    cls['className'] ?? 'Unnamed Class',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _onClassSelected,
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: Responsive.getSpacing(context) * 1.5),

                                    // Subject Selection Card
                                    _buildSectionLabel(context, 'Select Subject'),
                                    CustomCard(
                                      margin: EdgeInsets.zero,
                                      padding: EdgeInsets.symmetric(horizontal: Responsive.getSpacing(context) * 1.5, vertical: 4),
                                      backgroundColor: _selectedClass == null
                                          ? (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray)
                                          : Theme.of(context).cardTheme.color,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<dynamic>(
                                          value: _selectedSubject,
                                          borderRadius: BorderRadius.circular(16),
                                          dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
                                          isExpanded: true,
                                          hint: Text(
                                            _selectedClass == null
                                                ? 'Select a class first'
                                                : 'Choose a subject',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _selectedClass == null
                                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                          items: _subjects
                                              .map<DropdownMenuItem<dynamic>>(
                                                (sub) => DropdownMenuItem<dynamic>(
                                                  value: sub,
                                                  child: Text(
                                                    sub['subjectName'] ?? 'Unnamed Subject',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _selectedClass == null
                                              ? null
                                              : (value) =>
                                                  setState(() => _selectedSubject = value),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: Responsive.getSpacing(context) * 4),

                                    // Info card when nothing selected
                                    if (_selectedClass == null || _selectedSubject == null)
                                      CustomCard(
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.25),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.info_outline_rounded,
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: Responsive.getSpacing(context) * 1.5),
                                            Expanded(
                                              child: Text(
                                                'Select a class and subject above to generate an attendance QR code.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    SizedBox(height: Responsive.getSpacing(context) * 2),

                                    // Generate QR Button
                                    CustomButton(
                                      text: 'Generate QR Code',
                                      icon: Icons.qr_code_2_rounded,
                                      type: ButtonType.gradient,
                                      width: double.infinity,
                                      onPressed: (_selectedClass != null &&
                                              _selectedSubject != null)
                                          ? () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => QRDisplayScreen(
                                                    classId: _selectedClass!['classId'],
                                                    subjectId: _selectedSubject!['subjectId'],
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                    ),

                                    SizedBox(height: Responsive.getSpacing(context) * 3),
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
  }

  // ── Dynamic Greeting ──────────────────────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // ── Rich Dashboard Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark ? Theme.of(context).colorScheme.onSurface : Colors.white;
    final subtitleColor = isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85);
    final headerIconBgColor = isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2);

    return Container(
      margin: EdgeInsets.fromLTRB(Responsive.getPadding(context).left, Responsive.getSpacing(context) * 2, Responsive.getPadding(context).right, 0),
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.5),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardTheme.color : null,
        gradient: isDark ? null : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 1.5),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: AppTheme.primaryBlack.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar & Logout Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.getSpacing(context) * 0.75),
                decoration: BoxDecoration(
                  color: headerIconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: headerTextColor,
                  size: Responsive.getIconSize(context, 24),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Logout',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: headerTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.logout_rounded,
                          color: headerTextColor,
                          size: Responsive.getIconSize(context, 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: Responsive.getSpacing(context) * 1.5),
          
          // Greeting and Faculty Details
          Text(
            '${_getGreeting()} 👋',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _facultyName ?? 'Dr. Rajesh Kumar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: headerTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.getFontSize(context, 22),
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.getSpacing(context) * 3),
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: _fetchDashboardData,
                type: ButtonType.gradient,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.only(
        left: Responsive.getSpacing(context) * 0.5,
        bottom: Responsive.getSpacing(context) * 0.75,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8) : AppTheme.darkGray,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}