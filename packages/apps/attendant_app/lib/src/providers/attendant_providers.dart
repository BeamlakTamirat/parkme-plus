import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

// Auth providers
final attendantAuthServiceProvider = Provider<ComprehensiveAuthService>((ref) {
  return ComprehensiveAuthService.instance;
});

final currentAttendantProvider = FutureProvider<User?>((ref) async {
  final authService = ref.read(attendantAuthServiceProvider);
  return await authService.getCurrentUser();
});

final isAttendantAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentAttendantProvider.future);
  // Temporarily allow any authenticated user for testing
  return user != null; // && user.role == 'attendant';
});

// Database providers
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

// Attendant location provider - gets the parking location assigned to current attendant
final attendantLocationProvider = FutureProvider<ParkingLocation?>((ref) async {
  final currentUser = await ref.watch(currentAttendantProvider.future);
  if (currentUser == null) {
    if (kDebugMode) print('🚨 No current user found');
    return null;
  }

  if (kDebugMode) print('👤 Current attendant ID: ${currentUser.id}');
  if (kDebugMode) print('👤 Current attendant name: ${currentUser.fullName}');

  final databaseService = ref.read(databaseServiceProvider);
  final allLocations = await databaseService.getAllParkingLocations();

  if (kDebugMode) print('📍 Total locations found: ${allLocations.length}');

  // Debug: Show all locations and their attendant assignments
  for (final location in allLocations) {
    if (kDebugMode) print('🏢 Location: ${location.name}');
    if (kDebugMode) print('   - ID: ${location.id}');
    if (kDebugMode) print('   - AttendantId: "${location.attendantId}"');
    if (kDebugMode) print('   - Match: ${location.attendantId == currentUser.id}');
  }

  // Find location where this attendant is assigned
  for (final location in allLocations) {
    if (location.attendantId == currentUser.id) {
      if (kDebugMode) print('✅ Found assigned location: ${location.name}');
      return location;
    }
  }
  if (kDebugMode) print('❌ No location assigned to this attendant');

  // TEMPORARY FIX: For testing, assign attendant to first available location
  if (allLocations.isNotEmpty) {
    final testLocation = allLocations.first;
    if (kDebugMode) {
      print(
          '🔧 TEMP FIX: Using first location for testing: ${testLocation.name}');
    }
    return testLocation;
  }

  return null;
});
// Bookings for attendant's location
final attendantBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final location = await ref.watch(attendantLocationProvider.future);
  if (location == null) {
    if (kDebugMode) print('📋 No assigned location, returning empty bookings list');
    return [];
  }

  if (kDebugMode) {
    print(
        '📋 Fetching bookings for location: ${location.name} (ID: ${location.id})');
  }

  final databaseService = ref.read(databaseServiceProvider);
  final allBookings = await databaseService.getAllBookings();

  if (kDebugMode) print('📋 Total bookings in database: ${allBookings.length}');

  // Filter bookings for this location
  final filteredBookings = allBookings
      .where((booking) => booking.parkingLocationId == location.id)
      .toList();

  if (kDebugMode) print('📋 Bookings for this location: ${filteredBookings.length}');

  // Debug: Show all bookings and their location assignments
  for (final booking in allBookings) {
    if (kDebugMode) print('🎫 Booking ID: ${booking.id}');
    if (kDebugMode) print('   - LocationId: "${booking.parkingLocationId}"');
    if (kDebugMode) print('   - Match: ${booking.parkingLocationId == location.id}');
  }

  return filteredBookings;
});

// Active bookings only (for QR scanning)
final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final allBookings = await ref.watch(attendantBookingsProvider.future);
  return allBookings
      .where((booking) =>
          booking.status == 'active' || booking.status == 'pending')
      .toList();
});

// Update booking status
final updateBookingStatusProvider =
    FutureProvider.family<bool, Booking>((ref, booking) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.updateBooking(booking);
});

// Refresh trigger for real-time updates
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

void refreshData(WidgetRef ref) {
  ref.invalidate(attendantBookingsProvider);
  ref.invalidate(activeBookingsProvider);
  ref.invalidate(attendantLocationProvider);
  ref.read(refreshTriggerProvider.notifier).state++;
}
