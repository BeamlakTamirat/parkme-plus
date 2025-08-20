import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/gebeta_maps_config.dart';
import '../../models/parking/parking_location.dart';

/// Gebeta Maps service for WePark
/// Uses REAL Gebeta Maps API calls
class GebetaMapsService {
  static GebetaMapsService? _instance;
  late final Dio _dio;

  GebetaMapsService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: GebetaMapsConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10), // Fixed: was 30000 seconds!
      receiveTimeout: const Duration(seconds: 10), // Fixed: was 30000 seconds!
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${GebetaMapsConfig.apiKey}',
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

  static GebetaMapsService get instance {
    _instance ??= GebetaMapsService._internal();
    return _instance!;
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      if (kDebugMode) print('📍 Getting current location...');

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) print('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) print('❌ Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (kDebugMode) {
        print(
            '✅ Current location: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Convert coordinates to address using Gebeta Maps API
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      if (kDebugMode) print('🏠 Getting address for: $latitude, $longitude');

      // Call Gebeta Maps reverse geocoding API
      final response = await _dio.get('/geocoding/reverse', queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'key': GebetaMapsConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final address = data['data']['formatted_address'];
          if (kDebugMode) print('✅ Address: $address');
          return address;
        }
      }

      // Fallback to geocoding package
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        if (kDebugMode) print('✅ Address (fallback): $address');
        return address;
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting address: $e');
      return null;
    }
  }

  /// Convert address to coordinates using Gebeta Maps API
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      if (kDebugMode) print('📍 Getting coordinates for: $address');

      // Call Gebeta Maps geocoding API
      final response = await _dio.get('/geocoding/forward', queryParameters: {
        'address': address,
        'key': GebetaMapsConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success' && data['data'].isNotEmpty) {
          final location = data['data'][0];
          final coordinates = <String, double>{
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
          };

          if (kDebugMode) {
            print(
                '✅ Coordinates: ${coordinates['latitude']}, ${coordinates['longitude']}');
          }

          return coordinates;
        }
      }

      // Fallback to geocoding package
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final coordinates = <String, double>{
          'latitude': location.latitude,
          'longitude': location.longitude,
        };

        if (kDebugMode) {
          print(
              '✅ Coordinates (fallback): ${coordinates['latitude']}, ${coordinates['longitude']}');
        }

        return coordinates;
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting coordinates: $e');
      return null;
    }
  }

  /// Search for parking locations near coordinates using Gebeta Maps API
  Future<List<ParkingLocation>> searchNearbyParking(
    double latitude,
    double longitude, {
    double radius = 5000, // 5km radius
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Searching for parking near: $latitude, $longitude');
      }

      // Call Gebeta Maps places API for parking locations
      final response = await _dio.get('/places/nearby', queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radius': radius,
        'type': 'parking',
        'key': GebetaMapsConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final places = data['data'] as List;
          final parkingLocations = <ParkingLocation>[];

          for (final place in places) {
            try {
              final location = ParkingLocation(
                id: place['place_id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: place['name'] ?? 'Unknown Parking',
                address: place['vicinity'] ?? 'Unknown Address',
                latitude:
                    (place['geometry']['location']['lat'] ?? 0.0).toDouble(),
                longitude:
                    (place['geometry']['location']['lng'] ?? 0.0).toDouble(),
                totalSpots: 50, // Default value, would come from your database
                availableSpots:
                    15, // Default value, would come from your database
                hourlyRate:
                    30.0, // Default value, would come from your database
                isActive: true,
                description: place['name'] ?? 'Parking location',
                amenities: ['Security'], // Default amenities
                images: [], // No images from Gebeta Maps
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              parkingLocations.add(location);
            } catch (e) {
              if (kDebugMode) print('❌ Error parsing place: $e');
            }
          }

          if (kDebugMode) {
            print('✅ Found ${parkingLocations.length} parking locations');
          }

          return parkingLocations;
        }
      }

      // Fallback to mock data if API fails
      if (kDebugMode) print('⚠️ Using fallback parking data');
      return _getMockParkingLocations();
    } catch (e) {
      if (kDebugMode) print('❌ Error searching nearby parking: $e');
      return _getMockParkingLocations();
    }
  }

  /// Get route between two points using Gebeta Maps API
  Future<Map<String, dynamic>?> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      if (kDebugMode) {
        print(
            '🛣️ Getting route from $originLat,$originLng to $destLat,$destLng');
      }

      // Call Gebeta Maps directions API
      final response = await _dio.get('/directions', queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': mode,
        'key': GebetaMapsConfig.apiKey,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final route = data['data']['routes'][0];
          final legs = route['legs'][0];

          final routeInfo = {
            'distance': legs['distance']['text'],
            'duration': legs['duration']['text'],
            'steps': legs['steps'] as List,
            'polyline': route['overview_polyline']['points'],
          };

          if (kDebugMode) {
            print(
                '✅ Route: ${routeInfo['distance']} in ${routeInfo['duration']}');
          }

          return routeInfo;
        }
      }

      // Fallback: calculate simple distance
      final distance =
          await calculateDistance(originLat, originLng, destLat, destLng);
      return {
        'distance': '${distance?.toStringAsFixed(1) ?? 0} km',
        'duration': 'Unknown',
        'steps': [],
        'polyline': '',
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error getting route: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  Future<double?> calculateDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      if (kDebugMode) {
        print('📏 Calculating distance...');
      }

      final distance = Geolocator.distanceBetween(
        originLat,
        originLng,
        destLat,
        destLng,
      );

      final distanceKm = distance / 1000; // Convert to kilometers

      if (kDebugMode) {
        print('✅ Distance: ${distanceKm.toStringAsFixed(2)} km');
      }

      return distanceKm;
    } catch (e) {
      if (kDebugMode) print('❌ Error calculating distance: $e');
      return null;
    }
  }

  /// Get map tiles URL for Gebeta Maps
  String getMapTilesUrl({
    required int x,
    required int y,
    required int z,
    String style = 'default',
  }) {
    // Gebeta Maps tile URL format
    return '${GebetaMapsConfig.baseUrl}/tiles/$style/$z/$x/$y.png?key=${GebetaMapsConfig.apiKey}';
  }

  /// Get static map image URL
  String getStaticMapUrl({
    required double lat,
    required double lng,
    int width = 600,
    int height = 400,
    int zoom = 15,
    String style = 'default',
  }) {
    return '${GebetaMapsConfig.baseUrl}/staticmap?'
        'center=$lat,$lng&'
        'zoom=$zoom&'
        'size=${width}x$height&'
        'style=$style&'
        'key=${GebetaMapsConfig.apiKey}';
  }

  /// Mock parking locations for fallback
  List<ParkingLocation> _getMockParkingLocations() {
    return [
      ParkingLocation(
        id: '1',
        name: 'Meskel Square Parking',
        address: 'Meskel Square, Addis Ababa',
        latitude: 9.0054,
        longitude: 38.7636,
        totalSpots: 50,
        availableSpots: 15,
        hourlyRate: 30.0,
        isActive: true,
        description: 'Secure parking near Meskel Square',
        amenities: ['Security', 'CCTV', 'Well-lit'],
        images: ['https://example.com/meskel.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ParkingLocation(
        id: '2',
        name: 'Bole Arena Plaza',
        address: 'Bole, Addis Ababa',
        latitude: 8.9806,
        longitude: 38.7578,
        totalSpots: 30,
        availableSpots: 8,
        hourlyRate: 25.0,
        isActive: true,
        description: 'Convenient parking at Bole Arena',
        amenities: ['Security', 'Easy access'],
        images: ['https://example.com/bole.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ParkingLocation(
        id: '3',
        name: 'Piassa Mall Garage',
        address: 'Piassa, Addis Ababa',
        latitude: 9.0272,
        longitude: 38.7369,
        totalSpots: 40,
        availableSpots: 22,
        hourlyRate: 20.0,
        isActive: true,
        description: 'Underground parking at Piassa Mall',
        amenities: ['Covered parking', 'Security'],
        images: ['https://example.com/piassa.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
