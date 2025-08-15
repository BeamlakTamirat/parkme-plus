import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import '../../config/appwrite_config.dart';
import '../../models/user/simple_user.dart';
import '../database/simple_database_service.dart';

/// Ultra-simple authentication service
class SimpleAuthService {
  static SimpleAuthService? _instance;

  SimpleAuthService._();

  static SimpleAuthService get instance {
    _instance ??= SimpleAuthService._();
    return _instance!;
  }

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (kDebugMode) print('🔐 Starting signup for: $email');

      // Validate inputs
      if (!_isValidEmail(email)) {
        return AuthResult.error('Please enter a valid email address');
      }
      if (password.length < 8) {
        return AuthResult.error('Password must be at least 8 characters');
      }
      if (name.trim().isEmpty) {
        return AuthResult.error('Name is required');
      }

      // Create account in Appwrite Auth
      final user = await AppwriteConfig.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name.trim(),
      );

      if (kDebugMode) print('✅ Appwrite account created: ${user.$id}');

      // Create session (log in automatically)
      await AppwriteConfig.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Save user data to database
      final simpleUser = SimpleUser(
        id: user.$id,
        email: email,
        name: name.trim(),
        createdAt: DateTime.now(),
      );

      await SimpleDatabaseService.instance.saveUser(simpleUser);

      if (kDebugMode) print('✅ User data saved to database');

      return AuthResult.success(
        user: simpleUser,
        message: 'Account created successfully!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Signup error: ${e.message}');
      return AuthResult.error(_getErrorMessage(e.message ?? 'Signup failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected signup error: $e');
      return AuthResult.error('Signup failed. Please try again.');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) print('🔐 Starting signin for: $email');

      // Validate inputs
      if (!_isValidEmail(email)) {
        return AuthResult.error('Please enter a valid email address');
      }
      if (password.isEmpty) {
        return AuthResult.error('Password is required');
      }

      // Create session
      await AppwriteConfig.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Get current user
      final appwriteUser = await AppwriteConfig.account.get();

      // Get user data from database
      final userData =
          await SimpleDatabaseService.instance.getUser(appwriteUser.$id);

      SimpleUser? user;
      if (userData != null) {
        user = userData;
      } else {
        // Fallback: create user data if missing
        user = SimpleUser(
          id: appwriteUser.$id,
          email: appwriteUser.email,
          name: appwriteUser.name,
          createdAt: DateTime.now(),
        );
        await SimpleDatabaseService.instance.saveUser(user);
      }

      if (kDebugMode) print('✅ Signin successful');

      return AuthResult.success(
        user: user,
        message: 'Welcome back!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Signin error: ${e.message}');
      return AuthResult.error(_getErrorMessage(e.message ?? 'Signin failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected signin error: $e');
      return AuthResult.error('Signin failed. Please try again.');
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    try {
      await AppwriteConfig.account.deleteSession(sessionId: 'current');
      if (kDebugMode) print('✅ User signed out');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Signout error: $e');
      return false;
    }
  }

  /// Get current user
  Future<SimpleUser?> getCurrentUser() async {
    try {
      final appwriteUser = await AppwriteConfig.account.get();
      final userData =
          await SimpleDatabaseService.instance.getUser(appwriteUser.$id);
      return userData;
    } catch (e) {
      if (kDebugMode) print('ℹ️ No current user: $e');
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      await AppwriteConfig.account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  String _getErrorMessage(String error) {
    if (error.contains('user_already_exists')) {
      return 'An account with this email already exists';
    }
    if (error.contains('user_invalid_credentials')) {
      return 'Invalid email or password';
    }
    if (error.contains('user_not_found')) {
      return 'No account found with this email';
    }
    return error;
  }
}

/// Simple authentication result
class AuthResult {
  final bool success;
  final SimpleUser? user;
  final String message;

  AuthResult._({
    required this.success,
    this.user,
    required this.message,
  });

  factory AuthResult.success({
    SimpleUser? user,
    required String message,
  }) {
    return AuthResult._(
      success: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      success: false,
      message: message,
    );
  }
}
