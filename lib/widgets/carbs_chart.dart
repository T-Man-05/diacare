import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'legend_item.dart';
import '../utils/constants.dart';

class CarbsChart extends StatelessWidget {
  const CarbsChart({Key? key}) : super(key: key);

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
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LegendItem(color: AppColors.primary, label: 'Normal'),
            LegendItem(color: Color(0xFFE87B3C), label: 'Above Normal'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 200,
              barTouchData: const BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = [
                        'Sat',
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri'
                      ];
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
                _makeBarGroup(0, 130, AppColors.primary),
                _makeBarGroup(1, 155, AppColors.primary),
                _makeBarGroup(2, 140, AppColors.primary),
                _makeBarGroup(3, 80, AppColors.primary),
                _makeBarGroup(4, 165, const Color(0xFFE87B3C)),
                _makeBarGroup(5, 145, AppColors.primary),
                _makeBarGroup(6, 110, AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
