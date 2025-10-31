// dashboard_data.dart
import 'chart_data.dart';
import 'health_card.dart';

class DashboardData {
  final String greeting;
  final GlucoseInfo glucose;
  final String reminder;
  final List<HealthCard> healthCards;
  final ChartData chart;

  DashboardData({
    required this.greeting,
    required this.glucose,
    required this.reminder,
    required this.healthCards,
    required this.chart,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      greeting: json['greeting'] ?? '',
      glucose: GlucoseInfo.fromJson(json['glucose'] ?? {}),
      reminder: json['reminder'] ?? '',
      healthCards: (json['health_cards'] as List<dynamic>?)
              ?.map((e) => HealthCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chart: ChartData.fromJson(json['chart'] ?? {}),
    );
  }
}

class GlucoseInfo {
  final int value;
  final String unit;
  final String status;

  GlucoseInfo({required this.value, required this.unit, required this.status});

  factory GlucoseInfo.fromJson(Map<String, dynamic> json) {
    return GlucoseInfo(
      value: json['value'] ?? 0,
      unit: json['unit'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

// class HealthCard {
//   final String title;
//   final double value;
//   final String unit;

//   HealthCard({required this.title, required this.value, required this.unit});

//   factory HealthCard.fromJson(Map<String, dynamic> json) {
//     return HealthCard(
//       title: json['title'] ?? '',
//       value: (json['value'] is int)
//           ? (json['value'] as int).toDouble()
//           : (json['value'] ?? 0.0),
//       unit: json['unit'] ?? '',
//     );
//   }
// }

// class ChartData {
//   final String title;
//   final Map<String, List<int>> data;
//   final List<String> days;

//   ChartData({required this.title, required this.data, required this.days});

//   factory ChartData.fromJson(Map<String, dynamic> json) {
//     final dataMap = json['data'] as Map<String, dynamic>? ?? {};
//     return ChartData(
//       title: json['title'] ?? '',
//       data: {
//         'before_meal':
//             (dataMap['before_meal'] as List<dynamic>?)
//                 ?.map((e) => e as int)
//                 .toList() ??
//             [],
//         'after_meal':
//             (dataMap['after_meal'] as List<dynamic>?)
//                 ?.map((e) => e as int)
//                 .toList() ??
//             [],
//       },
//       days:
//           (json['days'] as List<dynamic>?)?.map((e) => e as String).toList() ??
//           [],
//     );
//   }
// }

// settings_data.dart
class SettingsData {
  String email;
  String password;
  DiabeticProfile diabeticProfile;
  Preferences preferences;

  SettingsData({
    required this.email,
    required this.password,
    required this.diabeticProfile,
    required this.preferences,
  });

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      diabeticProfile: DiabeticProfile.fromJson(json['diabetic_profile'] ?? {}),
      preferences: Preferences.fromJson(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'diabetic_profile': diabeticProfile.toJson(),
      'preferences': preferences.toJson(),
    };
  }
}

class DiabeticProfile {
  String diabetesType;
  List<String> treatments;

  DiabeticProfile({required this.diabetesType, required this.treatments});

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
    return {'diabetes_type': diabetesType, 'treatments': treatments};
  }
}

class Preferences {
  String theme;
  bool notificationsEnabled;

  Preferences({required this.theme, required this.notificationsEnabled});

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      theme: json['theme'] ?? 'light',
      notificationsEnabled: json['notifications_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'theme': theme, 'notifications_enabled': notificationsEnabled};
  }
}
