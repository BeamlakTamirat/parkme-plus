class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final UserRole role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserStats? stats;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.stats,
    this.preferences,
    this.metadata,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      fullName: data['full_name'],
      phoneNumber: data['phone_number'],
      profileImageUrl: data['profile_image_url'],
      role: _parseUserRole(data['role']),
      isEmailVerified: data['is_email_verified'] ?? false,
      isPhoneVerified: data['is_phone_verified'] ?? false,
      isActive: data['is_active'] ?? true,
      createdAt: _parseTimestamp(data['created_at']),
      updatedAt: _parseTimestamp(data['updated_at']),
      preferences: data['preferences'],
      metadata: data['metadata'],
    );
  }

  /// Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'role': role.name,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'preferences': preferences ?? {},
      'metadata': metadata ?? {},
    };
  }

  /// Parse UserRole from string
  static UserRole _parseUserRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'attendant':
        return UserRole.attendant;
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }

  /// Parse timestamp from Firestore
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStats? stats,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
    );
  }
}

class UserStats {
  final int totalBookings;
  final double totalAmountSpent;
  final int totalHoursParked;
  final bool isPremiumMember;

  const UserStats({
    required this.totalBookings,
    required this.totalAmountSpent,
    required this.totalHoursParked,
    required this.isPremiumMember,
  });
}

enum UserRole {
  user,
  admin,
  attendant,
  superAdmin,
}
