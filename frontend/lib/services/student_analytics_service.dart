import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/utils/constants.dart';

class StudentAnalyticsService {
  final AuthService _authService = AuthService();

  // Helper method to get headers
  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch student analytics data from the backend
  Future<Map<String, dynamic>> getStudentAnalytics() async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    try {
      print('DEBUG: Fetching student analytics from: ${AppConstants.apiBaseUrl}/api/analytics/student');
      
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/analytics/student'),
        headers: _getHeaders(token),
      );

      print('DEBUG: Student analytics response status: ${response.statusCode}');
      print('DEBUG: Student analytics response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'message': 'API Error (${response.statusCode}): ${response.body}'};
      }
    } catch (e) {
      print('DEBUG: Student analytics error: $e');
      return {'success': false, 'message': 'Error fetching student analytics: $e'};
    }
  }

  // Fetch student profile information
  Future<Map<String, dynamic>> getStudentProfile() async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    try {
      print('DEBUG: Fetching student profile from: ${AppConstants.apiBaseUrl}/auth/profile');
      
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/profile'),
        headers: _getHeaders(token),
      );

      print('DEBUG: Student profile response status: ${response.statusCode}');
      print('DEBUG: Student profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'message': 'API Error (${response.statusCode}): ${response.body}'};
      }
    } catch (e) {
      print('DEBUG: Student profile error: $e');
      return {'success': false, 'message': 'Error fetching student profile: $e'};
    }
  }
}
