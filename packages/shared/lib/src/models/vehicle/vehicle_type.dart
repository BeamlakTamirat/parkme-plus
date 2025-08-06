enum VehicleType {
  car,
  suv,
  truck,
  motorcycle,
  van,
  electric;

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.van:
        return 'Van';
      case VehicleType.electric:
        return 'Electric Vehicle';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.suv:
        return '🚙';
      case VehicleType.truck:
        return '🚚';
      case VehicleType.motorcycle:
        return '🏍️';
      case VehicleType.van:
        return '🚐';
      case VehicleType.electric:
        return '🔋';
    }
  }
}
