/// Amenities available at a parking location
class ParkingAmenities {
  final bool hasEVCharging;
  final bool hasCCTV;
  final bool hasSecurity;
  final bool hasRoofCover;
  final bool hasRestrooms;
  final bool hasCarWash;
  final bool hasValetService;
  final bool hasHandicapAccess;
  final bool has24x7Access;
  final bool hasDisabledAccess;
  final bool hasElevator;
  final bool hasEvCharging;
  final bool hasRestroom;
  final bool isCovered;

  const ParkingAmenities({
    this.hasEVCharging = false,
    this.hasCCTV = false,
    this.hasSecurity = false,
    this.hasRoofCover = false,
    this.hasRestrooms = false,
    this.hasCarWash = false,
    this.hasValetService = false,
    this.hasHandicapAccess = false,
    this.has24x7Access = false,
    this.hasDisabledAccess = false,
    this.hasElevator = false,
    this.hasEvCharging = false,
    this.hasRestroom = false,
    this.isCovered = false,
  });

  /// Create a copy with updated values
  ParkingAmenities copyWith({
    bool? hasEVCharging,
    bool? hasCCTV,
    bool? hasSecurity,
    bool? hasRoofCover,
    bool? hasRestrooms,
    bool? hasCarWash,
    bool? hasValetService,
    bool? hasHandicapAccess,
    bool? has24x7Access,
    bool? hasDisabledAccess,
    bool? hasElevator,
    bool? hasEvCharging,
    bool? hasRestroom,
    bool? isCovered,
  }) {
    return ParkingAmenities(
      hasEVCharging: hasEVCharging ?? this.hasEVCharging,
      hasCCTV: hasCCTV ?? this.hasCCTV,
      hasSecurity: hasSecurity ?? this.hasSecurity,
      hasRoofCover: hasRoofCover ?? this.hasRoofCover,
      hasRestrooms: hasRestrooms ?? this.hasRestrooms,
      hasCarWash: hasCarWash ?? this.hasCarWash,
      hasValetService: hasValetService ?? this.hasValetService,
      hasHandicapAccess: hasHandicapAccess ?? this.hasHandicapAccess,
      has24x7Access: has24x7Access ?? this.has24x7Access,
      hasDisabledAccess: hasDisabledAccess ?? this.hasDisabledAccess,
      hasElevator: hasElevator ?? this.hasElevator,
      hasEvCharging: hasEvCharging ?? this.hasEvCharging,
      hasRestroom: hasRestroom ?? this.hasRestroom,
      isCovered: isCovered ?? this.isCovered,
    );
  }

  /// Get list of available amenities
  List<String> get availableAmenities {
    final amenities = <String>[];
    if (hasEVCharging || hasEvCharging) amenities.add('EV Charging');
    if (hasCCTV) amenities.add('CCTV');
    if (hasSecurity) amenities.add('Security');
    if (hasRoofCover || isCovered) amenities.add('Covered');
    if (hasRestrooms || hasRestroom) amenities.add('Restrooms');
    if (hasCarWash) amenities.add('Car Wash');
    if (hasValetService) amenities.add('Valet Service');
    if (hasHandicapAccess || hasDisabledAccess) amenities.add('Disabled Access');
    if (has24x7Access) amenities.add('24/7 Access');
    if (hasElevator) amenities.add('Elevator');
    return amenities;
  }

  @override
  String toString() {
    return 'ParkingAmenities(available: ${availableAmenities.join(', ')})';
  }
}
