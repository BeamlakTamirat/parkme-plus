/// Ultra-simple user model - just the essentials
class SimpleUser {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  SimpleUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  /// Create from Appwrite document
  factory SimpleUser.fromMap(Map<String, dynamic> map) {
    return SimpleUser(
      id: map['\$id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SimpleUser(id: $id, email: $email, name: $name)';
  }
}
