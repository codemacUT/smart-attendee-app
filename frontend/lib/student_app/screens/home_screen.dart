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

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> with TickerProviderStateMixin {
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
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Custom Header
                              Container(
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
                                            'Hi, ${_getStudentName()}! 👋',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: Responsive.getFontSize(context, 20),
                                            ),
                                          ),
                                          Text(
                                            '${_getClassName()} • Ready to mark your attendance?',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
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
                                        borderRadius: BorderRadius.circular(
                                            Responsive.getSpacing(context) * 0.75),
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
                              ),
                              
                              // Main Content
                              Padding(
                                padding: Responsive.getPadding(context),
                                child: Column(
                                  children: [
                        // Quick Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Total Present',
                                value: '${_getTotalPresent()}',
                                icon: Icons.check_circle_rounded,
                                iconColor: Colors.green,
                              ),
                            ),
                            SizedBox(width: Responsive.getSpacing(context) * 2),
                            Expanded(
                              child: StatCard(
                                title: 'Total Absent',
                                value: '${_getTotalAbsent()}',
                                icon: Icons.cancel_rounded,
                                iconColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: Responsive.getSpacing(context)),
                        
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Attendance %',
                                value: '${_getAttendancePercentage()}%',
                                icon: Icons.trending_up_rounded,
                                iconColor: AppTheme.primaryBlack,
                              ),
                            ),
                            SizedBox(width: Responsive.getSpacing(context) * 2),
                            Expanded(
                              child: StatCard(
                                title: 'Subjects',
                                value: '${_getSubjectsCount()}',
                                icon: Icons.school_rounded,
                                iconColor: AppTheme.primaryBlack,
                              ),
                            ),
                          ],
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
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 1.5),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: Responsive.getIconSize(context, 50),
                                  color: Colors.white,
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
                            ],
                          ),
                        ),
                        
                        SizedBox(height: Responsive.getSpacing(context) * 1.5),
                        
                        // Info Card
                        CustomCard(
                          backgroundColor: AppTheme.lightGray,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlack,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location Required',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ensure your location is enabled to mark attendance',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.darkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: Responsive.getSpacing(context) * 1.5),
                        
                        // Recent Activity Card
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    color: AppTheme.primaryBlack,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Subject Attendance',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ..._buildSubjectItems(context),
                              // View all / Show less toggle
                              if (_getSubjectsCount() > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton.icon(
                                    onPressed: () => setState(
                                        () => _showAllSubjects = !_showAllSubjects),
                                    icon: Icon(
                                      _showAllSubjects
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      size: 18,
                                      color: AppTheme.primaryBlack,
                                    ),
                                    label: Text(
                                      _showAllSubjects
                                          ? 'Show less'
                                          : 'View all ${_getSubjectsCount()} subjects',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.primaryBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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
          )
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                  color: AppTheme.darkGray,
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
          AppTheme.mediumGray,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray),
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
                    color: AppTheme.darkGray,
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
}