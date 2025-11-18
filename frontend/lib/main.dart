import 'package:flutter/material.dart';
import 'package:smart_attendee/shared/screens/login_screen.dart';
import 'package:smart_attendee/utils/theme.dart';

void main() {
  runApp(const SmartAtendeeApp());
}

class SmartAtendeeApp extends StatelessWidget {
  const SmartAtendeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAtendee',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}