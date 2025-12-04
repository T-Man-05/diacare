import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

class ReminderCardWidget extends StatelessWidget {
  final String title;
  final String nextTime;
  final String timeRemaining;
  final bool isLate;
  final bool isDone;
  final IconData icon;
  final VoidCallback? onTap;

  const ReminderCardWidget({
    Key? key,
    required this.title,
    required this.nextTime,
    required this.timeRemaining,
    this.isLate = false,
    this.isDone = false,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final iconBgColor = isDark ? AppColors.darkSurface : Colors.grey.shade100;
    final iconColor =
        isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLate ? Colors.red.shade100 : Colors.blue.shade100,
            width: isLate ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDark ? 0.05 : 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        l10n.nextTime,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        nextTime,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeRemaining,
                        style: TextStyle(
                          fontSize: 14,
                          color: isLate ? Colors.red : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.teal.shade50
                    : isLate
                        ? Colors.red.shade50
                        : iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDone
                    ? Colors.teal
                    : isLate
                        ? Colors.red
                        : iconColor,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
