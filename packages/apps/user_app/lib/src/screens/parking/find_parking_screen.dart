import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Find Parking',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchSection(),

          // Map view toggle section
          if (_showMapView) _buildMapViewSection(),

          // Filter chips
          _buildFilterSection(),

          // Available parking list
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapViewSection() {
    return Container(
      color: Colors.white,
      height: 200,
      child: Stack(
        children: [
          // Map placeholder with interactive overlay
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Interactive Map View',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Floating location markers
          Positioned(
            top: 40,
            left: 60,
            child: _buildMapMarker('5', Colors.orange),
          ),
          Positioned(
            top: 80,
            right: 80,
            child: _buildMapMarker('6', Colors.orange),
          ),
          Positioned(
            bottom: 60,
            left: 100,
            child: _buildMapMarker('7', Colors.orange),
          ),

          // Map view toggle tooltip
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
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
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.orange[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Interactive Map View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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

  Widget _buildMapMarker(String number, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ['All', 'Covered', '24/7', 'Under 30 ETB', 'EV Charging'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = filter == _selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildParkingList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // List header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Available Parking (12)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // TODO: Implement sort options
                  },
                  child: const Text(
                    'Sort by Distance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Parking locations
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildParkingLocationCard(
                  name: 'Meskel Square Parking',
                  distance: '0.2 km',
                  price: '25 ETB/hr',
                  availableSpots: '15 spots',
                  amenities: ['Covered', '24/7', 'Security'],
                  rating: 4.8,
                ),
                const SizedBox(height: 12),
                _buildParkingLocationCard(
                  name: 'Piassa Mall Garage',
                  distance: '0.5 km',
                  price: '30 ETB/hr',
                  availableSpots: '8 spots',
                  amenities: ['EV Charging', 'Covered'],
                  rating: 4.9,
                  spotsColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingLocationCard({
    required String name,
    required String distance,
    required String price,
    required String availableSpots,
    required List<String> amenities,
    required double rating,
    Color spotsColor = Colors.orange,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Car icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_parking,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 12,
                            color: index < rating.floor()
                                ? Colors.orange
                                : Colors.grey[300],
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite icon
              Icon(
                Icons.favorite_border,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Amenities
          Wrap(
            spacing: 8,
            children: amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  amenity,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Price and booking
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: spotsColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  availableSpots,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.push('/book-parking', extra: {
                  'name': name,
                  'price': price,
                  'distance': distance,
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
