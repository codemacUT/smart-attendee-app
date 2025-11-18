import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/services/location_service.dart';
import 'package:smart_attendee/utils/constants.dart';

class AttendanceService {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  // This is a helper to avoid repeating headers
  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Your existing, correct function
  Future<Map<String, dynamic>> generateQrSession(
      {required int classId, required int subjectId}) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }
    final correctUrl = Uri.parse('${AppConstants.apiBaseUrl}/attendance/generate-qr');
    try {
      final position = await _locationService.getCurrentPosition();
      final requestBody = {
        'classId': classId,
        'subjectId': subjectId,
        'geoLat': position.latitude,
        'geoLng': position.longitude,
      };
      final response = await http.post(
        correctUrl,
        headers: _getHeaders(token),
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'API Error (${response.statusCode}): ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- ADDED THIS METHOD ---
  // Fetches the live status of an attendance session, including students who have attended.
  // This is required by your qr_display_screen.dart for polling.
  Future<Map<String, dynamic>> getSessionDetails(int sessionId) async {
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Not logged in'};

    // Note: The documentation implies an endpoint like this for polling.
    // If the actual endpoint is different, you'll need to update the URL here.
    final url = Uri.parse('${AppConstants.apiBaseUrl}/attendance/session/$sessionId');
    try {
      final response = await http.get(url, headers: _getHeaders(token));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch session details'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  Future<Map<String, dynamic>> endSession(int sessionId) async {
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Not logged in'};

    final url = Uri.parse('${AppConstants.apiBaseUrl}/attendance/end-session');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({'sessionId': sessionId}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {'success': false, 'message': 'Failed to end session'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Your existing, correct function
  Future<Map<String, dynamic>> markAttendance({required String qrSessionId}) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }
    try {
      final position = await _locationService.getCurrentPosition();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/attendance/mark-attendance'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'qrSessionId': int.tryParse(qrSessionId),
          'geoLat': position.latitude,
          'geoLng': position.longitude,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to mark attendance'};
      }
    } on LocationException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'An unknown error occurred.'};
    }
  }
}

