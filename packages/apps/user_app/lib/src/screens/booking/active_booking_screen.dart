import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  @override
  Widget build(BuildContext context) {
    final location = widget.bookingData?['location'] ?? 'Meskel Square Parking';
    final space = widget.bookingData?['space'] ?? 'A12 (Level 1)';
    final vehicle =
        widget.bookingData?['vehicle'] ?? 'Toyota Corolla (AA-123-456)';
    final startTime = widget.bookingData?['startTime'] ?? '9:00 AM';
    final endTime = widget.bookingData?['endTime'] ?? '5:00 PM';

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
                child: QrImageView(
                  data:
                      'WEPARK:BOOKING:${DateTime.now().millisecondsSinceEpoch}:A12',
                  version: QrVersions.auto,
                  size: 120.0,
                  foregroundColor: Colors.black87,
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
