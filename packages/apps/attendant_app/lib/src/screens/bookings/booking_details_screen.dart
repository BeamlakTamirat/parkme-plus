import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../providers/attendant_providers.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;
  final Booking? booking;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(attendantBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          // Find the specific booking
          final currentBooking =
              booking ?? bookings.where((b) => b.id == bookingId).firstOrNull;

          if (currentBooking == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Booking not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The booking you\'re looking for doesn\'t exist or has been removed.',
                  ),
                ],
              ),
            );
          }

          return _buildBookingDetails(context, ref, currentBooking);
        },
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
                onPressed: () => ref.refresh(attendantBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetails(
      BuildContext context, WidgetRef ref, Booking booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            color: _getStatusColor(booking.status).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(booking.status),
                          ),
                        ),
                        Text(
                          _getStatusDescription(booking.status),
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Booking Information
          const Text(
            'Booking Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Booking ID', booking.id),
                  _buildDetailRow('Spot Number', booking.spotNumber),
                  _buildDetailRow('Start Time', booking.formattedStartTime),
                  _buildDetailRow('End Time', booking.formattedEndTime),
                  _buildDetailRow('Duration',
                      '${booking.durationInHours.toStringAsFixed(1)} hours'),
                  _buildDetailRow('Total Amount', booking.formattedTotalAmount),
                  _buildDetailRow(
                      'Payment Status', booking.paymentStatus.toUpperCase()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Information
          const Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Plate Number', booking.vehiclePlateNumber),
                  if (booking.vehicleModel != null)
                    _buildDetailRow('Vehicle Model', booking.vehicleModel!),
                  if (booking.vehicleColor != null)
                    _buildDetailRow('Vehicle Color', booking.vehicleColor!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // QR Code Section
          if (booking.qrCode != null) ...[
            const Text(
              'QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      size: 100,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.qrCode!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Payment Information
          if (booking.paymentMethod != null ||
              booking.transactionId != null) ...[
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (booking.paymentMethod != null)
                      _buildDetailRow('Payment Method',
                          booking.paymentMethod!.toUpperCase()),
                    if (booking.transactionId != null)
                      _buildDetailRow('Transaction ID', booking.transactionId!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          if (_canUpdateStatus(booking.status)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateBookingStatus(context, ref, booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getActionColor(booking.status),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _getActionText(booking.status),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Additional Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showContactDialog(context),
                  child: const Text('Contact User'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reportIssue(context),
                  child: const Text('Report Issue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
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

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting for check-in';
      case 'active':
        return 'Currently parked';
      case 'completed':
        return 'Checked out successfully';
      case 'cancelled':
        return 'Booking was cancelled';
      default:
        return 'Unknown status';
    }
  }

  bool _canUpdateStatus(String status) {
    return status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'active';
  }

  String _getActionText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Check In Vehicle';
      case 'active':
        return 'Check Out Vehicle';
      default:
        return 'Update Status';
    }
  }

  Color _getActionColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.green;
      case 'active':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateBookingStatus(
      BuildContext context, WidgetRef ref, Booking booking) async {
    try {
      String newStatus;
      if (booking.status.toLowerCase() == 'pending') {
        newStatus = 'active';
      } else if (booking.status.toLowerCase() == 'active') {
        newStatus = 'completed';
      } else {
        return;
      }

      final updatedBooking = booking.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      final result =
          await ref.read(updateBookingStatusProvider(updatedBooking).future);

      if (result) {
        refreshData(ref);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Booking ${newStatus == 'active' ? 'checked in' : 'checked out'} successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update booking status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact User'),
        content: const Text('Contact functionality not implemented yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content:
            const Text('Issue reporting functionality not implemented yet.'),
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
