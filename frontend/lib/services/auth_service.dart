import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attendee/utils/constants.dart'; // Make sure this path is correct

class AuthService {
  // ... other methods (getToken, logout) remain the same ...
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    // --- ADDED FOR DEBUGGING ---
    print('--- Attempting Login ---');
    print('URL: ${AppConstants.apiBaseUrl}/auth/login');
    print('Email: $email');

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // --- ADDED FOR DEBUGGING ---
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _saveToken(token);

        final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
        
        return {'success': true, 'role': payload['role']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      // --- THIS IS THE MOST IMPORTANT PART ---
      // This will print the exact technical error to your console.
      print('!!!!!! LOGIN API CRITICAL ERROR !!!!!!');
      print(e.toString());
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      
      return {'success': false, 'message': 'Connection Error. See console for details.'};
    }
  }
}

