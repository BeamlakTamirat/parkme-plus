import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  Duration _timeRemaining = const Duration(hours: 2, minutes: 15, seconds: 43);
  Booking? _currentBooking;
  bool _isCreatingBooking = false;

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
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleBookingData() {
    final bookingData = widget.bookingData;
    if (bookingData != null && bookingData['action'] == 'create') {
      final location = bookingData['location'] as ParkingLocation?;
      if (location != null) {
        _createBooking(location);
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
        'spotNumber':
            'A${DateTime.now().millisecondsSinceEpoch % 100}', // Generate spot number
        'vehiclePlateNumber': currentUser.vehiclePlateNumber ?? 'UNKNOWN',
        'vehicleModel': currentUser.vehicleModel,
        'vehicleColor': currentUser.vehicleColor,
        'startTime': DateTime.now().toIso8601String(),
        'endTime':
            DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'totalAmount': location.hourlyRate * 2, // 2 hours
        'status': 'pending',
        'paymentStatus': 'pending',
        'qrCode': 'WEPARK_QR_${DateTime.now().millisecondsSinceEpoch}',
      };

      final result = await ref.read(createBookingProvider(bookingData).future);

      if (result.success && result.booking != null) {
        setState(() {
          _currentBooking = result.booking;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

    // Use actual booking data if available, otherwise use defaults
    final location = _currentBooking != null
        ? 'Parking Location' // We'll get this from the booking
        : widget.bookingData?['location']?.name ?? 'Meskel Square Parking';
    final space = _currentBooking?.spotNumber ?? 'A12 (Level 1)';
    final vehicle =
        _currentBooking?.vehiclePlateNumber ?? 'Toyota Corolla (AA-123-456)';
    final startTime = _currentBooking?.formattedStartTime ?? '9:00 AM';
    final endTime = _currentBooking?.formattedEndTime ?? '5:00 PM';

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
            _buildParkingDetailsSection(
                location, space, vehicle, startTime, endTime),
            const SizedBox(height: 32),

            // QR Code section
            _buildQRCodeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parking Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Space A12 is reserved for you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
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
    return Column(
      children: [
        const Text(
          'Time Remaining',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          _formatDuration(_timeRemaining),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),

        const SizedBox(height: 8),

        // Progress bar
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor:
                _timeRemaining.inSeconds / (8 * 60 * 60), // 8 hours total
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Expires at 5:00 PM today',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildParkingDetailsSection(String location, String space,
      String vehicle, String startTime, String endTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parking Details',
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
          ),
          child: Column(
            children: [
              _buildDetailRow('Location', location),
              const SizedBox(height: 16),
              _buildDetailRow('Space', space),
              const SizedBox(height: 16),
              _buildDetailRow('Vehicle', vehicle),
              const SizedBox(height: 16),
              _buildDetailRow('Start Time', startTime),
              const SizedBox(height: 16),
              _buildDetailRow('End Time', endTime),
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
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      size: 80,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'WEPARK:BOOKING:${DateTime.now().millisecondsSinceEpoch}:A12',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Show this QR code at the parking entrance and exit',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
