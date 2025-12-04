import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import 'legend_item.dart';
import '../utils/constants.dart';

class ActivityChart extends StatelessWidget {
  final List<double> values;
  final List<String> days;
  final List<bool> hasData;
  final int totalRecords;

  const ActivityChart({
    Key? key,
    required this.values,
    required this.days,
    required this.hasData,
    required this.totalRecords,
  }) : super(key: key);

  BarChartGroupData _makeBarGroup(int x, double y, Color color, bool showData) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: showData ? y : 0,
          color: showData ? color : Colors.transparent,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final gridColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final l10n = AppLocalizations.of(context);

    // Use provided days or default
    final displayDays = days.isNotEmpty
        ? days
        : [
            l10n.daySat,
            l10n.daySun,
            l10n.dayMon,
            l10n.dayTue,
            l10n.dayWed,
            l10n.dayThu,
            l10n.dayFri,
          ];

    // Check if we have any data
    if (totalRecords == 0) {
      return _buildEmptyState(l10n, textPrimary, textSecondary);
    }

    // Calculate max Y value based on data
    double maxY = 1.6;
    if (values.isNotEmpty) {
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      maxY = (maxValue * 1.3).clamp(0.5, 10.0);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LegendItem(color: const Color(0xFF6B9EFA), label: l10n.normal),
            const SizedBox(width: 16),
            LegendItem(color: const Color(0xFF4FC3C3), label: l10n.aboveUsual),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: totalRecords == 1
              ? _buildSinglePointChart(l10n, textSecondary, gridColor)
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: const BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: maxY / 4,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(
                                color: textSecondary,
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
                            final idx = value.toInt();
                            if (idx >= 0 && idx < displayDays.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  displayDays[idx],
                                  style: TextStyle(
                                    color: textSecondary,
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
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: gridColor,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(),
                  ),
                ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < values.length && i < 7; i++) {
      final value = values[i];
      final show = hasData.length > i ? hasData[i] : false;
      // Above 1.0 km is considered above usual
      final color =
          value > 1.0 ? const Color(0xFF4FC3C3) : const Color(0xFF6B9EFA);
      groups.add(_makeBarGroup(i, value, color, show));
    }
    return groups;
  }

  Widget _buildEmptyState(
      AppLocalizations l10n, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk_outlined,
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
            'Add activity data to see the chart',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePointChart(
      AppLocalizations l10n, Color textSecondary, Color gridColor) {
    // Find the single data point
    int dataIndex = hasData.indexWhere((h) => h);
    if (dataIndex == -1) dataIndex = 0;
    final value = values.isNotEmpty ? values[dataIndex] : 0.0;
    final color =
        value > 1.0 ? const Color(0xFF4FC3C3) : const Color(0xFF6B9EFA);

    // Use provided days or default
    final displayDays = days.isNotEmpty
        ? days
        : [
            l10n.daySat,
            l10n.daySun,
            l10n.dayMon,
            l10n.dayTue,
            l10n.dayWed,
            l10n.dayThu,
            l10n.dayFri,
          ];

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _SinglePointPainter(
        value: value,
        dayIndex: dataIndex,
        days: displayDays,
        color: color,
        textColor: textSecondary,
        gridColor: gridColor,
      ),
    );
  }
}

class _SinglePointPainter extends CustomPainter {
  final double value;
  final int dayIndex;
  final List<String> days;
  final Color color;
  final Color textColor;
  final Color gridColor;

  _SinglePointPainter({
    required this.value,
    required this.dayIndex,
    required this.days,
    required this.color,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final chartTop = 10.0;
    final chartBottom = size.height - 30; // Leave space for day labels
    final chartHeight = chartBottom - chartTop;

    for (int i = 0; i <= 4; i++) {
      final y = chartBottom - (chartHeight / 4 * i);
      canvas.drawLine(Offset(40, y), Offset(size.width - 10, y), gridPaint);
    }

    // Draw day labels at bottom
    final dayWidth = (size.width - 50) / days.length;
    for (int i = 0; i < days.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: days[i],
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final x = 40 + (i + 0.5) * dayWidth - textPainter.width / 2;
      textPainter.paint(canvas, Offset(x, size.height - 20));
    }

    // Draw the point at the correct day position
    final x = 40 + (dayIndex + 0.5) * dayWidth;
    final maxY = value * 1.5;
    final y = chartBottom - (value / maxY * chartHeight);

    // Draw point with glow effect
    canvas.drawCircle(Offset(x, y), 12, Paint()..color = color.withAlpha(50));
    canvas.drawCircle(Offset(x, y), 8, paint);

    // Draw value text above the point
    final valuePainter = TextPainter(
      text: TextSpan(
        text: '${value.toStringAsFixed(2)} km',
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    valuePainter.layout();
    valuePainter.paint(canvas, Offset(x - valuePainter.width / 2, y - 25));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
