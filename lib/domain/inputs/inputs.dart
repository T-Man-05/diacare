/// Input DTOs for write operations
/// These are used to pass data TO the data layer for creation/update operations
/// They are backend-agnostic - the data layer converts them to backend format

/// Input for creating a new reminder
class CreateReminderInput {
  final String title;
  final String reminderType;
  final String scheduledTime;
  final String? description;
  final bool isRecurring;
  final String? recurrencePattern;

  const CreateReminderInput({
    required this.title,
    required this.reminderType,
    required this.scheduledTime,
    this.description,
    this.isRecurring = false,
    this.recurrencePattern,
  });
}

/// Input for updating a reminder
class UpdateReminderInput {
  final String? title;
  final String? reminderType;
  final String? scheduledTime;
  final String? description;
  final bool? isEnabled;
  final String? status;

  const UpdateReminderInput({
    this.title,
    this.reminderType,
    this.scheduledTime,
    this.description,
    this.isEnabled,
    this.status,
  });
}

/// Input for creating a glucose reading
class CreateGlucoseReadingInput {
  final double value;
  final String unit;
  final String readingType;
  final String? notes;
  final DateTime? recordedAt;

  const CreateGlucoseReadingInput({
    required this.value,
    this.unit = 'mg/dL',
    this.readingType = 'before_meal',
    this.notes,
    this.recordedAt,
  });
}

/// Input for updating health card
class UpdateHealthCardInput {
  final String cardType;
  final double value;
  final String unit;

  const UpdateHealthCardInput({
    required this.cardType,
    required this.value,
    required this.unit,
  });
}

/// Input for updating user profile
class UpdateProfileInput {
  final String? fullName;
  final String? username;
  final String? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final String? profileImageUrl;

  const UpdateProfileInput({
    this.fullName,
    this.username,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.profileImageUrl,
  });
}

/// Input for updating diabetic profile
class UpdateDiabeticProfileInput {
  final String? diabeticType;
  final String? treatmentType;
  final int? minGlucose;
  final int? maxGlucose;

  const UpdateDiabeticProfileInput({
    this.diabeticType,
    this.treatmentType,
    this.minGlucose,
    this.maxGlucose,
  });
}

/// Input for user registration
class RegisterUserInput {
  final String email;
  final String password;
  final String username;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final bool seedDemoData;

  const RegisterUserInput({
    required this.email,
    required this.password,
    required this.username,
    this.fullName = '',
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.seedDemoData = false,
  });
}

/// Input for user login
class LoginInput {
  final String email;
  final String password;

  const LoginInput({
    required this.email,
    required this.password,
  });
}
