import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ReminderCardWidget extends StatelessWidget {
  final String title;
  final String nextTime;
  final String timeRemaining;
  final bool isLate;
  final bool isDone;
  final bool isEnabled;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onToggleEnabled;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;

  const ReminderCardWidget({
    Key? key,
    required this.title,
    required this.nextTime,
    required this.timeRemaining,
    this.isLate = false,
    this.isDone = false,
    this.isEnabled = true,
    required this.icon,
    this.onTap,
    this.onToggleEnabled,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
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

    // Determine card border color based on status
    Color borderColor;
    if (!isEnabled) {
      borderColor = Colors.grey.shade300;
    } else if (isDone) {
      borderColor = Colors.green.shade300;
    } else if (isLate) {
      borderColor = Colors.red.shade300;
    } else {
      borderColor = AppColors.primary.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: isSelectionMode ? onSelectToggle : onTap,
      onLongPress: onSelectToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isEnabled ? cardBackground : cardBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 2.5 : 1.5,
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
            // Selection checkbox when in selection mode
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: (_) => onSelectToggle?.call(),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? textPrimary : textSecondary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Time row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        nextTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? textPrimary : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Status badge
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.green.shade50
                                : isLate
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeRemaining,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDone
                                  ? Colors.green.shade700
                                  : isLate
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status icon
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green.shade50
                    : isLate
                        ? Colors.red.shade50
                        : (isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDone
                    ? Colors.green
                    : isLate
                        ? Colors.red
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade600),
                size: 22,
              ),
            ),

            // Bell toggle button
            if (!isSelectionMode) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onToggleEnabled,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppColors.primary.withOpacity(0.1)
                        : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: isEnabled ? AppColors.primary : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
