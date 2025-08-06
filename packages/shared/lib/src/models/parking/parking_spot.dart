class ParkingSpot {
  final String id;
  final String locationId;
  final String spotNumber;
  final ParkingSpotType type;
  final ParkingSpotStatus status;
  final double? length;
  final double? width;
  final String? floor;
  final String? section;
  final bool isEvChargingSpot;
  final bool isDisabledAccessible;
  final DateTime? reservedUntil;
  final String? currentBookingId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSpot({
    required this.id,
    required this.locationId,
    required this.spotNumber,
    required this.type,
    required this.status,
    this.length,
    this.width,
    this.floor,
    this.section,
    required this.isEvChargingSpot,
    required this.isDisabledAccessible,
    this.reservedUntil,
    this.currentBookingId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable =>
      status == ParkingSpotStatus.available &&
      (reservedUntil == null || DateTime.now().isAfter(reservedUntil!));

  bool get isOccupied => status == ParkingSpotStatus.occupied;

  bool get isReserved =>
      reservedUntil != null && DateTime.now().isBefore(reservedUntil!);

  String get displayName =>
      '$spotNumber${floor != null ? ' (Floor $floor)' : ''}';
}

enum ParkingSpotType {
  standard,
  compact,
  large,
  motorcycle,
  evCharging,
  disabled,
}

enum ParkingSpotStatus {
  available,
  occupied,
  reserved,
  maintenance,
  outOfService,
}
