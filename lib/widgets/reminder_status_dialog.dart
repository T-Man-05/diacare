// ========================================
// lib/widgets/reminder_status_dialog.dart
// ========================================
import 'package:flutter/material.dart';

class ReminderStatusDialog extends StatelessWidget {
  final String title;
  final Function(String) onStatusSelected;

  const ReminderStatusDialog({
    Key? key,
    required this.title,
    required this.onStatusSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildStatusButton(
              context,
              'Done',
              Icons.check_circle,
              Colors.green,
              () {
                onStatusSelected('done');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildStatusButton(
              context,
              'Not Done',
              Icons.cancel,
              Colors.red,
              () {
                onStatusSelected('not_done');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildStatusButton(
              context,
              'I Will Do It Later',
              Icons.access_time,
              Colors.orange,
              () {
                onStatusSelected('later');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color? get shade700 => null;
}