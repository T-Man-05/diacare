/// ============================================================================
/// SUPABASE SERVICE - Cloud Database & Authentication Service
/// ============================================================================
///
/// This service manages all Supabase operations for DiaCare, replacing SQLite.
/// It handles:
/// - Supabase client initialization
/// - Authentication (signup, login, logout, password reset)
/// - CRUD operations for all tables
/// - Real-time subscriptions (optional)
///
/// Tables (PostgreSQL):
/// - profiles: User profile data (extends auth.users)
/// - diabetic_profiles: Diabetes configuration
/// - glucose_readings: Blood glucose measurements
/// - health_cards: Daily health metrics
/// - reminders: Medication and activity reminders
/// - user_preferences: Theme, locale, units settings
///
/// Security:
/// - All tables have Row Level Security (RLS) enabled
/// - Users can only access their own data
/// - Auth handled by Supabase Auth with JWT
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._internal();

  /// Get singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  /// Initialize Supabase client
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw SupabaseServiceException(
        'Missing Supabase credentials. Please check your .env file.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );

    _client = Supabase.instance.client;
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw SupabaseServiceException(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
  }) async {
    final response = await client.auth.signUp(
      email: email.toLowerCase().trim(),
      password: password,
      data: {
        'username': username ?? email.split('@').first,
        'full_name': fullName ?? '',
      },
    );

    // Update profile with additional data after signup
    if (response.user != null) {
      await client.from('profiles').update({
        'username': username ?? email.split('@').first,
        'full_name': fullName ?? '',
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'height': height,
        'weight': weight,
      }).eq('id', response.user!.id);
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.toLowerCase().trim(),
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email.toLowerCase().trim());
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    // Delete will cascade to all related data due to FK constraints
    await client.rpc('delete_user');
    await signOut();
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final result = await client
        .from('profiles')
        .select('id')
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();
    return result != null;
  }

  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================

  /// Get current user profile
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final result =
        await client.from('profiles').select().eq('id', userId).single();

    return result;
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    await client.from('profiles').update(data).eq('id', userId);
  }

  // ============================================================================
  // DIABETIC PROFILE OPERATIONS
  // ============================================================================

  /// Get diabetic profile
  Future<Map<String, dynamic>?> getDiabeticProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final result = await client
        .from('diabetic_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return result;
  }

  /// Update diabetic profile
  Future<void> updateDiabeticProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    await client.from('diabetic_profiles').update(data).eq('user_id', userId);
  }

  // ============================================================================
  // GLUCOSE READINGS OPERATIONS
  // ============================================================================

  /// Add glucose reading
  Future<Map<String, dynamic>> addGlucoseReading({
    required double value,
    String unit = 'mg/dL',
    String readingType = 'before_meal',
    String? notes,
    DateTime? recordedAt,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    final result = await client
        .from('glucose_readings')
        .insert({
          'user_id': userId,
          'value': value,
          'unit': unit,
          'reading_type': readingType,
          'notes': notes,
          'recorded_at':
              (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
        })
        .select()
        .single();

    return result;
  }

  /// Get glucose readings
  Future<List<Map<String, dynamic>>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query = client.from('glucose_readings').select().eq('user_id', userId);

    if (startDate != null) {
      query = query.gte('recorded_at', startDate.toUtc().toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('recorded_at', endDate.toUtc().toIso8601String());
    }

    var orderedQuery = query.order('recorded_at', ascending: false);

    if (limit != null) {
      return await orderedQuery.limit(limit);
    }

    return await orderedQuery;
  }

  /// Get latest glucose reading
  Future<Map<String, dynamic>?> getLatestGlucoseReading() async {
    final readings = await getGlucoseReadings(limit: 1);
    return readings.isEmpty ? null : readings.first;
  }

  /// Get glucose chart data (last 7 hours)
  Future<Map<String, dynamic>> getGlucoseChartData() async {
    final userId = currentUserId;
    if (userId == null) {
      return {
        'before_meal': <double>[],
        'after_meal': <double>[],
        'hours': <String>[]
      };
    }

    final now = DateTime.now();
    final sevenHoursAgo = now.subtract(const Duration(hours: 7));

    final results = await client
        .from('glucose_readings')
        .select()
        .eq('user_id', userId)
        .gte('recorded_at', sevenHoursAgo.toUtc().toIso8601String())
        .order('recorded_at', ascending: true);

    // Group readings by hour
    Map<int, List<double>> beforeMealByHour = {};
    Map<int, List<double>> afterMealByHour = {};

    for (final reading in results) {
      final value = (reading['value'] as num).toDouble();
      final recordedAt =
          DateTime.parse(reading['recorded_at'] as String).toLocal();
      final hour = recordedAt.hour;

      if (reading['reading_type'] == 'before_meal' ||
          reading['reading_type'] == 'fasting') {
        beforeMealByHour.putIfAbsent(hour, () => []).add(value);
      } else {
        afterMealByHour.putIfAbsent(hour, () => []).add(value);
      }
    }

    // Generate hour labels for last 7 hours
    List<String> hourLabels = [];
    List<double> beforeMeal = [];
    List<double> afterMeal = [];

    for (int i = 6; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i)).hour;
      final hourStr = hour == 0
          ? '12AM'
          : hour < 12
              ? '${hour}AM'
              : hour == 12
                  ? '12PM'
                  : '${hour - 12}PM';

      hourLabels.add(hourStr);

      // Average readings for this hour
      if (beforeMealByHour.containsKey(hour) &&
          beforeMealByHour[hour]!.isNotEmpty) {
        final avg = beforeMealByHour[hour]!.reduce((a, b) => a + b) /
            beforeMealByHour[hour]!.length;
        beforeMeal.add(avg);
      } else if (beforeMeal.isNotEmpty) {
        beforeMeal.add(beforeMeal.last);
      } else {
        beforeMeal.add(0);
      }

      if (afterMealByHour.containsKey(hour) &&
          afterMealByHour[hour]!.isNotEmpty) {
        final avg = afterMealByHour[hour]!.reduce((a, b) => a + b) /
            afterMealByHour[hour]!.length;
        afterMeal.add(avg);
      } else if (afterMeal.isNotEmpty) {
        afterMeal.add(afterMeal.last);
      } else {
        afterMeal.add(0);
      }
    }

    return {
      'before_meal': beforeMeal,
      'after_meal': afterMeal,
      'hours': hourLabels,
    };
  }

  // ============================================================================
  // HEALTH CARDS OPERATIONS
  // ============================================================================

  /// Upsert health card (insert or update)
  Future<void> upsertHealthCard({
    required String cardType,
    required double value,
    required String unit,
    DateTime? recordedDate,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    final date = recordedDate ?? DateTime.now();
    final dateStr = date.toIso8601String().split('T')[0];

    await client.from('health_cards').upsert(
      {
        'user_id': userId,
        'card_type': cardType,
        'value': value,
        'unit': unit,
        'recorded_date': dateStr,
      },
      onConflict: 'user_id,card_type,recorded_date',
    );
  }

  /// Get health cards for a specific date
  Future<List<Map<String, dynamic>>> getHealthCards({DateTime? date}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final dateStr = (date ?? DateTime.now()).toIso8601String().split('T')[0];

    return await client
        .from('health_cards')
        .select()
        .eq('user_id', userId)
        .eq('recorded_date', dateStr);
  }

  /// Get weekly carbs chart data
  Future<Map<String, dynamic>> getCarbsChartData() async {
    final userId = currentUserId;
    if (userId == null) {
      return {
        'values': <double>[],
        'days': <String>[],
        'hasData': <bool>[],
        'totalRecords': 0
      };
    }

    final now = DateTime.now();
    List<double> values = [];
    List<String> days = [];
    List<bool> hasData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dayName = _getDayName(date.weekday);

      final result = await client
          .from('health_cards')
          .select('value')
          .eq('user_id', userId)
          .eq('card_type', 'carbs')
          .eq('recorded_date', dateStr)
          .maybeSingle();

      days.add(dayName);
      if (result != null) {
        values.add((result['value'] as num).toDouble());
        hasData.add(true);
      } else {
        values.add(0.0);
        hasData.add(false);
      }
    }

    return {
      'values': values,
      'days': days,
      'hasData': hasData,
      'totalRecords': hasData.where((h) => h).length,
    };
  }

  /// Get weekly activity chart data
  Future<Map<String, dynamic>> getActivityChartData() async {
    final userId = currentUserId;
    if (userId == null) {
      return {
        'values': <double>[],
        'days': <String>[],
        'hasData': <bool>[],
        'totalRecords': 0
      };
    }

    final now = DateTime.now();
    List<double> values = [];
    List<String> days = [];
    List<bool> hasData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dayName = _getDayName(date.weekday);

      final result = await client
          .from('health_cards')
          .select('value')
          .eq('user_id', userId)
          .eq('card_type', 'activity')
          .eq('recorded_date', dateStr)
          .maybeSingle();

      days.add(dayName);
      if (result != null) {
        final steps = (result['value'] as num).toDouble();
        // Convert steps to km (1 km ≈ 1312 steps)
        values.add(steps / 1312.0);
        hasData.add(true);
      } else {
        values.add(0.0);
        hasData.add(false);
      }
    }

    return {
      'values': values,
      'days': days,
      'hasData': hasData,
      'totalRecords': hasData.where((h) => h).length,
    };
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

  // ============================================================================
  // REMINDERS OPERATIONS
  // ============================================================================

  /// Add reminder
  Future<Map<String, dynamic>> addReminder({
    required String title,
    required String reminderType,
    required String scheduledTime,
    String? description,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    final result = await client
        .from('reminders')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'reminder_type': reminderType,
          'scheduled_time': scheduledTime,
          'is_recurring': isRecurring,
          'recurrence_pattern': recurrencePattern,
          'status': 'pending',
          'is_enabled': true,
        })
        .select()
        .single();

    return result;
  }

  /// Get reminders
  Future<List<Map<String, dynamic>>> getReminders({bool? isEnabled}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query = client.from('reminders').select().eq('user_id', userId);

    if (isEnabled != null) {
      query = query.eq('is_enabled', isEnabled);
    }

    return await query.order('scheduled_time', ascending: true);
  }

  /// Update reminder
  Future<void> updateReminder(
      String reminderId, Map<String, dynamic> data) async {
    await client.from('reminders').update(data).eq('id', reminderId);
  }

  /// Update reminder status
  Future<void> updateReminderStatus(String reminderId, String status) async {
    await client.from('reminders').update({
      'status': status,
      'completed_at': status == 'completed' || status == 'done'
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    }).eq('id', reminderId);
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    await client.from('reminders').delete().eq('id', reminderId);
  }

  // ============================================================================
  // USER PREFERENCES OPERATIONS
  // ============================================================================

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    final userId = currentUserId;
    if (userId == null) return null;

    return await client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  /// Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    await client.from('user_preferences').update(data).eq('user_id', userId);
  }

  // ============================================================================
  // DASHBOARD DATA
  // ============================================================================

  /// Get complete dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    final profile = await getProfile();
    final latestGlucose = await getLatestGlucoseReading();
    final healthCards = await getHealthCards();
    final reminders = await getReminders(isEnabled: true);
    final chartData = await getGlucoseChartData();

    // Default health card types
    final cardTypes = ['water', 'pills', 'activity', 'carbs', 'insulin'];
    final cardTitles = {
      'water': 'Water',
      'pills': 'Pills',
      'activity': 'Activity',
      'carbs': 'Carbs',
      'insulin': 'Insulin',
    };
    final cardUnits = {
      'water': 'L',
      'pills': 'taken',
      'activity': 'steps',
      'carbs': 'cal',
      'insulin': 'units',
    };

    final healthCardsList = cardTypes.map((type) {
      final existing = healthCards.firstWhere(
        (c) => c['card_type'] == type,
        orElse: () => <String, dynamic>{},
      );
      return {
        'title': cardTitles[type],
        'value': existing.isNotEmpty ? (existing['value'] ?? 0.0) : 0.0,
        'unit': existing.isNotEmpty
            ? (existing['unit'] ?? cardUnits[type])
            : cardUnits[type],
      };
    }).toList();

    // Get next reminder
    String nextReminder = 'No reminders';
    if (reminders.isNotEmpty) {
      nextReminder = reminders.first['title'] ?? 'Reminder';
    }

    return {
      'greeting':
          'Hi, ${profile?['full_name'] ?? profile?['username'] ?? 'User'}',
      'glucose': {
        'value': latestGlucose?['value']?.toInt() ?? 0,
        'unit': latestGlucose?['unit'] ?? 'mg/dL',
        'status': _getGlucoseStatus(
            (latestGlucose?['value'] as num?)?.toDouble() ?? 0),
      },
      'reminder': nextReminder,
      'health_cards': healthCardsList,
      'chart': {
        'title': 'Blood Sugar',
        'data': {
          'before_meal': chartData['before_meal'],
          'after_meal': chartData['after_meal'],
        },
        'hours': chartData['hours'],
      },
    };
  }

  String _getGlucoseStatus(double value) {
    if (value == 0) return 'No readings';
    if (value < 70) return 'Low - Please eat something';
    if (value > 180) return 'High - Monitor closely';
    return 'You are fine';
  }

  // ============================================================================
  // SETTINGS DATA
  // ============================================================================

  /// Get complete settings data
  Future<Map<String, dynamic>> getSettingsData() async {
    final profile = await getProfile();
    final diabeticProfile = await getDiabeticProfile();
    final preferences = await getUserPreferences();

    if (profile == null) {
      throw SupabaseServiceException('User profile not found');
    }

    return {
      'email': profile['email'],
      'full_name': profile['full_name'] ?? '',
      'username': profile['username'] ?? '',
      'profile_image_url': profile['profile_image_url'],
      'diabetic_profile': {
        'diabetic_type': diabeticProfile?['diabetic_type'] ?? 'Type 1',
        'treatment_type': diabeticProfile?['treatment_type'] ?? 'Insulin',
        'min_glucose': diabeticProfile?['min_glucose'] ?? 70,
        'max_glucose': diabeticProfile?['max_glucose'] ?? 180,
      },
      'preferences': {
        'theme': preferences?['theme'] ?? 'light',
        'notifications_enabled': preferences?['notifications_enabled'] ?? true,
        'units': preferences?['units'] ?? 'mg/dL',
      },
    };
  }

  // ============================================================================
  // DEMO DATA SEEDING
  // ============================================================================

  /// Seed demo data for current user
  Future<void> seedDemoData() async {
    final userId = currentUserId;
    if (userId == null) throw SupabaseServiceException('No user logged in');

    final now = DateTime.now();

    // Add sample glucose readings for the past 7 hours
    final glucoseValues = [95.0, 110.0, 125.0, 105.0, 140.0, 98.0, 115.0];
    final readingTypes = [
      'fasting',
      'before_meal',
      'after_meal',
      'before_meal',
      'after_meal',
      'before_meal',
      'random'
    ];

    for (int i = 6; i >= 0; i--) {
      final readingTime = now.subtract(Duration(hours: i));
      await addGlucoseReading(
        value: glucoseValues[6 - i],
        unit: 'mg/dL',
        readingType: readingTypes[6 - i],
        recordedAt: readingTime,
      );
    }

    // Add today's health cards
    await upsertHealthCard(cardType: 'water', value: 1.2, unit: 'L');
    await upsertHealthCard(cardType: 'pills', value: 2, unit: 'taken');
    await upsertHealthCard(cardType: 'activity', value: 3250, unit: 'steps');
    await upsertHealthCard(cardType: 'carbs', value: 190, unit: 'g');
    await upsertHealthCard(cardType: 'insulin', value: 5, unit: 'units');

    // Add daily data for the past 7 days
    final activityValues = [4500, 3200, 5800, 2900, 6100, 4000, 3250];
    final carbsValues = [180, 220, 150, 280, 200, 250, 190];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      await upsertHealthCard(
        cardType: 'activity',
        value: activityValues[6 - i].toDouble(),
        unit: 'steps',
        recordedDate: date,
      );
      await upsertHealthCard(
        cardType: 'carbs',
        value: carbsValues[6 - i].toDouble(),
        unit: 'cal',
        recordedDate: date,
      );
    }

    // Add sample reminders
    await addReminder(
      title: 'Drink Water',
      reminderType: 'water',
      scheduledTime: '${(now.hour + 1).toString().padLeft(2, '0')}:00',
      isRecurring: true,
      recurrencePattern: 'hourly',
    );

    await addReminder(
      title: 'Take Medication',
      reminderType: 'medication',
      scheduledTime: '08:00',
      isRecurring: true,
      recurrencePattern: 'daily',
    );

    await addReminder(
      title: 'Check Blood Sugar',
      reminderType: 'glucose',
      scheduledTime: '12:00',
      isRecurring: true,
      recurrencePattern: 'daily',
    );
  }
}

/// Custom exception for Supabase service errors
class SupabaseServiceException implements Exception {
  final String message;
  SupabaseServiceException(this.message);

  @override
  String toString() => 'SupabaseServiceException: $message';
}
