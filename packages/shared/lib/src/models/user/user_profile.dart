class UserProfile {
  final String userId;
  final String? bio;
  final String? address;
  final String? city;
  final String? country;
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    required this.userId,
    this.bio,
    this.address,
    this.city,
    this.country,
    this.dateOfBirth,
    this.emergencyContact,
    this.preferences,
  });
} 