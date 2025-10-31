// ========================================
// lib/widgets/blood_sugar_chart.dart
// ========================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'legend_item.dart';
import '../models/chart_data.dart';

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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            LegendItem(color: Color(0xFF6B9EFA), label: 'Before Meal'),
            LegendItem(color: Color(0xFF4FC3C3), label: 'After Meal'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeBarGroup(0, 130, const Color(0xFF4FC3C3)),
                _makeBarGroup(1, 155, const Color(0xFF4FC3C3)),
                _makeBarGroup(2, 140, const Color(0xFF4FC3C3)),
                _makeBarGroup(3, 80, const Color(0xFF4FC3C3)),
                _makeBarGroup(4, 165, const Color(0xFFE87B3C)),
                _makeBarGroup(5, 145, const Color(0xFF4FC3C3)),
                _makeBarGroup(6, 110, const Color(0xFF4FC3C3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }
}
