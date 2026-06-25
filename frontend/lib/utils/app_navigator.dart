import 'package:flutter/material.dart';

/// A global [NavigatorKey] that allows navigation from outside the widget tree.
/// Registered in MaterialApp and used by [ApiClient] to redirect to LoginScreen
/// when a 401 response is received.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
