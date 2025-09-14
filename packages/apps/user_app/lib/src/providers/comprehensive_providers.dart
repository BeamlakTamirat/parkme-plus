import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Comprehensive authentication service provider
final comprehensiveAuthProvider = Provider<ComprehensiveAuthService>((ref) {
  return ComprehensiveAuthService.instance;
});

/// Authentication state provider to trigger refreshes
final authStateProvider = StateProvider<String?>((ref) => null);

/// Current user provider (comprehensive) - now depends on auth state
final currentUserProvider = FutureProvider<User?>((ref) async {
  // Watch auth state to trigger refresh when it changes
  ref.watch(authStateProvider);

  final authService = ref.read(comprehensiveAuthProvider);
  return await authService.getCurrentUser();
});

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Check if user is authenticated - now depends on auth state
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  // Watch auth state to trigger refresh when it changes
  ref.watch(authStateProvider);

  final authService = ref.read(comprehensiveAuthProvider);
  return await authService.isLoggedIn();
});

/// Onboarding state provider
final isFirstTimeUserProvider = FutureProvider<bool>((ref) async {
  return true;
});

/// Complete onboarding provider
final completeOnboardingProvider =
    FutureProvider.family<void, bool>((ref, completed) async {
  await Future.delayed(const Duration(milliseconds: 100));
});

/// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// User profile provider
final userProfileProvider =
    FutureProvider.family<User?, String>((ref, userId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  final userData = await databaseService.getUser(userId);
  if (userData != null) {
    return User.fromDocument(userData);
  }
  return null;
});

/// Parking locations provider
final parkingLocationsProvider =
    FutureProvider<List<ParkingLocation>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllParkingLocations();
});

/// User bookings provider
final userBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, userId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getUserBookings(userId);
});

/// All bookings provider (admin only)
final allBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllBookings();
});

/// Database connection status provider
final databaseConnectionProvider = FutureProvider<bool>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.isConnected();
});

/// Provider to refresh user data
final refreshUserProvider = Provider<void>((ref) {
  // This provider can be used to trigger user data refresh
  ref.read(authStateProvider.notifier).state = DateTime.now().toIso8601String();
});

// ==================== ENHANCED BOOKING PROVIDERS ====================

/// Booking state provider to trigger refreshes
final bookingStateProvider = StateProvider<String?>((ref) => null);

/// Current booking provider - tracks the booking being created
final currentBookingProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Booking creation provider
final createBookingProvider =
    FutureProvider.family<BookingResult, Map<String, dynamic>>(
        (ref, bookingData) async {
  try {
    final databaseService = ref.read(databaseServiceProvider);
    final result = await databaseService.createBookingFromMap(bookingData);

    if (result.success) {
      // Refresh booking state
      ref.read(bookingStateProvider.notifier).state =
          DateTime.now().toIso8601String();
      // Clear current booking
      ref.read(currentBookingProvider.notifier).state = null;
    }

    return result;
  } catch (e) {
    return BookingResult.error('Failed to create booking: $e');
  }
});

/// Real-time active booking provider - shows current active booking with live updates
final activeBookingProvider = StreamProvider<Booking?>((ref) async* {
  final currentUser = await ref.read(currentUserProvider.future);
  if (currentUser == null) {
    yield null;
    return;
  }

  final databaseService = ref.read(databaseServiceProvider);
  
  // Subscribe to real-time booking updates and filter for active bookings
  await for (final bookings in databaseService.subscribeToUserBookings(currentUser.id)) {
    // Find active booking (status: 'active' or 'pending')
    final activeBooking = bookings
        .where((booking) =>
            booking.status == 'active' || booking.status == 'pending')
        .firstOrNull;
    
    yield activeBooking;
  }
});

/// Real-time booking history provider - shows all user bookings with live updates
final bookingHistoryProvider = StreamProvider<List<Booking>>((ref) async* {
  final currentUser = await ref.read(currentUserProvider.future);
  if (currentUser == null) {
    yield [];
    return;
  }

  final databaseService = ref.read(databaseServiceProvider);
  
  // Subscribe to real-time booking updates for the current user
  yield* databaseService.subscribeToUserBookings(currentUser.id);
});

/// Payment service provider
final paymentServiceProvider = Provider<ChapaPaymentService>((ref) {
  return ChapaPaymentService.instance;
});

/// Payment processing provider
final processPaymentProvider =
    FutureProvider.family<ChapaPaymentResult, Map<String, dynamic>>(
        (ref, paymentData) async {
  try {
    final paymentService = ref.read(paymentServiceProvider);
    return await paymentService.createParkingPayment(
      userId: paymentData['userId'],
      parkingLocationId: paymentData['parkingLocationId'],
      bookingId: paymentData['bookingId'],
      amount: paymentData['amount'],
      userEmail: paymentData['userEmail'],
      userName: paymentData['userName'],
      vehiclePlateNumber: paymentData['vehiclePlateNumber'],
    );
  } catch (e) {
    return ChapaPaymentResult.error('Payment processing failed: $e');
  }
});

/// Provider to refresh booking data
final refreshBookingProvider = Provider<void>((ref) {
  ref.read(bookingStateProvider.notifier).state =
      DateTime.now().toIso8601String();
});

/// Provider to clear current booking
final clearBookingProvider = Provider<void>((ref) {
  ref.read(currentBookingProvider.notifier).state = null;
});

/// Provider to get parking location name by ID
final parkingLocationNameProvider =
    FutureProvider.family<String?, String>((ref, locationId) async {
  try {
    final databaseService = ref.read(databaseServiceProvider);
    final locationData = await databaseService.getParkingLocation(locationId);
    if (locationData != null) {
      final location = ParkingLocation.fromDocument(locationData);
      return location.name;
    }
    return null;
  } catch (e) {
    return null;
  }
});
