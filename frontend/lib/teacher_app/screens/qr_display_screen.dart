import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_attendee/services/attendance_service.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';

import 'package:smart_attendee/shared/widgets/loading_indicator.dart';
import 'package:smart_attendee/shared/widgets/session_summary_modal.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';

class QRDisplayScreen extends StatefulWidget {
  final int classId;
  final int subjectId;
  const QRDisplayScreen({
    super.key,
    required this.classId,
    required this.subjectId,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AttendanceService _attendanceService = AttendanceService();
  String? _qrData;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Session management
  int? _sessionId;
  List<Map<String, dynamic>> _students = [];
  int _timeRemaining = 300; // 5 minutes in seconds
  static const int _sessionDuration = 300;
  DateTime? _sessionStartTime;
  Timer? _timer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _generateQr();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _timer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _sessionStartTime != null) {
      // Recalculate remaining time from wall-clock to prevent drift
      final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
      final remaining = _sessionDuration - elapsed;
      if (mounted) {
        setState(() => _timeRemaining = remaining.clamp(0, _sessionDuration));
        if (remaining <= 0) _endSession();
      }
    }
  }

  Future<void> _generateQr() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await _attendanceService.generateQrSession(
        classId: widget.classId,
        subjectId: widget.subjectId,
      );

      if (result['success']) {
        final data = result['data'];

        setState(() {
          _qrData = data['qrSessionId']?.toString() ??
                   data['sessionId']?.toString() ??
                   data['id']?.toString() ??
                   'test_qr_${DateTime.now().millisecondsSinceEpoch}';
          _sessionId = data['sessionId'] ??
                      int.tryParse(data['qrSessionId']?.toString() ?? '') ??
                      int.tryParse(data['id']?.toString() ?? '');
        });

        _startTimers();
        _animationController.reset();
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = 'Failed to generate QR code: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating QR code. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshQr() async {
    if (_sessionId == null) {
      return _generateQr();
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await _attendanceService.refreshQrSession(
        sessionId: _sessionId!,
      );

      if (result['success']) {
        _startTimers();
        _animationController.reset();
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = 'Failed to refresh QR code: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error refreshing QR code. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTimers() {
    _timer?.cancel();
    _pollingTimer?.cancel();
    
    _timeRemaining = _sessionDuration;
    _sessionStartTime = DateTime.now();
    
    // Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            timer.cancel();
            _endSession();
          }
        });
      }
    });

    // Polling timer for student status
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollStudentStatus();
    });
  }

  Future<void> _pollStudentStatus() async {
    if (_sessionId == null) return;
    
    try {
      final result = await _attendanceService.getSessionDetails(_sessionId!);
      if (mounted && result['success']) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(result['data']['students'] ?? []);
        });
      }
    } catch (e) {
      // Silently handle polling errors
    }
  }

  Future<void> _confirmEndSession() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bool? shouldEnd = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context).left),
          backgroundColor: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.getSpacing(context) * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 60,
                ),
                SizedBox(height: Responsive.getSpacing(context) * 1.5),
                Text(
                  'End Session?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.getSpacing(context)),
                Text(
                  'Are you sure you want to close this session? The QR code will immediately expire.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        type: ButtonType.secondary,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    SizedBox(width: Responsive.getSpacing(context)),
                    Expanded(
                      child: CustomButton(
                        text: 'End Session',
                        type: ButtonType.gradient,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldEnd == true) {
      _endSession();
    }
  }

  Future<void> _endSession() async {
    _timer?.cancel();
    _pollingTimer?.cancel();

    int presentCount = 0;
    int totalCount = 0;
    List<dynamic> presentStudents = [];
    List<dynamic> absentStudents = [];

    if (_sessionId != null) {
      try {
        await _attendanceService.endSession(_sessionId!);
        final statsRes = await _attendanceService.getSessionStats(_sessionId!);
        if (statsRes['success'] == true) {
          final data = statsRes['data'];
          presentCount = data['presentCount'] ?? 0;
          totalCount = data['totalCount'] ?? 0;
          presentStudents = data['presentStudents'] ?? [];
          absentStudents = data['absentStudents'] ?? [];
        }
      } catch (e) {
        // Handle silently
      }
    }

    if (!mounted) return;

    await showSessionSummaryModal(
      context,
      presentCount: presentCount,
      totalCount: totalCount,
      presentStudents: presentStudents,
      absentStudents: absentStudents,
    );
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              margin: EdgeInsets.fromLTRB(Responsive.getPadding(context).left, Responsive.getSpacing(context) * 2, Responsive.getPadding(context).right, 0),
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getSpacing(context) * 2,
                horizontal: Responsive.getSpacing(context) * 2,
              ),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: Responsive.getSpacing(context) * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code Active',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Students can scan this to mark attendance',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: LoadingIndicator(
                        message: 'Generating QR Code...',
                        size: 50,
                      ),
                    )
                  : _errorMessage != null
                      ? SingleChildScrollView(
                          padding: Responsive.getPadding(context),
                          child: 
                            CustomCard(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _errorMessage!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.darkGray,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: 'Try Again',
                                          icon: Icons.refresh_rounded,
                                          onPressed: _refreshQr,
                                          type: ButtonType.gradient,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomButton(
                                          text: 'Go Back',
                                          icon: Icons.arrow_back_rounded,
                                          onPressed: () => Navigator.pop(context),
                                          type: ButtonType.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        )
                      : _qrData != null
                          ? FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: SingleChildScrollView(
                                  padding: Responsive.getPadding(context),
                                  child: Column(
                              children: [
                                // QR Code Card
                                CustomCard(
                                  child: Column(
          children: [
                                      Container(
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.mediumGray),
                                        ),
                                        child: QrImageView(
                                          data: _qrData!,
                                          version: QrVersions.auto,
                                          size: 260.0,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                 const SizedBox(height: 8),
                                
                                // Status Card with Countdown
                                CustomCard(
                                  backgroundColor: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _timeRemaining > 60 ? Colors.green : Colors.orange,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _timeRemaining > 60 ? Icons.schedule_rounded : Icons.warning_rounded,
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
                                              'QR Code Active',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Expires in ${_formatTime(_timeRemaining)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: _timeRemaining > 60 ? Colors.green : Colors.orange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Refresh QR',
                                        icon: Icons.refresh_rounded,
                                        onPressed: _refreshQr,
                                        type: ButtonType.gradient,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Close Session',
                                        icon: Icons.stop_rounded,
                                        onPressed: () {
                                          _confirmEndSession();
                                        },
                                        type: ButtonType.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Student Attendance List
                                if (_students.isNotEmpty) ...[
                                  CustomCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.people_rounded,
                                              color: AppTheme.primaryBlack,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Student Attendance (${_students.length})',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_students.map((student) => _buildStudentItem(student))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                
                                // Instructions Card
                                CustomCard(
                                  backgroundColor: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: isDark ? Theme.of(context).colorScheme.onSurface : AppTheme.primaryBlack,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Instructions',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInstructionItem(context, '1', 'Display this QR code to students'),
                                      const SizedBox(height: 8),
                                      _buildInstructionItem(context, '2', 'Students scan the code with their app'),
                                      const SizedBox(height: 8),
                                      _buildInstructionItem(context, '3', 'Attendance is marked automatically'),
                                      const SizedBox(height: 8),
                                      _buildInstructionItem(context, '4', 'QR code expires in 5 minutes'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String number,
    String text,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface : AppTheme.primaryBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8) : AppTheme.darkGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> student) {
    final isPresent = student['status'] == 'present' || student['attended'] == true;
    final studentName = student['name'] ?? student['studentName'] ?? 'Unknown Student';
    final rollNumber = student['rollNumber'] ?? student['roll'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.withValues(alpha: 0.1) : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPresent ? Colors.green : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor : AppTheme.mediumGray),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isPresent ? Colors.green : AppTheme.darkGray,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rollNumber.isNotEmpty)
                  Text(
                    'Roll: $rollNumber',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent ? Colors.green : AppTheme.darkGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPresent ? 'Present' : 'Pending',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
