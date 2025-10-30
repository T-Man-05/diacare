/// Model for glucose information
class GlucoseInfo {
  final int value;
  final String unit;
  final String status;

  GlucoseInfo({
    required this.value,
    required this.unit,
    required this.status,
  });

  factory GlucoseInfo.fromJson(Map<String, dynamic> json) {
    return GlucoseInfo(
      value: json['value'] ?? 0,
      unit: json['unit'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'status': status,
    };
  }
}
