import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// Parking location model for WePark ecosystem
class ParkingLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalSpots;
  final int availableSpots;
  final double hourlyRate;
  final bool isActive;
  final String? description;
  final List<String>? amenities;
  final List<String>? images;
  final String? attendantId; // ID of assigned attendant
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Computed properties for filtering
  double? _distanceFromUser; // Distance in kilometers
  double? _rating; // Rating out of 5

  ParkingLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalSpots,
    required this.availableSpots,
    required this.hourlyRate,
    required this.isActive,
    this.description,
    this.amenities,
    this.images,
    this.attendantId,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Create from Appwrite document
  factory ParkingLocation.fromDocument(Map<String, dynamic> document) {
    final rawLat = document['latitude'];
    final rawLng = document['longitude'];
    final latitude = (rawLat ?? 0.0).toDouble();
    final longitude = (rawLng ?? 0.0).toDouble();

    // Debug coordinate parsing
    if (kDebugMode) {
      print('🗺️ Parsing location: ${document['name']}');
      print('   Raw coordinates: lat=$rawLat, lng=$rawLng');
      print('   Parsed coordinates: lat=$latitude, lng=$longitude');
    }

    return ParkingLocation(
      id: document['\$id'] ?? '',
      name: document['name'] ?? '',
      address: document['address'] ?? '',
      latitude: latitude,
      longitude: longitude,
      totalSpots: document['totalSpots'] ?? 0,
      availableSpots: document['availableSpots'] ?? 0,
      hourlyRate: (document['hourlyRate'] ?? 0.0).toDouble(),
      isActive: document['isActive'] ?? true,
      description: document['description'],
      amenities: _parseStringList(document['amenities']),
      images: _parseStringList(document['images']),
      attendantId: document['attendantId'],
      createdAt: DateTime.parse(
          document['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          document['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: _parseMetadata(document['metadata']),
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'totalSpots': totalSpots,
      'availableSpots': availableSpots,
      'hourlyRate': hourlyRate,
      'isActive': isActive,
      'description': description,
      // 🔧 FIX: Convert amenities List<String> to comma-separated string
      'amenities': amenities?.join(','),
      // 🔧 FIX: Convert images List<String> to comma-separated string
      'images': images?.join(','),
      'attendantId': attendantId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create copy with updated fields
  ParkingLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? totalSpots,
    int? availableSpots,
    double? hourlyRate,
    bool? isActive,
    String? description,
    List<String>? amenities,
    List<String>? images,
    String? attendantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ParkingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalSpots: totalSpots ?? this.totalSpots,
      availableSpots: availableSpots ?? this.availableSpots,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      attendantId: attendantId ?? this.attendantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if location has available spots
  bool get hasAvailableSpots => availableSpots > 0;

  /// Get occupancy percentage
  double get occupancyPercentage {
    if (totalSpots == 0) return 0.0;
    return ((totalSpots - availableSpots) / totalSpots) * 100;
  }

  /// Get formatted hourly rate
  String get formattedHourlyRate => '${hourlyRate.toStringAsFixed(0)} ETB/hr';

  /// Calculate distance from user location (Haversine formula)
  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(userLat - latitude);
    final double dLng = _toRadians(userLng - longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(userLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    _distanceFromUser = earthRadius * c;

    return _distanceFromUser!;
  }

  /// Get distance from user (calculate if not already calculated)
  double? getDistanceFromUser(double userLat, double userLng) {
    if (_distanceFromUser == null) {
      calculateDistance(userLat, userLng);
    }
    return _distanceFromUser;
  }

  /// Get formatted distance string
  String getFormattedDistance(double userLat, double userLng) {
    final distance = getDistanceFromUser(userLat, userLng);
    if (distance == null) return 'Distance unavailable';

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  /// Get rating (from metadata or default)
  double get rating {
    if (_rating != null) return _rating!;

    // Try to get rating from metadata
    if (metadata != null && metadata!.containsKey('rating')) {
      _rating = (metadata!['rating'] as num?)?.toDouble() ?? 4.0;
    } else {
      // Default rating based on available spots and hourly rate
      final availabilityRatio =
          totalSpots > 0 ? availableSpots / totalSpots : 0.0;
      final rateScore =
          hourlyRate <= 50 ? 1.0 : (hourlyRate <= 100 ? 0.5 : 0.0);
      _rating = 3.0 + (availabilityRatio * 1.5) + (rateScore * 0.5);
      _rating = _rating!.clamp(1.0, 5.0);
    }

    return _rating!;
  }

  /// Get formatted rating string
  String get formattedRating => '${rating.toStringAsFixed(1)}★';

  /// Get available spots percentage
  double get availabilityPercentage {
    if (totalSpots == 0) return 0.0;
    return (availableSpots / totalSpots) * 100;
  }

  /// Helper method to convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  @override
  String toString() {
    return 'ParkingLocation(id: $id, name: $name, availableSpots: $availableSpots/$totalSpots)';
  }

  /// Helper method to parse string list from database
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;

    // If it's already a list, convert to List<String>
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    // If it's a string, try to parse as comma-separated values
    if (value is String) {
      // Handle empty string
      if (value.trim().isEmpty) return [];

      // Split by comma and clean up
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Helper method to parse metadata from database
  static Map<String, dynamic>? _parseMetadata(dynamic value) {
    if (value == null) return null;

    // If it's already a Map, return it
    if (value is Map<String, dynamic>) {
      return value;
    }

    // If it's a string, try to parse as JSON
    if (value is String) {
      // Handle empty string
      if (value.trim().isEmpty) return null;

      try {
        // Try to parse as JSON
        if (value.startsWith('{') && value.endsWith('}')) {
          return <String, dynamic>{};
        }
      } catch (e) {
        // If parsing fails, return empty map
        return <String, dynamic>{};
      }
    }

    return null;
  }
}
