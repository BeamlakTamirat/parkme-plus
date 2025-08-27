import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/mapbox_config.dart';
import '../../models/parking/parking_location.dart';

/// Mapbox Maps service for WePark
/// Uses REAL Mapbox APIs for location services and geocoding
class MapboxService {
  static MapboxService? _instance;
  late final Dio _dio;

  MapboxService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.mapbox.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for debugging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  static MapboxService get instance {
    _instance ??= MapboxService._internal();
    return _instance!;
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      if (kDebugMode) {
        print('📍 Getting current location...');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) print('❌ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) print('❌ Location permissions denied forever');
        return null;
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (kDebugMode) {
        print(
            '✅ Current location: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Get address from coordinates using Mapbox Geocoding API
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (kDebugMode) {
        print('🏠 Getting address for: $latitude, $longitude');
      }

      // Use Mapbox Reverse Geocoding API
      final response = await _dio.get(
        '/geocoding/v5/mapbox.places/$longitude,$latitude.json',
        queryParameters: {
          'access_token': MapboxConfig.accessToken,
          'types': 'address,poi',
          'limit': 1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final features = data['features'] as List;

        if (features.isNotEmpty) {
          final placeName = features.first['place_name'] as String;
          if (kDebugMode) {
            print('✅ Address found: $placeName');
          }
          return placeName;
        }
      }

      // Fallback to native geocoding
      return await _getNativeAddress(latitude, longitude);
    } catch (e) {
      if (kDebugMode) print('❌ Mapbox geocoding error: $e');
      // Fallback to native geocoding
      return await _getNativeAddress(latitude, longitude);
    }
  }

  /// Fallback to native geocoding
  Future<String?> _getNativeAddress(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        if (kDebugMode) {
          print('✅ Native address found: $address');
        }
        return address;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Native geocoding error: $e');
    }
    return null;
  }

  /// Get coordinates from address using Mapbox Forward Geocoding API
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      if (kDebugMode) {
        print('📍 Getting coordinates for: $address');
      }

      // Use Mapbox Forward Geocoding API
      final response = await _dio.get(
        '/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json',
        queryParameters: {
          'access_token': MapboxConfig.accessToken,
          'limit': 1,
          'country': 'ET', // Limit to Ethiopia
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final features = data['features'] as List;

        if (features.isNotEmpty) {
          final coordinates = features.first['geometry']['coordinates'] as List;
          final longitude = coordinates[0] as double;
          final latitude = coordinates[1] as double;

          if (kDebugMode) {
            print('✅ Coordinates found: $latitude, $longitude');
          }

          return {
            'latitude': latitude,
            'longitude': longitude,
          };
        }
      }

      // Fallback to native geocoding
      return await _getNativeCoordinates(address);
    } catch (e) {
      if (kDebugMode) print('❌ Mapbox forward geocoding error: $e');
      // Fallback to native geocoding
      return await _getNativeCoordinates(address);
    }
  }

  /// Fallback to native geocoding for coordinates
  Future<Map<String, double>?> _getNativeCoordinates(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        if (kDebugMode) {
          print(
              '✅ Native coordinates found: ${location.latitude}, ${location.longitude}');
        }
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }
    } catch (e) {
      if (kDebugMode) print('❌ Native forward geocoding error: $e');
    }
    return null;
  }

  /// Search for nearby parking locations
  /// This combines database parking locations with real-world coordinates
  Future<List<ParkingLocation>> searchNearbyParking(
    double latitude,
    double longitude, {
    double radius = 5000, // 5km radius
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Searching for parking near: $latitude, $longitude');
        print('📏 Search radius: ${radius / 1000}km');
      }

      final mockLocations = _getMockParkingLocations();

      // Filter locations within radius
      final nearbyLocations = mockLocations.where((location) {
        final distance = calculateDistance(
          latitude,
          longitude,
          location.latitude,
          location.longitude,
        );
        return distance <= radius;
      }).toList();

      if (kDebugMode) {
        print('✅ Found ${nearbyLocations.length} parking locations nearby');
      }

      return nearbyLocations;
    } catch (e) {
      if (kDebugMode) print('❌ Error searching nearby parking: $e');
      return _getMockParkingLocations();
    }
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // Earth radius in meters

    final double lat1Rad = lat1 * math.pi / 180;
    final double lat2Rad = lat2 * math.pi / 180;
    final double deltaLat = (lat2 - lat1) * math.pi / 180;
    final double deltaLng = (lng2 - lng1) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get route between two points using Mapbox Directions API
  Future<Map<String, dynamic>?> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    String profile = 'driving', // driving, walking, cycling
  }) async {
    try {
      if (kDebugMode) {
        print(
            '🚗 Getting route from ($startLat, $startLng) to ($endLat, $endLng)');
      }

      final response = await _dio.get(
        '/directions/v5/mapbox/$profile/$startLng,$startLat;$endLng,$endLat',
        queryParameters: {
          'access_token': MapboxConfig.accessToken,
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final route = routes.first;
          final duration = route['duration'] as double; // in seconds
          final distance = route['distance'] as double; // in meters
          final geometry = route['geometry'];

          if (kDebugMode) {
            print(
                '✅ Route found: ${(distance / 1000).toStringAsFixed(1)}km, ${(duration / 60).toStringAsFixed(0)} mins');
          }

          return {
            'duration': duration,
            'distance': distance,
            'geometry': geometry,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error getting route: $e');
    }
    return null;
  }

  /// Get static map URL using Mapbox Static Images API
  String getStaticMapUrl({
    required double lat,
    required double lng,
    int width = 400,
    int height = 400,
    int zoom = 15,
    String style = 'streets-v12',
    List<Map<String, dynamic>>? markers,
  }) {
    final String baseUrl =
        'https://api.mapbox.com/styles/v1/mapbox/$style/static';

    String overlays = '';

    // Add markers if provided with coordinate validation
    if (markers != null && markers.isNotEmpty) {
      final validMarkers = <String>[];

      for (final marker in markers) {
        final markerLat = marker['lat'] ?? lat;
        final markerLng = marker['lng'] ?? lng;
        final color = marker['color'] ?? 'red';
        final size = marker['size'] ?? 'medium';

        // Validate coordinates
        if (_isValidCoordinate(markerLat, markerLng)) {
          // Round coordinates to 4 decimal places for cleaner URLs
          final roundedLat = double.parse(markerLat.toStringAsFixed(4));
          final roundedLng = double.parse(markerLng.toStringAsFixed(4));
          validMarkers.add('pin-$size-$color($roundedLng,$roundedLat)');
          if (kDebugMode) {
            print('✅ Valid marker: $roundedLng,$roundedLat');
          }
        } else {
          if (kDebugMode) {
            print(
                '❌ Invalid marker coordinates: $markerLng,$markerLat (outside Ethiopia bounds)');
          }
        }
      }

      if (validMarkers.isNotEmpty) {
        // Limit to 5 markers to avoid URL length issues
        final limitedMarkers = validMarkers.take(5).toList();
        overlays = '${limitedMarkers.join(',')}/';

        if (kDebugMode) {
          print(
              '🗺️ Using ${limitedMarkers.length} markers (limited from ${validMarkers.length})');
        }
      }
    }

    // Validate center coordinates
    if (!_isValidCoordinate(lat, lng)) {
      if (kDebugMode) {
        print(
            '❌ Invalid center coordinates: $lng,$lat - using default Addis Ababa');
      }
      lat = 9.0120; // Meskel Square
      lng = 38.7634;
    }

    final url =
        '$baseUrl/$overlays$lng,$lat,$zoom/${width}x$height@2x?access_token=${MapboxConfig.accessToken}';

    if (kDebugMode) {
      print('🗺️ Static map URL: $url');
      print('🗺️ Center: $lng,$lat (zoom: $zoom)');
      print('🗺️ Overlays: $overlays');

      // Also generate a simple map without markers for testing
      final simpleUrl =
          '$baseUrl/$lng,$lat,$zoom/${width}x$height@2x?access_token=${MapboxConfig.accessToken}';
      print('🗺️ Simple map URL (no markers): $simpleUrl');
    }

    return url;
  }

  /// Get a simple static map URL without any markers (for testing)
  String getSimpleStaticMapUrl({
    required double lat,
    required double lng,
    int width = 400,
    int height = 400,
    int zoom = 15,
    String style = 'streets-v12',
  }) {
    final String baseUrl =
        'https://api.mapbox.com/styles/v1/mapbox/$style/static';

    // Validate center coordinates
    if (!_isValidCoordinate(lat, lng)) {
      if (kDebugMode) {
        print(
            '❌ Invalid center coordinates: $lng,$lat - using default Addis Ababa');
      }
      lat = 9.0120; // Meskel Square
      lng = 38.7634;
    }

    final url =
        '$baseUrl/$lng,$lat,$zoom/${width}x$height@2x?access_token=${MapboxConfig.accessToken}';

    if (kDebugMode) {
      print('🗺️ Simple static map URL: $url');
    }

    return url;
  }

  /// Validate if coordinates are within valid ranges and in Ethiopia
  bool _isValidCoordinate(double lat, double lng) {
    // Basic coordinate validation
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    if (lat == 0.0 && lng == 0.0) return false; // Exclude null island

    // Ethiopia bounds check (approximate)
    // Ethiopia is roughly between 3°-15°N latitude and 33°-48°E longitude
    if (lat < 3.0 || lat > 15.0) return false;
    if (lng < 33.0 || lng > 48.0) return false;

    return true;
  }

  /// Mock parking locations for testing
  /// In a real app, these would come from your database
  List<ParkingLocation> _getMockParkingLocations() {
    return [
      ParkingLocation(
        id: 'mock_1',
        name: 'Bole Parking Center',
        address: 'Bole Road, Addis Ababa',
        latitude: 9.0120, // Meskel Square area
        longitude: 38.7634,
        totalSpots: 50,
        availableSpots: 15,
        hourlyRate: 30.0,
        isActive: true,
        description: 'Secure parking in the heart of Bole',
        amenities: ['Security', 'CCTV', '24/7 Access'],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ParkingLocation(
        id: 'mock_2',
        name: 'Mercato Mall Parking',
        address: 'Mercato, Addis Ababa',
        latitude: 9.0320,
        longitude: 38.7469,
        totalSpots: 100,
        availableSpots: 45,
        hourlyRate: 25.0,
        isActive: true,
        description: 'Large parking facility at Mercato Mall',
        amenities: ['Security', 'Covered Parking', 'Elevator'],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ParkingLocation(
        id: 'mock_3',
        name: 'Piazza Parking Hub',
        address: 'Piazza, Addis Ababa',
        latitude: 9.0417,
        longitude: 38.7369,
        totalSpots: 30,
        availableSpots: 8,
        hourlyRate: 20.0,
        isActive: true,
        description: 'Convenient parking near Piazza',
        amenities: ['Security', 'Street Access'],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
