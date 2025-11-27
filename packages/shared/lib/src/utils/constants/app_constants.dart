class AppConstants {
  // App Information
  static const String appName = 'ParkMe+';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Smart Parking Solution';

  // Company Information
  static const String companyName = 'Ozone Technology PLC';
  static const String supportEmail = 'support@parkmeplus.et';
  static const String websiteUrl = 'https://parkmeplus.et';

  // URLs
  static const String privacyPolicyUrl = 'https://parkmeplus.et/privacy';
  static const String termsOfServiceUrl = 'https://parkmeplus.et/terms';
  static const String helpCenterUrl = 'https://help.parkmeplus.et';

  // Timing Constants
  static const int bookingReminderMinutes = 15;
  static const int maxBookingHours = 24;
  static const int minBookingMinutes = 30;
  static const int qrCodeExpiryMinutes = 5;

  // Validation Constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxFullNameLength = 50;
  static const int maxNotesLength = 200;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheExpiry = Duration(minutes: 10);
  static const Duration longCacheExpiry = Duration(hours: 1);

  // Ethiopian Currency
  static const String currencySymbol = 'ETB';
  static const String currencyCode = 'ETB';

  // Default Values
  static const double defaultLatitude = 9.0192; // Addis Ababa
  static const double defaultLongitude = 38.7525;
  static const int defaultSearchRadius = 5; // kilometers

  // File Upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // Phone Number
  static const String ethiopianCountryCode = '+251';
  static const String phoneNumberPattern = r'^(\+251|0)[1-9]\d{8}$';
}
