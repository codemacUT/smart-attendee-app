import 'package:flutter/material.dart';
import 'package:smart_attendee/shared/screens/splash_screen.dart';
import 'package:smart_attendee/utils/app_navigator.dart';
import 'package:smart_attendee/utils/theme.dart';

void main() {
  runApp(const SmartAttendeeApp());
}

class SmartAttendeeApp extends StatelessWidget {
  const SmartAttendeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAttendee',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}