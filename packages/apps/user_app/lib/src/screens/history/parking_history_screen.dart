import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class ParkingHistoryScreen extends ConsumerStatefulWidget {
  const ParkingHistoryScreen({super.key});

  @override
  ConsumerState<ParkingHistoryScreen> createState() =>
      _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends ConsumerState<ParkingHistoryScreen> {
  Map<String, String> _locationNames = {};

  @override
  void initState() {
    super.initState();
    _loadLocationNames();
  }

  Future<void> _loadLocationNames() async {
    try {
      final locations = await ref.read(parkingLocationsProvider.future);
      setState(() {
        _locationNames = {
          for (var location in locations) location.id: location.name
        };
      });
    } catch (e) {
      // Handle error silently - we'll show "Unknown Location" as fallback
      print('Error loading location names: $e');
    }
  }

  String _getLocationName(String locationId) {
    return _locationNames[locationId] ?? 'Unknown Location';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Parking History',
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
        ],
      ),
      body: _buildBookingHistory(context, ref),
    );
  }

  Widget _buildBookingHistory(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(currentUserProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (user) {
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No user data found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/sign-in'),
                  child: const Text('Go to Sign In'),
                ),
              ],
            ),
          );
        }

        final bookingsAsync = ref.watch(bookingHistoryProvider);

        return bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(bookingHistoryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (bookings) {
            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No booking history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your parking bookings will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/find-parking'),
                      child: const Text('Find Parking'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Column(
                  children: [
                    _buildHistoryItem(
                      location: _getLocationName(booking
                          .parkingLocationId), // 🔧 FIX: Use real location name
                      space: booking.spotNumber,
                      vehicle: booking.vehiclePlateNumber,
                      date: booking.formattedStartTime,
                      time:
                          '${booking.formattedStartTime} - ${booking.formattedEndTime}',
                      duration:
                          '${booking.durationInHours.toStringAsFixed(1)} hours',
                      cost: booking.formattedTotalAmount,
                      status: booking.status,
                      statusColor: _getStatusColor(booking.status),
                      primaryAction: booking.isActive ? 'Manage' : 'Book Again',
                      primaryActionColor: Colors.orange,
                      secondaryAction: booking.status == 'pending' ||
                              booking.status == 'active'
                          ? 'Show QR Code'
                          : 'View Details',
                      onPrimaryAction: () {
                        if (booking.isActive) {
                          // Navigate to active booking
                          context.push('/booking', extra: {
                            'booking': booking,
                            'action': 'view',
                          });
                        } else {
                          // Navigate to find parking with previous location data
                          context.push('/find-parking', extra: {
                            'previousBooking': booking,
                            'action': 'book_again',
                          });
                        }
                      },
                      onSecondaryAction: () {
                        // Show booking details with QR code if applicable
                        _showBookingDetails(context, booking);
                      },
                    ),
                    if (index < bookings.length - 1) const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    final isActiveBooking =
        booking.status == 'pending' || booking.status == 'active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Code Section for Active Bookings
              if (isActiveBooking && booking.qrCode != null) ...[
                const Text(
                  'QR Code for Check-in/Check-out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: booking.qrCode!,
                          version: QrVersions.auto,
                          size: 120.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.qrCode!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        booking.status == 'pending'
                            ? Icons.schedule
                            : Icons.check_circle,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.status == 'pending'
                              ? 'Show to attendant for check-in'
                              : 'Show to attendant for check-out',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1565C0), // Colors.blue[800]
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Booking Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Location: ${_getLocationName(booking.parkingLocationId)}'),
                    const SizedBox(height: 6),
                    Text('Spot: ${booking.spotNumber}'),
                    const SizedBox(height: 6),
                    Text('Vehicle: ${booking.vehiclePlateNumber}'),
                    const SizedBox(height: 6),
                    Text('Start: ${booking.formattedStartTime}'),
                    const SizedBox(height: 6),
                    Text('End: ${booking.formattedEndTime}'),
                    const SizedBox(height: 6),
                    Text(
                        'Duration: ${booking.durationInHours.toStringAsFixed(1)} hours'),
                    const SizedBox(height: 6),
                    Text('Amount: ${booking.formattedTotalAmount}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Status: '),
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
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(booking.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Payment: ${booking.paymentStatus}'),
                  ],
                ),
              ),

              // Instructions for completed bookings
              if (booking.status == 'completed') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Booking completed successfully',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32), // Colors.green[800]
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String location,
    required String space,
    required String vehicle,
    required String date,
    required String time,
    required String duration,
    required String cost,
    required String status,
    required Color statusColor,
    required String primaryAction,
    required Color primaryActionColor,
    required String secondaryAction,
    required VoidCallback onPrimaryAction,
    required VoidCallback onSecondaryAction,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with location and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(
                  Icons.local_parking,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  space,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.directions_car,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  vehicle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Duration and cost
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.payment,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  cost,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryActionColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(primaryAction),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      secondaryAction,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Bookings'),
              leading: Radio<String>(
                value: 'all',
                groupValue: 'all',
                onChanged: (value) {
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Active Bookings'),
              leading: Radio<String>(
                value: 'active',
                groupValue: 'all',
                onChanged: (value) {
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Completed Bookings'),
              leading: Radio<String>(
                value: 'completed',
                groupValue: 'all',
                onChanged: (value) {
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Cancelled Bookings'),
              leading: Radio<String>(
                value: 'cancelled',
                groupValue: 'all',
                onChanged: (value) {
                  Navigator.pop(context);
                },
              ),
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
              // Apply filter
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
