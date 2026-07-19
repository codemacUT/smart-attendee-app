import 'package:flutter/material.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/utils/theme.dart';

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: AppTheme.darkGray),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _summaryStatTile(
                  context: context,
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  label: 'Present',
                  value: '$presentCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryStatTile(
                  context: context,
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                  label: 'Absent',
                  value: '$absentCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryStatTile(
                  context: context,
                  icon: Icons.group_rounded,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primaryBlack,
                  label: 'Total',
                  value: totalCount > 0 ? '$totalCount' : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                if (presentStudents.isNotEmpty) ...[
                  const Text("Present Students", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...presentStudents.map((s) => ListTile(
                    leading: const Icon(Icons.group_rounded, color: Colors.green),
                    title: Text(s['name'] ?? 'Unknown'),
                    subtitle: Text(s['enrollmentNo'] ?? ''),
                  )).toList(),
                  const Divider(),
                ],
                if (absentStudents.isNotEmpty) ...[
                  const Text("Absent Students", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...absentStudents.map((s) => ListTile(
                    leading: const Icon(Icons.group_rounded, color: Colors.red),
                    title: Text(s['name'] ?? 'Unknown'),
                    subtitle: Text(s['enrollmentNo'] ?? ''),
                  )).toList(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Done',
              icon: Icons.arrow_back_rounded,
              type: ButtonType.gradient,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStatTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.darkGray),
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
    isDismissible: false,
    enableDrag: false,
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
