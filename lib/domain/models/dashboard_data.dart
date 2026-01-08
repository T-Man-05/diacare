import 'glucose_reading.dart';
import 'health_card.dart';
import 'chart_data.dart';
import 'reminder.dart';

/// Domain model for dashboard screen data
/// This model is backend-agnostic - aggregates all dashboard info
class DashboardData {
  final String greeting;
  final LatestGlucose glucose;
  final Reminder? nextReminder;
  final int lateRemindersCount;
  final List<HealthCard> healthCards;
  final BloodSugarChartData chartData;
  final int minGlucose;
  final int maxGlucose;

  const DashboardData({
    required this.greeting,
    required this.glucose,
    this.nextReminder,
    this.lateRemindersCount = 0,
    required this.healthCards,
    required this.chartData,
    required this.minGlucose,
    required this.maxGlucose,
  });

  /// Time until next reminder formatted
  String? get timeUntilNextReminder {
    if (nextReminder == null) return null;
    final duration = nextReminder!.timeRemaining(DateTime.now());
    if (duration == null) return null;

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Check if user has late reminders
  bool get hasLateReminders => lateRemindersCount > 0;

  /// Default empty dashboard
  factory DashboardData.empty() {
    return DashboardData(
      greeting: 'Welcome',
      glucose: const LatestGlucose(
        value: 0,
        unit: 'mg/dL',
        status: 'No data',
      ),
      healthCards: const [],
      chartData: const BloodSugarChartData(
        title: 'Blood Sugar (mg/dL)',
        beforeMealValues: [],
        afterMealValues: [],
        labels: [],
      ),
      minGlucose: 70,
      maxGlucose: 180,
    );
  }
}
