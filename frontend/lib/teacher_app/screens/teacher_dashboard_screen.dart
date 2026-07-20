import 'package:flutter/material.dart';
import 'package:smart_attendee/services/attendance_service.dart';
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/services/faculty_service.dart';
import 'package:smart_attendee/shared/screens/login_screen.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';

import 'package:smart_attendee/shared/widgets/shimmer_loading.dart';
import 'package:smart_attendee/shared/widgets/logout_dialog.dart';
import 'package:smart_attendee/shared/widgets/session_summary_modal.dart';
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
  final AttendanceService _attendanceService = AttendanceService();

  late AnimationController _animationController;
  String? _facultyName;
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];
  List<dynamic> _recentSessions = [];

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
      // Ensure the slide animation finishes so the shimmer is visible
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final profileFuture = _facultyService.getFacultyProfile();
      final analyticsFuture = _facultyService.getFacultyAnalytics();
      final results = await Future.wait([profileFuture, analyticsFuture]);

      final profile = results[0];
      final analyticsData = results[1];
      final assignedClasses = analyticsData['classes'] as List<dynamic>? ?? [];
      final recentSessions = analyticsData['recentSessions'] as List<dynamic>? ?? [];

      setState(() {
        _facultyName = profile['name'];
        _classes = assignedClasses;
        _recentSessions = recentSessions;
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
    final bool? shouldLogout = await showLogoutDialog(context);

    if (shouldLogout != true) return;

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
              ? const DashboardSkeletonLoader()
              : _errorMessage != null
                  ? _buildErrorState()
                  : Column(
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

                                    // Create Session Card
                                    _buildSectionLabel(context, 'Create New Session'),
                                    CustomCard(
                                      margin: EdgeInsets.zero,
                                      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.5),
                                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardTheme.color : Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Class Dropdown
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<dynamic>(
                                                value: _selectedClass,
                                                borderRadius: BorderRadius.circular(16),
                                                dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
                                                isExpanded: true,
                                                hint: Text(
                                                  'Choose a class',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface),
                                                items: _classes.map<DropdownMenuItem<dynamic>>((cls) => DropdownMenuItem<dynamic>(
                                                  value: cls,
                                                  child: Text(
                                                    cls['className'] ?? 'Unnamed Class',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                                  ),
                                                )).toList(),
                                                onChanged: _onClassSelected,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: Responsive.getSpacing(context)),
                                          // Subject Dropdown
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _selectedClass == null
                                                  ? (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : AppTheme.lightGray.withValues(alpha: 0.5))
                                                  : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<dynamic>(
                                                value: _selectedSubject,
                                                borderRadius: BorderRadius.circular(16),
                                                dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
                                                isExpanded: true,
                                                hint: Text(
                                                  _selectedClass == null ? 'Select a class first' : 'Choose a subject',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                icon: Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  color: _selectedClass == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3) : Theme.of(context).colorScheme.onSurface,
                                                ),
                                                items: _subjects.map<DropdownMenuItem<dynamic>>((sub) => DropdownMenuItem<dynamic>(
                                                  value: sub,
                                                  child: Text(
                                                    sub['subjectName'] ?? 'Unnamed Subject',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                                  ),
                                                )).toList(),
                                                onChanged: _selectedClass == null ? null : (value) => setState(() => _selectedSubject = value),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: Responsive.getSpacing(context) * 2),
                                          // Generate Button
                                          CustomButton(
                                            text: 'Generate QR Code',
                                            icon: Icons.qr_code_2_rounded,
                                            type: ButtonType.gradient,
                                            width: double.infinity,
                                            onPressed: (_selectedClass != null && _selectedSubject != null)
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
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: Responsive.getSpacing(context) * 3),

                                    // Recent Sessions Section
                                    _buildSectionLabel(context, 'Recent Sessions'),
                                    if (_recentSessions.isNotEmpty) ...[
                                      ..._recentSessions.map((session) => _buildSessionCard(session)),
                                    ] else ...[
                                      CustomCard(
                                        padding: EdgeInsets.all(Responsive.getSpacing(context) * 2),
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                            ? Theme.of(context).colorScheme.surfaceContainerHighest 
                                            : AppTheme.lightGray,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'No recent sessions found',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).brightness == Brightness.dark 
                                                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) 
                                                      : AppTheme.darkGray,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: Responsive.getSpacing(context) * 2),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.getPadding(context).left, 
        Responsive.getSpacing(context) * 2.5, 
        Responsive.getPadding(context).right, 
        Responsive.getSpacing(context) * 1.5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Premium Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Middle: Greeting and Faculty Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} 👋',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _facultyName ?? 'Dr. Rajesh Kumar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : AppTheme.primaryBlack,
                        fontWeight: FontWeight.w800,
                        fontSize: Responsive.getFontSize(context, 22),
                        letterSpacing: -0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Right: Elegant Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: isDark ? Theme.of(context).colorScheme.onSurface : AppTheme.primaryBlack,
                  size: 22,
                ),
              ),
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

  Future<void> _showSessionDetails(dynamic session) async {
    final sessionId = session['sessionId'] ?? session['id'];
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Session ID is missing')),
      );
      return;
    }
    
    showSessionSummaryFutureModal(
      context,
      fetchFuture: _attendanceService.getSessionStats(sessionId),
      title: '${session['className']} - ${session['subjectName']}',
    );
  }

  // ── Session Card ────────────────────────────────────────────────────────
  Widget _buildSessionCard(dynamic session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.parse(session['date']).toLocal();
    final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final presentCount = session['presentCount'] ?? 0;
    final totalStudents = session['totalStudents'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => _showSessionDetails(session),
        child: CustomCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.5),
          backgroundColor: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          child: Row(
            children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session['className']} - ${session['subjectName']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_alt_rounded, size: 14, color: isDark ? Colors.white70 : AppTheme.darkGray),
                  const SizedBox(width: 4),
                  Text(
                    '$presentCount/$totalStudents',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.primaryBlack,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}