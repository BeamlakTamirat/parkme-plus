import '../common/location.dart';
import 'parking_amenities.dart';

/// Parking location model representing a parking facility
class ParkingLocation {
  final String id;
  final String name;
  final String address;
  final String description;
  final double latitude;
  final double longitude;
  final Location coordinates;
  final int totalSpots;
  final int availableSpots;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final ParkingAmenities amenities;
  final Map<String, Map<String, String>> operatingHours;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParkingLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.coordinates,
    required this.totalSpots,
    required this.availableSpots,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.operatingHours,
    this.images = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated values
  ParkingLocation copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
    Location? coordinates,
    int? totalSpots,
    int? availableSpots,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    ParkingAmenities? amenities,
    Map<String, Map<String, String>>? operatingHours,
    List<String>? images,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      coordinates: coordinates ?? this.coordinates,
      totalSpots: totalSpots ?? this.totalSpots,
      availableSpots: availableSpots ?? this.availableSpots,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      amenities: amenities ?? this.amenities,
      operatingHours: operatingHours ?? this.operatingHours,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ParkingLocation(id: $id, name: $name, address: $address, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParkingLocation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
