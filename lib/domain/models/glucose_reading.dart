/// Domain model for glucose readings
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts
class GlucoseReading {
  final String id;
  final double value;
  final String unit;
  final GlucoseReadingType readingType;
  final String? notes;
  final DateTime recordedAt;

  const GlucoseReading({
    required this.id,
    required this.value,
    required this.unit,
    required this.readingType,
    this.notes,
    required this.recordedAt,
  });

  /// Check if reading is in normal range
  bool isInRange(int minGlucose, int maxGlucose) {
    return value >= minGlucose && value <= maxGlucose;
  }

  /// Get status based on glucose range
  GlucoseStatus getStatus(int minGlucose, int maxGlucose) {
    if (value < minGlucose) return GlucoseStatus.low;
    if (value > maxGlucose) return GlucoseStatus.high;
    return GlucoseStatus.normal;
  }

  GlucoseReading copyWith({
    String? id,
    double? value,
    String? unit,
    GlucoseReadingType? readingType,
    String? notes,
    DateTime? recordedAt,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      readingType: readingType ?? this.readingType,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

/// Latest glucose reading with status for dashboard display
class LatestGlucose {
  final double value;
  final String unit;
  final String status;
  final GlucoseReadingType? readingType;

  const LatestGlucose({
    required this.value,
    required this.unit,
    required this.status,
    this.readingType,
  });

  /// Value as integer for display
  int get displayValue => value.round();
}

/// Glucose reading type enumeration
enum GlucoseReadingType {
  beforeMeal,
  afterMeal,
  fasting,
  bedtime,
  random,
}

/// Glucose status enumeration
enum GlucoseStatus {
  low,
  normal,
  high,
}
