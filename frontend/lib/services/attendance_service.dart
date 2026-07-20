import 'dart:convert';
import 'package:smart_attendee/services/api_client.dart';
import 'package:smart_attendee/services/location_service.dart';

class AttendanceService {
  final ApiClient _api = ApiClient();
  final LocationService _locationService = LocationService();

  Future<Map<String, dynamic>> generateQrSession({
    required int classId,
    required int subjectId,
  }) async {
    try {
      final position = await _locationService.getCurrentPosition();
      final response = await _api.post(
        '/attendance/generate-qr',
        body: {
          'classId': classId,
          'subjectId': subjectId,
          'geoLat': position.latitude,
          'geoLng': position.longitude,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'API Error (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> refreshQrSession({
    required int sessionId,
  }) async {
    try {
      final response = await _api.post(
        '/attendance/refresh-qr',
        body: {
          'qrSessionId': sessionId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'API Error (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSessionDetails(int sessionId) async {
    try {
      final response = await _api.get('/attendance/session/$sessionId');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch session details'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
    try {
      final response = await _api.get('/attendance/session/$sessionId/stats');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch session stats'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> endSession(int sessionId) async {
    try {
      final response = await _api.post(
        '/attendance/end-session',
        body: {'sessionId': sessionId},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message']
        };
      } else {
        return {'success': false, 'message': 'Failed to end session'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markAttendance({
    required String qrSessionId,
  }) async {
    try {
      final position = await _locationService.getCurrentPosition();
      final response = await _api.post(
        '/attendance/mark-attendance',
        body: {
          'qrSessionId': int.tryParse(qrSessionId),
          'geoLat': position.latitude,
          'geoLng': position.longitude,
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to mark attendance'
        };
      }
    } on LocationException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'An unknown error occurred.'};
    }
  }
}
