import 'package:appwrite/models.dart' as appwrite;

/// Comprehensive user model for WePark ecosystem
class User {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role; // 'user', 'admin', 'attendant'
  final bool isActive;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  final String? vehiclePlateNumber;
  final String? vehicleModel;
  final String? vehicleColor;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    this.vehiclePlateNumber,
    this.vehicleModel,
    this.vehicleColor,
  });

  /// Create from Appwrite User model
  factory User.fromAppwriteUser(appwrite.User appwriteUser) {
    return User(
      id: appwriteUser.$id,
      email: appwriteUser.email,
      fullName: appwriteUser.name,
      phoneNumber: null, // Will be fetched from database
      role: 'user', // Default role
      isActive: true,
      profileImageUrl: null,
      createdAt: DateTime.parse(appwriteUser.$createdAt),
      updatedAt: DateTime.parse(appwriteUser.$updatedAt),
    );
  }

  /// Create from Appwrite document
  factory User.fromDocument(Map<String, dynamic> document) {
    return User(
      id: document['\$id'] ?? '',
      email: document['email'] ?? '',
      fullName: document['fullName'] ?? '',
      phoneNumber: document['phoneNumber'],
      role: document['role'] ?? 'user',
      isActive: document['isActive'] ?? true,
      profileImageUrl: document['profileImageUrl'],
      createdAt: DateTime.parse(
          document['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          document['updatedAt'] ?? DateTime.now().toIso8601String()),
      preferences: document['preferences'] != null
          ? _jsonStringToMap(document['preferences'])
          : null,
      vehiclePlateNumber: document['vehiclePlateNumber'],
      vehicleModel: document['vehicleModel'],
      vehicleColor: document['vehicleColor'],
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toDocument() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences':
          preferences != null ? _mapToJsonString(preferences!) : null,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
    };
  }

  /// Convert map to JSON string
  static String _mapToJsonString(Map<String, dynamic> map) {
    try {
      return map.toString(); // Simple conversion for now
    } catch (e) {
      return '{}';
    }
  }

  /// Convert JSON string to map
  static Map<String, dynamic>? _jsonStringToMap(String jsonString) {
    try {
      // Simple parsing for now - you can use jsonDecode for proper JSON
      if (jsonString.startsWith('{') && jsonString.endsWith('}')) {
        return {}; // Return empty map for now
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get formatted created at date
  String get formattedCreatedAt =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  /// Get formatted updated at date
  String get formattedUpdatedAt =>
      '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';

  /// Create copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? role,
    bool? isActive,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    String? vehiclePlateNumber,
    String? vehicleModel,
    String? vehicleColor,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is attendant
  bool get isAttendant => role == 'attendant';

  /// Check if user is regular user
  bool get isRegularUser => role == 'user';

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}
