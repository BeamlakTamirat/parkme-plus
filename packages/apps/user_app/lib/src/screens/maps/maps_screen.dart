import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  List<ParkingLocation> _parkingLocations = [];
  ParkingLocation? _selectedLocation;
  bool _isLoading = true;

  // Default center (Meskel Square - Famous landmark in Addis Ababa)
  static const double _defaultLatitude = 9.0120;
  static const double _defaultLongitude = 38.7634;

  @override
  void initState() {
    super.initState();
    _loadParkingLocations();
  }

  Future<void> _loadParkingLocations() async {
    try {
      final mapsService = MapboxService.instance;
      final locations = await mapsService.searchNearbyParking(
        _defaultLatitude,
        _defaultLongitude,
        radius: 5000, // 5km radius
      );

      setState(() {
        _parkingLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading parking locations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onLocationSelected(ParkingLocation location) {
    setState(() {
      _selectedLocation = location;
    });

    _showLocationDetails(location);
  }

  void _showLocationDetails(ParkingLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationDetailsSheet(location),
    );
  }

  Widget _buildLocationDetailsSheet(ParkingLocation location) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_parking,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              location.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Availability status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: location.hasAvailableSpots
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: location.hasAvailableSpots
                            ? Colors.green
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          location.hasAvailableSpots
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: location.hasAvailableSpots
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.hasAvailableSpots
                                    ? 'Spots Available'
                                    : 'No Spots Available',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: location.hasAvailableSpots
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              Text(
                                '${location.availableSpots}/${location.totalSpots} spots',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Details
                  _buildDetailRow('Price', location.formattedHourlyRate),
                  _buildDetailRow('Description',
                      location.description ?? 'No description available'),

                  if (location.amenities != null &&
                      location.amenities!.isNotEmpty)
                    _buildDetailRow(
                        'Amenities', location.amenities!.join(', ')),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _getDirections(location),
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: location.hasAvailableSpots
                              ? () => _bookParking(location)
                              : null,
                          icon: const Icon(Icons.book_online),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _getDirections(ParkingLocation location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${location.name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _bookParking(ParkingLocation location) {
    // Navigate to booking screen
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: {
        'location': location,
        'action': 'create',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mapbox Maps',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapbox Widget
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: InteractiveMapboxWidget(
                centerLat: _defaultLatitude,
                centerLng: _defaultLongitude,
                initialZoom: 15.0,
                parkingLocations: _parkingLocations,
                onLocationSelected: (lat, lng) {
                  // Handle location selection differently for interactive map
                  print('📍 Location selected: $lat, $lng');
                },
                showMarkers: true,
                showCurrentLocation: true,
                showZoomControls: true,
                showStyleToggle: true, // Enable style toggle
                onStyleChanged: (styleName) {
                  print(' Maps screen style changed to: $styleName');
                },
                onExpandChanged: (isExpanded) {
                  print(' Maps screen expansion state: $isExpanded');
                  // Maps screen doesn't need expansion for now
                },
              ),
            ),
          ),

          // Location list
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Nearby Parking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_parkingLocations.length} locations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location list
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _parkingLocations.length,
                            itemBuilder: (context, index) {
                              final location = _parkingLocations[index];
                              return _buildLocationCard(location);
                            },
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

  Widget _buildLocationCard(ParkingLocation location) {
    final isSelected = _selectedLocation?.id == location.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_parking,
            color: location.hasAvailableSpots ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.address,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.local_parking,
                  size: 16,
                  color: location.hasAvailableSpots ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${location.availableSpots}/${location.totalSpots} spots',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        location.hasAvailableSpots ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  location.formattedHourlyRate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed:
              location.hasAvailableSpots ? () => _bookParking(location) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Book',
            style: TextStyle(fontSize: 12),
          ),
        ),
        onTap: () => _onLocationSelected(location),
      ),
    );
  }

  void _showFilterDialog() {
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
              title: const Text('Available Spots'),
              subtitle: const Text('Show only available'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Toggle available spots filter
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
}
