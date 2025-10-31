import 'dart:convert';
import 'package:flutter/services.dart';
import 'app_repository.dart';
import '../models/dashboard_data.dart';

/// Local demo repository implementation
/// Reads data from JSON file and provides it through single getData() function
class LocalDemoRepository implements AppRepository {
  Map<String, dynamic>? _cachedData;

  /// Single getData function - ONLY function UI calls to get data
  /// Loads JSON file from assets and returns all app data
  @override
  Future<Map<String, dynamic>> getData() async {
    // Return cached data if already loaded
    if (_cachedData != null) {
      return _cachedData!;
    }

    // Load JSON file from assets
    final String jsonString =
        await rootBundle.loadString('assets/data/demo_data.json');

    // Parse JSON
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Cache the data
    _cachedData = jsonData;

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return jsonData;
  }

  /// Get settings data
  /// @override
  @override
  Future<SettingsData> getSettingsData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return SettingsData.fromJson(
        _cachedData!['settings'] as Map<String, dynamic>);
  }

  /// Update settings data
  @override
  Future<void> updateSettings(Map<String, dynamic> settingsData) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Update cached data
    if (_cachedData != null) {
      _cachedData!['settings'] = settingsData;
    }
  }

  /// Helper method to get available treatment options
  List<String> getAvailableTreatments() {
    return ['Diet', 'Pills', 'Insulin'];
  }

  /// Helper method to get diabetes types
  List<String> getDiabetesTypes() {
    return ['Type 1', 'Type 2', 'Gestational'];
  }
}
