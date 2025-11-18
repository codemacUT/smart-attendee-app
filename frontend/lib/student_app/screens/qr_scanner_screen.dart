import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_attendee/services/attendance_service.dart';
import 'package:smart_attendee/shared/widgets/loading_indicator.dart';
import 'package:smart_attendee/utils/theme.dart';

class QRScannerScreen extends StatefulWidget {
  final Future<void> Function()? onAttendanceMarked;
  const QRScannerScreen({super.key, this.onAttendanceMarked});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isProcessing = false;

  // Handles the entire flow after a QR code is detected
  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return; // Prevent multiple submissions
    setState(() => _isProcessing = true);

    final String? qrSessionId = capture.barcodes.first.rawValue;
    if (qrSessionId != null) {
      final result = await _attendanceService.markAttendance(qrSessionId: qrSessionId);

      if (mounted) {
        if(widget.onAttendanceMarked!=null)
          {
            await widget.onAttendanceMarked!();
          }
        Navigator.pop(context); // Go back to home screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Status Unknown'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } else {
      // If QR is empty, allow scanning again
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          
          // Custom App Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Scan QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Scanning Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scanning Frame
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Corner decorations
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Position the QR code within the frame',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure the QR code is clearly visible and well-lit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoadingIndicator(
                        message: 'Processing attendance...',
                        size: 50,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Please wait while we mark your attendance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}