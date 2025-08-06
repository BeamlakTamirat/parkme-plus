class UserPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final String language;
  final String theme;
  final bool autoExtendBooking;
  final int defaultParkingDuration;

  const UserPreferences({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.language,
    required this.theme,
    required this.autoExtendBooking,
    required this.defaultParkingDuration,
  });
} 