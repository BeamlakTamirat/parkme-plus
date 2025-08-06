import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class FindParkingScreen extends StatefulWidget {
  const FindParkingScreen({super.key});

  @override
  State<FindParkingScreen> createState() => _FindParkingScreenState();
}

class _FindParkingScreenState extends State<FindParkingScreen> {
  final _searchController = TextEditingController();
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Parking',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            icon: Icon(
              _isMapView ? Icons.list_rounded : Icons.map_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search parking locations...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  onPressed: () {
                    // TODO: Implement filter
                  },
                  icon: const Icon(Icons.tune, color: AppColors.primary),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Map View',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Google Maps integration coming soon',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockParkingLocations.length,
      itemBuilder: (context, index) {
        final location = _mockParkingLocations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ParkingLocationCard(location: location),
        );
      },
    );
  }
}

class _ParkingLocationCard extends StatelessWidget {
  final ParkingLocationData location;

  const _ParkingLocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(
                Icons.local_parking_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),

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
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: location.availableSpots > 0
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${location.availableSpots} spots',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: location.availableSpots > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${location.distance}km • ${location.walkTime} min walk',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${location.pricePerHour} ETB/hr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: location.availableSpots > 0
                        ? () {
                            // TODO: Navigate to booking details
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      location.availableSpots > 0 ? 'Book Now' : 'Full',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParkingLocationData {
  final String name;
  final String address;
  final double distance;
  final int walkTime;
  final int pricePerHour;
  final int availableSpots;

  ParkingLocationData({
    required this.name,
    required this.address,
    required this.distance,
    required this.walkTime,
    required this.pricePerHour,
    required this.availableSpots,
  });
}

final List<ParkingLocationData> _mockParkingLocations = [
  ParkingLocationData(
    name: 'Bole Atlas Mall',
    address: 'Bole Road, Addis Ababa',
    distance: 1.2,
    walkTime: 5,
    pricePerHour: 25,
    availableSpots: 15,
  ),
  ParkingLocationData(
    name: 'Edna Mall Parking',
    address: 'Bole Medhanialem, Addis Ababa',
    distance: 2.1,
    walkTime: 8,
    pricePerHour: 30,
    availableSpots: 8,
  ),
  ParkingLocationData(
    name: 'Sarbet Parking Zone',
    address: 'Sarbet, Addis Ababa',
    distance: 0.8,
    walkTime: 3,
    pricePerHour: 20,
    availableSpots: 0,
  ),
  ParkingLocationData(
    name: 'Unity Park Entrance',
    address: 'Unity Park, Addis Ababa',
    distance: 3.5,
    walkTime: 12,
    pricePerHour: 35,
    availableSpots: 23,
  ),
];
