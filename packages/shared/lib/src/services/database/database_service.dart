import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../config/appwrite_config.dart';
import '../../models/user/user.dart';
import '../../models/parking/parking_location.dart';
import '../../models/booking/booking.dart';

/// Comprehensive database service for WePark ecosystem
class DatabaseService {
  static DatabaseService? _instance;
  late final Databases _databases;
  late final Realtime _realtime;
  
  // Stream controllers for real-time updates
  final Map<String, StreamController<Booking>> _bookingStreamControllers = {};
  final StreamController<List<Booking>> _userBookingsStreamController = 
      StreamController<List<Booking>>.broadcast();
  
  RealtimeSubscription? _userBookingsSubscription;

  DatabaseService._() {
    _databases = AppwriteConfig.databases;
    _realtime = Realtime(AppwriteConfig.client);
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
      
      //  Generate proper spot number using attendant app logic
      final spotNumber = await _generateAvailableSpotNumber(bookingData['parkingLocationId']);

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

      if (kDebugMode) {
        print('🔍 DATABASE SERVICE - Transaction ID Debug:');
        print('   Raw transactionId from bookingData: ${bookingData['transactionId']}');
        print('   Type: ${bookingData['transactionId'].runtimeType}');
        print('   Is null: ${bookingData['transactionId'] == null}');
        print('   Is empty: ${bookingData['transactionId'] == ""}');
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

      if (kDebugMode) {
        print('🔍 BOOKING OBJECT - Transaction ID: ${booking.transactionId}');
        print('🔍 DOCUMENT DATA: ${booking.toDocument()}');
      }

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

  /// Generate available spot number using proper A1-A20, B1-B20, C1-C20 system
  Future<String> _generateAvailableSpotNumber(String locationId) async {
    try {
      // Get all active bookings for this location
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.equal('parkingLocationId', locationId),
          Query.equal('status', ['pending', 'active']), // Only check occupied spots
        ],
      );

      // Get occupied spot numbers
      final occupiedSpots = response.documents
          .map((doc) => doc.data['spotNumber'] as String?)
          .where((spot) => spot != null)
          .cast<String>()
          .toSet();

      if (kDebugMode) {
        print(' Occupied spots for location $locationId: $occupiedSpots');
      }

      // Generate spot numbers in proper sequence: A1-A20, B1-B20, C1-C20, etc.
      for (int index = 1; index <= 200; index++) { // Support up to 200 spots (10 sections)
        final letter = String.fromCharCode(65 + ((index - 1) ~/ 20)); // A, B, C...
        final number = ((index - 1) % 20) + 1; // 1-20
        final spotNumber = '$letter$number';

        if (!occupiedSpots.contains(spotNumber)) {
          if (kDebugMode) {
            print(' Assigned available spot: $spotNumber');
          }
          return spotNumber;
        }
      }

      // Fallback if all spots are occupied (shouldn't happen with 200 spots)
      final fallbackSpot = 'Z${DateTime.now().millisecondsSinceEpoch % 100}';
      if (kDebugMode) {
        print(' All spots occupied, using fallback: $fallbackSpot');
      }
      return fallbackSpot;

    } catch (e) {
      if (kDebugMode) {
        print(' Error generating spot number: $e');
      }
      // Fallback to A1 if there's an error
      return 'A1';
    }
  }

  /// Get all bookings for a specific user
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

  /// Check and expire bookings that have passed their end time without check-in/out
  Future<List<Booking>> expireOverdueBookings() async {
    try {
      if (kDebugMode) print('🕐 Checking for overdue bookings...');

      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookingsCollectionId,
        queries: [
          Query.notEqual('status', 'completed'),
          Query.notEqual('status', 'cancelled'),
          Query.notEqual('status', 'expired'),
        ],
      );

      final now = DateTime.now();
      final expiredBookings = <Booking>[];

      for (final doc in response.documents) {
        final booking = Booking.fromDocument(doc.data);

        // Check if booking has passed its end time
        if (booking.endTime != null && now.isAfter(booking.endTime!)) {
          // Only expire if not checked in or if checked in but past end time
          if (booking.status == 'pending' ||
              (booking.status == 'active' && now.isAfter(booking.endTime!))) {
            final expiredBooking = booking.copyWith(
              status: 'expired',
              updatedAt: now,
            );

            final success = await updateBooking(expiredBooking);
            if (success) {
              expiredBookings.add(expiredBooking);
              if (kDebugMode) {
                print(
                    '⏰ Expired booking: ${booking.id} (${booking.vehiclePlateNumber})');
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print('✅ Expired ${expiredBookings.length} overdue bookings');
      }

      return expiredBookings;
    } catch (e) {
      if (kDebugMode) print('❌ Error expiring overdue bookings: $e');
      return [];
    }
  }

  /// Get booking by QR code
  Future<Booking?> getBookingByQRCode(String qrCode) async {
    try {
      // Extract booking ID from QR code format: "booking:{bookingId}"
      if (!qrCode.startsWith('booking:')) {
        if (kDebugMode) print('❌ Invalid QR code format: $qrCode');
        return null;
      }

      final bookingId = qrCode.substring(8);
      final bookingData = await getBooking(bookingId);

      if (bookingData != null) {
        return Booking.fromDocument(bookingData);
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting booking by QR code: $e');
      return null;
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

  // ==================== REAL-TIME SUBSCRIPTION METHODS ====================

  /// Subscribe to real-time updates for a specific user's bookings
  Stream<List<Booking>> subscribeToUserBookings(String userId) {
    if (kDebugMode) print('🔔 Subscribing to real-time booking updates for user: $userId');
    
    // Cancel existing subscription if any
    _userBookingsSubscription?.close();
    
    // Create subscription for the bookings collection with user filter
    _userBookingsSubscription = _realtime.subscribe([
      'databases.$_databaseId.collections.$_bookingsCollectionId.documents'
    ]);
    
    _userBookingsSubscription!.stream.listen(
      (response) async {
        if (kDebugMode) print('📡 Real-time booking update received: ${response.events}');
        
        try {
          // Fetch updated user bookings and emit to stream
          final updatedBookings = await getUserBookings(userId);
          _userBookingsStreamController.add(updatedBookings);
          
          if (kDebugMode) {
            print('✅ Emitted ${updatedBookings.length} updated bookings to stream');
          }
        } catch (e) {
          if (kDebugMode) print('❌ Error processing real-time booking update: $e');
          _userBookingsStreamController.addError(e);
        }
      },
      onError: (error) {
        if (kDebugMode) print('❌ Real-time subscription error: $error');
        _userBookingsStreamController.addError(error);
      },
    );
    
    // Initial data fetch
    getUserBookings(userId).then((bookings) {
      _userBookingsStreamController.add(bookings);
    }).catchError((error) {
      _userBookingsStreamController.addError(error);
    });
    
    return _userBookingsStreamController.stream;
  }

  /// Subscribe to real-time updates for a specific booking
  Stream<Booking> subscribeToBooking(String bookingId) {
    if (kDebugMode) print('🔔 Subscribing to real-time updates for booking: $bookingId');
    
    // Create or get existing stream controller for this booking
    if (!_bookingStreamControllers.containsKey(bookingId)) {
      _bookingStreamControllers[bookingId] = StreamController<Booking>.broadcast();
    }
    
    final streamController = _bookingStreamControllers[bookingId]!;
    
    // Create subscription for the specific booking document
    final subscription = _realtime.subscribe([
      'databases.$_databaseId.collections.$_bookingsCollectionId.documents.$bookingId'
    ]);
    
    subscription.stream.listen(
      (response) async {
        if (kDebugMode) print('📡 Real-time update for booking $bookingId: ${response.events}');
        
        try {
          // Fetch updated booking data
          final bookingData = await getBooking(bookingId);
          if (bookingData != null) {
            final updatedBooking = Booking.fromDocument(bookingData);
            streamController.add(updatedBooking);
            
            if (kDebugMode) {
              print('✅ Emitted updated booking status: ${updatedBooking.status}');
            }
          }
        } catch (e) {
          if (kDebugMode) print('❌ Error processing real-time booking update: $e');
          streamController.addError(e);
        }
      },
      onError: (error) {
        if (kDebugMode) print('❌ Real-time subscription error for booking $bookingId: $error');
        streamController.addError(error);
      },
    );
    
    // Initial data fetch
    getBooking(bookingId).then((bookingData) {
      if (bookingData != null) {
        final booking = Booking.fromDocument(bookingData);
        streamController.add(booking);
      }
    }).catchError((error) {
      streamController.addError(error);
    });
    
    return streamController.stream;
  }

  /// Unsubscribe from user bookings updates
  void unsubscribeFromUserBookings() {
    if (kDebugMode) print('🔕 Unsubscribing from user bookings updates');
    _userBookingsSubscription?.close();
    _userBookingsSubscription = null;
  }

  /// Unsubscribe from a specific booking updates
  void unsubscribeFromBooking(String bookingId) {
    if (kDebugMode) print('🔕 Unsubscribing from booking updates: $bookingId');
    _bookingStreamControllers[bookingId]?.close();
    _bookingStreamControllers.remove(bookingId);
  }

  /// Clean up all real-time subscriptions
  void dispose() {
    if (kDebugMode) print('🧹 Disposing database service and cleaning up subscriptions');
    
    _userBookingsSubscription?.close();
    _userBookingsStreamController.close();
    
    for (final controller in _bookingStreamControllers.values) {
      controller.close();
    }
    _bookingStreamControllers.clear();
  }
}
