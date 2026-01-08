/// Domain model for chart data
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts

/// Blood sugar chart data for dashboard
class BloodSugarChartData {
  final String title;
  final List<double> beforeMealValues;
  final List<double> afterMealValues;
  final List<String> labels;

  const BloodSugarChartData({
    required this.title,
    required this.beforeMealValues,
    required this.afterMealValues,
    required this.labels,
  });

  /// Check if chart has data
  bool get hasData => beforeMealValues.isNotEmpty || afterMealValues.isNotEmpty;

  /// Get maximum value for chart scaling
  double get maxValue {
    double max = 0;
    for (final v in beforeMealValues) {
      if (v > max) max = v;
    }
    for (final v in afterMealValues) {
      if (v > max) max = v;
    }
    return max;
  }
}

/// Carbs chart data for insights page
class CarbsChartData {
  final List<double> values;
  final List<String> days;
  final bool hasData;
  final int totalRecords;

  const CarbsChartData({
    required this.values,
    required this.days,
    required this.hasData,
    required this.totalRecords,
  });

  /// Get maximum value for chart scaling
  double get maxValue {
    double max = 0;
    for (final v in values) {
      if (v > max) max = v;
    }
    return max;
  }

  /// Get average value
  double get average {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

/// Activity chart data for insights page
class ActivityChartData {
  final List<double> values;
  final List<String> hours;
  final bool hasData;
  final int totalRecords;

  const ActivityChartData({
    required this.values,
    required this.hours,
    required this.hasData,
    required this.totalRecords,
  });

  /// Get maximum value for chart scaling
  double get maxValue {
    double max = 0;
    for (final v in values) {
      if (v > max) max = v;
    }
    return max;
  }

  /// Get total steps
  double get total => values.fold(0, (sum, v) => sum + v);
}

/// Glucose chart data for insights page
class GlucoseChartData {
  final List<double> beforeMealValues;
  final List<double> afterMealValues;
  final List<String> hours;
  final bool hasData;
  final int totalRecords;

  const GlucoseChartData({
    required this.beforeMealValues,
    required this.afterMealValues,
    required this.hours,
    required this.hasData,
    required this.totalRecords,
  });

  /// Get maximum value for chart scaling
  double get maxValue {
    double max = 0;
    for (final v in beforeMealValues) {
      if (v > max) max = v;
    }
    for (final v in afterMealValues) {
      if (v > max) max = v;
    }
    return max;
  }
}
