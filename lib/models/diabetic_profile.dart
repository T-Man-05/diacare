/// Model for diabetic profile settings
class DiabeticProfile {
  String diabeticType;
  String treatmentType;
  int minGlucose;
  int maxGlucose;

  DiabeticProfile({
    this.diabeticType = 'Type 1',
    this.treatmentType = 'Insulin',
    this.minGlucose = 70,
    this.maxGlucose = 180,
  });

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Returns true if using insulin treatment
  bool get isInsulinDependent => treatmentType == 'Insulin';

  /// Returns true if Type 1 diabetic
  bool get isType1 => diabeticType == 'Type 1';

  /// Returns true if Type 2 diabetic
  bool get isType2 => diabeticType == 'Type 2';

  /// Returns true if gestational diabetic
  bool get isGestational => diabeticType == 'Gestational';

  /// Returns the glucose range width
  int get rangeWidth => maxGlucose - minGlucose;

  // ============================================================================
  // JSON SERIALIZATION
  // ============================================================================

  factory DiabeticProfile.fromJson(Map<String, dynamic> json) {
    return DiabeticProfile(
      diabeticType: json['diabetic_type'] ?? 'Type 1',
      treatmentType: json['treatment_type'] ?? 'Insulin',
      minGlucose: json['min_glucose'] ?? 70,
      maxGlucose: json['max_glucose'] ?? 180,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diabetic_type': diabeticType,
      'treatment_type': treatmentType,
      'min_glucose': minGlucose,
      'max_glucose': maxGlucose,
    };
  }

  /// Creates a copy with optional field updates
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
