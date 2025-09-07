import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Map Style definitions for WePark
enum MapStyle {
  streets('Streets', 'mapbox://styles/mapbox/streets-v12'),
  satellite('Satellite', 'mapbox://styles/mapbox/satellite-v9'),
  satelliteStreets(
      'Satellite + Streets', 'mapbox://styles/mapbox/satellite-streets-v12'),
  outdoors('Outdoors', 'mapbox://styles/mapbox/outdoors-v12'),
  light('Light', 'mapbox://styles/mapbox/light-v11'),
  dark('Dark', 'mapbox://styles/mapbox/dark-v11'),
  navigationDay('Navigation Day', 'mapbox://styles/mapbox/navigation-day-v1'),
  navigationNight(
      'Navigation Night', 'mapbox://styles/mapbox/navigation-night-v1');

  const MapStyle(this.displayName, this.styleUrl);
  final String displayName;
  final String styleUrl;
}

class MapboxConfig {
  static bool _isInitialized = false;
  static MapStyle _currentMapStyle = MapStyle.streets;

  static String get accessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('⚠️ MAPBOX_ACCESS_TOKEN not found in .env file, using fallback');
        return 'pk.demo-access-token-for-testing'; // Fallback for development
      }
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
    }
    return token;
  }

  static String? get secretToken {
    final token = dotenv.env['MAPBOX_SECRET_TOKEN'];
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('ℹ️ MAPBOX_SECRET_TOKEN not found in .env file (optional)');
      }
      return null;
    }
    return token;
  }

  static String get downloadsToken {
    final secretToken = dotenv.env['MAPBOX_SECRET_TOKEN'];
    if (secretToken != null && secretToken.isNotEmpty) {
      return secretToken;
    }

    final downloadsToken = dotenv.env['MAPBOX_DOWNLOADS_TOKEN'];
    if (downloadsToken != null && downloadsToken.isNotEmpty) {
      return downloadsToken;
    }

    // Fallback to access token for development
    final accessTokenFallback = accessToken;
    if (kDebugMode) {
      print('⚠️ Using access token as downloads token fallback');
    }
    return accessTokenFallback;
  }

  /// Get current map style
  static MapStyle get currentMapStyle => _currentMapStyle;

  /// Set current map style
  static void setMapStyle(MapStyle style) {
    _currentMapStyle = style;
    if (kDebugMode) {
      print(
          '🗺️ Map style changed to: ${style.displayName} (${style.styleUrl})');
    }
  }

  /// Get all available map styles
  static List<MapStyle> get availableMapStyles => MapStyle.values;

  /// Mapbox Map Style URL (uses current selected style)
  static String get styleUrl {
    final styleUrl = dotenv.env['MAPBOX_STYLE_URL'];
    if (styleUrl == null || styleUrl.isEmpty) {
      // Default to current map style
      return _currentMapStyle.styleUrl;
    }
    return styleUrl;
  }

  /// Whether to use Mapbox
  static bool get useMapbox {
    final useMaps = dotenv.env['USE_MAPBOX'];
    return useMaps == 'true' || useMaps == null; // Default to true
  }

  /// Default zoom level for maps
  static double get defaultZoom {
    final zoom = dotenv.env['MAPBOX_DEFAULT_ZOOM'];
    if (zoom != null && zoom.isNotEmpty) {
      return double.tryParse(zoom) ?? 15.0;
    }
    return 15.0; // Default zoom level
  }

  /// Minimum zoom level
  static double get minZoom {
    final zoom = dotenv.env['MAPBOX_MIN_ZOOM'];
    if (zoom != null && zoom.isNotEmpty) {
      return double.tryParse(zoom) ?? 8.0;
    }
    return 8.0;
  }

  /// Maximum zoom level
  static double get maxZoom {
    final zoom = dotenv.env['MAPBOX_MAX_ZOOM'];
    if (zoom != null && zoom.isNotEmpty) {
      return double.tryParse(zoom) ?? 22.0;
    }
    return 22.0;
  }

  /// Initialize Mapbox configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) print('🗺️ Initializing Mapbox Maps...');

      final token = accessToken;
      final style = styleUrl;

      // Initialize Mapbox Maps SDK
      MapboxOptions.setAccessToken(token);

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Mapbox Maps initialized successfully');
        print(
            '🔑 Access Token: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}');
        print('🎨 Style URL: $style');
        print('📱 Use Mapbox: $useMapbox');
        print('🔍 Default Zoom: $defaultZoom');
        print('📏 Zoom Range: $minZoom - $maxZoom');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mapbox Maps initialization failed: $e');
        print('🔍 Troubleshooting tips:');
        print('   1. Check MAPBOX_ACCESS_TOKEN in .env file');
        print('   2. Get your token from https://account.mapbox.com/');
        print('   3. Verify MAPBOX_STYLE_URL in .env file (optional)');
        print('   4. Ensure .env file is loaded properly');
        print('   5. App will continue with mock data');
      }

      // Initialize anyway with fallback for development
      _isInitialized = true;
    }
  }

  /// Check if Mapbox is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization (for testing)
  static void reset() {
    _isInitialized = false;
  }

  /// Get Mapbox tile URL for a given coordinate and zoom level
  static String getTileUrl({
    required double lat,
    required double lng,
    required int zoom,
    String style = 'streets-v12',
    int tileSize = 512,
  }) {
    // Calculate tile coordinates
    final x = _lonToTileX(lng, zoom);
    final y = _latToTileY(lat, zoom);

    return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/$tileSize/$zoom/$x/$y?access_token=$accessToken';
  }

  /// Convert longitude to tile X coordinate
  static int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Convert latitude to tile Y coordinate
  static int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                (math.log(math.tan(latRad) + (1 / math.cos(latRad))) /
                    math.pi)) /
            2.0 *
            (1 << zoom))
        .floor();
  }
}
