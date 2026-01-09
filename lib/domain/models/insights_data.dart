/// ============================================================================
/// INSIGHTS DATA MODEL
/// ============================================================================
///
/// Comprehensive health insights including statistics, trends, and patterns
/// ============================================================================

/// Health insights data from backend analytics
class InsightsData {
  // 7-day statistics
  final double sevenDayAverage;
  final double sevenDayMin;
  final double sevenDayMax;
  final int sevenDayCount;
  final double sevenDayInRange;
  final double sevenDayBelowRange;
  final double sevenDayAboveRange;

  // 30-day statistics
  final double thirtyDayAverage;
  final double thirtyDayMin;
  final double thirtyDayMax;
  final int thirtyDayCount;
  final double thirtyDayInRange;
  final double thirtyDayBelowRange;
  final double thirtyDayAboveRange;

  // Pattern analysis
  final double morningAverage;
  final int morningCount;
  final double eveningAverage;
  final int eveningCount;

  // Trend detection
  final String trend; // 'improving', 'worsening', 'stable', 'insufficient_data'

  // Recommendations
  final List<String> recommendations;

  // Target range
  final int minGlucose;
  final int maxGlucose;

  const InsightsData({
    required this.sevenDayAverage,
    required this.sevenDayMin,
    required this.sevenDayMax,
    required this.sevenDayCount,
    required this.sevenDayInRange,
    required this.sevenDayBelowRange,
    required this.sevenDayAboveRange,
    required this.thirtyDayAverage,
    required this.thirtyDayMin,
    required this.thirtyDayMax,
    required this.thirtyDayCount,
    required this.thirtyDayInRange,
    required this.thirtyDayBelowRange,
    required this.thirtyDayAboveRange,
    required this.morningAverage,
    required this.morningCount,
    required this.eveningAverage,
    required this.eveningCount,
    required this.trend,
    required this.recommendations,
    required this.minGlucose,
    required this.maxGlucose,
  });

  /// Check if there's sufficient data for insights
  bool get hasSufficientData => sevenDayCount >= 3 || thirtyDayCount >= 10;

  /// Get overall glucose control quality
  /// Returns 'good', 'fair', or 'needs_improvement'
  String get overallControl {
    if (!hasSufficientData) return 'insufficient_data';

    final avgInRange = (sevenDayInRange + thirtyDayInRange) / 2;
    if (avgInRange >= 70) return 'good';
    if (avgInRange >= 50) return 'fair';
    return 'needs_improvement';
  }

  /// Get trend emoji for display
  String get trendEmoji {
    switch (trend) {
      case 'improving':
        return '📈 Improving';
      case 'worsening':
        return '📉 Needs Attention';
      case 'stable':
        return '➡️ Stable';
      default:
        return '📊 Analyzing';
    }
  }
}
