import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

/// Daily health tip card for the dashboard
class DailyTipCard extends StatelessWidget {
  final bool isDark;

  const DailyTipCard({
    Key? key,
    this.isDark = false,
  }) : super(key: key);

  /// Get a tip based on the day of the year for variety
  Map<String, dynamic> _getTipOfTheDay(AppLocalizations l10n) {
    final tips = [
      {
        'icon': Icons.water_drop,
        'color': AppColors.waterColor,
        'title': l10n.translate('tips.hydration_title'),
        'tip': l10n.translate('tips.hydration'),
      },
      {
        'icon': Icons.directions_walk,
        'color': AppColors.activityColor,
        'title': l10n.translate('tips.exercise_title'),
        'tip': l10n.translate('tips.exercise'),
      },
      {
        'icon': Icons.restaurant,
        'color': AppColors.carbsColor,
        'title': l10n.translate('tips.diet_title'),
        'tip': l10n.translate('tips.diet'),
      },
      {
        'icon': Icons.monitor_heart,
        'color': AppColors.primary,
        'title': l10n.translate('tips.monitoring_title'),
        'tip': l10n.translate('tips.monitoring'),
      },
      {
        'icon': Icons.bedtime,
        'color': AppColors.insulinColor,
        'title': l10n.translate('tips.sleep_title'),
        'tip': l10n.translate('tips.sleep'),
      },
      {
        'icon': Icons.self_improvement,
        'color': AppColors.pillsColor,
        'title': l10n.translate('tips.stress_title'),
        'tip': l10n.translate('tips.stress'),
      },
      {
        'icon': Icons.medication,
        'color': AppColors.pillsColor,
        'title': l10n.translate('tips.medication_title'),
        'tip': l10n.translate('tips.medication'),
      },
    ];

    // Use day of year to rotate tips
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return tips[dayOfYear % tips.length];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tip = _getTipOfTheDay(l10n);
    final tipColor = tip['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tipColor.withOpacity(0.15),
            tipColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: tipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tipColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tip['icon'] as IconData,
              color: tipColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: tipColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.translate('tips.daily_tip'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tipColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tip['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['tip'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
