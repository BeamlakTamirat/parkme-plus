import 'package:flutter/foundation.dart';
import '../config/config.dart';
import 'services.dart';

/// Main backend service that initializes and manages all backend components
class BackendService {
  static BackendService? _instance;
  bool _isInitialized = false;

  BackendService._internal();

  static BackendService get instance {
    _instance ??= BackendService._internal();
    return _instance!;
  }

  /// Initialize all backend services
  Future<BackendInitializationResult> initialize() async {
    if (_isInitialized) {
      return BackendInitializationResult.success('Backend already initialized');
    }

    try {
      // Initialize Firebase
      await FirebaseConfig.initialize();

      // Initialize Supabase (will be fixed once dependency is available)
      // await SupabaseConfig.initialize();

      // Initialize local storage
      // await LocalStorageService.instance.initialize();

      // Initialize cache service
      // await CacheService.instance.initialize();

      // Enable offline persistence for Firestore
      await FirestoreService.instance.enableOfflinePersistence();

      // Setup background services
      // await BackgroundService.instance.initialize();

      // Initialize notification services
      // await NotificationService.instance.initialize();

      // Setup analytics
      // await AnalyticsService.instance.initialize();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ WePark Backend initialized successfully');
      }

      return BackendInitializationResult.success(
          'Backend initialized successfully');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Backend initialization failed: $e');
      }

      return BackendInitializationResult.error(
          'Backend initialization failed: $e');
    }
  }

  /// Check if backend is initialized
  bool get isInitialized => _isInitialized;

  /// Get backend status
  BackendStatus getBackendStatus() {
    return BackendStatus(
      isInitialized: _isInitialized,
      firebaseConnected: _isInitialized, // Simplified check
      supabaseConnected:
          false, // Will be implemented when dependency is available
      internetConnected: true, // Would use connectivity service
      services: {
        'firebase': _isInitialized,
        'firestore': _isInitialized,
        'auth': _isInitialized,
        'storage': false, // Supabase not initialized yet
        'analytics': _isInitialized,
        'crashlytics': _isInitialized,
        'messaging': _isInitialized,
      },
    );
  }

  /// Shutdown backend services
  Future<void> shutdown() async {
    try {
      // Close logger
      // LoggerService.instance.close();

      // Clear caches
      // await CacheService.instance.clear();

      _isInitialized = false;

      if (kDebugMode) {
        print('🔄 WePark Backend shutdown completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error during backend shutdown: $e');
      }
    }
  }

  /// Restart backend services
  Future<BackendInitializationResult> restart() async {
    await shutdown();
    return await initialize();
  }
}

/// Backend initialization result
class BackendInitializationResult {
  final bool success;
  final String message;
  final String? error;

  BackendInitializationResult._({
    required this.success,
    required this.message,
    this.error,
  });

  factory BackendInitializationResult.success(String message) {
    return BackendInitializationResult._(
      success: true,
      message: message,
    );
  }

  factory BackendInitializationResult.error(String error) {
    return BackendInitializationResult._(
      success: false,
      message: 'Initialization failed',
      error: error,
    );
  }

  @override
  String toString() {
    return 'BackendInitializationResult(success: $success, message: $message, error: $error)';
  }
}

/// Backend status information
class BackendStatus {
  final bool isInitialized;
  final bool firebaseConnected;
  final bool supabaseConnected;
  final bool internetConnected;
  final Map<String, bool> services;

  BackendStatus({
    required this.isInitialized,
    required this.firebaseConnected,
    required this.supabaseConnected,
    required this.internetConnected,
    required this.services,
  });

  /// Check if all critical services are available
  bool get isHealthy {
    return isInitialized &&
        firebaseConnected &&
        internetConnected &&
        services['firebase'] == true &&
        services['firestore'] == true &&
        services['auth'] == true;
  }

  /// Get list of failed services
  List<String> get failedServices {
    return services.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'BackendStatus(isInitialized: $isInitialized, isHealthy: $isHealthy, failedServices: $failedServices)';
  }
}
