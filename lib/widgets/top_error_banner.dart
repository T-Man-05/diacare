import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// A non-blocking error banner that slides into view at the top of a page.
///
/// Intended for API/network errors on main pages (Dashboard/Reminders/Settings/Insights)
/// instead of SnackBars/Dialogs.
class TopErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  const TopErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF3A2424) // deep muted red
        : const Color(0xFFFFF2F0); // soft red
    final border = isDark ? const Color(0xFF6B3A3A) : const Color(0xFFFFC6BE);
    final textColor = isDark ? Colors.white : const Color(0xFF5D1A1A);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: textColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}
