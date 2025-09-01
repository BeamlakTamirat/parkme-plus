import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';
import '../models/parking/parking_location.dart';

/// Interactive Mapbox widget for WePark
/// Provides real-time interactive map with parking locations
class InteractiveMapboxWidget extends StatefulWidget {
  final List<ParkingLocation> parkingLocations;
  final bool showCurrentLocation;
  final bool showMarkers;
  final bool showZoomControls;
  final Function(double lat, double lng)? onLocationSelected;
  final double initialZoom;
  final double centerLat;
  final double centerLng;

  const InteractiveMapboxWidget({
    super.key,
    this.parkingLocations = const [],
    this.showCurrentLocation = true,
    this.showMarkers = true,
    this.showZoomControls = true,
    this.onLocationSelected,
    this.initialZoom = 15.0,
    this.centerLat = 9.0120, // Meskel Square - Famous landmark in Addis Ababa
    this.centerLng = 38.7634,
  });

  @override
  State<InteractiveMapboxWidget> createState() =>
      _InteractiveMapboxWidgetState();
}

class _InteractiveMapboxWidgetState extends State<InteractiveMapboxWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    try {
      if (kDebugMode) {
        print('🗺️ Initializing interactive Mapbox widget...');
        print('📍 Center: ${widget.centerLat}, ${widget.centerLng}');
        print('🏢 Parking locations: ${widget.parkingLocations.length}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing interactive map: $e');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    try {
      // Set the map style
      await _mapboxMap?.loadStyleURI(MapboxConfig.styleUrl);

      // Create point annotation manager for markers
      _pointAnnotationManager =
          await _mapboxMap?.annotations.createPointAnnotationManager();

      // Add parking location markers
      await _addParkingMarkers();

      if (kDebugMode) {
        print('✅ Interactive map created and configured');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configuring map: $e');
      }
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _addParkingMarkers() async {
    if (_pointAnnotationManager == null || widget.parkingLocations.isEmpty) {
      if (kDebugMode) print('⚠️ No annotation manager or no locations');
      return;
    }

    try {
      final annotations = <PointAnnotationOptions>[];

      for (final location in widget.parkingLocations) {
        // if (!_isValidEthiopianCoordinate(location.latitude, location.longitude)) {
        //   continue;
        // }

        final annotation = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(location.longitude, location.latitude)),
          textField: "${location.name}", // ✅ EMOJI MARKER
          textOffset: [0.0, -1.5],
          textColor: const Color.fromARGB(255, 255, 149, 0).value,
          textSize: 12.5,
          textHaloColor: const Color.fromARGB(255, 220, 138, 30).value,
          textHaloWidth: 1.15,
        );
        annotations.add(annotation);

        if (kDebugMode) {
          print(
              '✅ Created marker for: ${location.name} at ${location.latitude}, ${location.longitude}');
        }
      }

      if (annotations.isNotEmpty) {
        await _pointAnnotationManager?.createMulti(annotations);
        if (kDebugMode) {
          print('🎉 SUCCESS: Added ${annotations.length} markers to map!');
        }
      } else {
        if (kDebugMode) print('⚠️ No valid annotations to add');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding markers: $e');
      }
    }
  }

  bool _isValidEthiopianCoordinate(double lat, double lng) {
    // Ethiopia bounds check (approximate)
    return lat >= 3.0 && lat <= 15.0 && lng >= 33.0 && lng <= 48.0;
  }

  void _onMapTap(MapContentGestureContext context) {
    if (kDebugMode) {
      print('🗺️ Map tapped at coordinate: ${context.point}');
    }

    // Extract lat/lng from the tap context point
    if (widget.onLocationSelected != null) {
      // Convert Point to lat/lng coordinates
      final point = context.point;
      final coordinates = point.coordinates;
      final lng = coordinates.lng.toDouble();
      final lat = coordinates.lat.toDouble();
      widget.onLocationSelected!(lat, lng);
      return;

      // Fallback to center coordinates
      widget.onLocationSelected!(widget.centerLat, widget.centerLng);
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Interactive Map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Map Failed to Load',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive map unavailable',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Debug: $error',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[500],
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Interactive Mapbox Map
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(
                  coordinates: Position(widget.centerLng, widget.centerLat)),
              zoom: widget.initialZoom,
            ),
            styleUri: MapboxConfig.styleUrl,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
          ),

          // Map attribution
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© Mapbox',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          // Debug info
          if (kDebugMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Interactive Map\n${widget.parkingLocations.length} locations',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pointAnnotationManager?.deleteAll();
    super.dispose();
  }
}
