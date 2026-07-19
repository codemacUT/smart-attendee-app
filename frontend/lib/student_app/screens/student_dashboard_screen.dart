import 'package:flutter/material.dart';
import 'package:smart_attendee/student_app/screens/qr_scanner_screen.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/shared/widgets/loading_indicator.dart';
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final StudentAnalyticsService _analyticsService = StudentAnalyticsService();
  final AuthService _authService = AuthService();
  
  // State variables for student data
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _studentProfile;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showAllSubjects = false;
  int _selectedTab = 0;

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
    
    _fetchStudentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentData() async {
    try {
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
                        child: SingleChildScrollView(
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
                                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 32),
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
                          child: Column(
                            children: [
                              Container(
                                padding: Responsive.getCardPadding(context),
                                decoration: BoxDecoration(
                                  color: isDark ? Theme.of(context).colorScheme.surface : null,
                                  gradient: isDark ? null : AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 1.5),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: Responsive.getIconSize(context, 50),
                                  color: isDark ? Theme.of(context).colorScheme.onSurface : Colors.white,
                                ),
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 1.5),
                              Text(
                                'Mark Your Attendance',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: Responsive.getFontSize(context, 20),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.getSpacing(context) / 2),
                              Text(
                                'Scan the QR code displayed by your teacher to mark your attendance',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.darkGray,
                                  fontSize: Responsive.getFontSize(context, 14),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 2),
                              CustomButton(
                                text: 'Scan QR Code',
                                icon: Icons.qr_code_scanner_rounded,
                                onPressed: _onScanPressed,
                                type: ButtonType.gradient,
                                width: double.infinity,
                              ),
                              SizedBox(height: Responsive.getSpacing(context) * 1.5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Location Required for Attendance',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                              // Custom Tab Bar
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedTab = 0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _selectedTab == 0 ? (isDark ? Theme.of(context).colorScheme.surface : Colors.white) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: _selectedTab == 0 ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ] : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Overview',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                                              color: _selectedTab == 0 ? Theme.of(context).colorScheme.onSurface : (isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedTab = 1),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _selectedTab == 1 ? (isDark ? Theme.of(context).colorScheme.surface : Colors.white) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: _selectedTab == 1 ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ] : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'History',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                                              color: _selectedTab == 1 ? Theme.of(context).colorScheme.onSurface : (isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_selectedTab == 0) ...[
                                ..._buildSubjectItems(context),
                                if (_getSubjectsCount() > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Center(
                                      child: TextButton.icon(
                                        onPressed: () => setState(() => _showAllSubjects = !_showAllSubjects),
                                        icon: Icon(
                                          _showAllSubjects ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        label: Text(
                                          _showAllSubjects ? 'Show less' : 'View all ${_getSubjectsCount()} subjects',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ] else ...[
                                ..._buildRecentSessions(context),
                              ],
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
                    ),
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
                  Icons.person_rounded, // Standard icon for student
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
          
          // Greeting and Student Details
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
            _getStudentName(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: headerTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.getFontSize(context, 22),
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _getClassName(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
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

  int _getTotalPresent() {
    if (_studentData != null) {
      // Accessing nested `overall.totalPresent`
      final overall = _studentData!['overall'];
      if (overall != null) {
        return overall['totalPresent'] ?? 0;
      }
    }
    return 0;
  }

  int _getTotalAbsent() {
    if (_studentData != null) {
      final overall = _studentData!['overall'];
      if (overall != null) {
        return overall['totalAbsent'] ?? 0;
      }
    }
    return 0;
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

  int _getSubjectsCount() {
    if (_studentData != null && _studentData!['subjects'] != null) {
      return (_studentData!['subjects'] as List).length;
    }
    return 0;
  }

  bool _hasRiskWarning() {
    if (_studentData != null && _studentData!['prediction'] != null) {
      return _studentData!['prediction']['risk'] == true;
    }
    return false;
  }

  List<Widget> _buildSubjectItems(BuildContext context) {
    if (_studentData == null || _studentData!['subjects'] == null) {
      return [
        _buildActivityItem(
          context,
          'No subjects available',
          'N/A',
          'N/A',
          Icons.info_rounded,
          Theme.of(context).colorScheme.primary,
        ),
      ];
    }

    final subjects = _studentData!['subjects'] as List;
    final List<Widget> items = [];
    // Show top 3 unless _showAllSubjects is true
    final limit = _showAllSubjects ? subjects.length : (subjects.length < 3 ? subjects.length : 3);

    for (int i = 0; i < limit; i++) {
      final subject = subjects[i];
      final subjectName = subject['subjectName'] ?? 
                         subject['subject_name'] ?? 
                         subject['name'] ?? 
                         'Subject ${i + 1}';
      final attendancePct = subject['attendancePct'] ?? 
                            subject['attendance_pct'] ?? 
                            subject['percentage'] ?? 
                            0.0;
      
      final isGoodAttendance = attendancePct >= 75.0;
      final status = isGoodAttendance ? 'Good' : 'Low';
      final icon = isGoodAttendance ? Icons.check_circle_rounded : Icons.warning_rounded;
      final color = isGoodAttendance ? Colors.green : Colors.orange;

      items.add(
        _buildActivityItem(
          context,
          subjectName,
          status,
          '${attendancePct.toStringAsFixed(1)}%',
          icon,
          color,
        ),
      );

      if (i < limit - 1) {
        items.add(const SizedBox(height: 12));
      }
    }

    return items;
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
    final List<Widget> items = [];
    final limit = sessions.length > 5 ? 5 : sessions.length; // Show up to 5 recent sessions

    for (int i = 0; i < limit; i++) {
      final session = sessions[i];
      final subjectName = session['subjectName'] ?? 'Unknown Subject';
      final status = session['status'] ?? 'absent';
      final date = DateTime.parse(session['date']).toLocal();
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      
      final isPresent = status.toLowerCase() == 'present';
      final displayStatus = isPresent ? 'Present' : 'Absent';
      final icon = isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded;
      final color = isPresent ? Colors.green : Colors.red;

      items.add(
        _buildActivityItem(
          context,
          subjectName,
          displayStatus,
          formattedDate,
          icon,
          color,
        ),
      );

      if (i < limit - 1) {
        items.add(const SizedBox(height: 12));
      }
    }

    return items;
  }
}