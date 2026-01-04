/// ============================================================================
/// ALARM NOTIFICATION SERVICE - Background Alarm & Notifications for DiaCare
/// ============================================================================
///
/// This service manages alarm scheduling and local notifications that work
/// even when the app is closed or in the background.
///
/// Features:
/// - Schedule alarms for specific times
/// - Show full-screen alarm notifications
/// - Handle notification taps to open alarm screen
/// - Cancel/update scheduled alarms
/// - Works in background and when app is closed
///
/// Usage:
///   await AlarmNotificationService.initialize();
///   await AlarmNotificationService.scheduleAlarm(
///     id: 1,
///     title: 'Wake up',
///     scheduledTime: TimeOfDay(hour: 7, minute: 0),
///   );
/// ============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

/// ============================================================================
/// GLOBAL NOTIFICATION INSTANCE
/// ============================================================================
/// This must be a top-level variable for background notification handling
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Callback for handling notification taps (must be top-level function)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification tap
  debugPrint(
      'Notification tapped in background: ${notificationResponse.payload}');
}

/// ============================================================================
/// ALARM NOTIFICATION SERVICE CLASS
/// ============================================================================
class AlarmNotificationService {
  // ---------------------------------------------------------------------------
  // SINGLETON PATTERN
  // ---------------------------------------------------------------------------
  static final AlarmNotificationService _instance =
      AlarmNotificationService._internal();
  factory AlarmNotificationService() => _instance;
  AlarmNotificationService._internal();

  // ---------------------------------------------------------------------------
  // STATE VARIABLES
  // ---------------------------------------------------------------------------

  /// Flag to track initialization status
  static bool _isInitialized = false;

  /// Callback for when notification is tapped
  static Function(String? payload)? onNotificationTap;

  // ---------------------------------------------------------------------------
  // NOTIFICATION CHANNEL CONFIGURATION
  // ---------------------------------------------------------------------------

  /// Android notification channel for alarms (high priority)
  static const AndroidNotificationChannel _alarmChannel =
      AndroidNotificationChannel(
    'diacare_alarms', // Channel ID
    'DiaCare Alarms', // Channel name
    description: 'Alarm notifications for reminders',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFF4CAF50),
  );

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  /// Initialize the notification service
  /// Must be called before using any other methods (typically in main.dart)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create the notification channel on Android
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_alarmChannel);
    }

    _isInitialized = true;
    debugPrint('AlarmNotificationService initialized');
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    onNotificationTap?.call(response.payload);
  }

  // ---------------------------------------------------------------------------
  // PERMISSIONS
  // ---------------------------------------------------------------------------

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Request notification permission for Android 13+
      final notificationStatus = await Permission.notification.request();

      // Request exact alarm permission for Android 12+
      final alarmStatus = await Permission.scheduleExactAlarm.request();

      return notificationStatus.isGranted &&
          (alarmStatus.isGranted || alarmStatus.isLimited);
    } else if (Platform.isIOS) {
      final result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }

  /// Check if permissions are granted
  static Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // ALARM SCHEDULING
  // ---------------------------------------------------------------------------

  /// Schedule an alarm notification
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this alarm (use reminder ID)
  /// - [title]: Alarm title (e.g., "Take medication")
  /// - [body]: Optional body text
  /// - [scheduledTime]: Time of day for the alarm
  /// - [payload]: Optional data to pass when notification is tapped
  static Future<void> scheduleAlarm({
    required int id,
    required String title,
    String? body,
    required TimeOfDay scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    // Calculate the next occurrence of this time
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert to timezone-aware datetime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Android notification details with full-screen intent for alarm
    final androidDetails = AndroidNotificationDetails(
      _alarmChannel.id,
      _alarmChannel.name,
      channelDescription: _alarmChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      ticker: title,
      // Full-screen intent to show alarm screen
      fullScreenIntent: true,
      // Category for alarm
      category: AndroidNotificationCategory.alarm,
      // Visibility on lock screen
      visibility: NotificationVisibility.public,
      // Auto-cancel when tapped
      autoCancel: false,
      // Ongoing notification (can't be swiped away)
      ongoing: true,
      // Sound
      playSound: true,
      // Vibration pattern
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      // LED light
      enableLights: true,
      ledColor: const Color(0xFF4CAF50),
      ledOnMs: 1000,
      ledOffMs: 500,
      // Style
      styleInformation: BigTextStyleInformation(
        body ?? 'Tap to view alarm',
        contentTitle: title,
        summaryText: 'DiaCare Reminder',
      ),
      // Actions
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'stop',
          'Stop',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          'Snooze',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    // Combined notification details
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body ?? 'Tap to view alarm',
      tzScheduledDate,
      notificationDetails,
      payload:
          payload ?? '$id|$title|${scheduledTime.hour}:${scheduledTime.minute}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
        'Alarm scheduled: $title at ${scheduledTime.hour}:${scheduledTime.minute}');
  }

  /// Schedule a daily repeating alarm
  static Future<void> scheduleDailyAlarm({
    required int id,
    required String title,
    String? body,
    required TimeOfDay scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    // Calculate the next occurrence of this time
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _alarmChannel.id,
      _alarmChannel.name,
      channelDescription: _alarmChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily repeating notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body ?? 'Tap to view alarm',
      tzScheduledDate,
      notificationDetails,
      payload:
          payload ?? '$id|$title|${scheduledTime.hour}:${scheduledTime.minute}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at same time
    );

    debugPrint(
        'Daily alarm scheduled: $title at ${scheduledTime.hour}:${scheduledTime.minute}');
  }

  // ---------------------------------------------------------------------------
  // ALARM MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Cancel a scheduled alarm
  static Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Alarm cancelled: $id');
  }

  /// Cancel all scheduled alarms
  static Future<void> cancelAllAlarms() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All alarms cancelled');
  }

  /// Show an immediate alarm notification (for testing)
  static Future<void> showImmediateAlarm({
    required int id,
    required String title,
    String? body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      _alarmChannel.id,
      _alarmChannel.name,
      channelDescription: _alarmChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'stop',
          'Stop',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          'Snooze',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body ?? 'Tap to view alarm',
      notificationDetails,
      payload: payload,
    );

    debugPrint('Immediate alarm shown: $title');
  }

  /// Get list of pending notifications
  static Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // ---------------------------------------------------------------------------
  // HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Parse a time string (HH:MM) to TimeOfDay
  static TimeOfDay? parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  /// Generate a unique ID from reminder ID string
  static int generateAlarmId(String reminderId) {
    return reminderId.hashCode.abs() % 2147483647; // Keep within int32 range
  }
}
