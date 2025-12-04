import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/chart_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/carbs_chart.dart';
import '../widgets/activity_chart.dart';
import '../models/chart_data.dart';
import '../utils/constants.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({Key? key}) : super(key: key);

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  ChartData _getBloodSugarData(AppLocalizations l10n) {
    return ChartData(
      title: l10n.bloodSugar,
      data: {
        'before_meal': [120, 110, 130, 125, 140, 100, 105],
        'after_meal': [160, 150, 140, 130, 145, 135, 120],
      },
      days: [
        l10n.dayMon,
        l10n.dayTue,
        l10n.dayWed,
        l10n.dayThu,
        l10n.dayFri,
        l10n.daySat,
        l10n.daySun,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.background;
    final headerBackground =
        isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(headerBackground, textPrimary, l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BloodSugarChart(
                      flag: false,
                      chartData: _getBloodSugarData(l10n),
                      onSeeDetails: () {
                        // No action needed in insights page
                      },
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      title: l10n.carbs,
                      unit: '(${l10n.translate('units.calories')})',
                      child: const CarbsChart(),
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      title: l10n.dailyActivity,
                      unit: '(${l10n.translate('units.km')})',
                      child: const ActivityChart(),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      Color headerBackground, Color textPrimary, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: headerBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.insightsPageTitle,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
