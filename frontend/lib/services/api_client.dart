import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_attendee/services/auth_service.dart';
import 'package:smart_attendee/shared/screens/login_screen.dart';
import 'package:smart_attendee/utils/app_navigator.dart';
import 'package:smart_attendee/utils/constants.dart';

/// A thin HTTP wrapper that:
/// - Automatically attaches the Bearer JWT to every request
/// - Intercepts 401 responses, clears the stored token, and redirects
///   to [LoginScreen] using the global [navigatorKey]
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final AuthService _authService = AuthService();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Handles a 401 by clearing the token and redirecting to login.
  Future<void> _handle401() async {
    await _authService.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Retrieves the stored token or triggers logout if missing.
  Future<String?> _getToken() async {
    final token = await _authService.getToken();
    if (token == null) await _handle401();
    return token;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public HTTP methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<http.Response> get(String path) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers(token),
    );

    if (response.statusCode == 401) {
      await _handle401();
      throw Exception('Session expired');
    }
    return response;
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      await _handle401();
      throw Exception('Session expired');
    }
    return response;
  }
}
