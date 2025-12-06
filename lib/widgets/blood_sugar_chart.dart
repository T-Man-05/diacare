import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data.dart';
import '../utils/constants.dart';

/// Blood Sugar Chart Widget with CustomPainter
class BloodSugarChart extends StatelessWidget {
  final ChartData chartData;
  final VoidCallback onSeeDetails;
  final bool flag;
  final String units;

  const BloodSugarChart({
    Key? key,
    required this.chartData,
    required this.onSeeDetails,
    required this.flag,
    this.units = 'mg/dL',
  }) : super(key: key);

  bool get _hasData {
    final before = chartData.data['before_meal'] ?? [];
    final after = chartData.data['after_meal'] ?? [];
    return before.isNotEmpty || after.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.bloodSugar,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegend(l10n.beforeMeal, AppColors.beforeMealColor,
                      textSecondary),
                  const SizedBox(width: 7),
                  _buildLegend(
                      l10n.afterMeal, AppColors.afterMealColor, textSecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _hasData
              ? _buildChart(isDark, textSecondary, l10n)
              : _buildEmptyState(l10n, textPrimary, textSecondary),
          const SizedBox(height: 16),
          if (flag)
            Center(
              child: TextButton(
                onPressed: onSeeDetails,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    l10n.seeDetails,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark, Color textSecondary, AppLocalizations l10n) {
    final beforeMeal = chartData.data['before_meal'] ?? [];
    final afterMeal = chartData.data['after_meal'] ?? [];
    final isSinglePoint = beforeMeal.length <= 1 && afterMeal.length <= 1;

    if (isSinglePoint) {
      return _buildSinglePointChart(isDark, textSecondary, l10n);
    }

    return Row(
      children: [
        SizedBox(
          width: 45,
          height: 200,
          child: CustomPaint(
            painter: YAxisPainter(
              beforeMeal: beforeMeal,
              afterMeal: afterMeal,
              textColor: textSecondary,
              units: units,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: LineChartPainter(
                beforeMeal: beforeMeal,
                afterMeal: afterMeal,
                hours: chartData.hours,
                textColor: textSecondary,
                gridColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                units: units,
              ),
            ),
          ),
        ),
        const SizedBox(width: 35),
      ],
    );
  }

  Widget _buildEmptyState(
      AppLocalizations l10n, Color textPrimary, Color textSecondary) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_outlined,
              size: 48,
              color: textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noData,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add blood sugar readings to see the chart',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePointChart(
      bool isDark, Color textSecondary, AppLocalizations l10n) {
    final beforeMeal = chartData.data['before_meal'] ?? [];
    final afterMeal = chartData.data['after_meal'] ?? [];

    return SizedBox(
      height: 200,
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: SinglePointChartPainter(
          beforeMeal: beforeMeal,
          afterMeal: afterMeal,
          textColor: textSecondary,
          gridColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          beforeLabel: l10n.beforeMeal,
          afterLabel: l10n.afterMeal,
          units: units,
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for single point display
class SinglePointChartPainter extends CustomPainter {
  final List<int> beforeMeal;
  final List<int> afterMeal;
  final Color textColor;
  final Color gridColor;
  final String beforeLabel;
  final String afterLabel;
  final String units;

  SinglePointChartPainter({
    required this.beforeMeal,
    required this.afterMeal,
    required this.textColor,
    required this.gridColor,
    required this.beforeLabel,
    required this.afterLabel,
    this.units = 'mg/dL',
  });

  String _formatValue(double mgDlValue) {
    if (units == 'mmol/L') {
      return '${(mgDlValue / 18.0).toStringAsFixed(1)} $units';
    }
    return '${mgDlValue.toInt()} $units';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4) - 20;
      if (y > 0) {
        canvas.drawLine(Offset(40, y), Offset(size.width - 40, y), gridPaint);
      }
    }

    // Draw before meal point if exists
    if (beforeMeal.isNotEmpty) {
      final value = beforeMeal.first.toDouble();
      final paint = Paint()
        ..color = AppColors.beforeMealColor
        ..style = PaintingStyle.fill;

      final x = size.width * 0.35;
      final y = size.height * 0.4;

      // Glow effect
      canvas.drawCircle(Offset(x, y), 16,
          Paint()..color = AppColors.beforeMealColor.withAlpha(50));
      canvas.drawCircle(Offset(x, y), 10, paint);

      // Value label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatValue(value),
          style: TextStyle(color: textColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 30));

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: beforeLabel,
          style: TextStyle(color: AppColors.beforeMealColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, y + 15));
    }

    // Draw after meal point if exists
    if (afterMeal.isNotEmpty) {
      final value = afterMeal.first.toDouble();
      final paint = Paint()
        ..color = AppColors.afterMealColor
        ..style = PaintingStyle.fill;

      final x = size.width * 0.65;
      final y = size.height * 0.5;

      // Glow effect
      canvas.drawCircle(Offset(x, y), 16,
          Paint()..color = AppColors.afterMealColor.withAlpha(50));
      canvas.drawCircle(Offset(x, y), 10, paint);

      // Value label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatValue(value),
          style: TextStyle(color: textColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 30));

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: afterLabel,
          style: TextStyle(color: AppColors.afterMealColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, y + 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for Y-axis labels only
class YAxisPainter extends CustomPainter {
  final List<int> beforeMeal;
  final List<int> afterMeal;
  final Color textColor;
  final String units;

  YAxisPainter({
    required this.beforeMeal,
    required this.afterMeal,
    required this.textColor,
    this.units = 'mg/dL',
  });

  String _formatValue(double mgDlValue) {
    if (units == 'mmol/L') {
      return (mgDlValue / 18.0).toStringAsFixed(1);
    }
    return mgDlValue.toInt().toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (beforeMeal.isEmpty || afterMeal.isEmpty) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final allValues = [...beforeMeal, ...afterMeal];
    final minValue = allValues.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = allValues.reduce((a, b) => a > b ? a : b).toDouble();
    final range = maxValue - minValue;
    final padding = range * 0.2;

    const numGridLines = 4;
    for (int i = 0; i <= numGridLines; i++) {
      final y = size.height * (i / numGridLines);
      final value =
          maxValue + padding - (range + 2 * padding) * (i / numGridLines);
      textPainter.text = TextSpan(
        text: _formatValue(value),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(size.width - textPainter.width - 5, y - 6));
    }
  }

  @override
  bool shouldRepaint(covariant YAxisPainter oldDelegate) {
    return oldDelegate.textColor != textColor ||
        oldDelegate.beforeMeal != beforeMeal ||
        oldDelegate.afterMeal != afterMeal ||
        oldDelegate.units != units;
  }
}

/// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<int> beforeMeal;
  final List<int> afterMeal;
  final List<String> hours;
  final Color textColor;
  final Color gridColor;
  final String units;

  LineChartPainter({
    required this.beforeMeal,
    required this.afterMeal,
    required this.hours,
    required this.textColor,
    required this.gridColor,
    this.units = 'mg/dL',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (beforeMeal.isEmpty || afterMeal.isEmpty) return;

    final paint1 = Paint()
      ..color = AppColors.beforeMealColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = AppColors.afterMealColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final allValues = [...beforeMeal, ...afterMeal];
    final minValue = allValues.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = allValues.reduce((a, b) => a > b ? a : b).toDouble();
    final range = maxValue - minValue;
    final padding = range * 0.2;

    const numGridLines = 4;
    for (int i = 0; i <= numGridLines; i++) {
      final y = size.height * (i / numGridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const horizontalPadding = 20.0;
    final chartWidth = size.width - (2 * horizontalPadding);
    final pointSpacing = chartWidth / (beforeMeal.length - 1);

    final path1 = Path();
    for (int i = 0; i < beforeMeal.length; i++) {
      final x = horizontalPadding + (i * pointSpacing);
      final normalizedValue =
          (beforeMeal[i] - (minValue - padding)) / (range + 2 * padding);
      final y = size.height - (normalizedValue * size.height);
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    canvas.drawPath(path1, paint1);

    final path2 = Path();
    for (int i = 0; i < afterMeal.length; i++) {
      final x = horizontalPadding + (i * pointSpacing);
      final normalizedValue =
          (afterMeal[i] - (minValue - padding)) / (range + 2 * padding);
      final y = size.height - (normalizedValue * size.height);
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, paint2);

    // Draw hour labels on X-axis with proper spacing
    for (int i = 0; i < hours.length; i++) {
      final x = horizontalPadding + (i * pointSpacing);
      textPainter.text = TextSpan(
        text: hours[i],
        style: TextStyle(
          color: textColor,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      // Ensure at least 2px spacing between labels
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.beforeMeal != beforeMeal ||
        oldDelegate.afterMeal != afterMeal ||
        oldDelegate.hours != hours ||
        oldDelegate.units != units;
  }
}
