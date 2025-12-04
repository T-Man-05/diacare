import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_data.dart';
import '../utils/constants.dart';

/// Blood Sugar Chart Widget with CustomPainter
class BloodSugarChart extends StatelessWidget {
  final ChartData chartData;
  final VoidCallback onSeeDetails;
  final bool flag;

  const BloodSugarChart({
    Key? key,
    required this.chartData,
    required this.onSeeDetails,
    required this.flag,
  }) : super(key: key);

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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
          Row(
            children: [
              SizedBox(
                width: 35,
                height: 200,
                child: CustomPaint(
                  painter: YAxisPainter(
                    beforeMeal: chartData.data['before_meal'] ?? [],
                    afterMeal: chartData.data['after_meal'] ?? [],
                    textColor: textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: LineChartPainter(
                      beforeMeal: chartData.data['before_meal'] ?? [],
                      afterMeal: chartData.data['after_meal'] ?? [],
                      days: chartData.days,
                      textColor: textSecondary,
                      gridColor:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 35),
            ],
          ),
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

/// Custom painter for Y-axis labels only
class YAxisPainter extends CustomPainter {
  final List<int> beforeMeal;
  final List<int> afterMeal;
  final Color textColor;

  YAxisPainter({
    required this.beforeMeal,
    required this.afterMeal,
    required this.textColor,
  });

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
        text: value.toInt().toString(),
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
        oldDelegate.afterMeal != afterMeal;
  }
}

/// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<int> beforeMeal;
  final List<int> afterMeal;
  final List<String> days;
  final Color textColor;
  final Color gridColor;

  LineChartPainter({
    required this.beforeMeal,
    required this.afterMeal,
    required this.days,
    required this.textColor,
    required this.gridColor,
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

    for (int i = 0; i < days.length; i++) {
      final x = horizontalPadding + (i * pointSpacing);
      textPainter.text = TextSpan(
        text: days[i],
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height + 10));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.beforeMeal != beforeMeal ||
        oldDelegate.afterMeal != afterMeal;
  }
}
