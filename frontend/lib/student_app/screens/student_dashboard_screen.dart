import 'package:flutter/material.dart';
import 'package:smart_attendee/student_app/screens/qr_scanner_screen.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';

import 'package:smart_attendee/shared/widgets/shimmer_loading.dart';
import 'package:smart_attendee/services/student_analytics_service.dart';
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/shared/screens/login_screen.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';
import 'package:smart_attendee/shared/widgets/logout_dialog.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final StudentAnalyticsService _analyticsService = StudentAnalyticsService();
  final AuthService _authService = AuthService();
  
  // State variables for student data
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _studentProfile;
  bool _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fetchStudentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentData() async {
    try {
      // Ensure the slide animation finishes so the shimmer is visible
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch both analytics and profile data
      final analyticsResult = await _analyticsService.getStudentAnalytics();
      final profileResult = await _analyticsService.getStudentProfile();

      if (analyticsResult['success']) {
        setState(() {
          _studentData = analyticsResult['data'];
        });
      } else {
        _errorMessage = analyticsResult['message'];
      }

      if (profileResult['success']) {
        setState(() {
          _studentProfile = profileResult['data'];
        });
      } else {
        // Profile failed non-critically — analytics may still display
      }

      // If both fail, show error
      if (!analyticsResult['success'] && !profileResult['success']) {
        setState(() {
          _errorMessage = 'Failed to load student data. Please try again.';
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _onScanPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          onAttendanceMarked: _fetchStudentData,
        ),
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
          child: _isLoading
              ? const DashboardSkeletonLoader()
              : _errorMessage != null
                  ? _buildErrorState()
                  : SingleChildScrollView(
                          child: Column(
                            children: [
                              // Custom Header
                              _buildHeader(),
                              
                              // Main Content
                              Padding(
                                padding: Responsive.getPadding(context),
                                child: Column(
                                  children: [
                        // Hero Stat Card
                        CustomCard(
                          padding: EdgeInsets.all(Responsive.getSpacing(context) * 2),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.analytics_rounded, color: isDark ? Theme.of(context).colorScheme.onPrimary : Colors.white, size: 32),
                              ),
                              SizedBox(width: Responsive.getSpacing(context) * 2),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall Attendance',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: isDark ? Theme.of(context).colorScheme.onSurface : AppTheme.darkGray,
                                    ),
                                  ),
                                  Text(
                                    '${_getAttendancePercentage()}%',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: Responsive.getSpacing(context) * 2),
                        
                        // Risk Warning Banner (if applicable)
                        if (_hasRiskWarning())
                          CustomCard(
                            backgroundColor: Colors.orange.withValues(alpha: 0.1),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.orange,
                                  size: Responsive.getIconSize(context, 24),
                                ),
                                SizedBox(width: Responsive.getSpacing(context) * 1.5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attendance Alert',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: Responsive.getFontSize(context, 16),
                                        ),
                                      ),
                                      SizedBox(height: Responsive.getSpacing(context) / 2),
                                      Text(
                                        'Your attendance is below the required threshold. Please attend more classes.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.orange.shade700,
                                          fontSize: Responsive.getFontSize(context, 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (_hasRiskWarning()) SizedBox(height: Responsive.getSpacing(context)),
                        
                        // Main Action Card
                        CustomCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.qr_code_scanner_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Ready for Class?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_rounded, size: 14, color: AppTheme.darkGray),
                                            const SizedBox(width: 4),
                                            Text('Location required', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkGray)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Scan QR Code',
                                icon: Icons.camera_alt_rounded,
                                onPressed: _onScanPressed,
                                type: ButtonType.gradient,
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: Responsive.getSpacing(context) * 1.5),
                        
                        // Details Card (Subjects / History)
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Heading
                              _buildSectionLabel(context, 'My Subjects'),
                              const SizedBox(height: 16),
                              ..._buildRecentSessions(context),
                              
                              // Decorative Footer
                              const SizedBox(height: 32),
                              _buildDecorativeFooter(context),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: Responsive.getSpacing(context) * 2.5),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
          ),
    );
  }

  Widget _buildDecorativeFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            "You're all caught up for today!",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : AppTheme.darkGray.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.getSpacing(context) * 3),
        child: CustomCard(
        child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              Icon(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              textAlign: TextAlign.center,
              ),
                              SizedBox(height: Responsive.getSpacing(context) * 1.5),
              CustomButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: _fetchStudentData,
                type: ButtonType.gradient,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  // Helper methods to extract data from API response
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
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Middle: Greeting and Name
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
                  _getStudentName(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : AppTheme.primaryBlack,
                        fontWeight: FontWeight.w800,
                        fontSize: Responsive.getFontSize(context, 22),
                        letterSpacing: -0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_getClassName() != 'Class') ...[
                  const SizedBox(height: 2),
                  Text(
                    _getClassName(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
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

  String _getStudentName() {
    if (_studentProfile != null) {
      return _studentProfile!['name'] ?? 
             _studentProfile!['studentName'] ?? 
             _studentProfile!['firstName'] ?? 
             'Student';
    }
    return 'Student';
  }

  String _getClassName() {
    if (_studentData != null) {
      return _studentData!['className'] ?? 
             _studentData!['class'] ?? 
             _studentData!['class_name'] ?? 
             'Class';
    }
    return 'Class';
  }

  double _getAttendancePercentage() {
    if (_studentData != null) {
      final overall = _studentData!['overall'];
      if (overall != null) {
        return (overall['attendancePct'] ?? 0.0).toDouble();
      }
    }
    return 0.0;
  }

  bool _hasRiskWarning() {
    if (_studentData != null && _studentData!['prediction'] != null) {
      return _studentData!['prediction']['risk'] == true;
    }
    return false;
  }

  Widget _buildActivityItem(
    BuildContext context,
    String subject,
    String status,
    String time,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 2),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentSessions(BuildContext context) {
    if (_studentData == null || _studentData!['recentSessions'] == null || (_studentData!['recentSessions'] as List).isEmpty) {
      return [
        _buildActivityItem(
          context,
          'No recent sessions',
          'N/A',
          'N/A',
          Icons.info_rounded,
          Theme.of(context).colorScheme.primary,
        ),
      ];
    }

    final sessions = _studentData!['recentSessions'] as List;
    final Map<String, List<dynamic>> groupedSessions = {};
    for (var session in sessions) {
      final subjectName = session['subjectName'] ?? 'Unknown Subject';
      if (!groupedSessions.containsKey(subjectName)) {
        groupedSessions[subjectName] = [];
      }
      groupedSessions[subjectName]!.add(session);
    }

    final List<Widget> items = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    for (var entry in groupedSessions.entries) {
      final subjectName = entry.key;
      final subjectSessions = entry.value;

      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                subjectName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${subjectSessions.length} Session${subjectSessions.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                ),
              ),
              leading: Icon(Icons.class_rounded, color: Theme.of(context).colorScheme.primary),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: subjectSessions.map((session) {
                final status = session['status'] ?? 'absent';
                final date = DateTime.parse(session['date']).toLocal();
                final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                
                final isPresent = status.toLowerCase() == 'present';
                final displayStatus = isPresent ? 'Present' : 'Absent';
                final color = isPresent ? Colors.green : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8) : AppTheme.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayStatus,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return items;
  }
}