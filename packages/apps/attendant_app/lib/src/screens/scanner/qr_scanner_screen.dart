import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared/shared.dart';
import '../../providers/attendant_providers.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  final TextEditingController _manualQrController = TextEditingController();

  bool isProcessing = false;
  bool hasPermission = false;
  bool isCameraActive = true;
  String? lastScannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || controller == null) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _initializeCamera();
        break;
      case AppLifecycleState.inactive:
        controller?.stop();
        break;
    }
  }

  Future<void> _initializeCamera() async {
    print('📷 Initializing camera...');

    // Request camera permission
    final permission = await Permission.camera.request();
    if (!mounted) return;

    setState(() {
      hasPermission = permission.isGranted;
    });

    if (hasPermission) {
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      print('✅ Camera initialized successfully');
    } else {
      print('❌ Camera permission denied');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    _manualQrController.dispose();
    super.dispose();
  }

  Future<void> _handleQRDetection(BarcodeCapture capture) async {
    if (isProcessing) return;

    final barcode = capture.barcodes.first;
    final qrCode = barcode.rawValue;

    if (qrCode == null || qrCode.isEmpty) return;

    // Prevent duplicate scans
    if (lastScannedCode == qrCode) return;

    setState(() {
      lastScannedCode = qrCode;
    });

    // Add delay to prevent rapid duplicate scans
    await Future.delayed(const Duration(seconds: 2));

    await _processQRCode(qrCode);

    // Clear last scanned code after processing
    setState(() {
      lastScannedCode = null;
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      print('🔍 Processing QR code: $qrCode');

      // Parse QR code - expecting format: "booking:{bookingId}"
      if (qrCode.startsWith('booking:')) {
        final bookingId = qrCode.substring(8);
        print('📋 Booking ID extracted: $bookingId');

        // Fetch booking details
        final databaseService = ref.read(databaseServiceProvider);
        final bookingData = await databaseService.getBooking(bookingId);

        if (bookingData != null) {
          final booking = Booking.fromDocument(bookingData);
          await _handleBookingAction(booking);
        } else {
          _showErrorDialog(
              'Booking not found', 'No booking found with ID: $bookingId');
        }
      } else {
        _showErrorDialog(
            'Invalid QR Code', 'QR code must start with "booking:" format.');
      }
    } catch (e) {
      print('❌ Error processing QR code: $e');
      _showErrorDialog('Processing Error', 'Failed to process QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleBookingAction(Booking booking) async {
    print('🎫 Processing booking: ${booking.id}');
    print('   Status: ${booking.status}');
    print('   Payment: ${booking.paymentStatus}');

    // Check if booking belongs to this attendant's location
    final currentLocation = await ref.read(attendantLocationProvider.future);
    if (currentLocation == null) {
      _showErrorDialog(
          'Location Error', 'No location assigned to this attendant.');
      return;
    }

    if (booking.parkingLocationId != currentLocation.id) {
      _showErrorDialog('Wrong Location',
          'This booking is for a different parking location.');
      return;
    }

    // Check payment status
    if (booking.paymentStatus != 'paid') {
      _showErrorDialog(
          'Payment Required', 'This booking has not been paid yet.');
      return;
    }

    // Determine action based on current status
    String newStatus;
    String actionMessage;
    DateTime? newStartTime;
    DateTime? newEndTime;

    switch (booking.status) {
      case 'pending':
        newStatus = 'active';
        newStartTime = DateTime.now(); // Update start time to actual check-in time
        newEndTime = booking.endTime; // Keep original planned end time
        actionMessage = 'Check-in successful! Vehicle can now park.';
        break;
      case 'active':
        newStatus = 'completed';
        newStartTime = booking.startTime; // Keep original start time
        newEndTime = DateTime.now(); // Update end time to actual check-out time
        actionMessage = 'Check-out successful! Parking session completed.';
        break;
      case 'completed':
        _showInfoDialog(
            'Already Completed', 'This booking has already been completed.');
        return;
      case 'cancelled':
        _showErrorDialog(
            'Cancelled Booking', 'This booking has been cancelled.');
        return;
      case 'expired':
        _showErrorDialog(
            'Expired Booking', 'This booking has expired and cannot be used.');
        return;
      default:
        _showErrorDialog(
            'Invalid Status', 'Unknown booking status: ${booking.status}');
        return;
    }

    // Check if booking is overdue (past original end time) during check-in
    if (newStatus == 'active' && booking.endTime != null) {
      final now = DateTime.now();
      if (now.isAfter(booking.endTime!)) {
        // Show warning but allow check-in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Warning: This booking was scheduled to end at ${booking.formattedEndTime}. '
              'Additional charges may apply for overtime parking.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    // Update booking with new times and status
    final updatedBooking = booking.copyWith(
      status: newStatus,
      startTime: newStartTime,
      endTime: newEndTime,
      updatedAt: DateTime.now(),
    );

    final databaseService = ref.read(databaseServiceProvider);
    final success = await databaseService.updateBooking(updatedBooking);

    if (success) {
      // Refresh attendant data
      ref.invalidate(attendantBookingsProvider);
      ref.invalidate(activeBookingsProvider);

      _showSuccessDialog(
        newStatus == 'active' ? 'Check-in Complete' : 'Check-out Complete',
        actionMessage,
        updatedBooking,
      );
    } else {
      _showErrorDialog('Update Failed',
          'Failed to update booking status. Please try again.');
    }
  }

  void _showSuccessDialog(String title, String message, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text('Booking Details:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Vehicle: ${booking.vehiclePlateNumber}'),
            Text('Spot: ${booking.spotNumber}'),
            Text('Status: ${booking.status.toUpperCase()}'),
            Text('Amount: ${booking.formattedTotalAmount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/booking/${booking.id}', extra: booking);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!hasPermission) {
      return _buildPermissionDeniedView();
    }

    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        MobileScanner(
          controller: controller!,
          onDetect: _handleQRDetection,
        ),

        // Scanning overlay
        Container(
          decoration: const ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
        ),

        // Top instruction
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Point camera at QR code to scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Processing indicator
        if (isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing QR Code...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'To scan QR codes, please allow camera access in your device settings.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentAttendantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (controller != null) ...[
            IconButton(
              icon: const Icon(Icons.flash_off), // Simplified torch icon
              onPressed: () => controller!.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => controller!.switchCamera(),
            ),
          ],
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Please log in to access the scanner',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              // Camera view
              Expanded(
                flex: 3,
                child: _buildCameraView(),
              ),

              // Manual input section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Manual Entry (for testing)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualQrController,
                            decoration: InputDecoration(
                              labelText: 'Enter QR Code',
                              hintText: 'booking:12345',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.qr_code),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  final qrCode =
                                      _manualQrController.text.trim();
                                  if (qrCode.isNotEmpty) {
                                    _processQRCode(qrCode);
                                    _manualQrController.clear();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Scan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Supported formats: booking:{id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentAttendantProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    path = Path.combine(
      PathOperation.difference,
      path,
      Path()
        ..addRRect(
            RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))),
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw corner borders
    final borderPath = Path();

    // Top-left corner
    borderPath
      ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
      ..arcToPoint(
        Offset(cutOutRect.left + borderRadius, cutOutRect.top),
        radius: Radius.circular(borderRadius),
        clockwise: false,
      )
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top-right corner
    borderPath
      ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
      ..arcToPoint(
        Offset(cutOutRect.right, cutOutRect.top + borderRadius),
        radius: Radius.circular(borderRadius),
        clockwise: false,
      )
      ..lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom-right corner
    borderPath
      ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
      ..arcToPoint(
        Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
        radius: Radius.circular(borderRadius),
        clockwise: false,
      )
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom-left corner
    borderPath
      ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
      ..arcToPoint(
        Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
        radius: Radius.circular(borderRadius),
        clockwise: false,
      )
      ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
