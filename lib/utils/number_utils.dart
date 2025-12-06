// Number formatting utilities
class NumberUtils {
  static String formatGlucose(double value) {
    return '${value.toStringAsFixed(1)} mg/dL';
  }

  static String formatWeight(double value) {
    return '${value.toStringAsFixed(1)} kg';
  }

  static String formatHeight(double value) {
    return '${value.toStringAsFixed(2)} m';
  }

  static String formatBMI(double value) {
    return value.toStringAsFixed(1);
  }

  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static String formatDuration(Duration duration) {
    int seconds = duration.inSeconds;
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    seconds = seconds % 60;

    List<String> parts = [];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');

    return parts.isEmpty ? '0s' : parts.join(' ');
  }

  static bool isValidNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value) != null;
  }
}
