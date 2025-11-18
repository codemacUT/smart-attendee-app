import 'package:flutter/material.dart';
import 'package:smart_attendee/services/faculty_service.dart';
import 'package:smart_attendee/teacher_app/screens/qr_display_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final FacultyService _facultyService = FacultyService();

  // State variables to hold the fetched data
  String? _facultyName;
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];

  // State variables to hold the user's selection
  dynamic _selectedClass;
  dynamic _selectedSubject;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Fetches all necessary data from the analytics endpoint
  Future<void> _fetchDashboardData() async {
    try {
      // Fetch both profile (for name) and analytics (for data)
      final profileFuture = _facultyService.getFacultyProfile();
      final analyticsFuture = _facultyService.getFacultyAnalytics();

      final results = await Future.wait([profileFuture, analyticsFuture]);

      final profile = results[0];
      final analyticsData = results[1];

      final assignedClasses = analyticsData['classes'] as List<dynamic>? ?? [];

      setState(() {
        _facultyName = profile['name'];
        _classes = assignedClasses;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load dashboard data: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // This now uses the already-fetched data, no new API call needed
  void _onClassSelected(dynamic selectedClass) {
    if (selectedClass == null) return;

    setState(() {
      _selectedClass = selectedClass;
      // Get subjects from the selected class object
      _subjects = selectedClass['subjects'] as List<dynamic>? ?? [];
      _selectedSubject = null; // Reset subject selection
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_facultyName ?? 'Teacher Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Class Selection Dropdown
            DropdownButtonFormField<dynamic>(
              value: _selectedClass,
              hint: const Text('Select a Class'),
              items: _classes.map<DropdownMenuItem<dynamic>>((cls) {
                return DropdownMenuItem<dynamic>(
                  value: cls,
                  child: Text(cls['className'] ?? 'Unnamed Class'),
                );
              }).toList(),
              onChanged: (value) => _onClassSelected(value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // Subject Selection Dropdown
            DropdownButtonFormField<dynamic>(
              value: _selectedSubject,
              hint: const Text('Select a Subject'),
              items: _subjects.map<DropdownMenuItem<dynamic>>((sub) {
                return DropdownMenuItem<dynamic>(
                  value: sub,
                  child: Text(sub['subjectName'] ?? 'Unnamed Subject'),
                );
              }).toList(),
              onChanged: (_selectedClass == null) ? null : (value) {
                setState(() => _selectedSubject = value);
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: _selectedClass == null,
                fillColor: Colors.grey[200],
              ),
            ),
            const Spacer(),

            // Generate QR Button
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Generate QR'),
              onPressed: (_selectedClass != null && _selectedSubject != null)
                  ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QRDisplayScreen(
                      // Pass the correct IDs
                      classId: _selectedClass!['classId'],
                      subjectId: _selectedSubject!['subjectId'],
                    ),
                  ),
                );
              }
                  : null, // Button is disabled
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}