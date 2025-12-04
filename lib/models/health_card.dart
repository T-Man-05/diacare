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
    return HealthCard(
      title: json['title'] ?? '',
      value: (json['value'] is int)
          ? (json['value'] as int).toDouble()
          : (json['value'] ?? 0.0),
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
}
