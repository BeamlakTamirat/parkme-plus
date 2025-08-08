import 'dart:async';
import '../../models/models.dart' as models;
import '../../config/firebase_config.dart';
import '../database/firestore_service.dart';
import 'package:geolocator/geolocator.dart';

/// Core parking service for managing parking locations and operations
class ParkingService {
  static ParkingService? _instance;
  late final FirestoreService _firestoreService;

  ParkingService._internal() {
    _firestoreService = FirestoreService.instance;
  }

  static ParkingService get instance {
    _instance ??= ParkingService._internal();
    return _instance!;
  }

  /// Get all parking locations
  Future<ServiceResult<List<models.ParkingLocation>>>
      getAllParkingLocations() async {
    try {
      final result = await _firestoreService.queryDocuments(
        collection: FirestoreCollections.parkingLocations,
        where: {FirestoreFields.isActive: true},
        orderBy: FirestoreFields.name,
      );

      if (result.success && result.data != null) {
        final locations =
            result.data!.map((data) => _mapToParkingLocation(data)).toList();

        return ServiceResult.success(locations);
      } else {
        return ServiceResult.error(
            'Failed to fetch parking locations: ${result.error}');
      }
    } catch (e) {
      return ServiceResult.error('Unexpected error: $e');
    }
  }

  /// Get nearby parking locations
  Future<ServiceResult<List<models.ParkingLocation>>>
      getNearbyParkingLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      // Get all active parking locations
      final result = await _firestoreService.queryDocuments(
        collection: FirestoreCollections.parkingLocations,
        where: {FirestoreFields.isActive: true},
        limit: 100, // Get more to filter by distance
      );

      if (result.success && result.data != null) {
        final allLocations =
            result.data!.map((data) => _mapToParkingLocation(data)).toList();

        // Filter by distance
        final nearbyLocations = <models.ParkingLocation>[];

        for (final location in allLocations) {
          final distance = Geolocator.distanceBetween(
                latitude,
                longitude,
                location.latitude,
                location.longitude,
              ) /
              1000; // Convert to kilometers

          if (distance <= radiusKm) {
            nearbyLocations.add(location);
          }
        }

        // Sort by distance and limit results
        nearbyLocations.sort((a, b) {
          final distanceA = Geolocator.distanceBetween(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          );
          final distanceB = Geolocator.distanceBetween(
            latitude,
            longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });

        final limitedResults = nearbyLocations.take(limit).toList();

        return ServiceResult.success(limitedResults);
      } else {
        return ServiceResult.error(
            'Failed to fetch parking locations: ${result.error}');
      }
    } catch (e) {
      return ServiceResult.error('Unexpected error: $e');
    }
  }

  /// Get parking location by ID
  Future<ServiceResult<models.ParkingLocation?>> getParkingLocationById(
      String locationId) async {
    try {
      final result = await _firestoreService.getDocument(
        collection: FirestoreCollections.parkingLocations,
        documentId: locationId,
      );

      if (result.success) {
        if (result.data != null) {
          final location = _mapToParkingLocation(result.data!);
          return ServiceResult.success(location);
        } else {
          return ServiceResult.success(null);
        }
      } else {
        return ServiceResult.error(
            'Failed to fetch parking location: ${result.error}');
      }
    } catch (e) {
      return ServiceResult.error('Unexpected error: $e');
    }
  }

  /// Search parking locations
  Future<ServiceResult<List<models.ParkingLocation>>> searchParkingLocations({
    required String query,
    double? latitude,
    double? longitude,
    double? maxDistance,
    models.VehicleType? vehicleType,
    double? maxHourlyRate,
  }) async {
    try {
      // For now, implement basic search. In production, you'd use Algolia or Elasticsearch
      final allResult = await getAllParkingLocations();

      if (!allResult.success) {
        return allResult;
      }

      final allLocations = allResult.data!;
      final filteredLocations = <models.ParkingLocation>[];

      for (final location in allLocations) {
        bool matches = true;

        // Text search in name and address
        if (query.isNotEmpty) {
          final searchQuery = query.toLowerCase();
          final nameMatch = location.name.toLowerCase().contains(searchQuery);
          final addressMatch =
              location.address.toLowerCase().contains(searchQuery);

          if (!nameMatch && !addressMatch) {
            matches = false;
          }
        }

        // Distance filter
        if (matches &&
            latitude != null &&
            longitude != null &&
            maxDistance != null) {
          final distance = Geolocator.distanceBetween(
                latitude,
                longitude,
                location.latitude,
                location.longitude,
              ) /
              1000; // Convert to kilometers

          if (distance > maxDistance) {
            matches = false;
          }
        }

        // Price filter
        if (matches && maxHourlyRate != null) {
          if (location.hourlyRate > maxHourlyRate) {
            matches = false;
          }
        }

        if (matches) {
          filteredLocations.add(location);
        }
      }

      return ServiceResult.success(filteredLocations);
    } catch (e) {
      return ServiceResult.error('Unexpected error: $e');
    }
  }

  /// Get available parking spots for a location
  Future<ServiceResult<List<models.ParkingSpot>>> getAvailableParkingSpots({
    required String locationId,
    DateTime? startTime,
    DateTime? endTime,
    models.VehicleType? vehicleType,
  }) async {
    try {
      final result = await _firestoreService.queryDocuments(
        collection: FirestoreCollections.parkingSpots,
        where: {
          FirestoreFields.parkingLocationId: locationId,
          FirestoreFields.isActive: true,
        },
      );

      if (result.success && result.data != null) {
        final spots = result.data!
            .map((data) => _mapToParkingSpot(data))
            .where((spot) =>
                spot.status == models.ParkingSpotStatus.available &&
                (vehicleType == null ||
                    spot.supportedVehicleTypes.contains(vehicleType)))
            .toList();

        // TODO: Check for conflicting bookings if startTime and endTime are provided

        return ServiceResult.success(spots);
      } else {
        return ServiceResult.error(
            'Failed to fetch parking spots: ${result.error}');
      }
    } catch (e) {
      return ServiceResult.error('Unexpected error: $e');
    }
  }

  /// Stream parking location updates
  Stream<ServiceResult<List<models.ParkingLocation>>> streamParkingLocations() {
    try {
      return _firestoreService
          .streamDocuments(
        collection: FirestoreCollections.parkingLocations,
        where: {FirestoreFields.isActive: true},
        orderBy: FirestoreFields.name,
      )
          .map((result) {
        if (result.success && result.data != null) {
          final locations =
              result.data!.map((data) => _mapToParkingLocation(data)).toList();
          return ServiceResult.success(locations);
        } else {
          return ServiceResult.error(
              'Failed to stream parking locations: ${result.error}');
        }
      });
    } catch (e) {
      return Stream.value(ServiceResult.error('Unexpected error: $e'));
    }
  }

  /// Map Firestore data to ParkingLocation model
  models.ParkingLocation _mapToParkingLocation(Map<String, dynamic> data) {
    final lat = (data[FirestoreFields.latitude] ?? 0.0).toDouble();
    final lng = (data[FirestoreFields.longitude] ?? 0.0).toDouble();

    return models.ParkingLocation(
      id: data[FirestoreFields.id] ?? '',
      name: data[FirestoreFields.name] ?? '',
      address: data[FirestoreFields.address] ?? '',
      description: data['description'] ?? '',
      latitude: lat,
      longitude: lng,
      coordinates: models.Location(latitude: lat, longitude: lng),
      totalSpots: data[FirestoreFields.totalSpots] ?? 0,
      availableSpots: data[FirestoreFields.availableSpots] ?? 0,
      hourlyRate: (data[FirestoreFields.hourlyRate] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
      amenities: models.ParkingAmenities(
        hasEVCharging: data['amenities']?['has_ev_charging'] ?? false,
        hasCCTV: data['amenities']?['has_cctv'] ?? false,
        hasSecurity: data['amenities']?['has_security'] ?? false,
        hasRoofCover: data['amenities']?['has_roof_cover'] ?? false,
        hasRestrooms: data['amenities']?['has_restrooms'] ?? false,
        hasCarWash: data['amenities']?['has_car_wash'] ?? false,
        hasValetService: data['amenities']?['has_valet_service'] ?? false,
        hasHandicapAccess: data['amenities']?['has_handicap_access'] ?? false,
        has24x7Access: data['amenities']?['has_24x7_access'] ?? false,
        hasDisabledAccess: data['amenities']?['has_disabled_access'] ?? false,
        hasElevator: data['amenities']?['has_elevator'] ?? false,
        hasEvCharging: data['amenities']?['has_ev_charging'] ?? false,
        hasRestroom: data['amenities']?['has_restrooms'] ?? false,
        isCovered: data['amenities']?['is_covered'] ?? false,
      ),
      operatingHours: _parseOperatingHours(data['operating_hours']),
      images: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: data[FirestoreFields.isActive] ?? true,
      createdAt:
          _parseDateTime(data[FirestoreFields.createdAt]) ?? DateTime.now(),
      updatedAt:
          _parseDateTime(data[FirestoreFields.updatedAt]) ?? DateTime.now(),
    );
  }

  /// Map Firestore data to ParkingSpot model
  models.ParkingSpot _mapToParkingSpot(Map<String, dynamic> data) {
    return models.ParkingSpot(
      id: data[FirestoreFields.id] ?? '',
      locationId: data[FirestoreFields.parkingLocationId] ?? '',
      parkingLocationId: data[FirestoreFields.parkingLocationId] ?? '',
      spotNumber: data['spot_number'] ?? '',
      type: models.ParkingSpotType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => models.ParkingSpotType.standard,
      ),
      status: models.ParkingSpotStatus.values.firstWhere(
        (status) => status.name == data[FirestoreFields.status],
        orElse: () => models.ParkingSpotStatus.available,
      ),
      supportedVehicleTypes: (data['supported_vehicle_types'] as List<dynamic>?)
              ?.map((type) => models.VehicleType.values.firstWhere(
                    (vehicleType) => vehicleType.name == type,
                    orElse: () => models.VehicleType.car,
                  ))
              .toList() ??
          [models.VehicleType.car],
      hourlyRate: (data['hourly_rate'] ?? 0.0).toDouble(),
      isDisabledAccessible: data['is_disabled_accessible'] ?? false,
      isEvChargingSpot: data['is_ev_charging_spot'] ?? false,
      isActive: data[FirestoreFields.isActive] ?? true,
      createdAt:
          _parseDateTime(data[FirestoreFields.createdAt]) ?? DateTime.now(),
      updatedAt:
          _parseDateTime(data[FirestoreFields.updatedAt]) ?? DateTime.now(),
    );
  }

  /// Parse operating hours from Firestore data
  Map<String, Map<String, String>> _parseOperatingHours(dynamic data) {
    if (data is Map) {
      return (data as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).cast<String, String>(),
        ),
      );
    }
    return {};
  }

  /// Parse DateTime from Firestore Timestamp
  DateTime? _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    // Handle Firestore Timestamp if needed
    return DateTime.now(); // Fallback
  }
}

/// Service result wrapper
class ServiceResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ServiceResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory ServiceResult.success(T data) {
    return ServiceResult._(
      success: true,
      data: data,
    );
  }

  factory ServiceResult.error(String error) {
    return ServiceResult._(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ServiceResult(success: $success, data: $data, error: $error)';
  }
}
