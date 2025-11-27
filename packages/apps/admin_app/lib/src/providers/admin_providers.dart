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

    if (kDebugMode) {
      print('🔐 Using ComprehensiveAuthService.createUserForAdmin...');
    }

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

/// Update user provider with comprehensive validation and real-time updates
final updateUserProvider = FutureProvider.family<bool, User>((ref, user) async {
  try {
    if (kDebugMode) {
      print('🔄 Starting user update process for: ${user.fullName}');
      print('   User ID: ${user.id}');
      print('   Email: ${user.email}');
      print('   Role: ${user.role}');
      print('   Phone: ${user.phoneNumber ?? 'None'}');
    }

    final databaseService = ref.read(databaseServiceProvider);
    
    // Perform the actual update
    final success = await databaseService.updateUser(user);
    
    if (success) {
      if (kDebugMode) {
        print('✅ User update completed successfully');
      }
      
      // Trigger real-time UI updates
      ref.invalidate(allUsersProvider);
      ref.invalidate(usersByRoleProvider);
      ref.read(refreshTriggerProvider.notifier).state++;
      
      return true;
    } else {
      throw Exception('Database update failed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error updating user: $e');
    }
    rethrow; // Re-throw so the UI can handle the specific error
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
      if (kDebugMode) {
        print('⏰ Setting end time for completed booking: $endTime');
      }
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

/// Delete user provider with comprehensive validation and real-time updates
final deleteUserProvider = FutureProvider.family<bool, String>((ref, userId) async {
  try {
    if (kDebugMode) {
      print('🗑️ Starting user deletion process for ID: $userId');
    }

    final databaseService = ref.read(databaseServiceProvider);
    
    // Step 1: Get user details before deletion for logging
    final userData = await databaseService.getUser(userId);
    if (userData == null) {
      throw Exception('User not found');
    }

    final user = User.fromDocument(userData);

    if (kDebugMode) {
      print('👤 Deleting user: ${user.fullName} (${user.email}) - Role: ${user.role}');
    }

    // Step 2: Check for active bookings (prevent deletion if user has active bookings)
    final allBookings = await databaseService.getAllBookings();
    final userActiveBookings = allBookings
        .where((booking) => booking.userId == userId && booking.status == 'active')
        .toList();

    if (userActiveBookings.isNotEmpty) {
      throw Exception('Cannot delete user with ${userActiveBookings.length} active booking(s). Please complete or cancel active bookings first.');
    }

    // Step 3: Handle user role-specific cleanup
    if (user.role == 'attendant') {
      // Check if attendant is assigned to any locations
      final allLocations = await databaseService.getAllParkingLocations();
      final assignedLocations = allLocations
          .where((location) => location.attendantId == userId)
          .toList();

      if (assignedLocations.isNotEmpty) {
        // Unassign attendant from locations
        for (final location in assignedLocations) {
          final updatedLocation = location.copyWith(
            attendantId: null,
            updatedAt: DateTime.now(),
          );
          await databaseService.updateParkingLocation(updatedLocation);
          if (kDebugMode) {
            print('📍 Unassigned attendant from location: ${location.name}');
          }
        }
      }
    }

    // Step 4: Perform the actual deletion
    final success = await databaseService.deleteUser(userId);
    
    if (success) {
      if (kDebugMode) {
        print('✅ User deletion completed successfully');
      }
      
      // Step 5: Trigger real-time UI updates
      ref.invalidate(allUsersProvider);
      ref.invalidate(usersByRoleProvider);
      ref.invalidate(allParkingLocationsProvider); // In case attendant was unassigned
      ref.read(refreshTriggerProvider.notifier).state++;
      
      return true;
    } else {
      throw Exception('Failed to delete user from database');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error deleting user: $e');
    }
    rethrow;
  }
});

/// Delete parking location provider with dependency validation and real-time updates
final deleteParkingLocationProvider = FutureProvider.family<bool, String>((ref, locationId) async {
  try {
    if (kDebugMode) {
      print('🗑️ Starting location deletion process for ID: $locationId');
    }

    final databaseService = ref.read(databaseServiceProvider);
    
    // Step 1: Get location details before deletion
    final locationData = await databaseService.getParkingLocation(locationId);
    if (locationData == null) {
      throw Exception('Parking location not found');
    }

    final location = ParkingLocation.fromDocument(locationData);

    if (kDebugMode) {
      print('📍 Deleting location: ${location.name} (${location.address})');
    }

    // Step 2: Check for active bookings at this location
    final allBookings = await databaseService.getAllBookings();
    final locationActiveBookings = allBookings
        .where((booking) => booking.parkingLocationId == locationId && 
               (booking.status == 'active' || booking.status == 'confirmed'))
        .toList();

    if (locationActiveBookings.isNotEmpty) {
      throw Exception('Cannot delete location with ${locationActiveBookings.length} active/confirmed booking(s). Please complete or cancel all bookings first.');
    }

    // Step 3: Check for future bookings (within next 24 hours)
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final futureBookings = allBookings
        .where((booking) => 
            booking.parkingLocationId == locationId && 
            booking.startTime.isAfter(now) && 
            booking.startTime.isBefore(tomorrow))
        .toList();

    if (futureBookings.isNotEmpty) {
      throw Exception('Cannot delete location with ${futureBookings.length} upcoming booking(s) in the next 24 hours. Please reschedule or cancel these bookings first.');
    }

    // Step 4: Handle assigned attendant
    if (location.attendantId != null) {
      if (kDebugMode) {
        print('👤 Location has assigned attendant: ${location.attendantId}');
        print('ℹ️  Attendant will be unassigned but not deleted');
      }
    }

    // Step 5: Perform the actual deletion
    final success = await databaseService.deleteParkingLocation(locationId);
    
    if (success) {
      if (kDebugMode) {
        print('✅ Location deletion completed successfully');
      }
      
      // Step 6: Trigger real-time UI updates
      ref.invalidate(allParkingLocationsProvider);
      ref.invalidate(allBookingsProvider); // In case any bookings were affected
      ref.read(refreshTriggerProvider.notifier).state++;
      
      return true;
    } else {
      throw Exception('Failed to delete location from database');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error deleting location: $e');
    }
    rethrow;
  }
});
