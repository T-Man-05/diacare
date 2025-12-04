import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBackground =
        isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: dialogBackground,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildStatusButton(
              context,
              l10n.reminderDone,
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
              l10n.reminderNotDone,
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
              l10n.reminderDoLater,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? color.withOpacity(0.9) : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
