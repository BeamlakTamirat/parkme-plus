import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

// Auth providers
final adminAuthServiceProvider = Provider<ComprehensiveAuthService>((ref) {
  return ComprehensiveAuthService.instance;
});

final currentAdminProvider = FutureProvider<User?>((ref) async {
  final authService = ref.read(adminAuthServiceProvider);
  return await authService.getCurrentUser();
});

final isAdminAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentAdminProvider.future);
  return user != null && user.role == 'admin';
});

// Database providers
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

// All users provider
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllUsers();
});

// Users by role
final usersByRoleProvider =
    FutureProvider.family<List<User>, String>((ref, role) async {
  final allUsers = await ref.watch(allUsersProvider.future);
  return allUsers.where((user) => user.role == role).toList();
});

// All parking locations provider
final allParkingLocationsProvider =
    FutureProvider<List<ParkingLocation>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllParkingLocations();
});

// All bookings provider
final allBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllBookings();
});

// Analytics providers
final totalRevenueProvider = FutureProvider<double>((ref) async {
  final bookings = await ref.watch(allBookingsProvider.future);
  return bookings
      .where((booking) => booking.status == 'completed')
      .fold<double>(0.0, (total, booking) => total + booking.totalAmount);
});

final todayBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookings = await ref.watch(allBookingsProvider.future);
  final today = DateTime.now();
  return bookings.where((booking) {
    return booking.startTime.year == today.year &&
        booking.startTime.month == today.month &&
        booking.startTime.day == today.day;
  }).toList();
});

final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookings = await ref.watch(allBookingsProvider.future);
  return bookings.where((booking) => booking.status == 'active').toList();
});

// Create/Update providers
final createUserProvider =
    FutureProvider.family<User?, Map<String, dynamic>>((ref, userData) async {
  // i'd implement proper user creation through auth service
  try {
    // Placeholder - would need actual implementation
    return null;
  } catch (e) {
    return null;
  }
});

final updateUserProvider = FutureProvider.family<bool, User>((ref, user) async {
  // i'd implement proper user update
  try {
    // Placeholder - would need actual implementation
    return false;
  } catch (e) {
    return false;
  }
});

final createParkingLocationProvider =
    FutureProvider.family<ParkingLocation?, Map<String, dynamic>>(
        (ref, locationData) async {
  // i'd implement proper location creation
  try {
    // Placeholder - would need actual implementation
    return null;
  } catch (e) {
    return null;
  }
});

final updateParkingLocationProvider =
    FutureProvider.family<bool, ParkingLocation>((ref, location) async {
  // i'd implement proper location update
  try {
    // Placeholder - would need actual implementation
    return false;
  } catch (e) {
    return false;
  }
});

// Refresh trigger for real-time updates
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

void refreshAllData(WidgetRef ref) {
  ref.invalidate(allUsersProvider);
  ref.invalidate(allParkingLocationsProvider);
  ref.invalidate(allBookingsProvider);
  ref.invalidate(totalRevenueProvider);
  ref.invalidate(todayBookingsProvider);
  ref.invalidate(activeBookingsProvider);
  ref.read(refreshTriggerProvider.notifier).state++;
}
