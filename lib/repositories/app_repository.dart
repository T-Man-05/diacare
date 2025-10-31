// app_repository.dart
import '../models/dashboard_data.dart';

abstract class AppRepository {
  Future<Map<String, dynamic>> getData();
  Future<SettingsData> getSettingsData();
  Future<void> updateSettings(Map<String, dynamic> data);
}

// local_demo_repository.dart
// class LocalDemoRepository implements AppRepository {
//   // Simulated JSON data stored in memory
//   final Map<String, dynamic> _demoData = {
//     "dashboard": {
//       "greeting": "Hi, Sam",
//       "glucose": {"value": 112, "unit": "mg/dl", "status": "you are fine"},
//       "reminder": "Drink Water",
//       "health_cards": [
//         {"title": "Water", "value": 1.2, "unit": "L"},
//         {"title": "Pills", "value": 2, "unit": "taken"},
//         {"title": "Activity", "value": 306, "unit": "steps"},
//         {"title": "Carbs", "value": 522, "unit": "cal"},
//         {"title": "Insulin", "value": 5, "unit": "units"},
//       ],
//       "chart": {
//         "title": "Blood Sugar (mg/dl)",
//         "data": {
//           "before_meal": [120, 110, 130, 125, 140, 100, 105],
//           "after_meal": [160, 150, 140, 130, 145, 135, 120],
//         },
//         "days": ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"],
//       },
//     },
//     "settings": {
//       "email": "user@example.com",
//       "password": "••••••••",
//       "diabetic_profile": {
//         "diabetes_type": "Type 1",
//         "treatments": ["Insulin"],
//       },
//       "preferences": {"theme": "light", "notifications_enabled": true},
//     },
//   };

//   @override
//   Future<DashboardData> getDashboardData() async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 300));
//     return DashboardData.fromJson(
//       _demoData['dashboard'] as Map<String, dynamic>,
//     );
//   }

//

//

//   // Helper method to get available treatment options
//   List<String> getAvailableTreatments() {
//     return ['Diet', 'Pills', 'Insulin'];
//   }

//   // Helper method to get diabetes types
//   List<String> getDiabetesTypes() {
//     return ['Type 1', 'Type 2', 'Gestational'];
//   }
// }
