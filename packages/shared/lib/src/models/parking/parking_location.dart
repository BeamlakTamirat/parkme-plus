import '../common/location.dart';
import 'parking_amenities.dart';

class ParkingLocation {
  final String id;
  final String name;
  final String description;
  final String address;
  final Location coordinates;
  final List<String> images;
  final ParkingAmenities amenities;
  final int totalSpots;
  final int availableSpots;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? operatorId;

  const ParkingLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coordinates,
    required this.images,
    required this.amenities,
    required this.totalSpots,
    required this.availableSpots,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.operatorId,
  });

  ParkingLocation copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    Location? coordinates,
    List<String>? images,
    ParkingAmenities? amenities,
    int? totalSpots,
    int? availableSpots,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? operatorId,
  }) {
    return ParkingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      totalSpots: totalSpots ?? this.totalSpots,
      availableSpots: availableSpots ?? this.availableSpots,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      operatorId: operatorId ?? this.operatorId,
    );
  }

  double get distance => 0.0; // Will be calculated based on user location
  
  bool get hasAvailableSpots => availableSpots > 0;
} 