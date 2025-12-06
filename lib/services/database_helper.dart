/// ============================================================================
/// DATABASE HELPER - SQLite Database Management
/// ============================================================================
///
/// This class manages all SQLite database operations for DiaCare.
/// It handles:
/// - Database initialization and migrations
/// - Table creation for all entities
/// - CRUD operations for all tables
/// - User authentication and session management
///
/// Tables:
/// - users: User accounts with authentication
/// - glucose_readings: Blood glucose measurements
/// - health_cards: Daily health metrics (water, pills, activity, etc.)
/// - reminders: Medication and activity reminders
/// - diabetic_profiles: User diabetes configuration
/// ============================================================================

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Database version for migrations
  static const int _databaseVersion = 1;
  static const String _databaseName = 'diacare.db';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance (creates if not exists)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        username TEXT NOT NULL,
        full_name TEXT DEFAULT '',
        profile_image_url TEXT,
        date_of_birth TEXT,
        gender TEXT,
        height REAL,
        weight REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Diabetic profiles table
    await db.execute('''
      CREATE TABLE diabetic_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        diabetic_type TEXT DEFAULT 'Type 1',
        treatment_type TEXT DEFAULT 'Insulin',
        min_glucose INTEGER DEFAULT 70,
        max_glucose INTEGER DEFAULT 180,
        diagnosis_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Glucose readings table
    await db.execute('''
      CREATE TABLE glucose_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        value REAL NOT NULL,
        unit TEXT DEFAULT 'mg/dL',
        reading_type TEXT DEFAULT 'before_meal',
        notes TEXT,
        recorded_at TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Health cards table (daily metrics)
    await db.execute('''
      CREATE TABLE health_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        card_type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        recorded_date TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        reminder_type TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        is_recurring INTEGER DEFAULT 0,
        recurrence_pattern TEXT,
        status TEXT DEFAULT 'pending',
        completed_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Chart data table (for storing historical chart data)
    await db.execute('''
      CREATE TABLE chart_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        chart_type TEXT NOT NULL,
        data_json TEXT NOT NULL,
        recorded_date TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_glucose_user_date ON glucose_readings(user_id, recorded_at)');
    await db.execute(
        'CREATE INDEX idx_health_user_date ON health_cards(user_id, recorded_date)');
    await db.execute(
        'CREATE INDEX idx_reminders_user ON reminders(user_id, scheduled_time)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here for future versions
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE users ADD COLUMN new_field TEXT');
    // }
  }

  // ============================================================================
  // PASSWORD HASHING
  // ============================================================================

  /// Hash password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against hash
  bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  // ============================================================================
  // USER OPERATIONS
  // ============================================================================

  /// Create a new user account
  Future<int> createUser({
    required String email,
    required String password,
    required String username,
    String fullName = '',
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
  }) async {
    final db = await database;
    final passwordHash = hashPassword(password);

    final userId = await db.insert('users', {
      'email': email.toLowerCase().trim(),
      'password_hash': passwordHash,
      'username': username,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'height': height,
      'weight': weight,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Create default diabetic profile for the user
    await db.insert('diabetic_profiles', {
      'user_id': userId,
      'diabetic_type': 'Type 1',
      'treatment_type': 'Insulin',
      'min_glucose': 70,
      'max_glucose': 180,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return userId;
  }

  /// Authenticate user with email and password
  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    final db = await database;
    final passwordHash = hashPassword(password);

    final results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase().trim(), passwordHash],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    return results.isNotEmpty;
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Update user profile
  Future<int> updateUser(int userId, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Update user password
  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'password_hash': hashPassword(newPassword),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete user account and all related data
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================================
  // DIABETIC PROFILE OPERATIONS
  // ============================================================================

  /// Get diabetic profile for user
  Future<Map<String, dynamic>?> getDiabeticProfile(int userId) async {
    final db = await database;
    final results = await db.query(
      'diabetic_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Update diabetic profile
  Future<int> updateDiabeticProfile(
      int userId, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'diabetic_profiles',
      data,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================================
  // GLUCOSE READINGS OPERATIONS
  // ============================================================================

  /// Add a glucose reading
  Future<int> addGlucoseReading({
    required int userId,
    required double value,
    String unit = 'mg/dL',
    String readingType = 'before_meal',
    String? notes,
    DateTime? recordedAt,
  }) async {
    final db = await database;
    return await db.insert('glucose_readings', {
      'user_id': userId,
      'value': value,
      'unit': unit,
      'reading_type': readingType,
      'notes': notes,
      'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get glucose readings for user
  Future<List<Map<String, dynamic>>> getGlucoseReadings(
    int userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      whereClause += ' AND recorded_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND recorded_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'glucose_readings',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
  }

  /// Get latest glucose reading
  Future<Map<String, dynamic>?> getLatestGlucoseReading(int userId) async {
    final readings = await getGlucoseReadings(userId, limit: 1);
    if (readings.isEmpty) return null;
    return readings.first;
  }

  /// Get glucose readings for chart (last 7 hours)
  /// Returns data with hour labels for X-axis
  Future<Map<String, dynamic>> getGlucoseChartData(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final sevenHoursAgo = now.subtract(const Duration(hours: 7));

    final results = await db.query(
      'glucose_readings',
      where: 'user_id = ? AND recorded_at >= ?',
      whereArgs: [userId, sevenHoursAgo.toIso8601String()],
      orderBy: 'recorded_at ASC',
    );

    // Group readings by hour
    Map<int, List<double>> beforeMealByHour = {};
    Map<int, List<double>> afterMealByHour = {};

    for (final reading in results) {
      final value = (reading['value'] as num).toDouble();
      final recordedAt = DateTime.parse(reading['recorded_at'] as String);
      final hour = recordedAt.hour;

      if (reading['reading_type'] == 'before_meal') {
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
      // Format hour as 12-hour with AM/PM
      final hourStr = hour == 0
          ? '12AM'
          : hour < 12
              ? '${hour}AM'
              : hour == 12
                  ? '12PM'
                  : '${hour - 12}PM';
      hourLabels.add(hourStr);

      // Average readings for this hour if multiple exist
      if (beforeMealByHour.containsKey(hour) &&
          beforeMealByHour[hour]!.isNotEmpty) {
        final avg = beforeMealByHour[hour]!.reduce((a, b) => a + b) /
            beforeMealByHour[hour]!.length;
        beforeMeal.add(avg);
      } else if (beforeMeal.isNotEmpty) {
        // Use previous value for continuity
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
        // Use previous value for continuity
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

  /// Get weekly carbs chart data
  /// Returns a map with day names as keys and carb values
  Future<Map<String, dynamic>> getCarbsChartData(int userId) async {
    final db = await database;
    final now = DateTime.now();

    // Get data for the last 7 days
    List<double> values = [];
    List<String> days = [];
    List<bool> hasData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dayName = _getDayName(date.weekday);

      final results = await db.query(
        'health_cards',
        where: 'user_id = ? AND card_type = ? AND recorded_date = ?',
        whereArgs: [userId, 'carbs', dateStr],
      );

      days.add(dayName);
      if (results.isNotEmpty) {
        values.add((results.first['value'] as num).toDouble());
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
  /// Returns activity data in km (converted from steps: 1 km ≈ 1312 steps)
  Future<Map<String, dynamic>> getActivityChartData(int userId) async {
    final db = await database;
    final now = DateTime.now();

    List<double> values = [];
    List<String> days = [];
    List<bool> hasData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final dayName = _getDayName(date.weekday);

      final results = await db.query(
        'health_cards',
        where: 'user_id = ? AND card_type = ? AND recorded_date = ?',
        whereArgs: [userId, 'activity', dateStr],
      );

      days.add(dayName);
      if (results.isNotEmpty) {
        // Convert steps to km (1 km ≈ 1312 steps)
        final steps = (results.first['value'] as num).toDouble();
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

  /// Get day name from weekday number
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
  // HEALTH CARDS OPERATIONS
  // ============================================================================

  /// Add or update health card for today
  Future<int> upsertHealthCard({
    required int userId,
    required String cardType,
    required double value,
    required String unit,
    DateTime? recordedDate,
  }) async {
    final db = await database;
    final date = recordedDate ?? DateTime.now();
    final dateStr = date.toIso8601String().split('T')[0];

    // Check if entry exists for today
    final existing = await db.query(
      'health_cards',
      where: 'user_id = ? AND card_type = ? AND recorded_date = ?',
      whereArgs: [userId, cardType, dateStr],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'health_cards',
        {'value': value, 'unit': unit},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('health_cards', {
        'user_id': userId,
        'card_type': cardType,
        'value': value,
        'unit': unit,
        'recorded_date': dateStr,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get health cards for a specific date
  Future<List<Map<String, dynamic>>> getHealthCards(
    int userId, {
    DateTime? date,
  }) async {
    final db = await database;
    final dateStr = (date ?? DateTime.now()).toIso8601String().split('T')[0];

    return await db.query(
      'health_cards',
      where: 'user_id = ? AND recorded_date = ?',
      whereArgs: [userId, dateStr],
    );
  }

  /// Get default health cards (for new users or days without data)
  List<Map<String, dynamic>> getDefaultHealthCards() {
    return [
      {'card_type': 'water', 'value': 0.0, 'unit': 'L', 'title': 'Water'},
      {'card_type': 'pills', 'value': 0.0, 'unit': 'taken', 'title': 'Pills'},
      {
        'card_type': 'activity',
        'value': 0.0,
        'unit': 'steps',
        'title': 'Activity'
      },
      {'card_type': 'carbs', 'value': 0.0, 'unit': 'cal', 'title': 'Carbs'},
      {
        'card_type': 'insulin',
        'value': 0.0,
        'unit': 'units',
        'title': 'Insulin'
      },
    ];
  }

  // ============================================================================
  // REMINDERS OPERATIONS
  // ============================================================================

  /// Add a reminder
  Future<int> addReminder({
    required int userId,
    required String title,
    required String reminderType,
    required String scheduledTime,
    String? description,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    final db = await database;
    return await db.insert('reminders', {
      'user_id': userId,
      'title': title,
      'description': description,
      'reminder_type': reminderType,
      'scheduled_time': scheduledTime,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_pattern': recurrencePattern,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get reminders for user
  Future<List<Map<String, dynamic>>> getReminders(int userId,
      {bool? isEnabled}) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (isEnabled != null) {
      whereClause += ' AND is_enabled = ?';
      whereArgs.add(isEnabled ? 1 : 0);
    }

    return await db.query(
      'reminders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'scheduled_time ASC',
    );
  }

  /// Update reminder
  Future<int> updateReminder(int reminderId, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'reminders',
      data,
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  /// Update reminder status
  Future<int> updateReminderStatus(int reminderId, String status) async {
    final db = await database;
    return await db.update(
      'reminders',
      {
        'status': status,
        'completed_at':
            status == 'completed' ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  /// Delete reminder
  Future<int> deleteReminder(int reminderId) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  // ============================================================================
  // DASHBOARD DATA
  // ============================================================================

  /// Get complete dashboard data for user
  Future<Map<String, dynamic>> getDashboardData(int userId) async {
    final user = await getUserById(userId);
    final latestGlucose = await getLatestGlucoseReading(userId);
    final healthCards = await getHealthCards(userId);
    final reminders = await getReminders(userId, isEnabled: true);
    final chartData = await getGlucoseChartData(userId);

    // Fill in default health cards if missing
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
      'greeting': 'Hi, ${user?['full_name'] ?? user?['username'] ?? 'User'}',
      'glucose': {
        'value': latestGlucose?['value']?.toInt() ?? 0,
        'unit': latestGlucose?['unit'] ?? 'mg/dL',
        'status': _getGlucoseStatus(latestGlucose?['value']?.toDouble() ?? 0),
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

  /// Get glucose status message
  String _getGlucoseStatus(double value) {
    if (value == 0) return 'No readings';
    if (value < 70) return 'Low - Please eat something';
    if (value > 180) return 'High - Monitor closely';
    return 'You are fine';
  }

  // ============================================================================
  // SETTINGS DATA
  // ============================================================================

  /// Get complete settings data for user
  Future<Map<String, dynamic>> getSettingsData(int userId) async {
    final user = await getUserById(userId);
    final profile = await getDiabeticProfile(userId);

    if (user == null) {
      throw Exception('User not found');
    }

    return {
      'email': user['email'],
      'password': '••••••••',
      'full_name': user['full_name'] ?? '',
      'username': user['username'] ?? '',
      'profile_image_url': user['profile_image_url'],
      'diabetic_profile': {
        'diabetic_type': profile?['diabetic_type'] ?? 'Type 1',
        'treatment_type': profile?['treatment_type'] ?? 'Insulin',
        'min_glucose': profile?['min_glucose'] ?? 70,
        'max_glucose': profile?['max_glucose'] ?? 180,
      },
      'preferences': {
        'theme': 'light', // Will be overridden by SharedPreferences
        'notifications_enabled': true,
        'units': 'mg/dL',
      },
    };
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing/logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('chart_data');
    await db.delete('reminders');
    await db.delete('health_cards');
    await db.delete('glucose_readings');
    await db.delete('diabetic_profiles');
    await db.delete('users');
  }

  /// Seed demo data for a user
  Future<void> seedDemoData(int userId) async {
    final now = DateTime.now();

    // Add sample glucose readings for the past 7 hours (one per hour)
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
        userId: userId,
        value: glucoseValues[6 - i],
        unit: 'mg/dL',
        readingType: readingTypes[6 - i],
        recordedAt: readingTime,
      );
    }

    // Add today's health cards
    await upsertHealthCard(
        userId: userId, cardType: 'water', value: 1.2, unit: 'L');
    await upsertHealthCard(
        userId: userId, cardType: 'pills', value: 2, unit: 'taken');
    await upsertHealthCard(
        userId: userId, cardType: 'activity', value: 3250, unit: 'steps');
    await upsertHealthCard(
        userId: userId, cardType: 'carbs', value: 190, unit: 'g');
    await upsertHealthCard(
        userId: userId, cardType: 'insulin', value: 5, unit: 'units');

    // Add daily activity and carbs data for the past 7 days (for charts)
    final activityValues = [4500, 3200, 5800, 2900, 6100, 4000, 3250]; // steps
    final carbsValues = [180, 220, 150, 280, 200, 250, 190]; // grams (max 500g)

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Insert activity for each day
      await upsertHealthCard(
        userId: userId,
        cardType: 'activity',
        value: activityValues[6 - i].toDouble(),
        unit: 'steps',
        recordedDate: date,
      );

      // Insert carbs for each day
      await upsertHealthCard(
        userId: userId,
        cardType: 'carbs',
        value: carbsValues[6 - i].toDouble(),
        unit: 'cal',
        recordedDate: date,
      );
    }

    // Add sample reminders
    await addReminder(
      userId: userId,
      title: 'Drink Water',
      reminderType: 'water',
      scheduledTime: '${now.hour + 1}:00',
      isRecurring: true,
      recurrencePattern: 'hourly',
    );

    await addReminder(
      userId: userId,
      title: 'Take Medication',
      reminderType: 'medication',
      scheduledTime: '08:00',
      isRecurring: true,
      recurrencePattern: 'daily',
    );

    await addReminder(
      userId: userId,
      title: 'Check Blood Sugar',
      reminderType: 'glucose',
      scheduledTime: '12:00',
      isRecurring: true,
      recurrencePattern: 'daily',
    );
  }

  /// Seed default user: Islam Benali
  /// Email: nonodzmakafi@gmail.com, Password: 12345678
  Future<int?> seedDefaultUser() async {
    final db = await database;

    // Check if user already exists
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['helloworld@gmail.com'],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    // Create the user
    final userId = await createUser(
      email: 'helloworld@gmail.com',
      password: '12345678',
      username: 'islambenali',
      fullName: 'Islam Benali',
      dateOfBirth: '1995-06-15',
      gender: 'Male',
      height: 175.0,
      weight: 70.0,
    );

    // Update diabetic profile with more realistic data
    await db.update(
      'diabetic_profiles',
      {
        'diabetic_type': 'Type 2',
        'treatment_type': 'Medication',
        'min_glucose': 80,
        'max_glucose': 140,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Seed demo data for this user
    await seedDemoData(userId);

    return userId;
  }
}
