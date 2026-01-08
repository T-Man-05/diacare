/// Domain model for diabetic profile configuration
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts
class DiabeticProfile {
  final String diabeticType;
  final String treatmentType;
  final int minGlucose;
  final int maxGlucose;

  const DiabeticProfile({
    required this.diabeticType,
    required this.treatmentType,
    required this.minGlucose,
    required this.maxGlucose,
  });

  /// Default profile for new users
  factory DiabeticProfile.defaultProfile() {
    return const DiabeticProfile(
      diabeticType: 'Type 2',
      treatmentType: 'Diet',
      minGlucose: 70,
      maxGlucose: 180,
    );
  }

  /// Check if using insulin treatment
  bool get isInsulinDependent => treatmentType == 'Insulin';

  /// Check if Type 1 diabetic
  bool get isType1 => diabeticType == 'Type 1';

  /// Check if Type 2 diabetic
  bool get isType2 => diabeticType == 'Type 2';

  /// Check if gestational diabetic
  bool get isGestational => diabeticType == 'Gestational';

  /// Glucose range width
  int get rangeWidth => maxGlucose - minGlucose;

  /// Formatted glucose range string
  String glucoseRangeFormatted(String unit) =>
      '$minGlucose - $maxGlucose $unit';

  DiabeticProfile copyWith({
    String? diabeticType,
    String? treatmentType,
    int? minGlucose,
    int? maxGlucose,
  }) {
    return DiabeticProfile(
      diabeticType: diabeticType ?? this.diabeticType,
      treatmentType: treatmentType ?? this.treatmentType,
      minGlucose: minGlucose ?? this.minGlucose,
      maxGlucose: maxGlucose ?? this.maxGlucose,
    );
  }
}
