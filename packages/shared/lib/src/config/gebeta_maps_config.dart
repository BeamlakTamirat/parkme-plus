import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gebeta Maps configuration for WePark
class GebetaMapsConfig {
  static bool _isInitialized = false;

  /// Gebeta Maps API Key
  static String get apiKey {
    final apiKey = dotenv.env['GEBETA_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        print('⚠️ GEBETA_MAPS_API_KEY not found in .env file, using fallback');
        return 'demo-api-key-for-testing'; // Fallback for development
      }
      throw Exception('GEBETA_MAPS_API_KEY not found in .env file');
    }
    return apiKey;
  }

  /// Gebeta Maps Base URL (Fixed the typo)
  static String get baseUrl {
    final baseUrl = dotenv.env['GEBETA_MAPS_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      // Fallback to correct Gebeta Maps URL
      return 'https://api.gebeta.app/v1';
    }
    return baseUrl;
  }

  /// Whether to use Gebeta Maps
  static bool get useGebetaMaps {
    final useMaps = dotenv.env['USE_GEBETA_MAPS'];
    return useMaps == 'true' || useMaps == null; // Default to true
  }

  /// Initialize Gebeta Maps configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) print('🗺️ Initializing Gebeta Maps...');

      // Try to get API key (with fallback in debug mode)
      final key = apiKey;

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Gebeta Maps initialized successfully');
        print(
            '🔑 API Key: ${key.length > 20 ? '${key.substring(0, 20)}...' : key}');
        print('🌐 Base URL: $baseUrl');
        print('📱 Use Gebeta Maps: $useGebetaMaps');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gebeta Maps initialization failed: $e');
        print('🔍 Troubleshooting tips:');
        print('   1. Check GEBETA_MAPS_API_KEY in .env file');
        print(
            '   2. Verify GEBETA_MAPS_BASE_URL=https://api.gebeta.app/v1 in .env file');
        print('   3. Ensure .env file is loaded properly');
        print('   4. App will continue with mock data');
      }

      // Initialize anyway with fallback for development
      _isInitialized = true;
    }
  }

  /// Check if Gebeta Maps is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization (for testing)
  static void reset() {
    _isInitialized = false;
  }
}
