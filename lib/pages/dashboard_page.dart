import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dashboard_data.dart';
import '../providers/settings_provider.dart';
import '../repositories/app_repository.dart';
import '../widgets/info_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import 'insights_page.dart';

/// Dashboard Page - Main screen showing health metrics
class DashboardPage extends StatefulWidget {
  final AppRepository repository;

  const DashboardPage({Key? key, required this.repository}) : super(key: key);

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

  /// Load data using single getData() function from repository
  Future<void> _loadData() async {
    try {
      // Call single getData() function
      final allData = await widget.repository.getData();

      // Extract dashboard data
      final dashboardJson = allData['dashboard'] as Map<String, dynamic>;

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
    final settingsProvider = Provider.of<SettingsProvider>(context);

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 20),
              _buildGlucoseCard(theme, isDark, l10n, settingsProvider),
              const SizedBox(height: 16),
              _buildReminderCard(theme, isDark, l10n),
              const SizedBox(height: 20),
              _buildHealthCardsGrid(isDark),
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
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _dashboardData!.greeting,
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
    SettingsProvider settingsProvider,
  ) {
    final glucose = _dashboardData!.glucose;
    // Convert glucose value based on settings
    final displayValue =
        settingsProvider.formatGlucoseValue(glucose.value.toDouble());
    final units = settingsProvider.units;

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
                glucose.status,
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
                _dashboardData!.reminder,
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

  Widget _buildHealthCardsGrid(bool isDark) {
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
        return InfoCard(
          healthCard: _dashboardData!.healthCards[index],
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
