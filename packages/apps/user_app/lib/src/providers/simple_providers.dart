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

/// Onboarding state provider
final isFirstTimeUserProvider = FutureProvider<bool>((ref) async {
  // For now, always return true to show onboarding
  // In a real app, you'd check SharedPreferences
  return true;
});

/// Complete onboarding provider
final completeOnboardingProvider = FutureProvider.family<void, bool>((ref, completed) async {
  // In a real app, you'd save this to SharedPreferences
  // For now, just simulate the completion
  await Future.delayed(const Duration(milliseconds: 100));
});