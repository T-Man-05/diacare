/// Domain model for reminders
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts
class Reminder {
  final String id;
  final String title;
  final String reminderType;
  final String scheduledTime;
  final String? description;
  final bool isEnabled;
  final bool isRecurring;
  final String? recurrencePattern;
  final ReminderStatus status;
  final DateTime? createdAt;

  const Reminder({
    required this.id,
    required this.title,
    required this.reminderType,
    required this.scheduledTime,
    this.description,
    this.isEnabled = true,
    this.isRecurring = false,
    this.recurrencePattern,
    this.status = ReminderStatus.pending,
    this.createdAt,
  });

  /// Check if reminder is completed
  bool get isDone =>
      status == ReminderStatus.done || status == ReminderStatus.completed;

  /// Check if reminder is late (past scheduled time and not done)
  bool isLate(DateTime now) {
    if (isDone || !isEnabled) return false;
    final time = _parseTime();
    if (time == null) return false;

    final scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return now.isAfter(scheduled);
  }

  /// Get time remaining until reminder
  Duration? timeRemaining(DateTime now) {
    if (isDone || !isEnabled) return null;
    final time = _parseTime();
    if (time == null) return null;

    final scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (now.isAfter(scheduled)) return null;
    return scheduled.difference(now);
  }

  /// Format scheduled time for display (e.g., "08:30 AM")
  String get formattedTime {
    final time = _parseTime();
    if (time == null) return scheduledTime;

    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  _TimeOfDay? _parseTime() {
    if (scheduledTime.isEmpty) return null;
    final parts = scheduledTime.split(':');
    if (parts.length < 2) return null;
    try {
      return _TimeOfDay(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? reminderType,
    String? scheduledTime,
    String? description,
    bool? isEnabled,
    bool? isRecurring,
    String? recurrencePattern,
    ReminderStatus? status,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      reminderType: reminderType ?? this.reminderType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Reminder status enumeration
enum ReminderStatus {
  pending,
  done,
  completed,
  skipped,
  snoozed,
}

/// Helper class for time parsing
class _TimeOfDay {
  final int hour;
  final int minute;
  const _TimeOfDay(this.hour, this.minute);
}
