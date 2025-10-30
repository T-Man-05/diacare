import 'package:flutter/material.dart';
import '../models/chart_data.dart';
import '../utils/constants.dart';

/// Blood Sugar Chart Widget with CustomPainter
class BloodSugarChart extends StatelessWidget {
  final ChartData chartData;
  final VoidCallback onSeeDetails;

  const BloodSugarChart({
    Key? key,
    required this.chartData,
    required this.onSeeDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(chartData.title, style: AppTextStyles.cardTitle),
              const SizedBox(width: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegend('Before Meal', AppColors.beforeMealColor),
                  const SizedBox(width: 7),
                  _buildLegend('After Meal', AppColors.afterMealColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: LineChartPainter(
                beforeMeal: chartData.data['before_meal'] ?? [],
                afterMeal: chartData.data['after_meal'] ?? [],
                days: chartData.days,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onSeeDetails,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'See Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<int> beforeMeal;
  final List<int> afterMeal;
  final List<String> days;

  LineChartPainter({
    required this.beforeMeal,
    required this.afterMeal,
    required this.days,
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
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Find min and max values
    final allValues = [...beforeMeal, ...afterMeal];
    final minValue = allValues.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = allValues.reduce((a, b) => a > b ? a : b).toDouble();
    final range = maxValue - minValue;
    final padding = range * 0.2;

    // Draw horizontal grid lines and labels
    final numGridLines = 4;
    for (int i = 0; i <= numGridLines; i++) {
      final y = size.height * (i / numGridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Draw value labels
      final value =
          maxValue + padding - (range + 2 * padding) * (i / numGridLines);
      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-25, y - 6));
    }

    // Calculate points
    final pointSpacing = size.width / (beforeMeal.length - 1);

    // Draw before meal line
    final path1 = Path();
    for (int i = 0; i < beforeMeal.length; i++) {
      final x = i * pointSpacing;
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

    // Draw after meal line
    final path2 = Path();
    for (int i = 0; i < afterMeal.length; i++) {
      final x = i * pointSpacing;
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

    // Draw day labels
    for (int i = 0; i < days.length; i++) {
      final x = i * pointSpacing;
      textPainter.text = TextSpan(
        text: days[i],
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
