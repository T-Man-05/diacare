/// Model for diabetic profile information
class DiabeticProfile {
  String diabetesType;
  List<String> treatments;

  DiabeticProfile({
    required this.diabetesType,
    required this.treatments,
  });

  factory DiabeticProfile.fromJson(Map<String, dynamic> json) {
    return DiabeticProfile(
      diabetesType: json['diabetes_type'] ?? '',
      treatments: (json['treatments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diabetes_type': diabetesType,
      'treatments': treatments,
    };
  }
}
