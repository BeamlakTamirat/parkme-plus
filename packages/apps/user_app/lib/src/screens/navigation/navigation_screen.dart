import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

/// 🧭 Advanced Navigation Screen with Route Display
/// Shows shortest path from user location to booked parking spot
class NavigationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? navigationData;

  const NavigationScreen({
    super.key,
    this.navigationData,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  Position? _userLocation;
  ParkingLocation? _targetLocation;
  Booking? _booking;
  Map<String, dynamic>? _routeData;
  bool _isLoadingLocation = false;
  bool _isLoadingRoute = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    try {
      // Extract data from navigation parameters
      final data = widget.navigationData;
      if (data == null) {
        setState(() => _error = 'No navigation data provided');
        return;
      }

      _booking = data['booking'] as Booking?;
      if (_booking == null) {
        setState(() => _error = 'Invalid booking data');
        return;
      }

      if (kDebugMode) {
        print('🧭 Initializing navigation for booking: ${_booking!.id}');
        print('🎯 Target parking location: ${_booking!.parkingLocationId}');
      }

      // Load target parking location
      await _loadTargetLocation();

      // Get user location and calculate route
      await _getUserLocationAndCalculateRoute();
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing navigation: $e');
      setState(() => _error = 'Failed to initialize navigation: $e');
    }
  }

  Future<void> _loadTargetLocation() async {
    try {
      final locations = await ref.read(parkingLocationsProvider.future);
      _targetLocation = locations.firstWhere(
        (location) => location.id == _booking!.parkingLocationId,
        orElse: () => throw Exception('Parking location not found'),
      );

      if (kDebugMode) {
        print('✅ Target location loaded: ${_targetLocation!.name}');
        print(
            '📍 Coordinates: ${_targetLocation!.latitude}, ${_targetLocation!.longitude}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading target location: $e');
      throw Exception('Could not find parking location');
    }
  }

  Future<void> _getUserLocationAndCalculateRoute() async {
    if (!mounted) return; // Check if widget is still mounted

    setState(() => _isLoadingLocation = true);

    try {
      // Try multiple location methods with better error handling
      Position? position;

      // Method 1: Try to get last known position first (faster)
      try {
        position = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: false,
        );
        if (kDebugMode && position != null) {
          print(
              '📍 Using last known location: ${position.latitude}, ${position.longitude}');
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Could not get last known position: $e');
      }

      // Method 2: If no last known position, get current location with extended timeout
      if (position == null) {
        if (kDebugMode) {
          print('📍 Getting current location with extended timeout...');
        }

        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 30), // Extended timeout
          );
        } on TimeoutException {
          // Method 3: Fallback to lower accuracy but faster
          if (kDebugMode) {
            print('⚠️ High accuracy timed out, trying medium accuracy...');
          }
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
            );
          } on TimeoutException {
            if (kDebugMode) print('❌ All location methods timed out');
            position = null; // Explicitly set to null if all methods fail
          }
        }
      }

      if (position == null) {
        throw Exception(
            'Unable to get your location. Please:\n• Enable GPS/Location Services\n• Grant location permission to WePark\n• Ensure you have network connectivity\n• Try again in an open area');
      }

      if (!mounted) return; // Check again before setState

      setState(() {
        _userLocation = position;
        _isLoadingLocation = false;
        _isLoadingRoute = true;
      });

      if (kDebugMode) {
        print(
            '✅ User location obtained: ${position.latitude}, ${position.longitude}');
        print('🗺️ Calculating route to parking location...');
      }

      // Calculate route from user location to parking location
      final mapboxService = MapboxService.instance;
      final routeData = await mapboxService.getRoute(
        position.latitude,
        position.longitude,
        _targetLocation!.latitude,
        _targetLocation!.longitude,
      );

      if (!mounted) return; // Check before final setState

      if (routeData == null) {
        throw Exception('Could not calculate route to parking location');
      }

      if (!mounted) return; // Check before final setState

      setState(() {
        _routeData = routeData;
        _isLoadingRoute = false;
      });

      if (kDebugMode) {
        final distanceKm = (routeData['distance'] as double) / 1000;
        final durationMin = (routeData['duration'] as double) / 60;
        print(
            '✅ Route calculated: ${distanceKm.toStringAsFixed(1)}km, ${durationMin.toStringAsFixed(0)} minutes');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error getting location/route: $e');

      if (!mounted) return; // Check before error setState

      setState(() {
        _error = e.toString();
        _isLoadingLocation = false;
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Navigation',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_targetLocation != null)
              Text(
                'To ${_targetLocation!.name}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _getUserLocationAndCalculateRoute,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_isLoadingLocation) {
      return _buildLoadingWidget('Getting your location...');
    }

    if (_userLocation == null || _targetLocation == null) {
      return _buildLoadingWidget('Loading navigation data...');
    }

    // Wait for route calculation to complete before showing map
    if (_isLoadingRoute) {
      return _buildLoadingWidget('Calculating route...');
    }

    return Column(
      children: [
        // Route summary card
        _buildRouteSummaryCard(),

        // Interactive map with route
        Expanded(
          child: _buildNavigationMap(),
        ),

        // Navigation actions
        _buildNavigationActions(),
      ],
    );
  }

  Widget _buildRouteSummaryCard() {
    if (_isLoadingRoute) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Calculating route...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_routeData == null) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Expanded(
                child: Text('Route could not be calculated',
                    style: TextStyle(fontSize: 12))),
          ],
        ),
      );
    }

    final distanceKm = (_routeData!['distance'] as double) / 1000;
    final durationMin = (_routeData!['duration'] as double) / 60;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.route, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${distanceKm.toStringAsFixed(1)} km • ${durationMin.toStringAsFixed(0)} min',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'Optimal route to parking',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575), // Colors.grey[600]
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Removed unused _buildRouteMetric method

  Widget _buildNavigationMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: NavigationMapWidget(
          key: ValueKey(
              'navigation_map_${_routeData?.hashCode ?? 'null'}'), // Force rebuild when route data changes
          userLocation: _userLocation!,
          targetLocation: _targetLocation!,
          routeData: _routeData, // Always pass route data, even if null
          booking: _booking!,
        ),
      ),
    );
  }

  Widget _buildNavigationActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startNavigation,
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _callSupport,
              icon: const Icon(Icons.support_agent),
              label: const Text('Support'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startNavigation() async {
    if (_userLocation == null || _targetLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Unable to start navigation - location data missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      
      final String mapsUrl;

      // Detect platform and create appropriate URL
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Use Google Maps URL scheme for Android
        mapsUrl =
            'google.navigation:q=${_targetLocation!.latitude},${_targetLocation!.longitude}&mode=d';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Use Apple Maps URL scheme for iOS
        mapsUrl =
            'maps:///?daddr=${_targetLocation!.latitude},${_targetLocation!.longitude}&dirflg=d';
      } else {
        // Web fallback - open in browser
        mapsUrl =
            'https://www.google.com/maps/dir/?api=1&destination=${_targetLocation!.latitude},${_targetLocation!.longitude}&travelmode=driving';
      }

      if (await canLaunchUrl(Uri.parse(mapsUrl))) {
        await launchUrl(
          Uri.parse(mapsUrl),
          mode: LaunchMode.externalApplication,
        );

        if (kDebugMode) {
          print('🧭 Opened navigation app with URL: $mapsUrl');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧭 Navigation started to ${_targetLocation!.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Fallback: Open in web browser
        final webUrl =
            'https://www.google.com/maps/dir/?api=1&destination=${_targetLocation!.latitude},${_targetLocation!.longitude}&travelmode=driving';

        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(Uri.parse(webUrl),
              mode: LaunchMode.externalApplication);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗺️ Opened directions in web browser'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error starting navigation: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Could not start navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Removed unused methods: _openInMaps and _shareLocation

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 Contacting support...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child:
                  const Icon(Icons.location_off, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _initializeNavigation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Open app settings
                Geolocator.openAppSettings();
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Open App Settings'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🗺️ Custom Navigation Map Widget with Route Display
class NavigationMapWidget extends ConsumerStatefulWidget {
  final Position userLocation;
  final ParkingLocation targetLocation;
  final Map<String, dynamic>? routeData;
  final Booking booking;
  final Function()? onRouteCalculated; // Callback to notify when route is ready

  const NavigationMapWidget({
    super.key,
    required this.userLocation,
    required this.targetLocation,
    required this.routeData, // Make this required to ensure it's always passed
    required this.booking,
    this.onRouteCalculated,
  });

  @override
  ConsumerState<NavigationMapWidget> createState() =>
      _NavigationMapWidgetState();
}

class _NavigationMapWidgetState extends ConsumerState<NavigationMapWidget> {
  List<ParkingLocation> _allParkingLocations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _loadAllParkingLocations();

    if (kDebugMode) {
      print('🗺️ NavigationMapWidget initialized');
      print('📊 Initial route data: ${widget.routeData != null}');
      if (widget.routeData != null) {
        print('📊 Initial route data keys: ${widget.routeData!.keys.toList()}');
      }
    }
  }

  @override
  void didUpdateWidget(NavigationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if route data has changed
    if (oldWidget.routeData != widget.routeData) {
      if (kDebugMode) {
        print('📊 Route data updated in NavigationMapWidget');
        print('📊 New route data: ${widget.routeData != null}');
        if (widget.routeData != null) {
          print('📊 Route data keys: ${widget.routeData!.keys.toList()}');
        }
      }

      // Force rebuild when route data changes
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadAllParkingLocations() async {
    try {
      final locations = await ref.read(parkingLocationsProvider.future);
      if (mounted) {
        setState(() {
          _allParkingLocations = locations;
          _isLoadingLocations = false;
        });

        if (kDebugMode) {
          print(
              '🗺️ Loaded ${locations.length} parking locations for navigation map');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading parking locations: $e');
      // Fallback to just showing the target location
      if (mounted) {
        setState(() {
          _allParkingLocations = [widget.targetLocation];
          _isLoadingLocations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocations) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 8),
              Text('Loading map locations...')
            ],
          ),
        ),
      );
    }

    // Debug route data passing
    if (kDebugMode) {
      print(
          '📊 NavigationMapWidget building with route data: ${widget.routeData != null}');
      if (widget.routeData != null) {
        print('📊 Route data keys: ${widget.routeData!.keys.toList()}');
      }
    }

    return InteractiveMapboxWidget(
      // Center map between user and target location
      centerLat:
          (widget.userLocation.latitude + widget.targetLocation.latitude) / 2,
      centerLng:
          (widget.userLocation.longitude + widget.targetLocation.longitude) / 2,
      initialZoom: 13.0, // Slightly zoomed out to show more locations
      userLocationLat: widget.userLocation.latitude,
      userLocationLng: widget.userLocation.longitude,
      parkingLocations: _allParkingLocations, // Show ALL parking locations
      routeData: widget.routeData, // Pass route data from NavigationMapWidget
      showMarkers: true,
      showCurrentLocation: true,
      showZoomControls: true,
      showStyleToggle: true, // Enable style toggle for navigation
      showExpandButton: false, // Remove expand button from navigation screen
      onLocationSelected: (lat, lng) {
        if (kDebugMode) {
          print('📍 Map location selected: $lat, $lng');
        }
      },
      onStyleChanged: (styleName) {
        if (kDebugMode) {
          print('🎨 Navigation map style changed to: $styleName');
        }
      },
    );
  }
}
