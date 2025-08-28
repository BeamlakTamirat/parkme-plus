import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // 🐛 for kDebugMode
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
  try {
    if (kDebugMode) {
      print('👥 Creating user with data:');
      print('   Email: ${userData['email']}');
      print('   Full Name: ${userData['fullName']}');
      print('   Role: ${userData['role']}');
      print('   Phone: ${userData['phoneNumber'] ?? 'None'}');
    }

    // Validate required fields
    final email = userData['email'] as String?;
    final password = userData['password'] as String?;
    final fullName = userData['fullName'] as String?;
    final role = userData['role'] as String? ?? 'user';

    if (email == null || email.isEmpty) {
      throw Exception('Email is required');
    }
    if (password == null || password.isEmpty) {
      throw Exception('Password is required');
    }
    if (fullName == null || fullName.isEmpty) {
      throw Exception('Full name is required');
    }

    if (kDebugMode)
      print('🔐 Using ComprehensiveAuthService.createUserForAdmin...');

    // Use ComprehensiveAuthService.createUserForAdmin (NO session creation)
    final result = await ComprehensiveAuthService.instance.createUserForAdmin(
      email: email,
      password: password,
      fullName: fullName,
      role: role, // 🎯 Pass the role directly
      phoneNumber: userData['phoneNumber'] as String?,
      vehiclePlateNumber: userData['vehiclePlateNumber'] as String?,
      vehicleModel: userData['vehicleModel'] as String?,
      vehicleColor: userData['vehicleColor'] as String?,
    );

    if (result.success) {
      // 🎉 Role is already set correctly in createUserForAdmin
      if (kDebugMode) print('✅ User created successfully with role: $role');
      // Refresh the users list
      ref.invalidate(allUsersProvider);
      return result.user;
    } else {
      if (kDebugMode) print('❌ User creation failed: ${result.message}');
      throw Exception(result.message);
    }
  } catch (e) {
    if (kDebugMode) print('❌ Error creating user: $e');
    rethrow; // Re-throw so the UI can handle it
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
  try {
    if (kDebugMode) {
      print('🏢 Creating parking location with data:');
      print('   Name: ${locationData['name']}');
      print('   Address: ${locationData['address']}');
      print(
          '   Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      print('   Images: ${locationData['images']?.length ?? 0} images');
    }

    // Generate unique ID
    final locationId = DatabaseService.instance.generateId();

    // Create ParkingLocation object from the data
    final location = ParkingLocation(
      id: locationId,
      name: locationData['name'],
      address: locationData['address'],
      latitude: locationData['latitude'],
      longitude: locationData['longitude'],
      totalSpots: locationData['totalSpots'],
      availableSpots: locationData['availableSpots'],
      hourlyRate: locationData['hourlyRate'],
      isActive: locationData['isActive'] ?? true,
      description: locationData['description'],
      amenities: locationData['amenities'] != null
          ? List<String>.from(locationData['amenities'])
          : null,
      images: locationData['images'] != null
          ? List<String>.from(locationData['images'])
          : null,
      attendantId: locationData['attendantId'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 🔍 DETAILED DEBUGGING
    if (kDebugMode) {
      print('📊 Location object created:');
      print('   ID: ${location.id}');
      print('   Document data: ${location.toDocument()}');
    }

    // Use DatabaseService to create the location
    if (kDebugMode) {
      print('💾 Calling DatabaseService.createParkingLocation...');
    }
    final success =
        await DatabaseService.instance.createParkingLocation(location);

    if (success) {
      if (kDebugMode) print('✅ Location created successfully: ${location.id}');
      // Refresh the locations list
      ref.invalidate(allParkingLocationsProvider);
      return location;
    } else {
      if (kDebugMode) {
        print('❌ DatabaseService.createParkingLocation returned false');
        print('🔍 Check Appwrite console for errors');
        print('🔍 Verify collection permissions and database setup');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Error creating parking location: $e');
    return null;
  }
});

final updateParkingLocationProvider =
    FutureProvider.family<bool, ParkingLocation>((ref, location) async {
  try {
    if (kDebugMode) {
      print('🔄 Updating parking location: ${location.name}');
    }

    // Use DatabaseService to update the location
    final success =
        await DatabaseService.instance.updateParkingLocation(location);

    if (success) {
      if (kDebugMode) print('✅ Location updated successfully: ${location.id}');
      // Refresh the locations list
      ref.invalidate(allParkingLocationsProvider);
      return true;
    } else {
      if (kDebugMode) print('❌ Failed to update location in database');
      return false;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Error updating parking location: $e');
    return false;
  }
});

// 📊 NEW: Booking Status Update Provider
final updateBookingStatusProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  try {
    final bookingId = data['bookingId'] as String;
    final newStatus = data['newStatus'] as String;
    final paymentStatus = data['paymentStatus'] as String?;

    if (kDebugMode) {
      print('📊 Updating booking status:');
      print('   Booking ID: $bookingId');
      print('   New Status: $newStatus');
      if (paymentStatus != null) print('   Payment Status: $paymentStatus');
    }

    // Get the current booking from database
    final currentBookingData =
        await DatabaseService.instance.getBooking(bookingId);
    if (currentBookingData == null) {
      if (kDebugMode) print('❌ Booking not found: $bookingId');
      return false;
    }

    // Create updated booking object
    final currentBooking = Booking.fromDocument(currentBookingData);

    // Determine end time if completing the booking
    DateTime? endTime = currentBooking.endTime;
    if (newStatus == 'completed' && endTime == null) {
      endTime = DateTime.now();
      if (kDebugMode)
        print('⏰ Setting end time for completed booking: $endTime');
    }

    final updatedBooking = currentBooking.copyWith(
      status: newStatus,
      paymentStatus: paymentStatus ?? currentBooking.paymentStatus,
      endTime: endTime,
      updatedAt: DateTime.now(),
    );

    // Update in database
    final success =
        await DatabaseService.instance.updateBooking(updatedBooking);

    if (success) {
      if (kDebugMode) print('✅ Booking status updated successfully');
      // Refresh all booking-related providers
      ref.invalidate(allBookingsProvider);
      ref.invalidate(todayBookingsProvider);
      ref.invalidate(activeBookingsProvider);
      return true;
    } else {
      if (kDebugMode) print('❌ Failed to update booking in database');
      return false;
    }
  } catch (e) {
    if (kDebugMode) print('❌ Error updating booking status: $e');
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
