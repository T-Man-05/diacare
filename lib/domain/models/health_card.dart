/// Domain model for health card information
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts
class HealthCard {
  final String id;
  final HealthCardType type;
  final double value;
  final String unit;
  final DateTime? updatedAt;

  const HealthCard({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    this.updatedAt,
  });

  /// Get display title based on type
  String get title => type.displayName;

  /// Value formatted for display
  String get displayValue {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Create a copy with a new title (for localization)
  HealthCard copyWithTitle(String newTitle) {
    // Since type determines title, we just return a copy
    return copyWith();
  }

  HealthCard copyWith({
    String? id,
    HealthCardType? type,
    double? value,
    String? unit,
    DateTime? updatedAt,
  }) {
    return HealthCard(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Health card type enumeration
enum HealthCardType {
  water,
  pills,
  activity,
  carbs,
  insulin,
}

extension HealthCardTypeExtension on HealthCardType {
  String get displayName {
    switch (this) {
      case HealthCardType.water:
        return 'Water';
      case HealthCardType.pills:
        return 'Pills';
      case HealthCardType.activity:
        return 'Activity';
      case HealthCardType.carbs:
        return 'Carbs';
      case HealthCardType.insulin:
        return 'Insulin';
    }
  }

  String get defaultUnit {
    switch (this) {
      case HealthCardType.water:
        return 'L';
      case HealthCardType.pills:
        return 'taken';
      case HealthCardType.activity:
        return 'steps';
      case HealthCardType.carbs:
        return 'cal';
      case HealthCardType.insulin:
        return 'units';
    }
  }
}
