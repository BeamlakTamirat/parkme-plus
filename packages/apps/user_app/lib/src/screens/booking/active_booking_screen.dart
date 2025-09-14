import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class ActiveBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? bookingData;

  const ActiveBookingScreen({
    super.key,
    this.bookingData,
  });

  @override
  ConsumerState<ActiveBookingScreen> createState() =>
      _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends ConsumerState<ActiveBookingScreen> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  Booking? _currentBooking;
  bool _isCreatingBooking = false;
  bool _isOverdue = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _handleBookingData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentBooking != null) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    if (_currentBooking == null || _currentBooking!.endTime == null) return;

    // Adjust for timezone offset - add 3 hours
    final now = DateTime.now().add(const Duration(hours: 3));
    final endTime = _currentBooking!.endTime!;
    
    setState(() {
      if (now.isBefore(endTime)) {
        _timeRemaining = endTime.difference(now);
        _isOverdue = false;
      } else {
        _timeRemaining = now.difference(endTime);
        _isOverdue = true;
      }
    });
  }

  void _handleBookingData() {
    final bookingData = widget.bookingData;
    if (bookingData != null) {
      if (bookingData['action'] == 'create') {
        final location = bookingData['location'] as ParkingLocation?;
        if (location != null) {
          _createBooking(location);
        }
      } else if (bookingData['action'] == 'view' && bookingData['booking'] != null) {
        // Load existing booking data when accessed via MANAGE button
        setState(() {
          _currentBooking = bookingData['booking'] as Booking;
        });
        _updateTimeRemaining();
      }
    } else {
      // If no booking data provided, try to load the user's active booking
      _loadActiveBooking();
    }
  }

  Future<void> _loadActiveBooking() async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) return;

      final databaseService = ref.read(databaseServiceProvider);
      final userBookings = await databaseService.getUserBookings(currentUser.id);
      
      // Find the most recent active booking
      final activeBooking = userBookings
          .where((booking) => booking.status == 'active' || booking.status == 'pending')
          .isNotEmpty
          ? userBookings
              .where((booking) => booking.status == 'active' || booking.status == 'pending')
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          : null;

      if (activeBooking != null) {
        setState(() {
          _currentBooking = activeBooking;
        });
        _updateTimeRemaining();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createBooking(ParkingLocation location) async {
    setState(() {
      _isCreatingBooking = true;
    });

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final bookingData = {
        'userId': currentUser.id,
        'parkingLocationId': location.id,
        //  Remove broken spot generation - DatabaseService will handle proper allocation
        'vehiclePlateNumber': currentUser.vehiclePlateNumber ?? 'UNKNOWN',
        'vehicleModel': currentUser.vehicleModel,
        'vehicleColor': currentUser.vehicleColor,
        'startTime': DateTime.now().toIso8601String(),
        'endTime':
            DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'totalAmount': location.hourlyRate * 2, // 2 hours
        //  status and paymentStatus are handled by DatabaseService.createBookingFromMap
        // qrCode format is handled by DatabaseService
      };

      final result = await ref.read(createBookingProvider(bookingData).future);

      if (result.success && result.booking != null) {
        setState(() {
          _currentBooking = result.booking;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingBooking) {
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
            'Creating Booking',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Creating your booking...',
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

    // Show loading state if booking is not loaded yet
    if (_currentBooking == null && !_isCreatingBooking) {
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
            'Active Booking',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading booking details...',
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
          'Active Booking',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Active status banner
            _buildActiveStatusBanner(),
            const SizedBox(height: 24),

            // Countdown timer
            _buildCountdownSection(),
            const SizedBox(height: 32),

            // Parking details
            _buildParkingDetailsSection(),
            const SizedBox(height: 32),

            // QR Code section
            _buildQRCodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusBanner() {
    final status = _currentBooking?.status ?? 'unknown';
    final spotNumber = _currentBooking?.spotNumber ?? 'N/A';
    
    Color statusColor;
    Color bgColor;
    Color borderColor;
    String statusText;
    String statusMessage;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        bgColor = Colors.orange[50]!;
        borderColor = Colors.orange[200]!;
        statusText = 'Booking Confirmed';
        statusMessage = 'Space $spotNumber is reserved for you';
        statusIcon = Icons.schedule;
        break;
      case 'active':
        statusColor = Colors.green;
        bgColor = Colors.green[50]!;
        borderColor = Colors.green[200]!;
        statusText = 'Parking Active';
        statusMessage = 'Currently parked in space $spotNumber';
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = Colors.blue;
        bgColor = Colors.blue[50]!;
        borderColor = Colors.blue[200]!;
        statusText = 'Parking Completed';
        statusMessage = 'Session ended for space $spotNumber';
        statusIcon = Icons.done_all;
        break;
      case 'expired':
        statusColor = Colors.red;
        bgColor = Colors.red[50]!;
        borderColor = Colors.red[200]!;
        statusText = 'Booking Expired';
        statusMessage = 'Booking for space $spotNumber has expired';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey[50]!;
        borderColor = Colors.grey[200]!;
        statusText = 'Unknown Status';
        statusMessage = 'Booking status unknown';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isOverdue ? 'Time Overdue' : 'Time Remaining',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isOverdue ? Colors.red : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_timeRemaining.inHours.toString().padLeft(2, '0')}:${(_timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}:${(_timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _isOverdue ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOverdue 
                ? 'Booking ended at ${_currentBooking?.formattedEndTime ?? '5:00 PM'}'
                : 'Until ${_currentBooking?.formattedEndTime ?? '5:00 PM'}',
            style: TextStyle(
              fontSize: 14,
              color: _isOverdue ? Colors.red[600] : Colors.black54,
            ),
          ),
          if (_isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                'Additional charges may apply',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParkingDetailsSection() {
    // Get actual booking data or fallback values
    final locationName = _currentBooking?.parkingLocationId ?? 'Unknown Location';
    final spotNumber = _currentBooking?.spotNumber ?? 'N/A';
    final vehicleInfo = _currentBooking?.vehiclePlateNumber != null 
        ? '${_currentBooking?.vehicleModel ?? 'Vehicle'} (${_currentBooking?.vehiclePlateNumber})'
        : 'No vehicle info';
    final startTime = _currentBooking?.formattedStartTime ?? 'N/A';
    final endTime = _currentBooking?.formattedEndTime ?? 'N/A';
    final totalAmount = _currentBooking?.totalAmount.toString() ?? '0';
    final bookingStatus = _currentBooking?.status ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow('Location ID', locationName),
              const SizedBox(height: 16),
              _buildDetailRow('Parking Space', spotNumber),
              const SizedBox(height: 16),
              _buildDetailRow('Vehicle', vehicleInfo),
              const SizedBox(height: 16),
              _buildDetailRow('Start Time', startTime),
              const SizedBox(height: 16),
              _buildDetailRow('End Time', endTime),
              const SizedBox(height: 16),
              _buildDetailRow('Total Amount', '$totalAmount ETB'),
              const SizedBox(height: 16),
              _buildDetailRow('Status', bookingStatus.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    final qrCode = _currentBooking?.qrCode;
    final hasValidQR = qrCode != null && qrCode.isNotEmpty;

    return Column(
      children: [
        const Text(
          'Entry/Exit QR Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasValidQR ? Colors.grey[300]! : Colors.red[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    if (hasValidQR) ...[
                      // Generate actual scannable QR code
                      QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${qrCode.length > 20 ? '${qrCode.substring(0, 20)}...' : qrCode}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else ...[
                      // Show placeholder when QR code is not available
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'QR Code\nNot Available',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasValidQR 
                    ? 'Show this QR code to the attendant for check-in and check-out'
                    : 'QR code will be generated once booking is confirmed',
                style: TextStyle(
                  fontSize: 14,
                  color: hasValidQR ? Colors.grey[600] : Colors.red[600],
                  fontWeight: hasValidQR ? FontWeight.normal : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasValidQR) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Keep this screen accessible for entry/exit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
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
        ),
      ],
    );
  }
}
