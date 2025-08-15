import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Simple authentication state provider
final simpleAuthProvider = Provider<SimpleAuthService>((ref) {
  return SimpleAuthService.instance;
});

/// Current user provider
final currentUserProvider = FutureProvider<SimpleUser?>((ref) async {
  final authService = ref.watch(simpleAuthProvider);
  return await authService.getCurrentUser();
});

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Check if user is authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(simpleAuthProvider);
  return await authService.isLoggedIn();
});
