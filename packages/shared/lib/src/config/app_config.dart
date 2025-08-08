import 'package:flutter/foundation.dart';


class AppConfig {
  static const String appName = 'WePark';
  static const String packageName = 'com.wepark.app';
  static const String version = '1.0.0';
  static const int buildNumber = 1;

  // Environment configuration
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => kReleaseMode;
  static bool get isProfile => kProfileMode;

  // API Base URLs
  static String get baseApiUrl {
    if (isDevelopment) {
      return 'http://localhost:3000/api';
    } else {
      return 'https://api.wepark.et';
    }
  }

  // Firebase project configuration
  static String get firebaseProjectId => 'wepark-smart-parking';

  // Supabase configuration
  static String get supabaseUrl {
    if (isDevelopment) {
      return 'https://dev-project.supabase.co';
    } else {
      return 'https://prod-project.supabase.co';
    }
  }

  static String get supabaseAnonKey {
    if (isDevelopment) {
      return 'dev-anon-key';
    } else {
      return 'prod-anon-key';
    }
  }

  // Google Maps API configuration
  static String get googleMapsApiKey {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'your-android-maps-key';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'your-ios-maps-key';
    } else {
      return 'your-web-maps-key';
    }
  }

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableRemoteConfig = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;
  static const bool enableBiometricAuth = true;
  static const bool enableLocationTracking = true;
  static const bool enablePaymentGateway = true;

  // Business logic configuration
  static const int maxBookingDurationHours = 24;
  static const int minBookingDurationMinutes = 30;
  static const int cancellationWindowMinutes = 30;
  static const int gracePeriodMinutes = 15;
  static const double latePenaltyRate = 0.1; // 10% penalty

  // Location configuration
  static const double defaultLatitude = 9.0054; // Addis Ababa
  static const double defaultLongitude = 38.7636;
  static const double searchRadiusKm = 5.0;
  static const int maxSearchResults = 50;

  // Cache configuration
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration imageCacheExpiration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Network configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Notification configuration
  static const String notificationChannelId = 'wepark_notifications';
  static const String notificationChannelName = 'WePark Notifications';
  static const String notificationChannelDescription =
      'Parking booking and location updates';

  // Security configuration
  static const Duration sessionTimeout = Duration(days: 30);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Pagination configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File upload configuration
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf'];

  // Currency configuration
  static const String defaultCurrency = 'ETB';
  static const String currencySymbol = 'Br';
  static const int currencyDecimalPlaces = 2;

  // Date/Time configuration
  static const String defaultTimeZone = 'Africa/Addis_Ababa';
  static const String defaultDateFormat = 'MMM dd, yyyy';
  static const String defaultTimeFormat = 'HH:mm';
  static const String defaultDateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Support configuration
  static const String supportEmail = 'support@wepark.et';
  static const String supportPhone = '+251911234567';
  static const String websiteUrl = 'https://wepark.et';
  static const String privacyPolicyUrl = 'https://wepark.et/privacy';
  static const String termsOfServiceUrl = 'https://wepark.et/terms';

  // Social media configuration
  static const String facebookUrl = 'https://facebook.com/wepark.et';
  static const String twitterUrl = 'https://twitter.com/wepark_et';
  static const String instagramUrl = 'https://instagram.com/wepark.et';
  static const String linkedinUrl = 'https://linkedin.com/company/wepark';

  // App store configuration
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';
  static const String appStoreUrl =
      'https://apps.apple.com/app/wepark/id123456789';

  // Deep linking configuration
  static const String deepLinkScheme = 'wepark';
  static const String deepLinkHost = 'app.wepark.et';

  // Analytics events configuration
  static const String analyticsUserProperty = 'user_type';
  static const String analyticsCustomDimension = 'parking_location';

  // Remote config keys
  static const String maintenanceModeKey = 'maintenance_mode';
  static const String minAppVersionKey = 'min_app_version';
  static const String forceUpdateKey = 'force_update';
  static const String paymentGatewayEnabledKey = 'payment_gateway_enabled';
  static const String realTimeTrackingEnabledKey = 'real_time_tracking_enabled';
  static const String maxBookingHoursKey = 'max_booking_hours';
  static const String cancellationWindowMinutesKey =
      'cancellation_window_minutes';
}

/// Environment-specific configuration
class EnvironmentConfig {
  static String get currentEnvironment {
    if (AppConfig.isDevelopment) return 'development';
    if (AppConfig.isProfile) return 'staging';
    return 'production';
  }

  static bool get enableLogging =>
      AppConfig.isDevelopment || AppConfig.isProfile;
  static bool get enableDebugMode => AppConfig.isDevelopment;
  static bool get enableStrictMode => AppConfig.isDevelopment;

  static String get logLevel {
    if (AppConfig.isDevelopment) return 'DEBUG';
    if (AppConfig.isProfile) return 'INFO';
    return 'ERROR';
  }
}
