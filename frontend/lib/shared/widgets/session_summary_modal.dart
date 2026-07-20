import 'package:flutter/material.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/shared/widgets/shimmer_loading.dart';

class SessionSummaryModal extends StatelessWidget {
  final int presentCount;
  final int totalCount;
  final List<dynamic> presentStudents;
  final List<dynamic> absentStudents;
  final String title;
  final String subtitle;

  const SessionSummaryModal({
    super.key,
    required this.presentCount,
    required this.totalCount,
    required this.presentStudents,
    required this.absentStudents,
    this.title = 'Session Complete',
    this.subtitle = 'QR attendance session has ended',
  });

  @override
  Widget build(BuildContext context) {
    final absentCount = totalCount > 0 ? totalCount - presentCount : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle and Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : AppTheme.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildPremiumStatCard(
                          context,
                          'Present',
                          '$presentCount',
                          Icons.check_circle_rounded,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPremiumStatCard(
                          context,
                          'Absent',
                          '$absentCount',
                          Icons.cancel_rounded,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumStatCard(
                    context,
                    'Total Students',
                    totalCount > 0 ? '$totalCount' : '—',
                    Icons.groups_rounded,
                    Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Students List
                  if (presentStudents.isNotEmpty || absentStudents.isNotEmpty)
                    Text(
                      'Attendance Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  if (presentStudents.isNotEmpty) ...[
                    _buildStudentSectionLabel(context, 'Present', Colors.green),
                    const SizedBox(height: 12),
                    ...presentStudents.map((s) => _buildPremiumStudentTile(context, s, true)),
                    const SizedBox(height: 24),
                  ],

                  if (absentStudents.isNotEmpty) ...[
                    _buildStudentSectionLabel(context, 'Absent', Colors.red),
                    const SizedBox(height: 12),
                    ...absentStudents.map((s) => _buildPremiumStudentTile(context, s, false)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSectionLabel(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumStudentTile(BuildContext context, dynamic student, bool isPresent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isPresent ? Colors.green : Colors.red;
    final name = student['name'] ?? 'Unknown';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (student['enrollmentNo'] != null)
                  Text(
                    student['enrollmentNo'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : AppTheme.darkGray,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSessionSummaryModal(
  BuildContext context, {
  required int presentCount,
  required int totalCount,
  required List<dynamic> presentStudents,
  required List<dynamic> absentStudents,
  String title = 'Session Complete',
  String subtitle = 'QR attendance session has ended',
}) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => SessionSummaryModal(
      presentCount: presentCount,
      totalCount: totalCount,
      presentStudents: presentStudents,
      absentStudents: absentStudents,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class SessionSummarySkeleton extends StatelessWidget {
  const SessionSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const ShimmerLoader(width: 60, height: 60, borderRadius: 30),
                const SizedBox(height: 16),
                const ShimmerLoader(width: 200, height: 24, borderRadius: 4),
                const SizedBox(height: 8),
                const ShimmerLoader(width: 150, height: 16, borderRadius: 4),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Expanded(child: ShimmerLoader(height: 100, width: double.infinity, borderRadius: 16)),
                      SizedBox(width: 16),
                      Expanded(child: ShimmerLoader(height: 100, width: double.infinity, borderRadius: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ShimmerLoader(height: 100, width: double.infinity, borderRadius: 16),
                  const SizedBox(height: 32),
                  const ShimmerLoader(height: 24, width: 150, borderRadius: 4),
                  const SizedBox(height: 16),
                  ...List.generate(4, (index) => const ShimmerLoader(height: 72, width: double.infinity, borderRadius: 16, margin: EdgeInsets.only(bottom: 12))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSessionSummaryFutureModal(
  BuildContext context, {
  required Future<Map<String, dynamic>> fetchFuture,
  String title = 'Session Complete',
  String subtitle = 'Session Details',
}) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => FutureBuilder<Map<String, dynamic>>(
      future: fetchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SessionSummarySkeleton();
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!['success'] != true) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Failed to load details', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!['data'];
        return SessionSummaryModal(
          presentCount: data['presentCount'] ?? 0,
          totalCount: data['totalCount'] ?? 0,
          presentStudents: data['presentStudents'] ?? [],
          absentStudents: data['absentStudents'] ?? [],
          title: title,
          subtitle: subtitle,
        );
      },
    ),
  );
}
