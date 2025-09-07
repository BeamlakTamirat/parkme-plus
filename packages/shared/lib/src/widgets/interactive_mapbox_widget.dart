import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';
import '../models/parking/parking_location.dart';

/// Interactive Mapbox widget for WePark
/// Provides real-time interactive map with parking locations and style switching
class InteractiveMapboxWidget extends StatefulWidget {
  final List<ParkingLocation> parkingLocations;
  final bool showCurrentLocation;
  final bool showMarkers;
  final bool showZoomControls;
  final bool showStyleToggle;
  final bool showExpandButton;
  final Function(double lat, double lng)? onLocationSelected;
  final Function(String)? onStyleChanged;
  final Function(bool)? onExpandChanged; // Callback when expand state changes
  final double initialZoom;
  final double centerLat;
  final double centerLng;
  final double? userLocationLat;
  final double? userLocationLng;
  final Map<String, dynamic>? routeData;
  final String? initialStyleUrl;

  const InteractiveMapboxWidget({
    super.key,
    this.parkingLocations = const [],
    this.showCurrentLocation = true,
    this.showMarkers = true,
    this.showZoomControls = true,
    this.showStyleToggle = true,
    this.showExpandButton = true,
    this.onLocationSelected,
    this.onStyleChanged,
    this.onExpandChanged,
    this.initialZoom = 15.0,
    this.centerLat = 9.0120, // Meskel Square - Famous landmark in Addis Ababa
    this.centerLng = 38.7634,
    this.userLocationLat,
    this.userLocationLng,
    this.routeData,
    this.initialStyleUrl,
  });

  @override
  State<InteractiveMapboxWidget> createState() =>
      _InteractiveMapboxWidgetState();
}

class _InteractiveMapboxWidgetState extends State<InteractiveMapboxWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  bool _isLoading = true;
  String? _error;
  String _currentStyleUrl = '';
  bool _showStyleSelector = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentStyleUrl = widget.initialStyleUrl ?? MapboxConfig.styleUrl;
    _initializeMap();
  }

  void _initializeMap() async {
    try {
      if (kDebugMode) {
        print('🗺️ Initializing interactive Mapbox widget...');
        print('📍 Center: ${widget.centerLat}, ${widget.centerLng}');
        print('🏢 Parking locations: ${widget.parkingLocations.length}');
        print('🛣️ Route data provided: ${widget.routeData != null}');
        if (widget.routeData != null) {
          print('🛣️ Route data keys: ${widget.routeData!.keys.toList()}');
        }
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
      await _mapboxMap?.loadStyleURI(_currentStyleUrl);

      // Create annotation managers for markers and lines
      _pointAnnotationManager =
          await _mapboxMap?.annotations.createPointAnnotationManager();
      _polylineAnnotationManager =
          await _mapboxMap?.annotations.createPolylineAnnotationManager();

      if (kDebugMode) {
        print('✅ Created annotation managers');
        print('📍 Point manager: ${_pointAnnotationManager != null}');
        print('🛣️ Polyline manager: ${_polylineAnnotationManager != null}');
      }

      // Add parking location markers
      await _addParkingMarkers();

      // Add user location marker
      await _addUserLocationMarker();

      // Add route visualization if route data is provided
      await _addRouteVisualization();

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

  /// 🗺️ Change map style dynamically
  Future<void> _changeMapStyle(String newStyleUrl, String styleName) async {
    if (_mapboxMap == null) return;

    try {
      if (kDebugMode) {
        print('🎨 Changing map style to: $styleName');
        print('🔗 Style URL: $newStyleUrl');
      }

      // Load the new style
      await _mapboxMap!.loadStyleURI(newStyleUrl);

      // Update current style
      setState(() {
        _currentStyleUrl = newStyleUrl;
        _showStyleSelector = false;
      });

      // Re-add all annotations after style change
      await _reAddAllAnnotations();

      // Notify parent widget
      widget.onStyleChanged?.call(styleName);

      if (kDebugMode) {
        print('✅ Map style changed successfully to: $styleName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error changing map style: $e');
      }
      setState(() {
        _error = 'Failed to change map style: $e';
      });
    }
  }

  /// 🔄 Re-add all annotations after style change
  Future<void> _reAddAllAnnotations() async {
    try {
      // Clear existing annotations
      await _pointAnnotationManager?.deleteAll();
      await _polylineAnnotationManager?.deleteAll();

      // Re-create annotation managers
      _pointAnnotationManager =
          await _mapboxMap?.annotations.createPointAnnotationManager();
      _polylineAnnotationManager =
          await _mapboxMap?.annotations.createPolylineAnnotationManager();

      // Re-add all content
      await _addParkingMarkers();
      await _addUserLocationMarker();
      await _addRouteVisualization();

      if (kDebugMode) {
        print('✅ All annotations re-added after style change');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error re-adding annotations: $e');
      }
    }
  }

  /// 🏢 Add parking location markers to the map with distinctive red markers
  Future<void> _addParkingMarkers() async {
    if (_pointAnnotationManager == null || widget.parkingLocations.isEmpty) {
      if (kDebugMode) print('⚠️ No annotation manager or no locations');
      return;
    }

    try {
      final annotations = <PointAnnotationOptions>[];

      for (final location in widget.parkingLocations) {
        //  LAYER 1: Large Red Circle for High Visibility (exact location)
        final outerMarker = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(location.longitude, location.latitude)),
          textField: "P", // Parking symbol - more reliable than emoji
          textOffset: [0.0, 0.0], // Centered at exact coordinates
          textColor: const Color.fromARGB(255, 220, 53, 69)
              .value, // Bootstrap danger red
          textSize: 28.0, // Slightly smaller for cleaner look
          textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
          textHaloWidth: 2.0, // Reduced halo
        );

        //  LAYER 2: Inner White Dot for Contrast
        final innerMarker = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(location.longitude, location.latitude)),
          textField: "●", // Small white center
          textOffset: [0.0, 0.0], // Centered at exact coordinates
          textColor:
              const Color.fromARGB(255, 255, 255, 255).value, // White center
          textSize: 10.0, // Smaller inner circle
        );

        //  LAYER 4: Location Name Label (exactly above the circle, no gap)
        final nameMarker = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(location.longitude, location.latitude)),
          textField: location.name,
          textOffset: [0.0, -1.8], // Directly above the circle with minimal gap
          textColor: const Color.fromARGB(255, 220, 53, 69).value,
          textSize: 12.50, // Smaller for cleaner appearance
          textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
          textHaloWidth: 1.5, // Reduced halo for cleaner look
        );

        //  LAYER 3: Parking Symbol (more visible than emoji)
        final parkingSymbol = PointAnnotationOptions(
          geometry: Point(
              coordinates: Position(location.longitude, location.latitude)),
          textField: "🅿", // Parking symbol - universally recognized
          textOffset: [0.0, -0.3], // Slightly above center
          textColor: const Color.fromARGB(255, 255, 255, 255).value, // White
          textSize: 18.0, // More prominent size
          textHaloColor:
              const Color.fromARGB(255, 220, 53, 69).value, // Red halo
          textHaloWidth: 4.0, // Even thicker halo for maximum visibility
        );

        // Removed status indicator (green checkmark) - keeping circle, symbol and name
        annotations
            .addAll([outerMarker, innerMarker, parkingSymbol, nameMarker]);

        if (kDebugMode) {
          print(
              '🔴 Added red marker for ${location.name} at ${location.latitude}, ${location.longitude}');
        }
      }

      if (annotations.isNotEmpty) {
        await _pointAnnotationManager?.createMulti(annotations);
        if (kDebugMode) {
          print(
              '✅ Successfully added ${annotations.length} red parking markers');
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

  ///  Add user location marker to show where the user currently is
  Future<void> _addUserLocationMarker() async {
    if (_pointAnnotationManager == null ||
        widget.userLocationLat == null ||
        widget.userLocationLng == null) {
      if (kDebugMode) print('⚠️ No user location to mark');
      return;
    }

    try {
      //  LAYER 1: Outer Ring for Visibility
      final outerRing = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "●", // Large circle
        textOffset: [0.0, 0.0],
        textColor: const Color.fromARGB(120, 0, 150, 255)
            .value, // Semi-transparent blue
        textSize: 35.0, // Very large for outer ring
        textHaloColor: const Color.fromARGB(50, 255, 255, 255).value,
        textHaloWidth: 2.0,
      );

      //  LAYER 2: Inner Dot for Precise Location
      final innerDot = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "●", // Solid circle
        textOffset: [0.0, 0.0],
        textColor: const Color.fromARGB(255, 0, 120, 255).value, // Solid blue
        textSize: 15.0, // Smaller inner circle
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 2.0,
      );

      //  LAYER 3: White Center Point for Maximum Contrast
      final centerPoint = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "●", // Small center
        textOffset: [0.0, 0.0],
        textColor:
            const Color.fromARGB(255, 255, 255, 255).value, // White center
        textSize: 6.0, // Very small center point
      );

      //  LAYER 4: Clear Text Label
      final textLabel = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "", // Clear text without emojis
        textOffset: [0.0, -3.5], // Position above the marker
        textColor: const Color.fromARGB(255, 0, 120, 255).value,
        textSize: 14.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 3.0, // Strong white outline
      );

      //  LAYER 5: Directional Arrows for Extra Visibility
      final arrowNorth = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "▲", // Up arrow
        textOffset: [0.0, -2],
        textColor: const Color.fromARGB(200, 255, 100, 0).value, // Orange arrow
        textSize: 12.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 2.0,
      );

      final arrowSouth = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "▼", // Down arrow
        textOffset: [0.0, 2],
        textColor: const Color.fromARGB(200, 255, 100, 0).value, // Orange arrow
        textSize: 12.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 2.0,
      );

      final arrowWest = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "◄", // Left arrow
        textOffset: [-2, 0.0],
        textColor: const Color.fromARGB(200, 255, 100, 0).value, // Orange arrow
        textSize: 12.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 2.0,
      );

      final arrowEast = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "►", // Right arrow
        textOffset: [2, 0.0],
        textColor: const Color.fromARGB(200, 255, 100, 0).value, // Orange arrow
        textSize: 12.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 2.0,
      );

      // Create all layers in order
      await _pointAnnotationManager?.create(outerRing);
      await _pointAnnotationManager?.create(arrowNorth);
      await _pointAnnotationManager?.create(arrowSouth);
      await _pointAnnotationManager?.create(arrowWest);
      await _pointAnnotationManager?.create(arrowEast);
      await _pointAnnotationManager?.create(innerDot);
      await _pointAnnotationManager?.create(centerPoint);
      await _pointAnnotationManager?.create(textLabel);

      //  LAYER 6: Alternative Fallback Markers (in case symbols don't render)
      final fallbackMarkerA = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "", // Simple X mark
        textOffset: [0.0, 0.0],
        textColor: const Color.fromARGB(255, 255, 0, 0).value, // Red X
        textSize: 20.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 3.0,
      );

      final fallbackMarkerB = PointAnnotationOptions(
        geometry: Point(
            coordinates:
                Position(widget.userLocationLng!, widget.userLocationLat!)),
        textField: "+", // Plus sign
        textOffset: [0.0, 0.0],
        textColor: const Color.fromARGB(255, 0, 255, 0).value, // Green plus
        textSize: 18.0,
        textHaloColor: const Color.fromARGB(255, 0, 0, 0).value,
        textHaloWidth: 2.0,
      );

      // Add fallback markers too
      await _pointAnnotationManager?.create(fallbackMarkerA);
      await _pointAnnotationManager?.create(fallbackMarkerB);

      if (kDebugMode) {
        print(
            '✅ User location marker added at: ${widget.userLocationLat}, ${widget.userLocationLng}');
        print(
            '🎯 Multi-layer marker created: circles, arrows, text, and fallback symbols');
        print('📍 User position now highly visible with professional design');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding user location marker: $e');
      }
    }
  }

  /// 🗺️ Add route visualization as a continuous line from user to parking location
  Future<void> _addRouteVisualization() async {
    if (kDebugMode) {
      print('🛣️ _addRouteVisualization called');
      print('📊 Route data is null: ${widget.routeData == null}');
      print(
          '🛣️ Polyline manager is null: ${_polylineAnnotationManager == null}');
      if (widget.routeData != null) {
        print('📊 Route data keys: ${widget.routeData!.keys.toList()}');
        if (widget.routeData!.containsKey('geometry')) {
          final geometry = widget.routeData!['geometry'];
          if (geometry is Map && geometry.containsKey('coordinates')) {
            final coords = geometry['coordinates'] as List;
            print('📊 Route geometry has ${coords.length} coordinate points');
          }
        }
      }
    }

    if (widget.routeData == null) {
      if (kDebugMode) print('⚠️ No route data for route visualization');
      return;
    }

    if (_polylineAnnotationManager == null) {
      if (kDebugMode) print('⚠️ Polyline annotation manager not initialized');
      return;
    }

    try {
      final geometry = widget.routeData!['geometry'];
      if (geometry == null) {
        if (kDebugMode) print('⚠️ No geometry data in route');
        return;
      }

      // Extract coordinates from the route geometry
      final coordinates = geometry['coordinates'] as List;
      if (coordinates.isEmpty) {
        if (kDebugMode) print('⚠️ No coordinates in route geometry');
        return;
      }

      if (kDebugMode) {
        print('🛣️ Drawing route line with ${coordinates.length} points');
        final distance = (widget.routeData!['distance'] as double) / 1000;
        final duration = (widget.routeData!['duration'] as double) / 60;
        print(
            '📊 Route: ${distance.toStringAsFixed(1)}km, ${duration.toStringAsFixed(0)} min');
      }

      // Convert coordinates to Position objects for polyline
      final routePositions = <Position>[];
      for (final coord in coordinates) {
        final coordList = coord as List;
        final lng = coordList[0] as double;
        final lat = coordList[1] as double;
        routePositions.add(Position(lng, lat));
      }

      // Create polyline if manager is available
      if (_polylineAnnotationManager != null) {
        // Create a white outline for better visibility
        final routeOutline = PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePositions),
          lineColor:
              const Color.fromARGB(255, 255, 255, 255).value, // White outline
          lineWidth: 8.0, // Slightly thicker for outline effect
          lineOpacity: 0.8,
        );

        // Create the main route polyline (thick blue line)
        final mainRouteLine = PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePositions),
          lineColor:
              const Color.fromARGB(255, 0, 123, 255).value, // Bright blue
          lineWidth: 5.0, // Thick line for visibility
          lineOpacity: 0.9,
        );

        // Add the lines (outline first, then main line)
        await _polylineAnnotationManager?.create(routeOutline);
        await _polylineAnnotationManager?.create(mainRouteLine);

        if (kDebugMode) {
          print('✅ Successfully added route polyline');
        }
      }

      // Add directional arrows and endpoint markers using point annotations
      await _addRouteDirectionMarkers(coordinates);
      await _addRouteEndpointMarkers(coordinates);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding route visualization: $e');
      }
    }
  }

  /// Add direction arrows along the route for better navigation guidance
  Future<void> _addRouteDirectionMarkers(List coordinates) async {
    if (_pointAnnotationManager == null) return;

    try {
      final directionMarkers = <PointAnnotationOptions>[];
      final totalPoints = coordinates.length;
      final arrowInterval =
          (totalPoints / 6).ceil(); // Show ~6 arrows along route

      for (int i = arrowInterval;
          i < coordinates.length - arrowInterval;
          i += arrowInterval) {
        final currentCoord = coordinates[i] as List;
        final currentLng = currentCoord[0] as double;
        final currentLat = currentCoord[1] as double;

        // Create direction arrow marker
        final arrowMarker = PointAnnotationOptions(
          geometry: Point(coordinates: Position(currentLng, currentLat)),
          textField: "▶", // Direction arrow
          textOffset: [0.0, 0.0],
          textColor:
              const Color.fromARGB(255, 255, 255, 255).value, // White arrow
          textSize: 12.0,
          textHaloColor:
              const Color.fromARGB(255, 0, 123, 255).value, // Blue halo
          textHaloWidth: 2.0,
        );

        directionMarkers.add(arrowMarker);
      }

      if (directionMarkers.isNotEmpty) {
        await _pointAnnotationManager?.createMulti(directionMarkers);
        if (kDebugMode) {
          print('✅ Added ${directionMarkers.length} direction arrows');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error adding direction markers: $e');
    }
  }

  /// Add special markers for route start and end points
  Future<void> _addRouteEndpointMarkers(List coordinates) async {
    if (_pointAnnotationManager == null || coordinates.isEmpty) return;

    try {
      final startCoord = coordinates.first as List;
      final endCoord = coordinates.last as List;

      final endpointMarkers = <PointAnnotationOptions>[];

      // Start marker (green circle)
      final startMarker = PointAnnotationOptions(
        geometry: Point(coordinates: Position(startCoord[0], startCoord[1])),
        textField: "●", // Green start point
        textOffset: [0.0, 0.0],
        textColor: const Color.fromARGB(255, 34, 139, 34).value, // Forest green
        textSize: 18.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 3.0,
      );

      // End marker (red target)
      final endMarker = PointAnnotationOptions(
        geometry: Point(coordinates: Position(endCoord[0], endCoord[1])),
        textField: "●", // Red end point
        textOffset: [0.0, 0.0],
        textColor: const Color.fromARGB(255, 220, 53, 69).value, // Red
        textSize: 18.0,
        textHaloColor: const Color.fromARGB(255, 255, 255, 255).value,
        textHaloWidth: 3.0,
      );

      endpointMarkers.addAll([startMarker, endMarker]);
      await _pointAnnotationManager?.createMulti(endpointMarkers);

      if (kDebugMode) {
        print('✅ Added route start and end markers');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error adding endpoint markers: $e');
    }
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
            key: ValueKey(
                "mapWidget_$_currentStyleUrl"), // Force rebuild when style changes
            cameraOptions: CameraOptions(
              center: Point(
                  coordinates: Position(widget.centerLng, widget.centerLat)),
              zoom: widget.initialZoom,
            ),
            styleUri: _currentStyleUrl,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
          ),

          // Style Toggle Button
          if (widget.showStyleToggle)
            Positioned(
              top: 16,
              left: 16,
              child: _buildStyleToggleButton(),
            ),

          // Expand/Diminish Button (moved to right bottom corner)
          if (widget.showExpandButton)
            Positioned(
              bottom: 8,
              right: 8, // Right bottom corner
              child: _buildExpandButton(),
            ),

          // Style Selector Overlay
          if (_showStyleSelector)
            Positioned.fill(
              child: _buildStyleSelectorOverlay(),
            ),

          // Removed custom attribution overlay

          // Removed debug info with location count
        ],
      ),
    );
  }

  ///  Build style toggle button
  Widget _buildStyleToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.layers, color: Colors.black87),
        onPressed: () {
          setState(() {
            _showStyleSelector = !_showStyleSelector;
          });
        },
        tooltip: 'Change map style',
        iconSize: 24,
      ),
    );
  }

  /// 📏 Build expand/diminish button
  Widget _buildExpandButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.black87,
        ),
        onPressed: _toggleExpand,
        tooltip: _isExpanded ? 'Minimize map' : 'Expand map',
        iconSize: 24,
      ),
    );
  }

  ///  Toggle expand/diminish state
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Notify parent about expand state change
    widget.onExpandChanged?.call(_isExpanded);

    if (kDebugMode) {
      print('📏 Map expansion toggled: $_isExpanded');
    }
  }

  ///  Build ultra-compact style selector overlay (4x2 grid)
  Widget _buildStyleSelectorOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showStyleSelector = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ultra-compact header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.layers, color: Colors.white, size: 12),
                      const SizedBox(width: 3),
                      const Text(
                        'Map Style',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 12),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _showStyleSelector = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Ultra-compact 4x2 grid layout (4 columns, 2 rows) - No padding to prevent overflow
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: GridView.count(
                    crossAxisCount: 4, // 4 columns
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: MapboxConfig.availableMapStyles.map((style) {
                      final isSelected = _currentStyleUrl == style.styleUrl;
                      return _buildUltraCompactStyleOption(style, isSelected);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///  Build ultra-compact style option (for 4x2 grid)
  Widget _buildUltraCompactStyleOption(MapStyle style, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
      ),
      child: InkWell(
        onTap: () {
          _changeMapStyle(style.styleUrl, style.displayName);
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStyleIcon(style),
                color: isSelected ? Colors.orange : Colors.grey[600],
                size: 16,
              ),
              const SizedBox(height: 1),
              Text(
                _getShortStyleName(style),
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.orange : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 1),
                Icon(
                  Icons.check,
                  color: Colors.orange,
                  size: 8,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get short name for style (for ultra-compact display)
  String _getShortStyleName(MapStyle style) {
    switch (style) {
      case MapStyle.streets:
        return 'Streets';
      case MapStyle.satellite:
        return 'Satellite';
      case MapStyle.satelliteStreets:
        return 'Sat+St';
      case MapStyle.outdoors:
        return 'Outdoors';
      case MapStyle.light:
        return 'Light';
      case MapStyle.dark:
        return 'Dark';
      case MapStyle.navigationDay:
        return 'Nav Day';
      case MapStyle.navigationNight:
        return 'Nav Night';
    }
  }

  ///  Get appropriate icon for each map style
  IconData _getStyleIcon(MapStyle style) {
    switch (style) {
      case MapStyle.streets:
        return Icons.map;
      case MapStyle.satellite:
        return Icons.satellite_alt;
      case MapStyle.satelliteStreets:
        return Icons.layers;
      case MapStyle.outdoors:
        return Icons.terrain;
      case MapStyle.light:
        return Icons.light_mode;
      case MapStyle.dark:
        return Icons.dark_mode;
      case MapStyle.navigationDay:
        return Icons.directions_car;
      case MapStyle.navigationNight:
        return Icons.directions_car_filled;
    }
  }

  @override
  void dispose() {
    _pointAnnotationManager?.deleteAll();
    _polylineAnnotationManager?.deleteAll();
    super.dispose();
  }
}
