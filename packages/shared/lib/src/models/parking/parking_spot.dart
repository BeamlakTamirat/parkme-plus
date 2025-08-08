import '../vehicle/vehicle_type.dart';

/// Parking spot status
enum ParkingSpotStatus {
  available,
  occupied,
  reserved,
  maintenance,
  disabled,
}

/// Parking spot type
enum ParkingSpotType {
  standard,
  regular,
  compact,
  large,
  handicap,
  electric,
  vip,
  motorcycle,
}

/// Individual parking spot within a parking location
class ParkingSpot {
  final String id;
  final String locationId;
  final String parkingLocationId;
  final String spotNumber;
  final ParkingSpotType type;
  final ParkingSpotStatus status;
  final List<VehicleType> supportedVehicleTypes;
  final double hourlyRate;
  final bool isDisabledAccessible;
  final bool isEvChargingSpot;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParkingSpot({
    required this.id,
    required this.locationId,
    required this.parkingLocationId,
    required this.spotNumber,
    required this.type,
    required this.status,
    required this.supportedVehicleTypes,
    required this.hourlyRate,
    required this.isDisabledAccessible,
    required this.isEvChargingSpot,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated values
  ParkingSpot copyWith({
    String? id,
    String? locationId,
    String? parkingLocationId,
    String? spotNumber,
    ParkingSpotType? type,
    ParkingSpotStatus? status,
    List<VehicleType>? supportedVehicleTypes,
    double? hourlyRate,
    bool? isDisabledAccessible,
    bool? isEvChargingSpot,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      parkingLocationId: parkingLocationId ?? this.parkingLocationId,
      spotNumber: spotNumber ?? this.spotNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      supportedVehicleTypes: supportedVehicleTypes ?? this.supportedVehicleTypes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isDisabledAccessible: isDisabledAccessible ?? this.isDisabledAccessible,
      isEvChargingSpot: isEvChargingSpot ?? this.isEvChargingSpot,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if spot is available
  bool get isAvailable => status == ParkingSpotStatus.available && isActive;

  /// Check if spot supports specific vehicle type
  bool supportsVehicleType(VehicleType vehicleType) {
    return supportedVehicleTypes.contains(vehicleType);
  }

  @override
  String toString() {
    return 'ParkingSpot(id: $id, spotNumber: $spotNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParkingSpot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
