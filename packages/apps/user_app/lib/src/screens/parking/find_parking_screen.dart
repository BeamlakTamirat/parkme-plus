import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class FindParkingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extraData;

  const FindParkingScreen({
    super.key,
    this.extraData,
  });

  @override
  ConsumerState<FindParkingScreen> createState() => _FindParkingScreenState();
}

class _FindParkingScreenState extends ConsumerState<FindParkingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final bool _showMapView = true;

  // Book again functionality
  bool _isBookAgainMode = false;
  ParkingLocation? _targetLocation;

  // Location state
  Position? _userLocation;
  bool _isLoadingLocation = false;
  bool _locationPermissionGranted = false;

  // Map expansion state
  bool _isMapExpanded = false;

  // Filtered and sorted locations
  List<ParkingLocation> _filteredLocations = [];

  // Advanced filtering state
  double _maxDistance = 10.0; // km
  RangeValues _priceRange = const RangeValues(0, 100); // ETB/hour
  double _minRating = 3.0; // stars
  bool _hasAvailableSpots = false;
  bool _showOnlyActive = true;
  // List<String> _selectedAmenities = []; // Reserved for future amenities filtering
  bool _useAdvancedFilters = false;
  // bool _isFiltering = false; // Reserved for future loading state

  @override
  void initState() {
    super.initState();
    _handleExtraData();
    _initializeLocationAndMap();

    // Apply initial filtering after location is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilterAndSorting();
    });
  }

  /// 🎯 Initialize location services and center map on user location
  Future<void> _initializeLocationAndMap() async {
    await _requestLocationPermissionAndGetLocation();
  }

  Future<void> _handleExtraData() async {
    if (widget.extraData != null) {
      final action = widget.extraData!['action'];
      final booking = widget.extraData!['previousBooking'] as Booking?;

      if (action == 'book_again' && booking != null) {
        setState(() {
          _isBookAgainMode = true;
        });

        // Find the parking location from the booking
        await _loadTargetLocation(booking.parkingLocationId);
      }
    }
  }

  Future<void> _loadTargetLocation(String locationId) async {
    try {
      final locations = await ref.read(parkingLocationsProvider.future);
      final targetLocation = locations.firstWhere(
        (location) => location.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );

      setState(() {
        _targetLocation = targetLocation;
      });

      // Show booking dialog for the target location after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _targetLocation != null) {
          _showBookingDialog(context, _targetLocation!);
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error loading target location: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find the previous parking location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🎯 Request location permission with user-friendly dialogs and get location
  Future<void> _requestLocationPermissionAndGetLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServiceDialog();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Show permission request dialog first
        bool shouldRequest = await _showPermissionRequestDialog();
        if (!shouldRequest) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showPermissionDeniedDialog();
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showPermissionDeniedForeverDialog();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Permission granted! Get location quickly
      await _getUserLocationAndCenter();
    } catch (e) {
      if (kDebugMode) print('Error in location permission flow: $e');
      _showLocationErrorSnackBar('Location error: ${e.toString()}');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  ///  Get user location and center map very fast
  Future<void> _getUserLocationAndCenter() async {
    try {
      Position position;

      // Try to get last known position first (faster)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          if (kDebugMode) {
            print(
                '📍 Using last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
          }
          position = lastKnown;
        } else {
          throw Exception('No last known position');
        }
      } catch (e) {
        // Fallback to current position
        if (kDebugMode) print('📍 Getting current position...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(
              seconds: 10), // Increased timeout for better reliability
        );
      }

      setState(() {
        _userLocation = position;
        _locationPermissionGranted = true;
        _isLoadingLocation = false;
      });

      // Show success message with coordinates
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📍 Location found! Map centered on your position\n'
                    'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (kDebugMode) {
        print(
            '✅ User location obtained: ${position.latitude}, ${position.longitude}');
        print('🗺️ Map will be centered on user location');
        print(
            '📊 Location state: _userLocation set, _locationPermissionGranted = true');
      }
    } catch (e) {
      if (kDebugMode) print('Error getting user location: $e');
      _showLocationErrorSnackBar(
          'Could not get your location. Using default location.');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<Position?> _getCurrentLocationWithPermission() async {
    if (_userLocation != null) {
      return _userLocation; // Return cached location
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (kDebugMode) print('Error getting location: $e');
      return null;
    }
  }

  void _onMapLocationTapped(double lat, double lng) {
    if (kDebugMode) {
      print('🗺️ Map location tapped: $lat, $lng');
    }
    // Handle map tap - could show location details or start booking
  }

  void _centerOnUserLocation() async {
    final location = await _getCurrentLocationWithPermission();
    if (location != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Centered on your location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your current location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //  LOCATION PERMISSION DIALOG METHODS

  Future<void> _showLocationServiceDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_off,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Services Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WePark needs location services to:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.search, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Find nearby parking spots')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.navigation, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Center map on your location')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Provide navigation to parking')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Please enable location services in your device settings.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPermissionRequestDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_searching,
                  color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Permission',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WePark needs access to your location to show nearby parking spots and center the map on your position.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.security, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your location is only used to improve your parking experience',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.location_on),
            label: const Text('Allow Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showPermissionDeniedDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_disabled,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Permission Denied'),
          ],
        ),
        content: const Text(
          'Location permission was denied. You can still browse parking locations, but the map won\'t center on your location.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDeniedForeverDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.block, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Permission Blocked'),
          ],
        ),
        content: const Text(
          'Location permission has been permanently denied. To use location features, please enable location permission for WePark in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find Parking',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () => _showFilterDialog(context),
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              onPressed: () => context.push('/debug'),
              tooltip: 'Database Debug',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Book Again Banner
            if (_isBookAgainMode && _targetLocation != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Taking you to ${_targetLocation!.name}...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isBookAgainMode = false;
                          _targetLocation = null;
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Search and filter section
            _buildSearchSection(),

            // Map view toggle section
            if (_showMapView) _buildMapViewSection(),

            // Filter chips
            _buildFilterSection(),

            // Available parking list - now scrollable with flex to prevent overflow
            Flexible(
              child: _buildParkingList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoadingLocation
                ? null
                : () {
                    if (!_locationPermissionGranted) {
                      _requestLocationPermissionAndGetLocation();
                    } else {
                      _centerOnUserLocation();
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _locationPermissionGranted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: _locationPermissionGranted
                    ? Border.all(color: Colors.green.withOpacity(0.3))
                    : null,
              ),
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  : Icon(
                      _locationPermissionGranted
                          ? Icons.location_on
                          : Icons.my_location,
                      color: _locationPermissionGranted
                          ? Colors.green
                          : Colors.orange,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapViewSection() {
    final parkingLocationsAsync = ref.watch(parkingLocationsProvider);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Dynamic height based on expansion state with safety constraints
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: _isMapExpanded
                ? MediaQuery.of(context).size.height *
                    0.58 // Expanded: 45% of screen (safer for list space)
                : MediaQuery.of(context).size.height *
                    0.22, // Normal: 25% of screen (more compact)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: parkingLocationsAsync.when(
              loading: () => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading map...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, _) => Container(
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
                        'Unable to load parking locations',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (parkingLocations) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    InteractiveMapboxWidget(
                      key: ValueKey(
                          'map_${_userLocation?.latitude}_${_userLocation?.longitude}'), // 🔥 Force rebuild when location changes
                      centerLat: _userLocation?.latitude ??
                          9.0120, // Use user location or default
                      centerLng: _userLocation?.longitude ?? 38.7634,
                      initialZoom: 16.0, // Closer zoom for better detail
                      parkingLocations: parkingLocations,
                      onLocationSelected: _onMapLocationTapped,
                      showMarkers: true,
                      showCurrentLocation: true,
                      showZoomControls: true,
                      showStyleToggle: true, // Enable style toggle
                      userLocationLat:
                          _userLocation?.latitude, // 🎯 Pass user location
                      userLocationLng:
                          _userLocation?.longitude, // 🎯 Pass user location
                      onStyleChanged: (styleName) {
                        // Optional: Handle style change feedback
                        if (kDebugMode) {
                          print(' Map style changed to: $styleName');
                        }
                      },
                      onExpandChanged: (isExpanded) {
                        setState(() {
                          _isMapExpanded = isExpanded;
                        });
                        if (kDebugMode) {
                          print(' Map expansion state: $isExpanded');
                        }
                      },
                    ),

                    // Removed location button to prevent conflict with expand/diminish button

                    // Removed location count indicator
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('Nearby', 'Nearby'),
            const SizedBox(width: 8),
            _buildFilterChip('Available', 'Available'),
            const SizedBox(width: 8),
            _buildFilterChip('Cheapest', 'Cheapest'),
            const SizedBox(width: 8),
            _buildFilterChip('Rated', 'Rated'),
            const SizedBox(width: 8),
            _buildFilterChip('Filtered', 'Filtered'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final isFilteredActive = value == 'Filtered' && _useAdvancedFilters;

    return GestureDetector(
      onTap: () async {
        // If clicking on Filtered chip when it's already selected, clear advanced filters
        if (isSelected && value == 'Filtered' && _useAdvancedFilters) {
          _clearAdvancedFilters();
          return;
        }

        setState(() {
          _selectedFilter = value;
        });

        // Apply filter and sorting
        await _applyFilterAndSorting();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange
              : (isFilteredActive ? Colors.orange[200] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: isFilteredActive
              ? Border.all(color: Colors.orange, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isFilteredActive
                        ? Colors.orange[800]
                        : Colors.grey[700]),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isFilteredActive) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _filteredLocations.length.toString(),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ///  Apply comprehensive filtering and sorting based on selected filter
  Future<void> _applyFilterAndSorting() async {
    try {
      final allLocations = await ref.read(parkingLocationsProvider.future);
      List<ParkingLocation> filteredLocations = List.from(allLocations);

      // Apply user location-based filtering if needed
      if (_userLocation != null) {
        // Calculate distances for all locations
        for (final location in filteredLocations) {
          location.calculateDistance(
              _userLocation!.latitude, _userLocation!.longitude);
        }
      }

      switch (_selectedFilter) {
        case 'All':
          // No additional filtering, show all active locations
          filteredLocations =
              filteredLocations.where((loc) => loc.isActive).toList();
          break;

        case 'Nearby':
          if (_userLocation != null) {
            // Sort by distance (nearest first)
            filteredLocations.sort((a, b) {
              final distA = a.getDistanceFromUser(
                      _userLocation!.latitude, _userLocation!.longitude) ??
                  double.infinity;
              final distB = b.getDistanceFromUser(
                      _userLocation!.latitude, _userLocation!.longitude) ??
                  double.infinity;
              return distA.compareTo(distB);
            });
          }
          // Filter to active locations only
          filteredLocations =
              filteredLocations.where((loc) => loc.isActive).toList();
          break;

        case 'Available':
          // Sort by most available spots (descending)
          filteredLocations
              .sort((a, b) => b.availableSpots.compareTo(a.availableSpots));
          // Filter to locations with available spots
          filteredLocations = filteredLocations
              .where((loc) => loc.availableSpots > 0 && loc.isActive)
              .toList();
          break;

        case 'Cheapest':
          // Sort by hourly rate (ascending - cheapest first)
          filteredLocations
              .sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
          // Filter to active locations only
          filteredLocations =
              filteredLocations.where((loc) => loc.isActive).toList();
          break;

        case 'Rated':
          // Sort by rating (highest first)
          filteredLocations.sort((a, b) => b.rating.compareTo(a.rating));
          // Filter to active locations only
          filteredLocations =
              filteredLocations.where((loc) => loc.isActive).toList();
          break;

        case 'Filtered':
          // Use the advanced filtered results
          if (_useAdvancedFilters && _filteredLocations.isNotEmpty) {
            filteredLocations = List.from(_filteredLocations);
          } else {
            // If no advanced filters applied, show all active locations
            filteredLocations =
                filteredLocations.where((loc) => loc.isActive).toList();
          }
          break;

        default:
          // Default to showing all active locations
          filteredLocations =
              filteredLocations.where((loc) => loc.isActive).toList();
      }

      setState(() {
        _filteredLocations = filteredLocations;
      });

      if (kDebugMode) {
        print(
            ' Applied filter: $_selectedFilter, found ${filteredLocations.length} locations');
      }
    } catch (e) {
      if (kDebugMode) {
        print(' Error applying filter: $e');
      }
      setState(() {
        _filteredLocations = [];
      });
    }
  }

  ///  Apply advanced filtering based on user selections
  Future<void> _applyAdvancedFilters() async {
    setState(() {
      // _isFiltering = true;
      _useAdvancedFilters = true;
    });

    try {
      final allLocations = await ref.read(parkingLocationsProvider.future);
      List<ParkingLocation> filteredLocations = List.from(allLocations);

      // Apply active locations filter
      if (_showOnlyActive) {
        filteredLocations =
            filteredLocations.where((loc) => loc.isActive).toList();
      }

      // Apply distance filter (if user location is available)
      if (_userLocation != null) {
        filteredLocations = filteredLocations.where((location) {
          final distance = location.getDistanceFromUser(
              _userLocation!.latitude, _userLocation!.longitude);
          return distance != null && distance <= _maxDistance;
        }).toList();
      }

      // Apply price range filter
      filteredLocations = filteredLocations.where((location) {
        return location.hourlyRate >= _priceRange.start &&
            location.hourlyRate <= _priceRange.end;
      }).toList();

      // Apply rating filter
      filteredLocations = filteredLocations.where((location) {
        return location.rating >= _minRating;
      }).toList();

      // Apply available spots filter
      if (_hasAvailableSpots) {
        filteredLocations = filteredLocations.where((location) {
          return location.availableSpots > 0;
        }).toList();
      }

      setState(() {
        _filteredLocations = filteredLocations;
        _selectedFilter = 'Filtered'; // Switch to filtered view
      });

      if (kDebugMode) {
        print(' Applied advanced filters:');
        print('   Distance: ≤ ${_maxDistance.toStringAsFixed(1)} km');
        print(
            '   Price: ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} ETB/hr');
        print('   Rating: ≥ ${_minRating.toStringAsFixed(1)} ★');
        print(
            '   Available spots: ${_hasAvailableSpots ? 'Required' : 'Optional'}');
        print('   Active locations: ${_showOnlyActive ? 'Only' : 'All'}');
        print('   Results: ${filteredLocations.length} locations found');
      }
    } catch (e) {
      if (kDebugMode) {
        print(' Error applying advanced filters: $e');
      }
      setState(() {
        _filteredLocations = [];
      });
    } finally {
      setState(() {
        // _isFiltering = false;
      });
    }
  }

  /// 🧹 Clear advanced filters and reset to default state
  void _clearAdvancedFilters() {
    setState(() {
      _useAdvancedFilters = false;
      _filteredLocations = [];
      _selectedFilter = 'All';

      // Reset filter values to defaults
      _maxDistance = 10.0;
      _priceRange = const RangeValues(0, 100);
      _minRating = 3.0;
      _hasAvailableSpots = false;
      _showOnlyActive = true;
      // _selectedAmenities = [];
    });

    // Reapply default filtering
    _applyFilterAndSorting();

    if (kDebugMode) {
      print(' Cleared advanced filters, reset to default state');
    }
  }

  Widget _buildParkingList() {
    final parkingLocationsAsync = ref.watch(parkingLocationsProvider);

    return parkingLocationsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(parkingLocationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (parkingLocations) {
        // Use filtered locations if available, otherwise apply default filtering
        final displayLocations = _filteredLocations.isNotEmpty
            ? _filteredLocations
            : parkingLocations.where((loc) => loc.isActive).toList();

        if (displayLocations.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'All'
                        ? 'No parking locations found'
                        : 'No locations match your filter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'All'
                        ? 'Check back later for available parking spots'
                        : 'Try changing your filter criteria',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reduced top padding
          itemCount: displayLocations.length,
          itemBuilder: (context, index) {
            final location = displayLocations[index];
            return Column(
              children: [
                _buildParkingItem(location),
                if (index < displayLocations.length - 1)
                  const SizedBox(height: 12), // Slightly reduced spacing
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildParkingItem(ParkingLocation location) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 140, // Minimum height to ensure content fits
        maxHeight: 160, // Maximum height to prevent excessive space usage
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 📸 COMPACT IMAGE SECTION
          Container(
            width: 120,
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 160),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: _buildCompactLocationImage(location),
                ),

                // Availability badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: location.hasAvailableSpots
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      location.hasAvailableSpots ? 'Available' : 'Full',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Rating badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          location.formattedRating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          //  Super compact and information-dense
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and pricing row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        location.formattedHourlyRate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Text(
                    location.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Car Icon below location name and address
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Parking Available',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Info chips row
                  Row(
                    children: [
                      _buildCompactInfoChip(
                        Icons.location_on_outlined,
                        _userLocation != null
                            ? location.getFormattedDistance(
                                _userLocation!.latitude,
                                _userLocation!.longitude)
                            : 'Distance unavailable',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildCompactInfoChip(
                        Icons.local_parking_outlined,
                        '${location.availableSpots}/${location.totalSpots} available',
                        location.hasAvailableSpots ? Colors.green : Colors.red,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Book now button
                  SizedBox(
                    width: double.infinity,
                    height: 32, // Compact button height
                    child: ElevatedButton(
                      onPressed: () => _bookParking(context, location),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_parking, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCompactInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  //COMPACT IMAGE WIDGET
  Widget _buildCompactLocationImage(ParkingLocation location) {
    if (location.images != null && location.images!.isNotEmpty) {
      return Image.network(
        location.images!.first,
        width: 120,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildCompactImagePlaceholder(),
      );
    } else {
      return _buildCompactImagePlaceholder();
    }
  }

  Widget _buildCompactImagePlaceholder() {
    return Container(
      width: 120,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[100]!,
            Colors.orange[200]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking,
            size: 32,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 4),
          Text(
            'Parking',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Text('Advanced Filters'),
              const Spacer(),
              if (_useAdvancedFilters)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_filteredLocations.length} found',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distance Filter
                const Text(
                  'Maximum Distance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Slider(
                  value: _maxDistance,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  label: '${_maxDistance.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() => _maxDistance = value);
                  },
                ),
                Text(
                  '${_maxDistance.toStringAsFixed(1)} km from your location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 20),

                // Price Range Filter
                const Text(
                  'Price Range (ETB/hour)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 200,
                  divisions: 20,
                  labels: RangeLabels(
                    '${_priceRange.start.toInt()}',
                    '${_priceRange.end.toInt()}',
                  ),
                  onChanged: (values) {
                    setState(() => _priceRange = values);
                  },
                ),
                Text(
                  '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} ETB/hour',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 20),

                // Rating Filter
                const Text(
                  'Minimum Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Slider(
                  value: _minRating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  label: '${_minRating.toStringAsFixed(1)} ★',
                  onChanged: (value) {
                    setState(() => _minRating = value);
                  },
                ),
                Row(
                  children: [
                    Text(
                      '${_minRating.toStringAsFixed(1)} stars and above',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < _minRating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Availability Filter
                Row(
                  children: [
                    const Text(
                      'Only Available Spots',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _hasAvailableSpots,
                      onChanged: (value) {
                        setState(() => _hasAvailableSpots = value);
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Active Locations Filter
                Row(
                  children: [
                    const Text(
                      'Only Active Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _showOnlyActive,
                      onChanged: (value) {
                        setState(() => _showOnlyActive = value);
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Filter Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: ≤ ${_maxDistance.toStringAsFixed(1)} km\n'
                        'Price: ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} ETB/hr\n'
                        'Rating: ≥ ${_minRating.toStringAsFixed(1)} ★\n'
                        'Available spots: ${_hasAvailableSpots ? 'Required' : 'Optional'}\n'
                        'Active locations: ${_showOnlyActive ? 'Only' : 'All'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset to defaults
                setState(() {
                  _maxDistance = 10.0;
                  _priceRange = const RangeValues(0, 100);
                  _minRating = 3.0;
                  _hasAvailableSpots = false;
                  _showOnlyActive = true;
                  // _selectedAmenities = [];
                  _useAdvancedFilters = false;
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyAdvancedFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _bookParking(BuildContext context, ParkingLocation location) {
    // Show booking dialog with duration selection
    _showBookingDialog(context, location);
  }

  void _showBookingDialog(BuildContext context, ParkingLocation location) {
    if (location.availableSpots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No parking spots available at this location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int selectedDuration = 2; // Default 2 hours

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Book Parking Spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${location.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Rate: ${location.formattedHourlyRate}'),
              const SizedBox(height: 8),
              Text('Available spots: ${location.availableSpots}'),
              const SizedBox(height: 16),

              // 🔧 FIX: Add duration selection
              const Text(
                'Duration:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 6, 8, 12, 24].map((hours) {
                  return ChoiceChip(
                    label: Text('${hours}h'),
                    selected: selectedDuration == hours,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedDuration = hours;
                        });
                      }
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selectedDuration == hours
                          ? Colors.orange[700]
                          : Colors.grey[700],
                      fontWeight: selectedDuration == hours
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              //  Dynamic total calculation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Cost:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      CurrencyFormatter.format(
                          location.hourlyRate * selectedDuration),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToPayment(context, location, selectedDuration);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue to Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment(
      BuildContext context, ParkingLocation location, int durationHours) async {
    // Get current user
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to continue'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/sign-in');
      }
      return;
    }

    // 🔧 FIX: Use dynamic duration and amount calculation
    final bookingData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'parkingLocationId': location.id,
      'parkingLocationName': location.name,
      'userId': currentUser.id,
      'vehiclePlateNumber': currentUser.vehiclePlateNumber ?? 'N/A',
      'totalAmount':
          location.hourlyRate * durationHours, // 🔧 FIX: Dynamic calculation
      'duration':
          '$durationHours hour${durationHours == 1 ? '' : 's'}', // 🔧 FIX: Dynamic duration text
      'startTime': DateTime.now(),
      'endTime': DateTime.now()
          .add(Duration(hours: durationHours)), // 🔧 FIX: Dynamic end time
    };

    // Navigate to payment screen
    if (context.mounted) {
      context.push('/payment', extra: bookingData);
    }
  }
}
