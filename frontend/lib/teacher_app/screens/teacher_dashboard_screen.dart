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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightGray, Colors.white],
          ),
        ),
        child: SafeArea(
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
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<dynamic>(
                                          value: _selectedClass,
                                          isExpanded: true,
                                          hint: Text(
                                            'Choose a class',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppTheme.accentGray,
                                                ),
                                          ),
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: AppTheme.darkGray,
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
                                      backgroundColor: _selectedClass == null
                                          ? AppTheme.lightGray
                                          : Colors.white,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<dynamic>(
                                          value: _selectedSubject,
                                          isExpanded: true,
                                          hint: Text(
                                            _selectedClass == null
                                                ? 'Select a class first'
                                                : 'Choose a subject',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppTheme.accentGray,
                                                ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _selectedClass == null
                                                ? AppTheme.mediumGray
                                                : AppTheme.darkGray,
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
                                        backgroundColor: AppTheme.lightGray,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlack,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.info_outline_rounded,
                                                color: Colors.white,
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
                                                    ?.copyWith(color: AppTheme.darkGray),
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
      ),
    );
  }

  // ── Gradient Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: Responsive.getMargin(context),
      padding: Responsive.getCardPadding(context),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.getSpacing(context) * 0.75),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 0.75),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: Responsive.getIconSize(context, 20),
            ),
          ),
          SizedBox(width: Responsive.getSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${_facultyName ?? 'Faculty'}! 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: Responsive.getFontSize(context, 18),
                      ),
                ),
                Text(
                  'Select class & subject to start a session',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: Responsive.getFontSize(context, 12),
                      ),
                ),
              ],
            ),
          ),
          // Logout button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 0.75),
            ),
            child: IconButton(
              onPressed: _logout,
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: Responsive.getIconSize(context, 20),
              ),
              tooltip: 'Logout',
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
        padding: const EdgeInsets.all(24),
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
                    ?.copyWith(color: AppTheme.darkGray),
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
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}