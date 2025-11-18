import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/utils/constants.dart';

class FacultyService {
  final AuthService _authService = AuthService();

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // This is still useful for getting the faculty's name for the app bar
  Future<Map<String, dynamic>> getFacultyProfile() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication token not found');

    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/profile'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load faculty profile');
    }
  }

  // --- ADDED THIS METHOD ---
  // Fetches the complete dashboard data, including classes and subjects,
  // from the correct analytics endpoint.
  Future<Map<String, dynamic>> getFacultyAnalytics() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication token not found');

    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/analytics/faculty'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load faculty analytics data');
    }
  }
}