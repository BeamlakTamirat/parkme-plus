import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../../config/appwrite_config.dart';
import '../../models/user/simple_user.dart';

/// Ultra-simple database service - just for user data
class SimpleDatabaseService {
  static SimpleDatabaseService? _instance;

  SimpleDatabaseService._();

  static SimpleDatabaseService get instance {
    _instance ??= SimpleDatabaseService._();
    return _instance!;
  }

  // Simple constants
  static const String databaseId = 'wepark_db';
  static const String usersCollectionId = 'users';

  /// Save user to database
  Future<void> saveUser(SimpleUser user) async {
    try {
      await AppwriteConfig.databases.createDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: user.id,
        data: user.toMap(),
      );

      if (kDebugMode) print('✅ User saved to database: ${user.email}');
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Document already exists, update it
        await AppwriteConfig.databases.updateDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: user.id,
          data: user.toMap(),
        );
        if (kDebugMode) print('✅ User updated in database: ${user.email}');
      } else {
        if (kDebugMode) print('❌ Database save error: ${e.message}');
        rethrow;
      }
    }
  }

  /// Get user from database
  Future<SimpleUser?> getUser(String userId) async {
    try {
      final document = await AppwriteConfig.databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );

      final user = SimpleUser.fromMap(document.data);
      if (kDebugMode) print('✅ User retrieved from database: ${user.email}');
      return user;
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        if (kDebugMode) print('ℹ️ User not found in database: $userId');
        return null;
      }
      if (kDebugMode) print('❌ Database get error: ${e.message}');
      return null;
    }
  }

  /// Get all users (for admin use)
  Future<List<SimpleUser>> getAllUsers() async {
    try {
      final documents = await AppwriteConfig.databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
      );

      final users = documents.documents
          .map((doc) => SimpleUser.fromMap(doc.data))
          .toList();

      if (kDebugMode) print('✅ Retrieved ${users.length} users from database');
      return users;
    } catch (e) {
      if (kDebugMode) print('❌ Database list error: $e');
      return [];
    }
  }

  /// Delete user from database
  Future<void> deleteUser(String userId) async {
    try {
      await AppwriteConfig.databases.deleteDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
      if (kDebugMode) print('✅ User deleted from database: $userId');
    } catch (e) {
      if (kDebugMode) print('❌ Database delete error: $e');
      rethrow;
    }
  }
}
