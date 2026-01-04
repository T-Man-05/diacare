import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

/// Quick stats summary card for the dashboard
class QuickStatsCard extends StatelessWidget {
  final int readingsToday;
  final int remindersCompleted;
  final int totalReminders;
  final double activityKm;
  final bool isDark;

  const QuickStatsCard({
    Key? key,
    required this.readingsToday,
    required this.remindersCompleted,
    required this.totalReminders,
    required this.activityKm,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
            AppColors.accentTeal.withOpacity(isDark ? 0.08 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.translate('stats.today_summary'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.bloodtype,
                  value: readingsToday.toString(),
                  label: l10n.translate('stats.readings'),
                  color: AppColors.primary,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_outline,
                  value: '$remindersCompleted/$totalReminders',
                  label: l10n.translate('stats.reminders'),
                  color: AppColors.waterColor,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_walk,
                  value: '${activityKm.toStringAsFixed(1)}',
                  label: l10n.translate('stats.km_walked'),
                  color: AppColors.activityColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
