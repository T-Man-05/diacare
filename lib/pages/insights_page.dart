import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/chart_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/carbs_chart.dart';
import '../widgets/activity_chart.dart';
import '../models/chart_data.dart';
import '../utils/constants.dart';
import '../services/data_service_new.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({Key? key}) : super(key: key);

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  ChartData? _bloodSugarData;
  Map<String, dynamic>? _carbsData;
  Map<String, dynamic>? _activityData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      final dataService = DataService.instance;

      // Load all chart data
      final glucoseData = await dataService.getGlucoseChartData();
      final carbsData = await dataService.getCarbsChartData();
      final activityData = await dataService.getActivityChartData();

      if (!mounted) return;

      setState(() {
        // Create ChartData for blood sugar
        _bloodSugarData = ChartData(
          title: 'Blood Sugar',
          data: {
            'before_meal':
                glucoseData['before_meal']?.map((e) => e.toInt()).toList() ??
                    [],
            'after_meal':
                glucoseData['after_meal']?.map((e) => e.toInt()).toList() ?? [],
          },
          days: _generateDayLabels(),
        );

        _carbsData = carbsData;
        _activityData = activityData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chart data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _generateDayLabels() {
    final now = DateTime.now();
    final days = <String>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      days.add(_getDayName(date.weekday));
    }
    return days;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Default empty chart data
    final bloodSugarData = _bloodSugarData ??
        ChartData(
          title: l10n.bloodSugar,
          data: {'before_meal': [], 'after_meal': []},
          days: _generateDayLabels(),
        );

    final carbsValues = (_carbsData?['values'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final carbsDays = (_carbsData?['days'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final carbsHasData = (_carbsData?['hasData'] as List<dynamic>?)
            ?.map((e) => e as bool)
            .toList() ??
        [];
    final carbsTotal = (_carbsData?['totalRecords'] as int?) ?? 0;

    final activityValues = (_activityData?['values'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final activityDays = (_activityData?['days'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final activityHasData = (_activityData?['hasData'] as List<dynamic>?)
            ?.map((e) => e as bool)
            .toList() ??
        [];
    final activityTotal = (_activityData?['totalRecords'] as int?) ?? 0;

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
                      chartData: bloodSugarData,
                      onSeeDetails: () {
                        // No action needed in insights page
                      },
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      title: l10n.carbs,
                      unit: '(${l10n.translate('units.calories')})',
                      child: CarbsChart(
                        values: carbsValues,
                        days: carbsDays,
                        hasData: carbsHasData,
                        totalRecords: carbsTotal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      title: l10n.dailyActivity,
                      unit: '(${l10n.translate('units.km')})',
                      child: ActivityChart(
                        values: activityValues,
                        days: activityDays,
                        hasData: activityHasData,
                        totalRecords: activityTotal,
                      ),
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
