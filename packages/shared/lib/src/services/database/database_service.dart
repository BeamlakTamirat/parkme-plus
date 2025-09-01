import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../../config/appwrite_config.dart';
import '../../models/user/user.dart';
import '../../models/parking/parking_location.dart';
import '../../models/booking/booking.dart';

/// Comprehensive database service for WePark ecosystem
class DatabaseService {
  static DatabaseService? _instance;
  late final Databases _databases;

  DatabaseService._() {
    _databases = AppwriteConfig.databases;
  }

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // Database and collection IDs
  static const String _databaseId = 'wepark_db';
  static const String _usersCollectionId = 'users';
  static const String _parkingLocationsCollectionId = 'parking_locations';
  static const String _bookingsCollectionId = 'bookings';

  // ==================== USER OPERATIONS ====================

  /// Create a new user
  Future<bool> createUser(User user) async {
    try {
      await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: user.id,
        data: user.toDocument(),
      );
      if (kDebugMode) print('✅ User created: ${user.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating user: $e');
      return false;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: userId,
      );
      return document.data;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting user: $e');
      return null;
    }
  }

  /// Update user
  Future<bool> updateUser(User user) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: user.id,
        data: user.toDocument(),
      );
      if (kDebugMode) print('✅ User updated: ${user.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating user: $e');
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: userId,
      );
      if (kDebugMode) print('✅ User deleted: $userId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting user: $e');
      return false;
    }
  }

  /// Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
      );

      return response.documents
          .map((doc) => User.fromDocument(doc.data))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error getting all users: $e');
      return [];
    }
  }

  // ==================== PARKING LOCATION OPERATIONS ====================

  /// Create a new parking location
  Future<bool> createParkingLocation(ParkingLocation location) async {
    try {
      await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _parkingLocationsCollectionId,
        documentId: location.id,
        data: location.toDocument(),
      );
      if (kDebugMode) print('✅ Parking location created: ${location.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating parking location: $e');
      return false;
    }
  }

  /// Get parking location by ID
  Future<Map<String, dynamic>?> getParkingLocation(String locationId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _parkingLocationsCollectionId,
        documentId: locationId,
      );
      return document.data;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting parking location: $e');
      return null;
    }
  }

  /// Update parking location
  Future<bool> updateParkingLocation(ParkingLocation location) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _parkingLocationsCollectionId,
        documentId: location.id,
        data: location.toDocument(),
      );
      if (kDebugMode) print('✅ Parking location updated: ${location.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating parking location: $e');
      return false;
    }
  }

  /// Delete parking location
  Future<bool> deleteParkingLocation(String locationId) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _parkingLocationsCollectionId,
        documentId: locationId,
      );
      if (kDebugMode) print('✅ Parking location deleted: $locationId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting parking location: $e');
      return false;
    }
  }

  /// Get all parking locations
  Future<List<ParkingLocation>> getAllParkingLocations() async {
    try {
      if (kDebugMode) print('🔍 Fetching parking locations from database...');

      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _parkingLocationsCollectionId,
      );

      if (kDebugMode) {
        print('📋 Found ${response.documents.length} parking documents');
      }

      final locations = response.documents
          .map((doc) => ParkingLocation.fromDocument(doc.data))
          .where((location) => location.isActive)
          .toList();

      if (kDebugMode) {
        print('✅ Returning ${locations.length} active parking locations');
        for (var location in locations) {
          print(
              '   - ${location.name} (${location.availableSpots}/${location.totalSpots} spots)');
        }
      }

      return locations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting parking locations: $e');
        print('🔍 Database ID: $_databaseId');
        print('🔍 Collection ID: $_parkingLocationsCollectionId');
        print(
            '💡 Make sure your Appwrite database and collections are set up correctly');
      }
      return [];
    }
  }

  /// Get parking locations by attendant
  Future<List<ParkingLocation>> getParkingLocationsByAttendant(
      String attendantId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _parkingLocationsCollectionId,
        queries: [
          Query.equal('attendantId', attendantId),
          Query.equal('isActive', true),
        ],
      );

      return response.documents
          .map((doc) => ParkingLocation.fromDocument(doc.data))
          .toList();
    } catch (e) {
      if (kDebugMode)
        print('❌ Error getting parking locations by attendant: $e');
      return [];
    }
  }

  // ==================== BOOKING OPERATIONS ====================

  /// Create a new booking
  Future<bool> createBooking(Booking booking) async {
    try {
      await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: booking.id,
        data: booking.toDocument(),
      );
      if (kDebugMode) print('✅ Booking created: ${booking.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating booking: $e');
      return false;
    }
  }

  /// Create a new booking from map data
  Future<BookingResult> createBookingFromMap(
      Map<String, dynamic> bookingData) async {
    try {
      if (kDebugMode)
        print('🎫 Creating booking from data: ${bookingData.keys}');

      // Generate unique ID for the booking
      final bookingId = bookingData['id'] ?? ID.unique();
      final spotNumber =
          'A${DateTime.now().millisecondsSinceEpoch % 100}'; // Generate spot number

      // Handle DateTime conversion properly
      DateTime startTime = DateTime.now();
      DateTime? endTime;

      if (bookingData['startTime'] is DateTime) {
        startTime = bookingData['startTime'];
      } else if (bookingData['startTime'] is String) {
        startTime = DateTime.parse(bookingData['startTime']);
      }

      if (bookingData['endTime'] is DateTime) {
        endTime = bookingData['endTime'];
      } else if (bookingData['endTime'] is String) {
        endTime = DateTime.parse(bookingData['endTime']);
      }

      // Create Booking object from map data
      final booking = Booking(
        id: bookingId,
        userId: bookingData['userId'] ?? '',
        parkingLocationId: bookingData['parkingLocationId'] ?? '',
        spotNumber: spotNumber,
        vehiclePlateNumber: bookingData['vehiclePlateNumber'] ?? 'N/A',
        vehicleModel: bookingData['vehicleModel'],
        vehicleColor: bookingData['vehicleColor'],
        startTime: startTime,
        endTime: endTime,
        totalAmount: (bookingData['totalAmount'] ?? 0.0).toDouble(),
        status: 'pending', //  Start as pending until attendant check-in
        paymentStatus:
            'paid', // Set as paid since this is called after payment success
        qrCode: 'booking:$bookingId', // Match attendant scanner format
        paymentMethod: bookingData['paymentMethod'],
        transactionId: bookingData['transactionId'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: bookingData['metadata'],
      );

      await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
        data: booking.toDocument(),
      );

      if (kDebugMode) print('✅ Booking created: $bookingId');
      return BookingResult.success(
        booking: booking,
        message: 'Booking created successfully',
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error creating booking: $e');
      return BookingResult.error(
        'Failed to create booking',
        error: e.toString(),
      );
    }
  }

  /// Get booking by ID
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
      );
      return document.data;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting booking: $e');
      return null;
    }
  }

  /// Update booking
  Future<bool> updateBooking(Booking booking) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: booking.id,
        data: booking.toDocument(),
      );
      if (kDebugMode) print('✅ Booking updated: ${booking.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating booking: $e');
      return false;
    }
  }

  /// Delete booking
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        documentId: bookingId,
      );
      if (kDebugMode) print('✅ Booking deleted: $bookingId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting booking: $e');
      return false;
    }
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      // Sort by createdAt descending
      final bookings = response.documents
          .map((doc) => Booking.fromDocument(doc.data))
          .toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting user bookings: $e');
      return [];
    }
  }

  /// Get active bookings for a parking location
  Future<List<Booking>> getActiveBookingsForLocation(String locationId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal('parkingLocationId', locationId),
          Query.equal('status', 'active'),
        ],
      );

      return response.documents
          .map((doc) => Booking.fromDocument(doc.data))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error getting active bookings for location: $e');
      return [];
    }
  }

  /// Get all bookings (admin only)
  Future<List<Booking>> getAllBookings() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
      );

      // Sort by createdAt descending
      final bookings = response.documents
          .map((doc) => Booking.fromDocument(doc.data))
          .toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting all bookings: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Generate unique ID
  String generateId() {
    return ID.unique();
  }

  /// Check if database is connected
  Future<bool> isConnected() async {
    try {
      await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Database connection error: $e');
      return false;
    }
  }
}
