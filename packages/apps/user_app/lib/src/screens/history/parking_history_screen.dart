import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';
import '../../widgets/common/wepark_dialog.dart';

class ParkingHistoryScreen extends ConsumerStatefulWidget {
  const ParkingHistoryScreen({super.key});

  @override
  ConsumerState<ParkingHistoryScreen> createState() =>
      _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends ConsumerState<ParkingHistoryScreen> {
  Map<String, String> _locationNames = {};

  // Filter state management - FIXED for real-time updates
  String _selectedFilter =
      'all'; // 'all', 'active', 'pending', 'completed', 'cancelled'
  bool _isFiltering = false;

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

  /// ✅ Apply filtering based on selected filter criteria - REAL-TIME COMPATIBLE
  void _applyFilter() {
    setState(() {
      _isFiltering = true;
    });

    // Just update the filter - the UI will automatically filter the live stream
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isFiltering = false;
      });
    });

    if (kDebugMode) {
      print('✅ Applied booking filter: $_selectedFilter (real-time)');
    }
  }

  /// 🔄 Reset filter to show all bookings - REAL-TIME COMPATIBLE
  void _resetFilter() {
    setState(() {
      _selectedFilter = 'all';
      _isFiltering = false;
    });

    if (kDebugMode) {
      print('🔄 Reset booking filter to show all bookings (real-time)');
    }
  }

  ///  Filter bookings in real-time from live stream
  List<Booking> _filterBookingsRealTime(List<Booking> liveBookings) {
    switch (_selectedFilter) {
      case 'all':
        return liveBookings;
      case 'active':
        return liveBookings
            .where((booking) => booking.status.toLowerCase() == 'active')
            .toList();
      case 'pending':
        return liveBookings
            .where((booking) => booking.status.toLowerCase() == 'pending')
            .toList();
      case 'completed':
        return liveBookings
            .where((booking) => booking.status.toLowerCase() == 'completed')
            .toList();
      case 'cancelled':
        return liveBookings
            .where((booking) => booking.status.toLowerCase() == 'cancelled')
            .toList();
      default:
        return liveBookings;
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
                  onPressed: () => ref.invalidate(bookingHistoryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (bookings) {
            //  REAL-TIME FILTERING: Apply filter to live stream data
            final displayBookings = _filterBookingsRealTime(bookings);

            if (displayBookings.isEmpty) {
              String emptyMessage = 'No booking history';
              String emptySubtitle = 'Your parking bookings will appear here';

              if (_selectedFilter != 'all') {
                emptyMessage =
                    'No ${_selectedFilter.toLowerCase()} bookings found';
                emptySubtitle = 'Try changing your filter or check back later';
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _selectedFilter == 'all'
                            ? Icons.history
                            : Icons.filter_list,
                        size: 64,
                        color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptySubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFilter != 'all') ...[
                      ElevatedButton(
                        onPressed: _resetFilter,
                        child: const Text('Show All Bookings'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton(
                      onPressed: () => context.go('/find-parking'),
                      child: const Text('Find Parking'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Filter status indicator (only show if filter is applied)
                if (_selectedFilter != 'all' && !_isFiltering) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list,
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing ${_selectedFilter.toLowerCase()} bookings (${displayBookings.length})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _resetFilter,
                          icon: Icon(Icons.clear,
                              size: 16, color: Colors.blue[700]),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Bookings list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: displayBookings.length,
                    itemBuilder: (context, index) {
                      final booking = displayBookings[index];
                      return Column(
                        children: [
                          _buildHistoryItem(
                            location:
                                _getLocationName(booking.parkingLocationId),
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
                            primaryAction:
                                booking.isActive ? 'Manage' : 'Book Again',
                            primaryActionColor: Colors.orange,
                            secondaryAction: booking.status == 'pending'
                                ? 'Navigate'
                                : booking.status == 'active'
                                    ? 'Show QR Code'
                                    : 'View Details',
                            tertiaryAction: booking.status == 'pending' ||
                                    booking.status == 'active'
                                ? 'Show QR Code'
                                : null,
                            quaternaryAction: booking.status == 'pending'
                                ? 'Cancel Booking'
                                : null,
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
                              if (booking.status == 'pending') {
                                // Navigate to parking location
                                _navigateToParking(context, booking);
                              } else {
                                // Show booking details with QR code if applicable
                                _showBookingDetails(context, booking);
                              }
                            },
                            onTertiaryAction: booking.status == 'pending' ||
                                    booking.status == 'active'
                                ? () => _showBookingDetails(context, booking)
                                : null,
                            onQuaternaryAction: booking.status == 'pending'
                                ? () => _cancelBooking(context, booking)
                                : null,
                          ),
                          if (index < displayBookings.length - 1)
                            const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.local_parking;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    final isActiveBooking =
        booking.status == 'pending' || booking.status == 'active';

    showDialog(
      context: context,
      builder: (context) => WeParkDialog(
        title: 'Booking Details',
        titleIcon: Icons.receipt_long,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Section for Active Bookings
            if (isActiveBooking && booking.qrCode != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primaryLight.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'QR Code for Check-in/Check-out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: booking.qrCode!,
                            version: QrVersions.auto,
                            size: 140.0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking.qrCode!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            booking.status == 'pending'
                                ? Icons.schedule
                                : Icons.check_circle,
                            color: AppColors.info,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.status == 'pending'
                                  ? 'Show to attendant for check-in'
                                  : 'Show to attendant for check-out',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Booking Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Location',
                    _getLocationName(booking.parkingLocationId),
                    Icons.location_on,
                  ),
                  _buildDetailRow(
                      'Spot', booking.spotNumber, Icons.local_parking),
                  _buildDetailRow(
                    'Vehicle',
                    booking.vehiclePlateNumber,
                    Icons.directions_car,
                  ),
                  _buildDetailRow(
                    'Start Time',
                    booking.formattedStartTime,
                    Icons.schedule,
                  ),
                  _buildDetailRow(
                    'End Time',
                    booking.formattedEndTime,
                    Icons.schedule_outlined,
                  ),
                  _buildDetailRow(
                    'Duration',
                    '${booking.durationInHours.toStringAsFixed(1)} hours',
                    Icons.timer,
                  ),
                  _buildDetailRow(
                    'Amount',
                    booking.formattedTotalAmount,
                    Icons.payments,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(booking.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(booking.status)
                                .withOpacity(0.3),
                          ),
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
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Payment',
                    booking.paymentStatus,
                    Icons.payment,
                  ),
                ],
              ),
            ),

            // Instructions for completed bookings
            if (booking.status == 'completed') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Booking completed successfully',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          WeParkButton(
            text: 'Close',
            isOutlined: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    String? tertiaryAction,
    String? quaternaryAction,
    required VoidCallback onPrimaryAction,
    required VoidCallback onSecondaryAction,
    VoidCallback? onTertiaryAction,
    VoidCallback? onQuaternaryAction,
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
            // Header with location and status badge
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Status Badge - This was missing!
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Time Row - Clean layout
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vehicle and Space Info
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  vehicle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  Icons.local_parking,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  'Space $space',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Duration and cost with better styling
            Row(
              children: [
                // Duration section
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          duration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Cost section
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cost,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Column(
              children: [
                // Check if we have 4 buttons (for pending bookings with cancel option)
                if (quaternaryAction != null && onQuaternaryAction != null) ...[
                  // 2x2 Grid layout for 4 buttons
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio:
                        3.2, // Make buttons wider but not too tall
                    children: [
                      // Primary action button - Book Again/Manage
                      _buildCompactButton(
                        label: primaryAction,
                        icon: primaryAction == 'Book Again'
                            ? Icons.refresh
                            : Icons.settings,
                        color: primaryActionColor,
                        onPressed: onPrimaryAction,
                        isPrimary: true,
                      ),

                      // Secondary action button - Navigate
                      _buildCompactButton(
                        label: secondaryAction,
                        icon: secondaryAction == 'Navigate'
                            ? Icons.navigation
                            : secondaryAction == 'Show QR Code'
                                ? Icons.qr_code
                                : Icons.info,
                        color: Colors.grey[
                            700]!, // Make it bold grey like "View Details"
                        onPressed: onSecondaryAction,
                      ),

                      // Tertiary action button - Show QR Code
                      if (tertiaryAction != null &&
                          onTertiaryAction != null) ...[
                        _buildCompactButton(
                          label: tertiaryAction,
                          icon: Icons.qr_code_scanner,
                          color: Colors.grey[
                              700]!, // Make it bold grey like "View Details"
                          onPressed: onTertiaryAction,
                        ),
                      ] else ...[
                        const SizedBox.shrink(),
                      ],

                      // Quaternary action button - Cancel Booking
                      _buildCompactButton(
                        label: quaternaryAction,
                        icon: Icons.cancel,
                        color: Colors.red,
                        onPressed: onQuaternaryAction,
                      ),
                    ],
                  ),
                ] else ...[
                  // Standard 2-button layout for other bookings - Enhanced styling
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onPrimaryAction,
                          icon: Icon(
                            primaryAction == 'Book Again'
                                ? Icons.refresh
                                : Icons.manage_accounts,
                            size: 18,
                          ),
                          label: Text(
                            primaryAction,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryActionColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSecondaryAction,
                          icon: Icon(
                            secondaryAction == 'Navigate'
                                ? Icons.navigation
                                : secondaryAction == 'Show QR Code'
                                    ? Icons.qr_code
                                    : Icons.info_outline,
                            size: 18,
                          ),
                          label: Text(
                            secondaryAction,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: secondaryAction == 'Navigate'
                                  ? Colors.green
                                  : Colors.grey[400]!,
                              width: 1.5,
                            ),
                            foregroundColor: secondaryAction == 'Navigate'
                                ? Colors.green
                                : Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tertiary action for non-pending bookings
                  if (tertiaryAction != null &&
                      onTertiaryAction != null &&
                      status.toLowerCase() != 'active') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onTertiaryAction,
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: Text(tertiaryAction),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToParking(BuildContext context, Booking booking) {
    context.push('/navigation', extra: {
      'booking': booking,
      'action': 'navigate_to_parking',
    });
  }

  /// 🎨 Build compact button for grid layout (2x2 for 4 buttons)
  Widget _buildCompactButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 36, // Compact height to fit 4 buttons nicely
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 14),
              label: Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                shadowColor: color.withOpacity(0.3),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 14),
              label: Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600, // Make text bolder like "View Details"
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1), // Same border as "View Details"
                foregroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
    );
  }

  /// 🗑️ Cancel booking with confirmation dialog
  Future<void> _cancelBooking(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => WeParkDialog(
        title: 'Cancel Booking',
        titleIcon: Icons.cancel,
        titleIconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location: ${_getLocationName(booking.parkingLocationId)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text('Spot: ${booking.spotNumber}'),
                  const SizedBox(height: 4),
                  Text('Vehicle: ${booking.vehiclePlateNumber}'),
                  const SizedBox(height: 4),
                  Text(
                      'Time: ${booking.formattedStartTime} - ${booking.formattedEndTime}'),
                  const SizedBox(height: 4),
                  Text('Amount: ${booking.formattedTotalAmount}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.amber[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          WeParkButton(
            text: 'Keep',
            isOutlined: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          WeParkButton(
            text: 'Cancel',
            backgroundColor: Colors.red,
            icon: Icons.delete_forever,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Cancelling booking...'),
                ],
              ),
            ),
          );
        }

        // Cancel the booking by updating its status
        final updatedBooking = booking.copyWith(
          status: 'cancelled',
          updatedAt: DateTime.now(),
        );

        final databaseService = ref.read(databaseServiceProvider);
        final success = await databaseService.updateBooking(updatedBooking);

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (success) {
          // 🔥 CRITICAL FIX: Force real-time UI updates
          ref.invalidate(bookingHistoryProvider);
          ref.invalidate(userBookingsProvider);
          ref.invalidate(currentUserProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Booking cancelled successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            // ✅ REAL-TIME: No manual refresh needed - stream updates automatically
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Failed to cancel booking. Please try again.'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog if still open
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Error cancelling booking: $e'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _showFilterDialog(BuildContext context) {
    String tempSelectedFilter =
        _selectedFilter; // Temporary variable for dialog state

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => WeParkDialog(
          title: 'Filter Bookings',
          titleIcon: Icons.filter_list,
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.7, // Limit to 70% of screen height
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter options with proper radio buttons
                  _buildFilterOption(
                    context: context,
                    setState: setState,
                    title: 'All Bookings',
                    subtitle: 'Show all your parking bookings',
                    value: 'all',
                    tempValue: tempSelectedFilter,
                    onChanged: (value) {
                      tempSelectedFilter = value!;
                      setState(() {});
                    },
                    icon: Icons.list,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 6),

                  _buildFilterOption(
                    context: context,
                    setState: setState,
                    title: 'Active',
                    subtitle: 'Currently parked vehicles',
                    value: 'active',
                    tempValue: tempSelectedFilter,
                    onChanged: (value) {
                      tempSelectedFilter = value!;
                      setState(() {});
                    },
                    icon: Icons.local_parking,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 6),

                  _buildFilterOption(
                    context: context,
                    setState: setState,
                    title: 'Pending',
                    subtitle: 'Upcoming parking reservations',
                    value: 'pending',
                    tempValue: tempSelectedFilter,
                    onChanged: (value) {
                      tempSelectedFilter = value!;
                      setState(() {});
                    },
                    icon: Icons.schedule,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 6),

                  _buildFilterOption(
                    context: context,
                    setState: setState,
                    title: 'Completed',
                    subtitle: 'Finished parking sessions',
                    value: 'completed',
                    tempValue: tempSelectedFilter,
                    onChanged: (value) {
                      tempSelectedFilter = value!;
                      setState(() {});
                    },
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 6),

                  _buildFilterOption(
                    context: context,
                    setState: setState,
                    title: 'Cancelled',
                    subtitle: 'Cancelled parking reservations',
                    value: 'cancelled',
                    tempValue: tempSelectedFilter,
                    onChanged: (value) {
                      tempSelectedFilter = value!;
                      setState(() {});
                    },
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 12),

                  // Filter summary - more compact
                  if (tempSelectedFilter != 'all') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter Preview',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Showing ${tempSelectedFilter.toLowerCase()} bookings only',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (_selectedFilter != 'all') ...[
              WeParkButton(
                text: 'Clear',
                isOutlined: true,
                onPressed: () {
                  Navigator.pop(context);
                  _resetFilter();
                },
              ),
            ],
            WeParkButton(
              text: 'Apply',
              icon: Icons.check,
              onPressed: () {
                Navigator.pop(context);
                // Apply the selected filter
                if (_selectedFilter != tempSelectedFilter) {
                  setState(() {
                    _selectedFilter = tempSelectedFilter;
                  });
                  _applyFilter();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Helper method to build filter option with proper styling
  Widget _buildFilterOption({
    required BuildContext context,
    required StateSetter setState,
    required String title,
    required String subtitle,
    required String value,
    required String tempValue,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = tempValue == value;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
      ),
      child: ListTile(
        leading: Radio<String>(
          value: value,
          groupValue: tempValue,
          onChanged: onChanged,
          activeColor: color,
        ),
        title: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        onTap: () => onChanged(value),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
      ),
    );
  }
}
