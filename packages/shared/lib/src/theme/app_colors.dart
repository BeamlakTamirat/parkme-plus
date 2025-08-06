import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (WePark Orange)
  static const Color primary = Color(0xFFFF9500);
  static const Color primaryDark = Color(0xFFE6850E);
  static const Color primaryLight = Color(0xFFFFB84D);

  // Secondary Colors
  static const Color secondary = Color(0xFF2C2C2E);
  static const Color secondaryLight = Color(0xFF48484A);

  // Background Colors
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF2F2F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);

  // Status Colors
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Semantic Colors
  static const Color available = Color(0xFF30D158);
  static const Color occupied = Color(0xFFFF3B30);
  static const Color reserved = Color(0xFFFF9F0A);
  static const Color maintenance = Color(0xFF8E8E93);

  // Neutral Colors
  static const Color grey50 = Color(0xFFF9F9F9);
  static const Color grey100 = Color(0xFFF2F2F7);
  static const Color grey200 = Color(0xFFE5E5EA);
  static const Color grey300 = Color(0xFFD1D1D6);
  static const Color grey400 = Color(0xFFC7C7CC);
  static const Color grey500 = Color(0xFF8E8E93);
  static const Color grey600 = Color(0xFF636366);
  static const Color grey700 = Color(0xFF48484A);
  static const Color grey800 = Color(0xFF2C2C2E);
  static const Color grey900 = Color(0xFF1D1D1F);

  // Disabled
  static const Color disabled = Color(0xFFC7C7CC);
  static const Color disabledText = Color(0xFF8E8E93);

  // Shadows
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Colors.white, grey50],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
