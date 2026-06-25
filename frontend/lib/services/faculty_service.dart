import 'dart:convert';
import 'package:smart_attendee/services/api_client.dart';

class FacultyService {
  final ApiClient _api = ApiClient();

  /// Gets the faculty's basic profile (name, id, etc.)
  Future<Map<String, dynamic>> getFacultyProfile() async {
    final response = await _api.get('/auth/profile');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load faculty profile');
    }
  }

  /// Gets the faculty's class + subject list from analytics endpoint.
  Future<Map<String, dynamic>> getFacultyAnalytics() async {
    final response = await _api.get('/api/analytics/faculty');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load faculty analytics data');
    }
  }
}