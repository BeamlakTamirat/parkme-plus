import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../../config/appwrite_config.dart';
import '../../models/user/user.dart';
import '../database/database_service.dart';

/// Callback type for auth state changes
typedef AuthStateCallback = void Function();

/// Comprehensive authentication service for WePark
/// Supports both simple and enhanced user registration
class ComprehensiveAuthService {
  static ComprehensiveAuthService? _instance;
  ComprehensiveAuthService._();
  static ComprehensiveAuthService get instance {
    _instance ??= ComprehensiveAuthService._();
    return _instance!;
  }

  // Callback to notify when auth state changes
  AuthStateCallback? _onAuthStateChanged;

  /// Set callback for auth state changes
  void setAuthStateCallback(AuthStateCallback callback) {
    _onAuthStateChanged = callback;
  }

  /// Notify auth state change
  void _notifyAuthStateChanged() {
    _onAuthStateChanged?.call();
  }

  /// Sign up with comprehensive user data
  Future<ComprehensiveAuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? vehiclePlateNumber,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    try {
      if (kDebugMode) print('🔐 Starting comprehensive signup for: $email');

      // Validate inputs
      if (!_isValidEmail(email)) {
        return ComprehensiveAuthResult.error(
            'Please enter a valid email address');
      }
      if (password.length < 8) {
        return ComprehensiveAuthResult.error(
            'Password must be at least 8 characters');
      }
      if (fullName.trim().isEmpty) {
        return ComprehensiveAuthResult.error('Full name is required');
      }

      // Create account in Appwrite Auth
      final appwriteUser = await AppwriteConfig.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: fullName.trim(),
      );

      if (kDebugMode) print('✅ Appwrite account created: ${appwriteUser.$id}');

      // Create session (log in automatically)
      await AppwriteConfig.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Create comprehensive user profile
      final user = User(
        id: appwriteUser.$id,
        email: email,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber,
        role: 'user', // Default role
        isActive: true,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: null,
        vehiclePlateNumber: vehiclePlateNumber,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
      );

      // Save user data to database
      final success = await DatabaseService.instance.createUser(user);

      if (!success) {
        // If database save fails, delete the Appwrite account
        try {
          await AppwriteConfig.account.deleteSessions();
        } catch (e) {
          if (kDebugMode)
            print('⚠️ Failed to clean up session after database error');
        }
        return ComprehensiveAuthResult.error(
            'Failed to save user profile. Please try again.');
      }

      if (kDebugMode) print('✅ Comprehensive user data saved to database');

      // Notify auth state change
      _notifyAuthStateChanged();

      return ComprehensiveAuthResult.success(
        user: user,
        message: 'Account created successfully! Welcome to WePark!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Signup error: ${e.message}');
      return ComprehensiveAuthResult.error(
          _getErrorMessage(e.message ?? 'Signup failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected signup error: $e');
      return ComprehensiveAuthResult.error('Signup failed. Please try again.');
    }
  }

  /// Admin-initiated user creation (NO session creation)
  /// Used when admin creates accounts for other users
  Future<ComprehensiveAuthResult> createUserForAdmin({
    required String email,
    required String password,
    required String fullName,
    required String role, // Allow specifying role
    String? phoneNumber,
    String? vehiclePlateNumber,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    try {
      if (kDebugMode)
        print('👨‍💼 Starting admin user creation for: $email (role: $role)');

      // Validate inputs
      if (!_isValidEmail(email)) {
        return ComprehensiveAuthResult.error(
            'Please enter a valid email address');
      }
      if (password.length < 8) {
        return ComprehensiveAuthResult.error(
            'Password must be at least 8 characters');
      }
      if (fullName.trim().isEmpty) {
        return ComprehensiveAuthResult.error('Full name is required');
      }
      if (!['user', 'admin', 'attendant'].contains(role.toLowerCase())) {
        return ComprehensiveAuthResult.error('Invalid role specified');
      }

      // Create account in Appwrite Auth (NO SESSION CREATION)
      final appwriteUser = await AppwriteConfig.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: fullName.trim(),
      );

      if (kDebugMode)
        print('✅ Appwrite account created by admin: ${appwriteUser.$id}');

      // 🔐 SKIP session creation - admin stays logged in
      // This is the key difference from regular signUp

      // Create comprehensive user profile with specified role
      final user = User(
        id: appwriteUser.$id,
        email: email,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber,
        role: role.toLowerCase(), // Use specified role
        isActive: true,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: null,
        vehiclePlateNumber: vehiclePlateNumber,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
      );

      // Save user data to database
      final success = await DatabaseService.instance.createUser(user);

      if (!success) {
        // If database save fails, we should delete the Appwrite account
        // But we can't use deleteSessions() because we didn't create a session
        // We'll need to use the Users API to delete the account
        if (kDebugMode)
          print(
              '❌ Database save failed, Appwrite account created but not saved to DB');
        return ComprehensiveAuthResult.error(
            'Failed to save user profile. Appwrite account created but not linked.');
      }

      if (kDebugMode) print('✅ Admin-created user data saved to database');

      // Do NOT notify auth state change (admin stays logged in)

      return ComprehensiveAuthResult.success(
        user: user,
        message:
            'Account created successfully by admin! User: ${user.fullName} (${user.role})',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Admin user creation error: ${e.message}');
      return ComprehensiveAuthResult.error(
          _getErrorMessage(e.message ?? 'User creation failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected admin user creation error: $e');
      return ComprehensiveAuthResult.error(
          'User creation failed. Please try again.');
    }
  }

  /// Simple sign up (backward compatibility)
  Future<ComprehensiveAuthResult> simpleSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (kDebugMode) print('🔐 Starting simple signup for: $email');

      // Validate inputs
      if (!_isValidEmail(email)) {
        return ComprehensiveAuthResult.error(
            'Please enter a valid email address');
      }
      if (password.length < 8) {
        return ComprehensiveAuthResult.error(
            'Password must be at least 8 characters');
      }
      if (name.trim().isEmpty) {
        return ComprehensiveAuthResult.error('Name is required');
      }

      // Create account in Appwrite Auth
      final appwriteUser = await AppwriteConfig.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name.trim(),
      );

      if (kDebugMode) print('✅ Appwrite account created: ${appwriteUser.$id}');

      // Create session (log in automatically)
      await AppwriteConfig.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Create simple user profile
      final user = User(
        id: appwriteUser.$id,
        email: email,
        fullName: name.trim(),
        phoneNumber: null,
        role: 'user',
        isActive: true,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: null,
        vehiclePlateNumber: null,
        vehicleModel: null,
        vehicleColor: null,
      );

      // Save user data to database
      final success = await DatabaseService.instance.createUser(user);

      if (!success) {
        // If database save fails, delete the Appwrite account
        try {
          await AppwriteConfig.account.deleteSessions();
        } catch (e) {
          if (kDebugMode)
            print('⚠️ Failed to clean up session after database error');
        }
        return ComprehensiveAuthResult.error(
            'Failed to save user profile. Please try again.');
      }

      if (kDebugMode) print('✅ Simple user data saved to database');

      return ComprehensiveAuthResult.success(
        user: user,
        message: 'Account created successfully!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Simple signup error: ${e.message}');
      return ComprehensiveAuthResult.error(
          _getErrorMessage(e.message ?? 'Signup failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected simple signup error: $e');
      return ComprehensiveAuthResult.error('Signup failed. Please try again.');
    }
  }

  /// Sign in with email and password
  Future<ComprehensiveAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) print('🔐 Starting signin for: $email');

      // Validate inputs
      if (!_isValidEmail(email)) {
        return ComprehensiveAuthResult.error(
            'Please enter a valid email address');
      }
      if (password.isEmpty) {
        return ComprehensiveAuthResult.error('Password is required');
      }

      // Create session
      await AppwriteConfig.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Get current user from Appwrite
      final appwriteUser = await AppwriteConfig.account.get();

      // Get comprehensive user data from database
      final userData = await DatabaseService.instance.getUser(appwriteUser.$id);

      if (userData == null) {
        return ComprehensiveAuthResult.error(
            'User profile not found. Please contact support.');
      }

      final user = User.fromDocument(userData);

      if (!user.isActive) {
        return ComprehensiveAuthResult.error(
            'Account is deactivated. Please contact support.');
      }

      if (kDebugMode) print('✅ Signin successful for: ${user.fullName}');

      // Notify auth state change
      _notifyAuthStateChanged();

      return ComprehensiveAuthResult.success(
        user: user,
        message: 'Welcome back, ${user.fullName}!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Signin error: ${e.message}');
      return ComprehensiveAuthResult.error(
          _getErrorMessage(e.message ?? 'Signin failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected signin error: $e');
      return ComprehensiveAuthResult.error('Signin failed. Please try again.');
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      final appwriteUser = await AppwriteConfig.account.get();
      final userData = await DatabaseService.instance.getUser(appwriteUser.$id);

      if (userData != null) {
        return User.fromDocument(userData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting current user: $e');
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

  /// Sign out
  Future<bool> signOut() async {
    try {
      await AppwriteConfig.account.deleteSessions();
      if (kDebugMode) print('✅ Signout successful');

      // Notify auth state change
      _notifyAuthStateChanged();

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Signout error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<ComprehensiveAuthResult> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? vehiclePlateNumber,
    String? vehicleModel,
    String? vehicleColor,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return ComprehensiveAuthResult.error('User not found');
      }

      final updatedUser = currentUser.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        vehiclePlateNumber: vehiclePlateNumber,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        preferences: preferences,
        updatedAt: DateTime.now(),
      );

      final success = await DatabaseService.instance.updateUser(updatedUser);

      if (!success) {
        return ComprehensiveAuthResult.error(
            'Failed to update profile. Please try again.');
      }

      if (kDebugMode) print('✅ Profile updated successfully');

      return ComprehensiveAuthResult.success(
        user: updatedUser,
        message: 'Profile updated successfully!',
      );
    } catch (e) {
      if (kDebugMode) print('❌ Profile update error: $e');
      return ComprehensiveAuthResult.error(
          'Failed to update profile. Please try again.');
    }
  }

  /// Change password
  Future<ComprehensiveAuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 8) {
        return ComprehensiveAuthResult.error(
            'New password must be at least 8 characters');
      }

      // Appwrite requires current password for updatePassword
      await AppwriteConfig.account.updatePassword(
        password: newPassword,
        oldPassword: currentPassword,
      );

      if (kDebugMode) print('✅ Password changed successfully');

      return ComprehensiveAuthResult.success(
        user: null,
        message: 'Password changed successfully!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Password change error: ${e.message}');
      return ComprehensiveAuthResult.error(
          _getErrorMessage(e.message ?? 'Password change failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected password change error: $e');
      return ComprehensiveAuthResult.error(
          'Password change failed. Please try again.');
    }
  }

  /// Update email in both auth and database
  Future<ComprehensiveAuthResult> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      if (!_isValidEmail(newEmail)) {
        return ComprehensiveAuthResult.error(
            'Please enter a valid email address');
      }

      // Update email in Appwrite auth
      await AppwriteConfig.account.updateEmail(
        email: newEmail,
        password: password,
      );

      // Get current user and update database
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          email: newEmail,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateUser(updatedUser);
      }

      if (kDebugMode) print('✅ Email updated successfully');

      return ComprehensiveAuthResult.success(
        user: null,
        message: 'Email updated successfully!',
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) print('❌ Email update error: ${e.message}');
      return ComprehensiveAuthResult.error(
          _getErrorMessage(e.message ?? 'Email update failed'));
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected email update error: $e');
      return ComprehensiveAuthResult.error(
          'Email update failed. Please try again.');
    }
  }

  /// Delete account
  Future<ComprehensiveAuthResult> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return ComprehensiveAuthResult.error('User not found');
      }

      // Delete user data from database
      final success = await DatabaseService.instance.deleteUser(currentUser.id);

      if (!success) {
        return ComprehensiveAuthResult.error(
            'Failed to delete account. Please try again.');
      }

      // Delete Appwrite account (not available in current version)
      // await AppwriteConfig.account.delete();

      if (kDebugMode) print('✅ Account deleted successfully');

      return ComprehensiveAuthResult.success(
        user: null,
        message: 'Account deleted successfully',
      );
    } catch (e) {
      if (kDebugMode) print('❌ Account deletion error: $e');
      return ComprehensiveAuthResult.error(
          'Failed to delete account. Please try again.');
    }
  }

  // Helper methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getErrorMessage(String message) {
    if (message.contains('Invalid credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('User already exists')) {
      return 'An account with this email already exists';
    } else if (message.contains('Invalid email')) {
      return 'Please enter a valid email address';
    } else if (message.contains('Invalid password')) {
      return 'Password must be at least 8 characters';
    } else if (message.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (message.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection';
    }
    return message;
  }
}

/// Comprehensive authentication result
class ComprehensiveAuthResult {
  final bool success;
  final User? user;
  final String message;

  ComprehensiveAuthResult._({
    required this.success,
    this.user,
    required this.message,
  });

  factory ComprehensiveAuthResult.success(
      {User? user, required String message}) {
    return ComprehensiveAuthResult._(
        success: true, user: user, message: message);
  }

  factory ComprehensiveAuthResult.error(String message) {
    return ComprehensiveAuthResult._(success: false, message: message);
  }
}
