/// ============================================================================
/// MAPPERS - JSON to Domain Model Mapping
/// ============================================================================
///
/// Centralized JSON parsing for all domain models.
/// Separates data transformation from data fetching.
/// ============================================================================

import '../../domain/models/models.dart';

/// User and Profile Mappers
class UserMapper {
  static UserProfile parseUserProfile(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      profileImageUrl: json['profile_image_url'],
    );
  }

  static DiabeticProfile parseDiabeticProfile(Map<String, dynamic> json) {
    // Handle nested 'data' wrapper if present
    final data = json['data'] ?? json;
    return DiabeticProfile(
      diabeticType: data['diabetic_type'] ?? 'Type 1',
      treatmentType: data['treatment_type'] ?? 'Insulin',
      minGlucose: data['min_glucose'] ?? 70,
      maxGlucose: data['max_glucose'] ?? 180,
    );
  }
}

/// Glucose Reading Mappers
class GlucoseMapper {
  static GlucoseReading parseGlucoseReading(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'].toString(),
      value: json['value']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'mg/dL',
      readingType: parseGlucoseReadingType(json['reading_type']),
      notes: json['notes'],
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'])
          : DateTime.now(),
    );
  }

  static GlucoseReadingType parseGlucoseReadingType(String? type) {
    switch (type?.toLowerCase()) {
      case 'before_meal':
        return GlucoseReadingType.beforeMeal;
      case 'after_meal':
        return GlucoseReadingType.afterMeal;
      case 'fasting':
        return GlucoseReadingType.fasting;
      case 'bedtime':
        return GlucoseReadingType.bedtime;
      default:
        return GlucoseReadingType.random;
    }
  }

  static List<GlucoseReading> parseGlucoseReadings(List<dynamic> readings) {
    return readings.map((r) => parseGlucoseReading(r)).toList();
  }

  static GlucoseChartData parseGlucoseChartData(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return GlucoseChartData(
      beforeMealValues: (data['before_meal'] as List?)
              ?.map((v) => (v as num).toDouble())
              .toList() ??
          [],
      afterMealValues: (data['after_meal'] as List?)
              ?.map((v) => (v as num).toDouble())
              .toList() ??
          [],
      hours: (data['labels'] as List?)?.map((l) => l.toString()).toList() ?? [],
      hasData: (data['before_meal'] as List?)?.isNotEmpty ?? false,
      totalRecords: ((data['before_meal'] as List?)?.length ?? 0) +
          ((data['after_meal'] as List?)?.length ?? 0),
    );
  }
}

/// Health Card Mappers
class HealthCardMapper {
  static HealthCard parseHealthCard(Map<String, dynamic> json) {
    return HealthCard(
      id: json['id'].toString(),
      type: parseHealthCardType(json['card_type']),
      value: json['value']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  static HealthCardType parseHealthCardType(String? type) {
    switch (type?.toLowerCase()) {
      case 'carbs':
        return HealthCardType.carbs;
      case 'activity':
        return HealthCardType.activity;
      case 'water':
        return HealthCardType.water;
      case 'pills':
        return HealthCardType.pills;
      case 'insulin':
        return HealthCardType.insulin;
      default:
        return HealthCardType.carbs;
    }
  }

  static List<HealthCard> parseHealthCards(List<dynamic> cards) {
    return cards.map((c) => parseHealthCard(c)).toList();
  }

  static CarbsChartData parseCarbsChartData(List<HealthCard> healthCards) {
    final carbsCards =
        healthCards.where((c) => c.type == HealthCardType.carbs).toList();

    final values = carbsCards.map((c) => c.value).toList();
    final days = carbsCards
        .map((c) => c.updatedAt != null
            ? c.updatedAt!.day.toString()
            : DateTime.now().day.toString())
        .toList();

    return CarbsChartData(
      values: values,
      days: days,
      hasData: values.isNotEmpty,
      totalRecords: values.length,
    );
  }

  static ActivityChartData parseActivityChartData(List<HealthCard> healthCards) {
    final activityCards =
        healthCards.where((c) => c.type == HealthCardType.activity).toList();

    final values = activityCards.map((c) => c.value).toList();
    final hours = activityCards
        .map((c) => c.updatedAt != null
            ? c.updatedAt!.hour.toString()
            : DateTime.now().hour.toString())
        .toList();

    return ActivityChartData(
      values: values,
      hours: hours,
      hasData: values.isNotEmpty,
      totalRecords: values.length,
    );
  }
}

/// Reminder Mappers
class ReminderMapper {
  static Reminder parseReminder(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      reminderType: json['reminder_type'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '',
      description: json['description'],
      isEnabled: json['is_enabled'] ?? true,
      isRecurring: json['is_recurring'] ?? false,
      recurrencePattern: json['recurrence_pattern'],
      status: parseReminderStatus(json['status']),
    );
  }

  static ReminderStatus parseReminderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'done':
        return ReminderStatus.done;
      case 'completed':
        return ReminderStatus.completed;
      case 'skipped':
        return ReminderStatus.skipped;
      case 'snoozed':
        return ReminderStatus.snoozed;
      default:
        return ReminderStatus.pending;
    }
  }

  static List<Reminder> parseReminders(List<dynamic> reminders) {
    return reminders.map((r) => parseReminder(r)).toList();
  }
}

/// Dashboard Mappers
class DashboardMapper {
  static DashboardData parseDashboardData(Map<String, dynamic> json) {
    // Parse latest glucose
    final latestGlucose = json['latest_glucose'] != null
        ? LatestGlucose(
            value: json['latest_glucose']['value']?.toDouble() ?? 0.0,
            unit: json['latest_glucose']['unit'] ?? 'mg/dL',
            status: json['latest_glucose']['status'] ?? 'No data',
            readingType: json['latest_glucose']['reading_type'] != null
                ? GlucoseMapper.parseGlucoseReadingType(
                    json['latest_glucose']['reading_type'])
                : null,
          )
        : const LatestGlucose(
            value: 0.0,
            unit: 'mg/dL',
            status: 'No data',
          );

    // Parse next reminder
    final nextReminder = json['next_reminder'] != null
        ? ReminderMapper.parseReminder(json['next_reminder'])
        : null;

    // Parse health cards
    final healthCards = json['health_cards'] != null
        ? HealthCardMapper.parseHealthCards(json['health_cards'] as List)
        : <HealthCard>[];

    // Parse chart data
    final chartData = json['chart_data'] != null
        ? BloodSugarChartData(
            title: 'Blood Sugar (mg/dL)',
            beforeMealValues: (json['chart_data']['before_meal'] as List?)
                    ?.map((v) => (v as num).toDouble())
                    .toList() ??
                [],
            afterMealValues: (json['chart_data']['after_meal'] as List?)
                    ?.map((v) => (v as num).toDouble())
                    .toList() ??
                [],
            labels: (json['chart_data']['labels'] as List?)
                    ?.map((l) => l.toString())
                    .toList() ??
                [],
          )
        : const BloodSugarChartData(
            title: 'Blood Sugar (mg/dL)',
            beforeMealValues: [],
            afterMealValues: [],
            labels: [],
          );

    return DashboardData(
      greeting: json['greeting'] ?? 'Hello',
      glucose: latestGlucose,
      nextReminder: nextReminder,
      lateRemindersCount: json['late_reminders_count'] ?? 0,
      healthCards: healthCards,
      chartData: chartData,
      minGlucose: json['min_glucose'] ?? 70,
      maxGlucose: json['max_glucose'] ?? 180,
    );
  }
}

/// Insights Mappers
class InsightsMapper {
  static InsightsData parseInsightsData(Map<String, dynamic> json) {
    return InsightsData(
      sevenDayAverage: json['seven_day_average']?.toDouble() ?? 0.0,
      sevenDayMin: json['seven_day_min']?.toDouble() ?? 0.0,
      sevenDayMax: json['seven_day_max']?.toDouble() ?? 0.0,
      sevenDayCount: json['seven_day_count'] ?? 0,
      sevenDayInRange: json['seven_day_in_range']?.toDouble() ?? 0.0,
      sevenDayBelowRange: json['seven_day_below_range']?.toDouble() ?? 0.0,
      sevenDayAboveRange: json['seven_day_above_range']?.toDouble() ?? 0.0,
      thirtyDayAverage: json['thirty_day_average']?.toDouble() ?? 0.0,
      thirtyDayMin: json['thirty_day_min']?.toDouble() ?? 0.0,
      thirtyDayMax: json['thirty_day_max']?.toDouble() ?? 0.0,
      thirtyDayCount: json['thirty_day_count'] ?? 0,
      thirtyDayInRange: json['thirty_day_in_range']?.toDouble() ?? 0.0,
      thirtyDayBelowRange: json['thirty_day_below_range']?.toDouble() ?? 0.0,
      thirtyDayAboveRange: json['thirty_day_above_range']?.toDouble() ?? 0.0,
      morningAverage: json['morning_average']?.toDouble() ?? 0.0,
      morningCount: json['morning_count'] ?? 0,
      eveningAverage: json['evening_average']?.toDouble() ?? 0.0,
      eveningCount: json['evening_count'] ?? 0,
      trend: json['trend'] ?? 'insufficient_data',
      recommendations: (json['recommendations'] as List?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
      minGlucose: json['min_glucose'] ?? 70,
      maxGlucose: json['max_glucose'] ?? 180,
    );
  }
}
