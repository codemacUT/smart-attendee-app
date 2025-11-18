import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_attendee/services/attendance_service.dart';
import 'package:smart_attendee/shared/widgets/custom_card.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/shared/widgets/loading_indicator.dart';
import 'package:smart_attendee/utils/theme.dart';

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

class _QRDisplayScreenState extends State<QRDisplayScreen> with TickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQr() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      print('DEBUG: QR Display - Starting QR generation');
      print('DEBUG: QR Display - ClassId: ${widget.classId}, SubjectId: ${widget.subjectId}');
      
      final result = await _attendanceService.generateQrSession(
        classId: widget.classId,
        subjectId: widget.subjectId,
      );
      
      print('DEBUG: QR Display - Generation result: $result');
      
      if (result['success']) {
        final data = result['data'];
        print('DEBUG: QR Display - Success data: $data');
        
        setState(() {
          // Try different possible keys for qrSessionId
          _qrData = data['qrSessionId']?.toString() ?? 
                   data['sessionId']?.toString() ?? 
                   data['id']?.toString() ?? 
                   'test_qr_${DateTime.now().millisecondsSinceEpoch}';
          _sessionId = data['sessionId'] ?? 
                      int.tryParse(data['qrSessionId']?.toString() ?? '') ??
                      int.tryParse(data['id']?.toString() ?? '');
        });
        
        print('DEBUG: QR Display - QR Data: $_qrData');
        print('DEBUG: QR Display - Session ID: $_sessionId');
        
        _startTimers();
        _animationController.forward();
      } else {
        print('DEBUG: QR Display - Error: ${result['message']}');
        setState(() {
          _errorMessage = 'Failed to generate QR code: ${result['message']}';
        });
      }
    } catch (e) {
      print('DEBUG: QR Display - Exception: $e');
      setState(() {
        _errorMessage = 'Error generating QR code: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTimers() {
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

  Future<void> _endSession() async {
    if (_sessionId != null) {
      try {
        await _attendanceService.endSession(_sessionId!);
      } catch (e) {
        // Handle error silently
      }
    }
    _timer?.cancel();
    _pollingTimer?.cancel();
    if (mounted) {
      Navigator.pop(context);
    }
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Custom Header
                    Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QR Code Display',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Students can scan this QR code',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                      child: Column(
                        children: [
                          if (_isLoading)
                            const LoadingIndicator(
                              message: 'Generating QR Code...',
                              size: 50,
                            )
                          else if (_errorMessage != null)
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
                                          onPressed: _generateQr,
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
                            )
                          else if (_qrData != null)
                            Column(
                              children: [
                                // QR Code Card
                                CustomCard(
                                  child: Column(
          children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.mediumGray),
                                        ),
                                        child: QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
                                          size: 200.0,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'QR Code Active',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Students can scan this code to mark attendance',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.darkGray,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                 const SizedBox(height: 8),
                                
                                // Status Card with Countdown
                                CustomCard(
                                  backgroundColor: AppTheme.lightGray,
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
                                        onPressed: _generateQr,
                                        type: ButtonType.gradient,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Close Session',
                                        icon: Icons.stop_rounded,
                                        onPressed: () {
                                          _endSession();
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
                                  backgroundColor: AppTheme.lightGray,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: AppTheme.primaryBlack,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
            color: AppTheme.primaryBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
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
              color: AppTheme.darkGray,
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
        color: isPresent ? Colors.green.withOpacity(0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPresent ? Colors.green : AppTheme.mediumGray,
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
                      color: AppTheme.darkGray,
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
