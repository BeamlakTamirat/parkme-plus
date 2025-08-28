import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class FindParkingScreen extends ConsumerStatefulWidget {
  const FindParkingScreen({super.key});

  @override
  ConsumerState<FindParkingScreen> createState() => _FindParkingScreenState();
}

class _FindParkingScreenState extends ConsumerState<FindParkingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final bool _showMapView = true;

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
      body: Column(
        children: [
          // Search and filter section
          _buildSearchSection(),

          // Map view toggle section
          if (_showMapView) _buildMapViewSection(),

          // Filter chips
          _buildFilterSection(),

          // Available parking list - now scrollable
          Expanded(
            child: _buildParkingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.orange,
              size: 16,
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
          // Map header with toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
        children: [
                const Icon(
                  Icons.map,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Static Map View',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
          Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Live',
                style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gebeta Maps Widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 200,
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
              data: (parkingLocations) => InteractiveMapboxWidget(
                centerLat:
                    9.0120, // Meskel Square - Famous landmark in Addis Ababa
                centerLng: 38.7634,
                initialZoom: 15.0,
                parkingLocations: parkingLocations,
                onLocationSelected:
                    null, // Makes map static - no tap interactions
                showMarkers: true,
                showCurrentLocation: true,
                showZoomControls:
                    false, // Hide zoom controls for static appearance
              ),
            ),
          ),

          const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
                child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
          label,
                    style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
        ),
      ),
    );
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
        if (parkingLocations.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Icon(Icons.local_parking, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No parking locations found',
                  style: TextStyle(
                    fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for available parking spots',
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
          padding: const EdgeInsets.all(16),
          itemCount: parkingLocations.length,
          itemBuilder: (context, index) {
            final location = parkingLocations[index];
            return Column(
              children: [
                _buildParkingItem(location),
                if (index < parkingLocations.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildParkingItem(ParkingLocation location) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        children: [
          // 📸 REAL PARKING IMAGES
              Container(
            height: 120,
                decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: _buildLocationImage(location),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        location.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ),
                    const Row(
                      children: [
                        Icon(
                            Icons.star,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.5', // Default rating since it's not in the model
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  location.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
              Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0.5 km', // Default distance since it's not in the model
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_parking,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${location.availableSpots}/${location.totalSpots} available',
                  style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                  ),
                ),
                  ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                      location.formattedHourlyRate,
                style: const TextStyle(
                        fontSize: 16,
                  fontWeight: FontWeight.bold,
                        color: Colors.orange,
                ),
              ),
              const Spacer(),
                    ElevatedButton(
                      onPressed: () => _bookParking(context, location),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📸 BUILD LOCATION IMAGE WITH FALLBACK
  Widget _buildLocationImage(ParkingLocation location) {
    // Check if location has images
    if (location.images != null && location.images!.isNotEmpty) {
      final imageUrl = location.images!.first;

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Stack(
          children: [
            // Main image
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.orange,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            ),

            // Image count indicator (if multiple images)
            if (location.images!.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    '${location.images!.length} photos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ),

            // Availability indicator
            Positioned(
              top: 8,
              left: 8,
                child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                  decoration: BoxDecoration(
                  color: location.hasAvailableSpots ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
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
            ],
        ),
      );
    } else {
      // Fallback to placeholder if no images
      return _buildImagePlaceholder();
    }
  }

  // 🎨 FALLBACK PLACEHOLDER
  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            'No image available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Price Range'),
              subtitle: const Text('0 - 50 ETB/hour'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Show price range picker
              },
            ),
            ListTile(
              title: const Text('Distance'),
              subtitle: const Text('Within 5 km'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Show distance picker
              },
            ),
            ListTile(
              title: const Text('Rating'),
              subtitle: const Text('4.0+ stars'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Show rating picker
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _onMapLocationSelected(ParkingLocation location) {
    // Show location details and book directly
    _showLocationDetailsDialog(context, location);
  }

  /// Find the closest parking location to the given coordinates
  ParkingLocation? _findClosestParkingLocation(
    List<ParkingLocation> locations,
    double lat,
    double lng,
  ) {
    if (locations.isEmpty) return null;

    ParkingLocation? closestLocation;
    double minDistance = double.infinity;

    for (final location in locations) {
      final distance = _calculateDistance(
        lat,
        lng,
        location.latitude,
        location.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestLocation = location;
      }
    }

    return closestLocation;
  }

  /// Calculate distance between two coordinates in meters
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth radius in meters
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLng = (lng2 - lng1) * (math.pi / 180);
    final double a = (0.5 - math.cos(dLat / 2)) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            (1 - math.cos(dLng / 2)) /
            2;
    return earthRadius * 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));
  }

  void _bookParking(BuildContext context, ParkingLocation location) {
    // Navigate directly to payment with booking data
    _showBookingDialog(context, location);
  }

  void _showLocationDetailsDialog(
      BuildContext context, ParkingLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address: ${location.address}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ${location.availableSpots}/${location.totalSpots} spots',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate: ${location.formattedHourlyRate}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bookParking(context, location);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            const Text(
              'Duration: 2 hours (default)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${CurrencyFormatter.format(location.hourlyRate * 2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
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
              _proceedToPayment(context, location);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );
  }

  void _proceedToPayment(BuildContext context, ParkingLocation location) async {
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

    // Create booking data
    final bookingData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'parkingLocationId': location.id,
      'parkingLocationName': location.name,
      'userId': currentUser.id,
      'vehiclePlateNumber': currentUser.vehiclePlateNumber ?? 'N/A',
      'totalAmount': location.hourlyRate * 2, // 2 hours default
      'duration': '2 hours',
      'startTime': DateTime.now(),
      'endTime': DateTime.now().add(const Duration(hours: 2)),
    };

    // Navigate to payment screen
    if (context.mounted) {
      context.push('/payment', extra: bookingData);
    }
  }
}
