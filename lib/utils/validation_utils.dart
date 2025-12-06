// Validation utility for form inputs
class ValidationUtils {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone.replaceAll(RegExp(r'\s'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateGlucoseLevel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Glucose level is required';
    }
    final glucose = double.tryParse(value);
    if (glucose == null) {
      return 'Please enter a valid number';
    }
    if (glucose < 20 || glucose > 600) {
      return 'Glucose level should be between 20 and 600 mg/dL';
    }
    return null;
  }
}
