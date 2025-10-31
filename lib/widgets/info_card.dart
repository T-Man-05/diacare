import 'package:flutter/material.dart';
import '../models/health_card.dart';
import '../utils/constants.dart';

/// Reusable Info Card Widget for health metrics
class InfoCard extends StatelessWidget {
  final HealthCard healthCard;

  const InfoCard({Key? key, required this.healthCard}) : super(key: key);

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'water':
        return Icons.water_drop;
      case 'pills':
        return Icons.medication;
      case 'activity':
        return Icons.directions_walk;
      case 'carbs':
        return Icons.restaurant;
      case 'insulin':
        return Icons.medical_services;
      default:
        return Icons.info;
    }
  }

  Color _getColorForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'water':
        return AppColors.waterColor;
      case 'pills':
        return AppColors.pillsColor;
      case 'activity':
        return AppColors.activityColor;
      case 'carbs':
        return AppColors.carbsColor;
      case 'insulin':
        return AppColors.insulinColor;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForTitle(healthCard.title);
    final icon = _getIconForTitle(healthCard.title);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                healthCard.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      '${healthCard.value.toStringAsFixed(healthCard.value.truncateToDouble() == healthCard.value ? 0 : 1)} ',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: healthCard.unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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
