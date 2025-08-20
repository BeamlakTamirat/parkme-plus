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

  const ParkingLocation({
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
    return ParkingLocation(
      id: document['\$id'] ?? '',
      name: document['name'] ?? '',
      address: document['address'] ?? '',
      latitude: (document['latitude'] ?? 0.0).toDouble(),
      longitude: (document['longitude'] ?? 0.0).toDouble(),
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
      'amenities': amenities,
      'images': images,
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
          // For now, just return empty map for JSON strings
          // You can implement proper JSON parsing if needed
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
