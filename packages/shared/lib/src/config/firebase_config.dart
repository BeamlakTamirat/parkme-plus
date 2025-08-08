import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration and initialization for WePark
class FirebaseConfig {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseMessaging? _messaging;
  static FirebaseAnalytics? _analytics;

  // Firebase project configuration
  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: '1:your-project-number:android:app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'wepark-smart-parking',
    storageBucket: 'wepark-smart-parking.appspot.com',
  );

  static const FirebaseOptions iosOptions = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: '1:your-project-number:ios:app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'wepark-smart-parking',
    storageBucket: 'wepark-smart-parking.appspot.com',
    iosBundleId: 'com.example.wepark',
  );

  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'your-web-api-key',
    appId: '1:your-project-number:web:app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'wepark-smart-parking',
    authDomain: 'wepark-smart-parking.firebaseapp.com',
    storageBucket: 'wepark-smart-parking.appspot.com',
  );

  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    if (_app != null) return; // Already initialized

    FirebaseOptions? options;

    if (defaultTargetPlatform == TargetPlatform.android) {
      options = androidOptions;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      options = iosOptions;
    } else if (kIsWeb) {
      options = webOptions;
    }

    if (options != null) {
      _app = await Firebase.initializeApp(options: options);
    } else {
      _app = await Firebase.initializeApp();
    }

    await _initializeServices();
  }

  /// Initialize Firebase services
  static Future<void> _initializeServices() async {
    // Initialize Firebase Auth
    _auth = FirebaseAuth.instance;

    // Initialize Firestore
    _firestore = FirebaseFirestore.instance;
    await _configureFirestore();

    // Initialize Firebase Messaging
    _messaging = FirebaseMessaging.instance;
    await _configureMessaging();

    // Initialize Analytics
    _analytics = FirebaseAnalytics.instance;
    await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);
  }

  /// Configure Firestore settings
  static Future<void> _configureFirestore() async {
    if (kDebugMode) {
      try {
        _firestore!.useFirestoreEmulator('localhost', 8080);
      } catch (e) {
        // Emulator not available, continue with production
        if (kDebugMode) print('Firestore emulator not available: $e');
      }
    }

    // Enable offline persistence (deprecated but still works)
    try {
      await _firestore!.enablePersistence();
    } catch (e) {
      if (kDebugMode) print('Could not enable persistence: $e');
    }
  }

  /// Configure Firebase Messaging
  static Future<void> _configureMessaging() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) print('Messaging setup failed: $e');
    }
  }

  // Getters for Firebase services
  static FirebaseApp get app => _app!;
  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseMessaging get messaging => _messaging!;
  static FirebaseAnalytics get analytics => _analytics!;
}

/// Firestore collection and field names
class FirestoreCollections {
  // Main Collections
  static const String users = 'users';
  static const String parkingLocations = 'parking_locations';
  static const String parkingSpots = 'parking_spots';
  static const String bookings = 'bookings';
  static const String vehicles = 'vehicles';
  static const String payments = 'payments';
  static const String notifications = 'notifications';
  static const String reviews = 'reviews';
  static const String analytics = 'analytics';
  static const String settings = 'settings';
}

/// Firestore field names for consistent referencing
class FirestoreFields {
  // Common fields
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isActive = 'is_active';

  // User fields
  static const String email = 'email';
  static const String fullName = 'full_name';
  static const String phoneNumber = 'phone_number';
  static const String profileImageUrl = 'profile_image_url';
  static const String role = 'role';

  // Location fields
  static const String name = 'name';
  static const String address = 'address';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String totalSpots = 'total_spots';
  static const String availableSpots = 'available_spots';
  static const String hourlyRate = 'hourly_rate';

  // Booking fields
  static const String userId = 'user_id';
  static const String parkingLocationId = 'parking_location_id';
  static const String parkingSpotId = 'parking_spot_id';
  static const String vehicleId = 'vehicle_id';
  static const String startTime = 'start_time';
  static const String endTime = 'end_time';
  static const String status = 'status';
  static const String totalAmount = 'total_amount';
  static const String paymentId = 'payment_id';

  // Payment fields
  static const String bookingId = 'booking_id';
  static const String amount = 'amount';
  static const String currency = 'currency';
  static const String paymentMethod = 'payment_method';
  static const String paymentStatus = 'payment_status';
  static const String transactionId = 'transaction_id';
}

/// Firebase Analytics Events
class AnalyticsEvents {
  static const String login = 'login';
  static const String signUp = 'sign_up';
  static const String searchParking = 'search_parking';
  static const String viewParkingLocation = 'view_parking_location';
  static const String startBooking = 'start_booking';
  static const String completeBooking = 'complete_booking';
  static const String cancelBooking = 'cancel_booking';
  static const String makePayment = 'make_payment';
  static const String paymentSuccess = 'payment_success';
  static const String paymentFailed = 'payment_failed';
}
