// Extension methods for String convenience
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Trim and check if empty
  bool get isBlank => trim().isEmpty;

  /// Remove all whitespace
  String removeAllWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Reverse string
  String reverse() => split('').reversed.join('');

  /// Truncate string with ellipsis
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }
}

// Extension methods for List convenience
extension ListExtensions<T> on List<T> {
  /// Check if list is empty or null
  bool get isBlank => isEmpty;

  /// Safe access with index
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Find first element or null
  T? firstOrNull() => isEmpty ? null : first;

  /// Find last element or null
  T? lastOrNull() => isEmpty ? null : last;
}

// Extension methods for num (int and double)
extension NumExtensions on num {
  /// Check if number is in range
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Clamp number between min and max
  num clamp(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
