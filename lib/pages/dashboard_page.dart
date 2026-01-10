import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../blocs/locale/locale_cubit.dart';
import '../data/service_locator.dart';
import '../domain/app_data_source.dart';
import '../domain/models/models.dart';
import '../widgets/info_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/add_data_dialog.dart';
import '../widgets/top_error_banner.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import 'insights_page.dart';
import 'login.dart';

/// Dashboard Page - Main screen showing health metrics
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data from the AppDataSource
  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
      final dataSource = getIt<AppDataSource>();

      // Get complete dashboard data (includes glucose, reminders, health cards, chart, profile)
      final dashboardData = await dataSource.getDashboardData();

      setState(() {
        _dashboardData = dashboardData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      // If the session is no longer valid (expired/cleared tokens), take the
      // user back to login instead of leaving them on a blank error screen.
      if (e is DataSourceException &&
          (e.code == 'session_expired' || e.code == 'not_authenticated')) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      debugPrint('Error loading dashboard data: $e');

      if (!mounted) return;
      final msg = e is DataSourceException
          ? e.displayMessage
          : AppLocalizations.of(context).error;
      setState(() {
        _errorMessage = msg;
      });
    }
  }

  /// Refresh data and settings on pull-to-refresh
  Future<void> _onRefresh() async {
    // Reload settings from SharedPreferences
    context.read<SettingsCubit>().loadSettings();
    context.read<LocaleCubit>().loadLocale();

    // Reload dashboard data
    await _loadData();
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  TopErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                    onRetry: _loadData,
                  )
                else
                  Text(
                    l10n.error,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme, isDark, l10n),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      TopErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                        onRetry: _loadData,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildGlucoseCard(theme, isDark, l10n, settingsState),
                    const SizedBox(height: 16),
                    _buildReminderCard(theme, isDark, l10n),
                    const SizedBox(height: 20),
                    _buildHealthCardsGrid(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildAddDataCard(isDark, l10n, settingsState),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    BloodSugarChart(
                      flag: true,
                      chartData: _dashboardData!.chartData,
                      units: settingsState.units,
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
      ],
    );
  }

  Widget _buildGlucoseCard(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    SettingsState settingsState,
  ) {
    final glucose = _dashboardData!.glucose;

    // Handle no glucose reading (value is 0 or status is 'No data')
    if (glucose.value == 0 || glucose.status == 'No data') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(isDark),
        child: Text(
          'No glucose data available',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    // Convert glucose value based on settings
    final displayValue =
        settingsState.formatGlucoseValue(glucose.value.toDouble());
    final units = settingsState.units;

    // Use status from backend (already calculated by Django)
    final status = glucose.status;
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'low':
        statusText = l10n.lowGlucose;
        statusColor = Colors.orange;
        statusIcon = Icons.arrow_downward;
        break;
      case 'high':
        statusText = l10n.highGlucose;
        statusColor = Colors.red;
        statusIcon = Icons.arrow_upward;
        break;
      default: // 'normal'
        statusText = l10n.youAreFine;
        statusColor = AppColors.primary;
        statusIcon = Icons.check;
        break;
    }

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
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
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
    // Get reminder title and time from the next upcoming reminder
    final nextReminder = _dashboardData!.nextReminder;
    final timeUntilReminder = _dashboardData!.timeUntilNextReminder;
    String reminderTitle;
    String reminderTime;

    if (nextReminder != null) {
      reminderTitle = _getLocalizedReminderByType(
        nextReminder.reminderType,
        nextReminder.title,
        l10n,
      );
      // Use formattedTime for display (e.g., "08:30")
      final parts = nextReminder.scheduledTime.split(':');
      reminderTime = parts.length >= 2
          ? '${parts[0]}:${parts[1]}'
          : nextReminder.scheduledTime;
    } else {
      // No upcoming reminders
      reminderTitle = l10n.reminders;
      reminderTime = '--:--';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _cardDecoration(isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
                  reminderTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reminderTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (timeUntilReminder != null && timeUntilReminder.isNotEmpty)
                    Text(
                      'in $timeUntilReminder',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
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

  /// Helper method to get localized reminder text by type
  String _getLocalizedReminderByType(
      String type, String title, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'water':
        return l10n.drinkWater;
      case 'pills':
        return l10n.takePill;
      case 'glucose':
        return l10n.checkGlucose;
      case 'activity':
        return l10n.activity;
      case 'meal':
        return l10n.translate('meal');
      default:
        return title.isNotEmpty ? title : l10n.reminders;
    }
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

  /// Build the Add Data card
  Widget _buildAddDataCard(
      bool isDark, AppLocalizations l10n, SettingsState settingsState) {
    return GestureDetector(
      onTap: () => _showAddDataDialog(settingsState),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.translate('addData'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the add data dialog
  void _showAddDataDialog(SettingsState settingsState) {
    showDialog(
      context: context,
      builder: (context) => AddDataDialog(
        currentUnits: settingsState.units,
        onDataAdded: () {
          // Refresh dashboard data after adding
          _loadData();
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _errorMessage = message;
          });
        },
      ),
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
