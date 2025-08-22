import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../providers/admin_providers.dart';

class BookingsOverviewScreen extends ConsumerStatefulWidget {
  const BookingsOverviewScreen({super.key});

  @override
  ConsumerState<BookingsOverviewScreen> createState() =>
      _BookingsOverviewScreenState();
}

class _BookingsOverviewScreenState extends ConsumerState<BookingsOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBookingsAsync = ref.watch(allBookingsProvider);
    final locationsAsync = ref.watch(allParkingLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings Overview'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(allBookingsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Bookings'),
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search bookings...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Bookings List
          Expanded(
            child: allBookingsAsync.when(
              data: (bookings) => locationsAsync.when(
                data: (locations) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(bookings, locations, 'all'),
                    _buildBookingsList(bookings, locations, 'active'),
                    _buildBookingsList(bookings, locations, 'pending'),
                    _buildBookingsList(bookings, locations, 'completed'),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error loading locations: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading bookings: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(allBookingsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> allBookings,
      List<ParkingLocation> locations, String status) {
    // Filter bookings by status and search query
    List<Booking> filteredBookings = allBookings;

    if (status != 'all') {
      filteredBookings =
          allBookings.where((booking) => booking.status == status).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredBookings = filteredBookings
          .where((booking) =>
              booking.vehiclePlateNumber.toLowerCase().contains(_searchQuery) ||
              booking.id.toLowerCase().contains(_searchQuery) ||
              (booking.spotNumber.toLowerCase().contains(_searchQuery)))
          .toList();
    }

    // Sort by creation date (newest first)
    filteredBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No ${status == 'all' ? '' : '$status '}bookings found'
                  : 'No bookings match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        final location = locations
            .where((l) => l.id == booking.parkingLocationId)
            .firstOrNull;
        return _buildBookingCard(booking, location);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, ParkingLocation? location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(booking.status),
                            color: _getStatusColor(booking.status),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(booking.status),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            booking.formattedTotalAmount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: ${booking.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location Info
            if (location != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Spot: ${booking.spotNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Vehicle & Time Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        booking.vehiclePlateNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (booking.vehicleModel != null)
                        Text(
                          '${booking.vehicleModel} ${booking.vehicleColor ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${booking.durationInHours.toStringAsFixed(1)} hours',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        booking.formattedStartTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment Info
            Row(
              children: [
                Icon(
                  _getPaymentStatusIcon(booking.paymentStatus),
                  color: _getPaymentStatusColor(booking.paymentStatus),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Payment: ${booking.paymentStatus.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPaymentStatusColor(booking.paymentStatus),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (booking.paymentMethod != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'via ${booking.paymentMethod!.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Created: ${booking.formattedCreatedAt}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBookingDetails(booking, location),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (booking.status == 'pending' || booking.status == 'active')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showUpdateStatusDialog(booking),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'active':
        return Icons.local_parking;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(Booking booking, ParkingLocation? location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking ${booking.id}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', booking.status.toUpperCase()),
              _buildDetailRow('Vehicle', booking.vehiclePlateNumber),
              if (booking.vehicleModel != null)
                _buildDetailRow('Model', booking.vehicleModel!),
              if (booking.vehicleColor != null)
                _buildDetailRow('Color', booking.vehicleColor!),
              if (location != null) _buildDetailRow('Location', location.name),
              _buildDetailRow('Spot', booking.spotNumber),
              _buildDetailRow('Start Time', booking.formattedStartTime),
              _buildDetailRow('End Time', booking.formattedEndTime),
              _buildDetailRow('Duration',
                  '${booking.durationInHours.toStringAsFixed(1)} hours'),
              _buildDetailRow('Amount', booking.formattedTotalAmount),
              _buildDetailRow('Payment', booking.paymentStatus.toUpperCase()),
              if (booking.paymentMethod != null)
                _buildDetailRow(
                    'Payment Method', booking.paymentMethod!.toUpperCase()),
              if (booking.transactionId != null)
                _buildDetailRow('Transaction ID', booking.transactionId!),
              _buildDetailRow('Created', booking.formattedCreatedAt),
              _buildDetailRow('Updated', booking.formattedUpdatedAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Booking Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current status: ${booking.status.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text(
                'This feature is not implemented yet. Status updates should be handled by attendants through QR scanning.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


