// ========================================
// lib/widgets/activity_chart.dart
// ========================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'legend_item.dart';
import '../utils/constants.dart';
class ActivityChart extends StatelessWidget {
  const ActivityChart({Key? key}) : super(key: key);

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legends
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            LegendItem(color: Color(0xFF6B9EFA), label: 'Normal'),
            SizedBox(width: 16),
            LegendItem(color: Color(0xFF4FC3C3), label: 'Above Usual'),
          ],
        ),
        const SizedBox(height: 20),

        // Chart
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.6,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.4,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeBarGroup(0, 0.95, const Color(0xFF6B9EFA)),
                _makeBarGroup(1, 1.2, const Color(0xFF6B9EFA)),
                _makeBarGroup(2, 1.1, const Color(0xFF6B9EFA)),
                _makeBarGroup(3, 0.65, const Color(0xFF6B9EFA)),
                _makeBarGroup(4, 1.3, AppColors.primary),
                _makeBarGroup(5, 1.05, const Color(0xFF6B9EFA)),
                _makeBarGroup(6, 0.85, const Color(0xFF6B9EFA)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
