import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../config/mapbox_config.dart';
import '../models/parking/parking_location.dart';
import '../services/maps/mapbox_service.dart';

/// Mapbox Widget for displaying real-world maps with parking locations
/// Uses Mapbox Static Maps API since the official SDK has compatibility issues
class MapboxWidget extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double zoom;
  final List<ParkingLocation> parkingLocations;
  final Function(ParkingLocation)? onLocationSelected;
  final bool showMarkers;
  final bool showCurrentLocation;
  final bool showZoomControls;

  const MapboxWidget({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.zoom = 15.0,
    this.parkingLocations = const [],
    this.onLocationSelected,
    this.showMarkers = true,
    this.showCurrentLocation = false,
    this.showZoomControls = true,
  });

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  bool _isLoading = true;
  String? _error;
  geo.Position? _currentLocation;
  double _currentZoom = 15.0;
  double _currentLat = 9.0120; // Meskel Square
  double _currentLng = 38.7634;
  String? _mapImageUrl;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoom;
    _currentLat = widget.initialLatitude;
    _currentLng = widget.initialLongitude;
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      if (kDebugMode) {
        print('🗺️ Initializing Mapbox widget...');
        print(
            '📍 Initial position: ${widget.initialLatitude}, ${widget.initialLongitude}');
        print('🏢 Parking locations: ${widget.parkingLocations.length}');
      }

      // Get current location if needed
      if (widget.showCurrentLocation) {
        _currentLocation = await MapboxService.instance.getCurrentLocation();
        if (kDebugMode && _currentLocation != null) {
          print(
              '📍 Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
        }
      }

      // Generate static map URL
      await _updateMapImage();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Mapbox widget: $e');
      }
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize map: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateMapImage() async {
    try {
      // Create markers list for static map
      final List<Map<String, dynamic>> markers = [];

      // Add parking location markers
      if (widget.showMarkers) {
        for (final location in widget.parkingLocations) {
          markers.add({
            'lat': location.latitude,
            'lng': location.longitude,
            'color': 'red',
            'size': 'medium',
          });
        }
      }

      // Add current location marker
      if (widget.showCurrentLocation && _currentLocation != null) {
        markers.add({
          'lat': _currentLocation!.latitude,
          'lng': _currentLocation!.longitude,
          'color': 'blue',
          'size': 'large',
        });
      }

      // Generate static map URL - try simple map first in debug mode
      String url;
      if (kDebugMode && markers.length > 3) {
        // In debug mode, try simple map first if too many markers
        url = MapboxService.instance.getSimpleStaticMapUrl(
          lat: _currentLat,
          lng: _currentLng,
          width: 400,
          height: 400,
          zoom: _currentZoom.round(),
        );
        if (kDebugMode) {
          print('🗺️ Using simple map due to many markers (${markers.length})');
        }
      } else {
        url = MapboxService.instance.getStaticMapUrl(
          lat: _currentLat,
          lng: _currentLng,
          width: 400,
          height: 400,
          zoom: _currentZoom.round(),
          markers: markers.isNotEmpty ? markers : null,
        );
      }

      if (mounted) {
        setState(() {
          _mapImageUrl = url;
        });
      }

      if (kDebugMode) {
        print('🗺️ Generated map image URL');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating map image: $e');
      }
    }
  }

  void _handleMapTap(TapUpDetails details, BoxConstraints constraints) {
    if (widget.onLocationSelected == null) return;

    try {
      // Find the nearest parking location to the tap
      ParkingLocation? nearestLocation;
      double minDistance = double.infinity;

      for (final location in widget.parkingLocations) {
        // Simple distance approximation for demonstration
        final distance = MapboxService.instance.calculateDistance(
          _currentLat,
          _currentLng,
          location.latitude,
          location.longitude,
        );

        if (distance < minDistance && distance < 2000) {
          // Within 2km
          minDistance = distance;
          nearestLocation = location;
        }
      }

      if (nearestLocation != null) {
        widget.onLocationSelected!(nearestLocation);
        if (kDebugMode) {
          print('📍 Selected parking location: ${nearestLocation.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling map tap: $e');
      }
    }
  }

  Future<void> _zoomIn() async {
    final newZoom =
        (_currentZoom + 1).clamp(MapboxConfig.minZoom, MapboxConfig.maxZoom);
    if (newZoom != _currentZoom) {
      setState(() {
        _currentZoom = newZoom;
        _isLoading = true;
      });
      await _updateMapImage();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _zoomOut() async {
    final newZoom =
        (_currentZoom - 1).clamp(MapboxConfig.minZoom, MapboxConfig.maxZoom);
    if (newZoom != _currentZoom) {
      setState(() {
        _currentZoom = newZoom;
        _isLoading = true;
      });
      await _updateMapImage();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Main Map Display
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTapUp: (details) => _handleMapTap(details, constraints),
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _mapImageUrl != null
                      ? Image.network(
                          _mapImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildLoadingWidget();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) {
                              print('❌ Error loading map image: $error');
                            }
                            return _buildFallbackMap();
                          },
                        )
                      : _buildFallbackMap(),
                ),
              ),
            ),

            // Parking location markers overlay
            if (widget.showMarkers && widget.parkingLocations.isNotEmpty)
              ..._buildParkingMarkers(constraints),

            // Current location marker overlay
            if (widget.showCurrentLocation && _currentLocation != null)
              _buildCurrentLocationMarker(constraints),

            // Zoom controls (if enabled)
            if (widget.showZoomControls)
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      mini: true,
                      heroTag: "zoom_in",
                      onPressed: _zoomIn,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      child: const Icon(Icons.zoom_in),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      mini: true,
                      heroTag: "zoom_out",
                      onPressed: _zoomOut,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      child: const Icon(Icons.zoom_out),
                    ),
                  ],
                ),
              ),

            // Map attribution
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
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
          ],
        );
      },
    );
  }

  List<Widget> _buildParkingMarkers(BoxConstraints constraints) {
    return widget.parkingLocations.map((location) {
      // Simple positioning - in a real app you'd use proper map projection
      const markerSize = 30.0;
      final left = constraints.maxWidth * 0.3 +
          (widget.parkingLocations.indexOf(location) * 40);
      final top = constraints.maxHeight * 0.4;

      return Positioned(
        left: left.clamp(0, constraints.maxWidth - markerSize),
        top: top.clamp(0, constraints.maxHeight - markerSize),
        child: GestureDetector(
          onTap: () => widget.onLocationSelected?.call(location),
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_parking,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCurrentLocationMarker(BoxConstraints constraints) {
    const markerSize = 20.0;
    final left = constraints.maxWidth * 0.5 - markerSize / 2;
    final top = constraints.maxHeight * 0.5 - markerSize / 2;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            SizedBox(height: 16),
            Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Powered by Mapbox',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
              'Map Loading Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _initializeMap(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return CustomPaint(
      painter: _MapPatternPainter(),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _error?.contains('422') == true
                    ? 'Map Load Failed'
                    : 'Map Preview',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error?.contains('422') == true
                    ? 'Invalid coordinates in database'
                    : 'Add your Mapbox token to .env file',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode && _error != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Debug: $_error',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Custom painter for fallback map pattern
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid pattern to simulate map
    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "streets"
    paint.color = Colors.grey.shade400;
    paint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
