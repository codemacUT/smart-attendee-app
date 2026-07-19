import 'dart:convert';
import 'package:smart_attendee/services/api_client.dart';

class StudentAnalyticsService {
  final ApiClient _api = ApiClient();

  /// Fetches overall attendance analytics for the logged-in student.
  Future<Map<String, dynamic>> getStudentAnalytics() async {
    try {
      final response = await _api.get('/analytics/student');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'API Error (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error fetching student analytics: $e'};
    }
  }

  /// Fetches the student's profile information.
  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final response = await _api.get('/auth/profile');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'API Error (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error fetching student profile: $e'};
    }
  }
}
