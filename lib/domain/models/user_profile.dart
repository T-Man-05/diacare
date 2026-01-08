/// Domain model for user profile information
/// This model is backend-agnostic - no JSON keys, no infrastructure concepts
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? profileImageUrl;
  final String? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
  });

  /// Display name - full name if available, otherwise username
  String get displayName => fullName.isNotEmpty ? fullName : username;

  /// Username without @ symbol
  String get usernameWithoutAt =>
      username.startsWith('@') ? username.substring(1) : username;

  /// Check if profile image exists
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
