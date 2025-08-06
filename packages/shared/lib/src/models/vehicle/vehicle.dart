import 'vehicle_type.dart';

class Vehicle {
  final String id;
  final String userId;
  final String licensePlate;
  final String make;
  final String model;
  final String color;
  final int? year;
  final VehicleType type;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.color,
    this.year,
    required this.type,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$make $model';
  
  String get fullDetails => 
      '$make $model${year != null ? ' ($year)' : ''} - $licensePlate';

  Vehicle copyWith({
    String? id,
    String? userId,
    String? licensePlate,
    String? make,
    String? model,
    String? color,
    int? year,
    VehicleType? type,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      color: color ?? this.color,
      year: year ?? this.year,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
 