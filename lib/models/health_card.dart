/// Model for health card information (Water, Pills, Activity, etc.)
class HealthCard {
  final String title;
  final double value;
  final String unit;

  HealthCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  factory HealthCard.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'];
    double parsedValue;
    if (rawValue == null) {
      parsedValue = 0.0;
    } else if (rawValue is int) {
      parsedValue = rawValue.toDouble();
    } else if (rawValue is double) {
      parsedValue = rawValue;
    } else if (rawValue is num) {
      parsedValue = rawValue.toDouble();
    } else {
      parsedValue = 0.0;
    }

    return HealthCard(
      title: json['title'] ?? '',
      value: parsedValue,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'unit': unit,
    };
  }

  /// Create a copy of this HealthCard with a new title
  HealthCard copyWithTitle(String newTitle) {
    return HealthCard(
      title: newTitle,
      value: value,
      unit: unit,
    );
  }

  /// Create a copy of this HealthCard with optional new values
  HealthCard copyWith({
    String? title,
    double? value,
    String? unit,
  }) {
    return HealthCard(
      title: title ?? this.title,
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }
}
