class ParkingAmenities {
  final bool isCovered;
  final bool has24x7Access;
  final bool hasSecurity;
  final bool hasEvCharging;
  final bool hasDisabledAccess;
  final bool hasCCTV;
  final bool hasCarWash;
  final bool hasRestroom;
  final bool hasElevator;

  const ParkingAmenities({
    required this.isCovered,
    required this.has24x7Access,
    required this.hasSecurity,
    required this.hasEvCharging,
    required this.hasDisabledAccess,
    required this.hasCCTV,
    required this.hasCarWash,
    required this.hasRestroom,
    required this.hasElevator,
  });

  List<String> get availableAmenities {
    final List<String> amenities = [];
    if (isCovered) amenities.add('Covered');
    if (has24x7Access) amenities.add('24/7 Access');
    if (hasSecurity) amenities.add('Security');
    if (hasEvCharging) amenities.add('EV Charging');
    if (hasDisabledAccess) amenities.add('Disabled Access');
    if (hasCCTV) amenities.add('CCTV');
    if (hasCarWash) amenities.add('Car Wash');
    if (hasRestroom) amenities.add('Restroom');
    if (hasElevator) amenities.add('Elevator');
    return amenities;
  }
}
