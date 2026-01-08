import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/settings/settings_state.dart';
import '../l10n/app_localizations.dart';
import '../widgets/chart_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/carbs_chart.dart';
import '../widgets/activity_chart.dart';
import '../utils/constants.dart';
import '../data/service_locator.dart';
import '../domain/app_data_source.dart';
import '../domain/models/models.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({Key? key}) : super(key: key);

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  BloodSugarChartData? _bloodSugarData;
  CarbsChartData? _carbsData;
  ActivityChartData? _activityData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      final dataSource = getIt<AppDataSource>();

      // Load all chart data
      final glucoseData = await dataSource.getGlucoseChartData();
      final carbsData = await dataSource.getCarbsChartData();
      final activityData = await dataSource.getActivityChartData();

      if (!mounted) return;

      setState(() {
        // Create BloodSugarChartData from GlucoseChartData
        _bloodSugarData = BloodSugarChartData(
          title: 'Blood Sugar',
          beforeMealValues: glucoseData.beforeMealValues,
          afterMealValues: glucoseData.afterMealValues,
          labels: glucoseData.hours,
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

  /// Refresh data on pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadChartData();
  }

  List<String> _generateHourLabels() {
    final now = DateTime.now();
    final hours = <String>[];
    for (int i = 6; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i)).hour;
      final hourStr = hour == 0
          ? '12AM'
          : hour < 12
              ? '${hour}AM'
              : hour == 12
                  ? '12PM'
                  : '${hour - 12}PM';
      hours.add(hourStr);
    }
    return hours;
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
        BloodSugarChartData(
          title: l10n.bloodSugar,
          beforeMealValues: [],
          afterMealValues: [],
          labels: _generateHourLabels(),
        );

    final carbsValues = _carbsData?.values ?? [];
    final carbsDays = _carbsData?.days ?? [];
    // Generate hasData list based on values (non-zero values have data)
    final carbsHasData = carbsValues.map((v) => v > 0).toList();
    final carbsTotal = _carbsData?.totalRecords ?? 0;

    final activityValues = _activityData?.values ?? [];
    final activityDays = _activityData?.hours ?? [];
    // Generate hasData list based on values (non-zero values have data)
    final activityHasData = activityValues.map((v) => v > 0).toList();
    final activityTotal = _activityData?.totalRecords ?? 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(headerBackground, textPrimary, l10n),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, settingsState) {
                          return BloodSugarChart(
                            flag: false,
                            chartData: bloodSugarData,
                            units: settingsState.units,
                            onSeeDetails: () {
                              // No action needed in insights page
                            },
                          );
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
