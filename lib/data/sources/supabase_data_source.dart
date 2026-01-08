/// ============================================================================
/// SUPABASE DATA SOURCE - Supabase Implementation of AppDataSource
/// ============================================================================
///
/// This class implements the AppDataSource interface using Supabase as backend.
/// ALL JSON parsing, key access, and backend-specific logic is encapsulated here.
/// UI code NEVER sees Maps, JSON, or Supabase types.
/// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart' hide HealthCard;
import '../../domain/app_data_source.dart';
import '../../domain/models/models.dart';
import '../../domain/inputs/inputs.dart';
import '../../services/preferences_service.dart';

/// Supabase implementation of AppDataSource
/// This is the ONLY place where Supabase SDK is used
class SupabaseDataSource implements AppDataSource {
  final SupabaseClient _client;
  final PreferencesService _prefs;

  SupabaseDataSource(this._client, this._prefs);

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  @override
  bool get isLoggedIn => _client.auth.currentUser != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<UserProfile?> login(LoginInput input) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: input.email.toLowerCase().trim(),
        password: input.password,
      );

      if (response.user != null) {
        return await getCurrentUser();
      }
      return null;
    } on AuthException catch (e) {
      throw DataSourceException('Login failed: ${e.message}',
          code: 'auth_error');
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    await _prefs.clearSession();
  }

  @override
  Future<String> registerUser(RegisterUserInput input) async {
    try {
      // Check if email already exists
      if (await emailExists(input.email)) {
        throw const DataSourceException('Email already exists',
            code: 'email_exists');
      }

      final response = await _client.auth.signUp(
        email: input.email.toLowerCase().trim(),
        password: input.password,
        data: {
          'username': input.username,
          'full_name': input.fullName,
        },
      );

      if (response.user == null) {
        throw const DataSourceException('Registration failed',
            code: 'registration_failed');
      }

      // Update profile with additional data
      await _client.from('profiles').update({
        'username': input.username,
        'full_name': input.fullName,
        'date_of_birth': input.dateOfBirth,
        'gender': input.gender,
        'height': input.height,
        'weight': input.weight,
      }).eq('id', response.user!.id);

      // Seed demo data if requested
      if (input.seedDemoData) {
        await _seedDemoData();
      }

      return response.user!.id;
    } on AuthException catch (e) {
      throw DataSourceException('Registration failed: ${e.message}',
          code: 'auth_error');
    }
  }

  @override
  Future<bool> emailExists(String email) async {
    final result = await _client
        .from('profiles')
        .select('id')
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();
    return result != null;
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  @override
  Future<UserProfile?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final result =
        await _client.from('profiles').select().eq('id', userId).single();

    return _parseUserProfile(result);
  }

  @override
  Future<void> updateUserProfile(UpdateProfileInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const DataSourceException('No user logged in',
          code: 'not_authenticated');
    }

    final data = <String, dynamic>{};
    if (input.fullName != null) data['full_name'] = input.fullName;
    if (input.username != null) data['username'] = input.username;
    if (input.dateOfBirth != null) data['date_of_birth'] = input.dateOfBirth;
    if (input.gender != null) data['gender'] = input.gender;
    if (input.height != null) data['height'] = input.height;
    if (input.weight != null) data['weight'] = input.weight;
    if (input.profileImageUrl != null)
      data['profile_image_url'] = input.profileImageUrl;

    if (data.isNotEmpty) {
      await _client.from('profiles').update(data).eq('id', userId);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
    await logout();
  }

  // ============================================================================
  // DASHBOARD
  // ============================================================================

  @override
  Future<DashboardData> getDashboardData() async {
    if (!isLoggedIn) {
      return DashboardData.empty();
    }

    // Fetch all data in parallel
    final results = await Future.wait([
      getCurrentUser(),
      getLatestGlucoseReading(),
      getHealthCards(),
      getReminders(),
      _getGlucoseChartDataRaw(),
      getDiabeticProfile(),
    ]);

    final profile = results[0] as UserProfile?;
    final latestGlucose = results[1] as GlucoseReading?;
    final healthCards = results[2] as List<HealthCard>;
    final reminders = results[3] as List<Reminder>;
    final chartDataRaw = results[4] as Map<String, dynamic>;
    final diabeticProfile = results[5] as DiabeticProfile?;

    final minGlucose = diabeticProfile?.minGlucose ?? 70;
    final maxGlucose = diabeticProfile?.maxGlucose ?? 180;

    // Find next reminder and count late ones
    final now = DateTime.now();
    int lateCount = 0;
    Reminder? nextReminder;
    Duration? closestDuration;

    for (final reminder in reminders) {
      if (!reminder.isEnabled || reminder.isDone) continue;

      if (reminder.isLate(now)) {
        lateCount++;
      } else {
        final duration = reminder.timeRemaining(now);
        if (duration != null &&
            (closestDuration == null || duration < closestDuration)) {
          closestDuration = duration;
          nextReminder = reminder;
        }
      }
    }

    // Build chart data
    final chartData = BloodSugarChartData(
      title: 'Blood Sugar (mg/dL)',
      beforeMealValues: (chartDataRaw['before_meal'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      afterMealValues: (chartDataRaw['after_meal'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      labels: (chartDataRaw['hours'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );

    // Build glucose status
    final glucoseValue = latestGlucose?.value ?? 0;
    String glucoseStatus;
    if (glucoseValue == 0) {
      glucoseStatus = 'No readings';
    } else if (glucoseValue < minGlucose) {
      glucoseStatus = 'Low - Please eat something';
    } else if (glucoseValue > maxGlucose) {
      glucoseStatus = 'High - Monitor closely';
    } else {
      glucoseStatus = 'You are fine';
    }

    return DashboardData(
      greeting: 'Hi, ${profile?.displayName ?? 'User'}',
      glucose: LatestGlucose(
        value: glucoseValue,
        unit: latestGlucose?.unit ?? 'mg/dL',
        status: glucoseStatus,
        readingType: latestGlucose?.readingType,
      ),
      nextReminder: nextReminder,
      lateRemindersCount: lateCount,
      healthCards: healthCards,
      chartData: chartData,
      minGlucose: minGlucose,
      maxGlucose: maxGlucose,
    );
  }

  // ============================================================================
  // SETTINGS
  // ============================================================================

  @override
  Future<SettingsData> getSettingsData() async {
    final results = await Future.wait([
      getCurrentUser(),
      getDiabeticProfile(),
    ]);

    final profile = results[0] as UserProfile?;
    final diabeticProfile = results[1] as DiabeticProfile?;

    if (profile == null) {
      throw const DataSourceException('User profile not found',
          code: 'profile_not_found');
    }

    return SettingsData(
      profile: profile,
      diabeticProfile: diabeticProfile ?? DiabeticProfile.defaultProfile(),
      preferences: getPreferences(),
    );
  }

  @override
  Future<void> updateSettingsData(SettingsData settings) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const DataSourceException('User not logged in',
          code: 'not_logged_in');
    }

    // Update user profile
    await _client.from('users').update({
      'full_name': settings.profile.fullName,
      'gender': settings.profile.gender,
      'height': settings.profile.height,
      'weight': settings.profile.weight,
      'date_of_birth': settings.profile.dateOfBirth,
    }).eq('id', userId);

    // Update diabetic profile
    await _client.from('diabetic_profiles').upsert({
      'user_id': userId,
      'diabetic_type': settings.diabeticProfile.diabeticType,
      'treatment_type': settings.diabeticProfile.treatmentType,
      'min_glucose': settings.diabeticProfile.minGlucose,
      'max_glucose': settings.diabeticProfile.maxGlucose,
    });
  }

  // ============================================================================
  // DIABETIC PROFILE
  // ============================================================================

  @override
  Future<DiabeticProfile?> getDiabeticProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final result = await _client
        .from('diabetic_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) return null;
    return _parseDiabeticProfile(result);
  }

  @override
  Future<void> updateDiabeticProfile(UpdateDiabeticProfileInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const DataSourceException('No user logged in',
          code: 'not_authenticated');
    }

    final data = <String, dynamic>{};
    if (input.diabeticType != null) data['diabetic_type'] = input.diabeticType;
    if (input.treatmentType != null)
      data['treatment_type'] = input.treatmentType;
    if (input.minGlucose != null) data['min_glucose'] = input.minGlucose;
    if (input.maxGlucose != null) data['max_glucose'] = input.maxGlucose;

    if (data.isNotEmpty) {
      await _client
          .from('diabetic_profiles')
          .update(data)
          .eq('user_id', userId);
    }
  }

  // ============================================================================
  // PREFERENCES
  // ============================================================================

  @override
  AppPreferences getPreferences() {
    return AppPreferences(
      theme: _prefs.getTheme(),
      locale: _prefs.getLocale(),
      units: _prefs.getUnits(),
      notificationsEnabled: _prefs.getNotificationsEnabled(),
      onboardingComplete: _prefs.isOnboardingComplete(),
    );
  }

  @override
  Future<void> setTheme(String theme) async {
    await _prefs.setTheme(theme);
    if (isLoggedIn) {
      await _updateUserPreferences({'theme': theme});
    }
  }

  @override
  Future<void> setLocale(String locale) async {
    await _prefs.setLocale(locale);
    if (isLoggedIn) {
      await _updateUserPreferences({'locale': locale});
    }
  }

  @override
  Future<void> setUnits(String units) async {
    await _prefs.setUnits(units);
    if (isLoggedIn) {
      await _updateUserPreferences({'units': units});
    }
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    if (isLoggedIn) {
      await _updateUserPreferences({'notifications_enabled': enabled});
    }
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setOnboardingComplete(complete);
    if (isLoggedIn) {
      await _updateUserPreferences({'onboarding_complete': complete});
    }
  }

  Future<void> _updateUserPreferences(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId != null) {
      await _client.from('user_preferences').update(data).eq('user_id', userId);
    }
  }

  // ============================================================================
  // GLUCOSE READINGS
  // ============================================================================

  @override
  Future<GlucoseReading> addGlucoseReading(
      CreateGlucoseReadingInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const DataSourceException('No user logged in',
          code: 'not_authenticated');
    }

    final result = await _client
        .from('glucose_readings')
        .insert({
          'user_id': userId,
          'value': input.value,
          'unit': input.unit,
          'reading_type': input.readingType,
          'notes': input.notes,
          'recorded_at':
              (input.recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
        })
        .select()
        .single();

    return _parseGlucoseReading(result);
  }

  @override
  Future<List<GlucoseReading>> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query = _client.from('glucose_readings').select().eq('user_id', userId);

    if (startDate != null) {
      query = query.gte('recorded_at', startDate.toUtc().toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('recorded_at', endDate.toUtc().toIso8601String());
    }

    var orderedQuery = query.order('recorded_at', ascending: false);

    List<Map<String, dynamic>> results;
    if (limit != null) {
      results = await orderedQuery.limit(limit);
    } else {
      results = await orderedQuery;
    }

    return results.map(_parseGlucoseReading).toList();
  }

  @override
  Future<GlucoseReading?> getLatestGlucoseReading() async {
    final readings = await getGlucoseReadings(limit: 1);
    return readings.isEmpty ? null : readings.first;
  }

  @override
  Future<GlucoseChartData> getGlucoseChartData() async {
    final raw = await _getGlucoseChartDataRaw();
    return GlucoseChartData(
      beforeMealValues: (raw['before_meal'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      afterMealValues: (raw['after_meal'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      hours:
          (raw['hours'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      hasData: (raw['before_meal'] as List?)?.isNotEmpty == true ||
          (raw['after_meal'] as List?)?.isNotEmpty == true,
      totalRecords: ((raw['before_meal'] as List?)?.length ?? 0) +
          ((raw['after_meal'] as List?)?.length ?? 0),
    );
  }

  Future<Map<String, dynamic>> _getGlucoseChartDataRaw() async {
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

    final results = await _client
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

    // Generate hour labels
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

      if (beforeMealByHour.containsKey(hour) &&
          beforeMealByHour[hour]!.isNotEmpty) {
        beforeMeal.add(beforeMealByHour[hour]!.reduce((a, b) => a + b) /
            beforeMealByHour[hour]!.length);
      } else if (beforeMeal.isNotEmpty) {
        beforeMeal.add(beforeMeal.last);
      } else {
        beforeMeal.add(0);
      }

      if (afterMealByHour.containsKey(hour) &&
          afterMealByHour[hour]!.isNotEmpty) {
        afterMeal.add(afterMealByHour[hour]!.reduce((a, b) => a + b) /
            afterMealByHour[hour]!.length);
      } else if (afterMeal.isNotEmpty) {
        afterMeal.add(afterMeal.last);
      } else {
        afterMeal.add(0);
      }
    }

    return {
      'before_meal': beforeMeal,
      'after_meal': afterMeal,
      'hours': hourLabels
    };
  }

  // ============================================================================
  // HEALTH CARDS
  // ============================================================================

  @override
  Future<List<HealthCard>> getHealthCards() async {
    final userId = currentUserId;
    if (userId == null) return _getDefaultHealthCards();

    final dateStr = DateTime.now().toIso8601String().split('T')[0];

    final results = await _client
        .from('health_cards')
        .select()
        .eq('user_id', userId)
        .eq('recorded_date', dateStr);

    // Merge with defaults to ensure all card types exist
    final defaults = _getDefaultHealthCards();
    final resultMap = <HealthCardType, HealthCard>{};

    for (final card in defaults) {
      resultMap[card.type] = card;
    }

    for (final row in results) {
      final type = _parseHealthCardType(row['card_type'] as String?);
      if (type != null) {
        resultMap[type] = HealthCard(
          id: row['id']?.toString() ?? '',
          type: type,
          value: (row['value'] as num?)?.toDouble() ?? 0.0,
          unit: row['unit'] as String? ?? type.defaultUnit,
        );
      }
    }

    return resultMap.values.toList();
  }

  @override
  Future<void> updateHealthCard(UpdateHealthCardInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const DataSourceException('No user logged in',
          code: 'not_authenticated');
    }

    final dateStr = DateTime.now().toIso8601String().split('T')[0];

    await _client.from('health_cards').upsert(
      {
        'user_id': userId,
        'card_type': input.cardType,
        'value': input.value,
        'unit': input.unit,
        'recorded_date': dateStr,
      },
      onConflict: 'user_id,card_type,recorded_date',
    );
  }

  List<HealthCard> _getDefaultHealthCards() {
    return HealthCardType.values
        .map((type) => HealthCard(
              id: type.name,
              type: type,
              value: 0.0,
              unit: type.defaultUnit,
            ))
        .toList();
  }

  // ============================================================================
  // REMINDERS
  // ============================================================================

  @override
  Future<List<Reminder>> getReminders() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final results = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('scheduled_time', ascending: true);

    return results.map(_parseReminder).toList();
  }

  @override
  Future<Reminder> addReminder(CreateReminderInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const DataSourceException('No user logged in',
          code: 'not_authenticated');
    }

    final result = await _client
        .from('reminders')
        .insert({
          'user_id': userId,
          'title': input.title,
          'description': input.description,
          'reminder_type': input.reminderType,
          'scheduled_time': input.scheduledTime,
          'is_recurring': input.isRecurring,
          'recurrence_pattern': input.recurrencePattern,
          'status': 'pending',
          'is_enabled': true,
        })
        .select()
        .single();

    return _parseReminder(result);
  }

  @override
  Future<void> updateReminder(
      String reminderId, UpdateReminderInput input) async {
    final data = <String, dynamic>{};
    if (input.title != null) data['title'] = input.title;
    if (input.reminderType != null) data['reminder_type'] = input.reminderType;
    if (input.scheduledTime != null)
      data['scheduled_time'] = input.scheduledTime;
    if (input.description != null) data['description'] = input.description;
    if (input.isEnabled != null) data['is_enabled'] = input.isEnabled;
    if (input.status != null) data['status'] = input.status;

    if (data.isNotEmpty) {
      await _client.from('reminders').update(data).eq('id', reminderId);
    }
  }

  @override
  Future<void> updateReminderStatus(String reminderId, String status) async {
    await _client.from('reminders').update({
      'status': status,
      'completed_at': (status == 'completed' || status == 'done')
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    }).eq('id', reminderId);
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }

  // ============================================================================
  // CHARTS
  // ============================================================================

  @override
  Future<CarbsChartData> getCarbsChartData() async {
    final userId = currentUserId;
    if (userId == null) {
      return const CarbsChartData(
          values: [], days: [], hasData: false, totalRecords: 0);
    }

    final now = DateTime.now();
    List<double> values = [];
    List<String> days = [];
    int recordCount = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dayName = _getDayName(date.weekday);

      final result = await _client
          .from('health_cards')
          .select('value')
          .eq('user_id', userId)
          .eq('card_type', 'carbs')
          .eq('recorded_date', dateStr)
          .maybeSingle();

      days.add(dayName);
      if (result != null) {
        values.add((result['value'] as num).toDouble());
        recordCount++;
      } else {
        values.add(0.0);
      }
    }

    return CarbsChartData(
      values: values,
      days: days,
      hasData: recordCount > 0,
      totalRecords: recordCount,
    );
  }

  @override
  Future<ActivityChartData> getActivityChartData() async {
    final userId = currentUserId;
    if (userId == null) {
      return const ActivityChartData(
          values: [], hours: [], hasData: false, totalRecords: 0);
    }

    final now = DateTime.now();
    List<double> values = [];
    List<String> days = [];
    int recordCount = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dayName = _getDayName(date.weekday);

      final result = await _client
          .from('health_cards')
          .select('value')
          .eq('user_id', userId)
          .eq('card_type', 'activity')
          .eq('recorded_date', dateStr)
          .maybeSingle();

      days.add(dayName);
      if (result != null) {
        final steps = (result['value'] as num).toDouble();
        values.add(steps / 1312.0); // Convert steps to km
        recordCount++;
      } else {
        values.add(0.0);
      }
    }

    return ActivityChartData(
      values: values,
      hours: days, // Using days as labels for weekly view
      hasData: recordCount > 0,
      totalRecords: recordCount,
    );
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  @override
  Future<void> clearAllData() async {
    await _prefs.clearAll();
  }

  @override
  Future<Map<String, dynamic>> getAppStrings() async {
    // Load app strings from Supabase or assets
    // For now, return from the app_data table
    try {
      final result = await _client
          .from('app_data')
          .select()
          .eq('key', 'strings')
          .maybeSingle();

      if (result != null && result['value'] != null) {
        return result['value'] as Map<String, dynamic>;
      }
    } catch (e) {
      // Fallback to default strings if database not available
    }

    return {
      'app_name': 'DiaCare',
      'welcome': 'Welcome!',
    };
  }

  // ============================================================================
  // PRIVATE PARSING METHODS - All JSON/Map parsing is encapsulated here
  // ============================================================================

  UserProfile _parseUserProfile(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  DiabeticProfile _parseDiabeticProfile(Map<String, dynamic> json) {
    return DiabeticProfile(
      diabeticType: json['diabetic_type'] as String? ?? 'Type 2',
      treatmentType: json['treatment_type'] as String? ?? 'Diet',
      minGlucose: json['min_glucose'] as int? ?? 70,
      maxGlucose: json['max_glucose'] as int? ?? 180,
    );
  }

  GlucoseReading _parseGlucoseReading(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'mg/dL',
      readingType: _parseGlucoseReadingType(json['reading_type'] as String?),
      notes: json['notes'] as String?,
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : DateTime.now(),
    );
  }

  GlucoseReadingType _parseGlucoseReadingType(String? type) {
    switch (type) {
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

  Reminder _parseReminder(Map<String, dynamic> json) {
    return Reminder(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      reminderType: json['reminder_type'] as String? ?? '',
      scheduledTime: json['scheduled_time'] as String? ?? '',
      description: json['description'] as String?,
      isEnabled: json['is_enabled'] == true ||
          json['is_enabled'] == 1 ||
          json['is_enabled'] == null,
      isRecurring: json['is_recurring'] == true || json['is_recurring'] == 1,
      recurrencePattern: json['recurrence_pattern'] as String?,
      status: _parseReminderStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  ReminderStatus _parseReminderStatus(String? status) {
    switch (status) {
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

  HealthCardType? _parseHealthCardType(String? type) {
    switch (type?.toLowerCase()) {
      case 'water':
        return HealthCardType.water;
      case 'pills':
        return HealthCardType.pills;
      case 'activity':
        return HealthCardType.activity;
      case 'carbs':
        return HealthCardType.carbs;
      case 'insulin':
        return HealthCardType.insulin;
      default:
        return null;
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  // ============================================================================
  // DEMO DATA SEEDING
  // ============================================================================

  Future<void> _seedDemoData() async {
    final now = DateTime.now();

    // Add sample glucose readings
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
      await addGlucoseReading(CreateGlucoseReadingInput(
        value: glucoseValues[6 - i],
        unit: 'mg/dL',
        readingType: readingTypes[6 - i],
        recordedAt: now.subtract(Duration(hours: i)),
      ));
    }

    // Add health cards
    await updateHealthCard(
        const UpdateHealthCardInput(cardType: 'water', value: 1.2, unit: 'L'));
    await updateHealthCard(const UpdateHealthCardInput(
        cardType: 'pills', value: 2, unit: 'taken'));
    await updateHealthCard(const UpdateHealthCardInput(
        cardType: 'activity', value: 3250, unit: 'steps'));
    await updateHealthCard(const UpdateHealthCardInput(
        cardType: 'carbs', value: 190, unit: 'cal'));
    await updateHealthCard(const UpdateHealthCardInput(
        cardType: 'insulin', value: 5, unit: 'units'));

    // Add reminders
    await addReminder(CreateReminderInput(
      title: 'Drink Water',
      reminderType: 'water',
      scheduledTime: '${(now.hour + 1).toString().padLeft(2, '0')}:00',
      isRecurring: true,
      recurrencePattern: 'hourly',
    ));

    await addReminder(const CreateReminderInput(
      title: 'Take Medication',
      reminderType: 'medication',
      scheduledTime: '08:00',
      isRecurring: true,
      recurrencePattern: 'daily',
    ));
  }
}
