import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/dashboard_data.dart';
import '../blocs/blocs.dart';
import '../services/data_service_new.dart';
import '../widgets/info_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import 'insights_page.dart';

/// Dashboard Page - Main screen showing health metrics
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data from the DataService
  Future<void> _loadData() async {
    try {
      final dataService = DataService.instance;

      // Get dashboard data from SQLite
      final dashboardJson = await dataService.getDashboardData();

      setState(() {
        _dashboardData = DashboardData.fromJson(dashboardJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    if (_dashboardData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text(
            l10n.error,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
        ),
      );
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isDark, l10n),
                  const SizedBox(height: 20),
                  _buildGlucoseCard(theme, isDark, l10n, settingsState),
                  const SizedBox(height: 16),
                  _buildReminderCard(theme, isDark, l10n),
                  const SizedBox(height: 20),
                  _buildHealthCardsGrid(isDark, l10n),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  BloodSugarChart(
                    flag: true,
                    chartData: _dashboardData!.chart,
                    onSeeDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InsightsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, AppLocalizations l10n) {
    // Extract name from greeting (e.g., "Hi, Sam" -> "Sam")
    final userName = _dashboardData!.greeting.split(', ').length > 1
        ? _dashboardData!.greeting.split(', ')[1]
        : 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.greeting(userName),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Row(
          children: [
            _buildIconButton(Icons.add),
            const SizedBox(width: 12),
            _buildIconButton(Icons.notifications),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildGlucoseCard(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    SettingsState settingsState,
  ) {
    final glucose = _dashboardData!.glucose;
    // Convert glucose value based on settings
    final displayValue =
        settingsState.formatGlucoseValue(glucose.value.toDouble());
    final units = settingsState.units;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.glucoseLevel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$displayValue ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      TextSpan(
                        text: units,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.youAreFine,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
      ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _cardDecoration(isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reminders,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getLocalizedReminder(_dashboardData!.reminder, l10n),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '15:34:12',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.timer_outlined,
                  color: AppColors.primary, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to get localized reminder text
  String _getLocalizedReminder(String reminder, AppLocalizations l10n) {
    switch (reminder.toLowerCase()) {
      case 'drink water':
        return l10n.drinkWater;
      case 'take your pill':
        return l10n.takePill;
      case 'check your glucose level':
        return l10n.checkGlucose;
      default:
        return reminder;
    }
  }

  /// Helper method to get localized health card title
  String _getLocalizedHealthCardTitle(String title, AppLocalizations l10n) {
    switch (title.toLowerCase()) {
      case 'water':
        return l10n.water;
      case 'pills':
        return l10n.pills;
      case 'activity':
        return l10n.activity;
      case 'carbs':
        return l10n.carbs;
      case 'insulin':
        return l10n.insulinCard;
      default:
        return title;
    }
  }

  Widget _buildHealthCardsGrid(bool isDark, AppLocalizations l10n) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.gridSpacing,
        mainAxisSpacing: AppSpacing.gridSpacing,
        childAspectRatio: 2,
      ),
      itemCount: _dashboardData!.healthCards.length,
      itemBuilder: (context, index) {
        final card = _dashboardData!.healthCards[index];
        return InfoCard(
          healthCard: card
              .copyWithTitle(_getLocalizedHealthCardTitle(card.title, l10n)),
          isDark: isDark,
        );
      },
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
