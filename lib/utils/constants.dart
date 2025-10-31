import 'package:flutter/material.dart';

/// App-wide constants and colors
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF2E7D32);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Health card colors
  static const Color waterColor = Color(0xFF2196F3);
  static const Color pillsColor = Color(0xFFFF9800);
  static const Color activityColor = Color(0xFFF44336);
  static const Color carbsColor = Color(0xFFE91E63);
  static const Color insulinColor = Color(0xFF9C27B0);

  // Chart colors
  static const Color beforeMealColor = Color(0xFF4CAF50);
  static const Color afterMealColor = Color(0xFF2196F3);
}

class AppSpacing {
  static const double screenPadding = 20.0;
  static const double cardPadding = 10.0;
  static const double gridSpacing = 12.0;
  static const double sectionSpacing = 24.0;
}

class AppTextStyles {
  static const TextStyle greeting = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
