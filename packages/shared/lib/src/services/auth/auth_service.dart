import 'package:firebase_auth/firebase_auth.dart';
import '../../config/firebase_config.dart';
import '../utils/simple_logger.dart';

/// Authentication service for handling user authentication
class AuthService {
  static AuthService? _instance;
  late final FirebaseAuth _auth;

  AuthService._internal() {
    _auth = FirebaseConfig.auth;
  }

  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      logger.info('Attempting to sign up user with email: $email');

      // Create user account
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update user profile
        await credential.user!.updateDisplayName(fullName);

        // Send email verification
        await credential.user!.sendEmailVerification();

        logger.info('User signed up successfully: ${credential.user!.uid}');

        return AuthResult(
          success: true,
          user: credential.user,
          message: 'Account created successfully. Please verify your email.',
        );
      } else {
        throw Exception('Failed to create user account');
      }
    } on FirebaseAuthException catch (e) {
      logger.error(
          'Firebase Auth error during sign up: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        error: _mapFirebaseAuthError(e),
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      logger.error('Unexpected error during sign up: $e');
      return AuthResult(
        success: false,
        error: 'unknown_error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      logger.info('Attempting to sign in user with email: $email');

      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        logger.info('User signed in successfully: ${credential.user!.uid}');

        return AuthResult(
          success: true,
          user: credential.user,
          message: 'Signed in successfully',
        );
      } else {
        throw Exception('Failed to sign in');
      }
    } on FirebaseAuthException catch (e) {
      logger.error(
          'Firebase Auth error during sign in: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        error: _mapFirebaseAuthError(e),
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      logger.error('Unexpected error during sign in: $e');
      return AuthResult(
        success: false,
        error: 'unknown_error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign out
  Future<AuthResult> signOut() async {
    try {
      logger.info('Attempting to sign out user');

      // Sign out from Firebase
      await _auth.signOut();

      logger.info('User signed out successfully');

      return AuthResult(
        success: true,
        message: 'Signed out successfully',
      );
    } catch (e) {
      logger.error('Error during sign out: $e');
      return AuthResult(
        success: false,
        error: 'sign_out_error',
        message: 'Failed to sign out. Please try again.',
      );
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      logger.info('Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email);

      logger.info('Password reset email sent successfully');

      return AuthResult(
        success: true,
        message: 'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      logger.error(
          'Firebase Auth error sending password reset: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        error: _mapFirebaseAuthError(e),
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      logger.error('Unexpected error sending password reset: $e');
      return AuthResult(
        success: false,
        error: 'unknown_error',
        message: 'Failed to send password reset email. Please try again.',
      );
    }
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return AuthResult(
          success: false,
          error: 'user_not_found',
          message: 'No user signed in',
        );
      }

      logger.info('Attempting to change password for user: ${user.uid}');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      logger.info('Password changed successfully for user: ${user.uid}');

      return AuthResult(
        success: true,
        message: 'Password changed successfully',
      );
    } on FirebaseAuthException catch (e) {
      logger.error(
          'Firebase Auth error changing password: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        error: _mapFirebaseAuthError(e),
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      logger.error('Unexpected error changing password: $e');
      return AuthResult(
        success: false,
        error: 'unknown_error',
        message: 'Failed to change password. Please try again.',
      );
    }
  }

  /// Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          error: 'user_not_found',
          message: 'No user signed in',
        );
      }

      if (user.emailVerified) {
        return AuthResult(
          success: true,
          message: 'Email is already verified',
        );
      }

      logger.info('Sending email verification to user: ${user.uid}');

      await user.sendEmailVerification();

      logger.info('Email verification sent successfully');

      return AuthResult(
        success: true,
        message: 'Verification email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      logger.error(
          'Firebase Auth error sending email verification: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        error: _mapFirebaseAuthError(e),
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      logger.error('Unexpected error sending email verification: $e');
      return AuthResult(
        success: false,
        error: 'unknown_error',
        message: 'Failed to send verification email. Please try again.',
      );
    }
  }

  /// Reload current user
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Delete user account
  Future<AuthResult> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return AuthResult(
          success: false,
          error: 'user_not_found',
          message: 'No user signed in',
        );
      }

      logger.info('Attempting to delete account for user: ${user.uid}');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user account
      await user.delete();

      logger.info('User account deleted successfully');

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } on FirebaseAuthException catch (e) {
      logger.error(
          'Firebase Auth error deleting account: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        error: _mapFirebaseAuthError(e),
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      logger.error('Unexpected error deleting account: $e');
      return AuthResult(
        success: false,
        error: 'unknown_error',
        message: 'Failed to delete account. Please try again.',
      );
    }
  }

  /// Map Firebase Auth errors to our error codes
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
        return 'wrong_password';
      case 'email-already-in-use':
        return 'email_already_in_use';
      case 'weak-password':
        return 'weak_password';
      case 'invalid-email':
        return 'invalid_email';
      case 'user-disabled':
        return 'user_disabled';
      case 'too-many-requests':
        return 'too_many_requests';
      case 'operation-not-allowed':
        return 'operation_not_allowed';
      case 'requires-recent-login':
        return 'requires_recent_login';
      default:
        return 'unknown_error';
    }
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Authentication result model
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    required this.message,
  });

  @override
  String toString() {
    return 'AuthResult(success: $success, user: ${user?.uid}, error: $error, message: $message)';
  }
}
