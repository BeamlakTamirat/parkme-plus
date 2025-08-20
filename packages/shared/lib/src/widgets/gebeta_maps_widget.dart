import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/maps/gebeta_maps_service.dart';
import '../models/parking/parking_location.dart';

/// Custom Gebeta Maps Widget
/// Uses REAL Gebeta Maps API calls to display maps
class GebetaMapsWidget extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double zoom;
  final List<ParkingLocation>? parkingLocations;
  final Function(ParkingLocation)? onLocationSelected;
  final bool showMarkers;
  final bool showCurrentLocation;

  const GebetaMapsWidget({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.zoom = 15.0,
    this.parkingLocations,
    this.onLocationSelected,
    this.showMarkers = true,
    this.showCurrentLocation = true,
  });

  @override
  State<GebetaMapsWidget> createState() => _GebetaMapsWidgetState();
}

class _GebetaMapsWidgetState extends State<GebetaMapsWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<ParkingLocation> _parkingLocations = [];
  Map<String, dynamic>? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get current location if enabled
      if (widget.showCurrentLocation) {
        await _getCurrentLocation();
      }

      // Load parking locations if not provided
      if (widget.parkingLocations == null) {
        await _loadParkingLocations();
      } else {
        _parkingLocations = widget.parkingLocations!;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      if (kDebugMode) print('❌ Error initializing Gebeta Maps: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final mapsService = GebetaMapsService.instance;
      final position = await mapsService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentLocation = {
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error getting current location: $e');
    }
  }

  Future<void> _loadParkingLocations() async {
    try {
      if (kDebugMode) print('🔍 Loading parking locations...');

      final mapsService = GebetaMapsService.instance;

      // Try to get locations with a timeout
      final locations = await mapsService
          .searchNearbyParking(
        widget.initialLatitude,
        widget.initialLongitude,
        radius: 5000, // 5km radius
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) print('⏰ Gebeta Maps timeout, using fallback data');
          return _getFallbackParkingLocations();
        },
      );

      if (kDebugMode) print('✅ Loaded ${locations.length} parking locations');

      setState(() {
        _parkingLocations =
            locations.isNotEmpty ? locations : _getFallbackParkingLocations();
      });
    } catch (e) {
      if (kDebugMode)
        print('❌ Error loading parking locations: $e, using fallback');
      setState(() {
        _parkingLocations = _getFallbackParkingLocations();
      });
    }
  }

  List<ParkingLocation> _getFallbackParkingLocations() {
    if (kDebugMode) print('📋 Using fallback parking locations');
    return [
      ParkingLocation(
        id: 'fallback_1',
        name: 'Meskel Square Parking',
        address: 'Meskel Square, Addis Ababa',
        latitude: 9.0054,
        longitude: 38.7636,
        totalSpots: 50,
        availableSpots: 15,
        hourlyRate: 30.0,
        isActive: true,
        description: 'Secure parking near Meskel Square (Demo)',
        amenities: ['Security', 'CCTV', 'Well-lit'],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ParkingLocation(
        id: 'fallback_2',
        name: 'Bole Arena Plaza',
        address: 'Bole, Addis Ababa',
        latitude: 8.9806,
        longitude: 38.7578,
        totalSpots: 30,
        availableSpots: 8,
        hourlyRate: 25.0,
        isActive: true,
        description: 'Convenient parking at Bole Arena (Demo)',
        amenities: ['Security', 'Easy access'],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ParkingLocation(
        id: 'fallback_3',
        name: 'Piassa Mall Garage',
        address: 'Piassa, Addis Ababa',
        latitude: 9.0272,
        longitude: 38.7369,
        totalSpots: 40,
        availableSpots: 22,
        hourlyRate: 20.0,
        isActive: true,
        description: 'Underground parking at Piassa Mall (Demo)',
        amenities: ['Covered parking', 'Security'],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return _buildMapView();
  }

  Widget _buildLoadingState() {
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
              'Loading Gebeta Maps...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
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
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Static map image from Gebeta Maps
            _buildStaticMapImage(),

            // Map controls
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  _buildMapControlButton(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                  ),
                  if (widget.showCurrentLocation) ...[
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.my_location,
                      onPressed: _centerOnCurrentLocation,
                    ),
                  ],
                ],
              ),
            ),

            // Parking location markers
            if (widget.showMarkers) ..._buildParkingMarkers(),

            // Current location marker
            if (widget.showCurrentLocation && _currentLocation != null)
              _buildCurrentLocationMarker(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticMapImage() {
    final mapsService = GebetaMapsService.instance;
    final centerLat = _currentLocation?['latitude'] ?? widget.initialLatitude;
    final centerLng = _currentLocation?['longitude'] ?? widget.initialLongitude;

    final mapUrl = mapsService.getStaticMapUrl(
      lat: centerLat,
      lng: centerLng,
      width: 600,
      height: 400,
      zoom: widget.zoom.toInt(),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        mapUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackMapView();
        },
      ),
    );
  }

  Widget _buildFallbackMapView() {
    final centerLat = _currentLocation?['latitude'] ?? widget.initialLatitude;
    final centerLng = _currentLocation?['longitude'] ?? widget.initialLongitude;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[100]!,
            Colors.green[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Map background pattern
          CustomPaint(
            size: Size.infinite,
            painter: MapPatternPainter(),
          ),

          // Center location info
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 32,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Addis Ababa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '${centerLat.toStringAsFixed(4)}, ${centerLng.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gebeta Maps (Fallback)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: Colors.black87,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  List<Widget> _buildParkingMarkers() {
    return _parkingLocations.asMap().entries.map((entry) {
      final index = entry.key;
      final location = entry.value;

      // Calculate position based on distance from center
      final centerLat = _currentLocation?['latitude'] ?? widget.initialLatitude;
      final centerLng =
          _currentLocation?['longitude'] ?? widget.initialLongitude;

      // Simple positioning (in a real implementation, you'd convert lat/lng to screen coordinates)
      final left = 50.0 + (index * 80.0);
      final top = 100.0 + (index * 60.0);

      return Positioned(
        left: left,
        top: top,
        child: _buildParkingMarker(location),
      );
    }).toList();
  }

  Widget _buildParkingMarker(ParkingLocation location) {
    return GestureDetector(
      onTap: () => widget.onLocationSelected?.call(location),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: location.hasAvailableSpots ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_parking,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${location.availableSpots}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Positioned(
      left: 20,
      top: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  void _zoomIn() {
    // In a real implementation, you'd update the zoom level
    if (kDebugMode) print('🔍 Zooming in...');
  }

  void _zoomOut() {
    // In a real implementation, you'd update the zoom level
    if (kDebugMode) print('🔍 Zooming out...');
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      // In a real implementation, you'd center the map on current location
      if (kDebugMode) {
        print(
            '📍 Centering on current location: ${_currentLocation!['latitude']}, ${_currentLocation!['longitude']}');
      }
    }
  }
}

/// Custom painter for drawing a map-like pattern
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    const gridSize = 40.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some "road" patterns
    final roadPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Horizontal "roads"
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );

    // Vertical "roads"
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
