import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared/shared.dart';

// Authentication Providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final authStateProvider = StreamProvider<auth.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<auth.User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Database Providers
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

// Parking Service Providers
final parkingServiceProvider = Provider<ParkingService>((ref) {
  return ParkingService.instance;
});

final nearbyParkingLocationsProvider =
    FutureProvider.family<ServiceResult<List<ParkingLocation>>, LocationParams>(
        (ref, params) async {
  final parkingService = ref.watch(parkingServiceProvider);
  return await parkingService.getNearbyParkingLocations(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
    limit: params.limit,
  );
});

final parkingLocationByIdProvider =
    FutureProvider.family<ServiceResult<ParkingLocation?>, String>(
        (ref, locationId) async {
  final parkingService = ref.watch(parkingServiceProvider);
  return await parkingService.getParkingLocationById(locationId);
});

// Real-time Parking Locations Stream
final parkingLocationsStreamProvider =
    StreamProvider<ServiceResult<List<ParkingLocation>>>((ref) {
  final parkingService = ref.watch(parkingServiceProvider);
  return parkingService.streamParkingLocations();
});

// Available Parking Spots Provider
final availableParkingSpotsProvider =
    FutureProvider.family<ServiceResult<List<ParkingSpot>>, SpotQueryParams>(
        (ref, params) async {
  final parkingService = ref.watch(parkingServiceProvider);
  return await parkingService.getAvailableParkingSpots(
    locationId: params.locationId,
    startTime: params.startTime,
    endTime: params.endTime,
    vehicleType: params.vehicleType,
  );
});

// Search Provider
final searchResultsProvider =
    FutureProvider.family<ServiceResult<List<ParkingLocation>>, SearchParams>(
        (ref, params) async {
  final parkingService = ref.watch(parkingServiceProvider);
  return await parkingService.searchParkingLocations(
    query: params.query,
    latitude: params.latitude,
    longitude: params.longitude,
    maxDistance: params.maxDistance,
    vehicleType: params.vehicleType,
    maxHourlyRate: params.maxHourlyRate,
  );
});

// User State Management
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
});

// Loading State Providers
final isLoadingProvider = StateProvider<bool>((ref) => false);
final loadingMessageProvider = StateProvider<String?>((ref) => null);

// Error State Provider
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Helper Classes for Provider Parameters
class LocationParams {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final int limit;

  LocationParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusKm == other.radiusKm &&
          limit == other.limit;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      radiusKm.hashCode ^
      limit.hashCode;
}

class SpotQueryParams {
  final String locationId;
  final DateTime? startTime;
  final DateTime? endTime;
  final VehicleType? vehicleType;

  SpotQueryParams({
    required this.locationId,
    this.startTime,
    this.endTime,
    this.vehicleType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotQueryParams &&
          runtimeType == other.runtimeType &&
          locationId == other.locationId &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          vehicleType == other.vehicleType;

  @override
  int get hashCode =>
      locationId.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      vehicleType.hashCode;
}

class SearchParams {
  final String query;
  final double? latitude;
  final double? longitude;
  final double? maxDistance;
  final VehicleType? vehicleType;
  final double? maxHourlyRate;

  SearchParams({
    required this.query,
    this.latitude,
    this.longitude,
    this.maxDistance,
    this.vehicleType,
    this.maxHourlyRate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          maxDistance == other.maxDistance &&
          vehicleType == other.vehicleType &&
          maxHourlyRate == other.maxHourlyRate;

  @override
  int get hashCode =>
      query.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      maxDistance.hashCode ^
      vehicleType.hashCode ^
      maxHourlyRate.hashCode;
}
