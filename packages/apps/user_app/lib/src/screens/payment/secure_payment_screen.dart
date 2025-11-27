import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';
import '../../widgets/common/wepark_dialog.dart';
import 'webview_payment_screen.dart';

/// Secure payment screen that uses Chapa for payment method selection
/// Removes redundant payment method selection and implements proper verification
class SecurePaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingData;

  const SecurePaymentScreen({
    super.key,
    required this.bookingData,
  });

  @override
  ConsumerState<SecurePaymentScreen> createState() =>
      _SecurePaymentScreenState();
}

class _SecurePaymentScreenState extends ConsumerState<SecurePaymentScreen> {
  bool _isProcessingPayment = false;
  String? _expandedMethod;

  @override
  Widget build(BuildContext context) {
    final amount = widget.bookingData['totalAmount'] as double;
    final locationName =
        widget.bookingData['parkingLocationName'] ?? 'Parking Location';
    final duration = widget.bookingData['duration'] ?? '2 hours';
    final vehiclePlate = widget.bookingData['vehiclePlateNumber'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Payment with Chapa',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose your payment method (Telebirr, CBE Birr, Cards) securely within Chapa\'s payment gateway.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Booking Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_parking,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Booking Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow('Location', locationName),
                        _buildDetailRow('Duration', duration),
                        _buildDetailRow('Vehicle', vehiclePlate),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'ETB ${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Methods Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        const Text(
                          'Available Payment Methods',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentMethodWithTest(
                          imagePath: 'assets/images/telebirr.png',
                          name: 'Telebirr',
                          description: 'Mobile wallet payment',
                          testCredentials: '0900112233',
                          methodKey: 'telebirr',
                        ),
                        _buildPaymentMethodWithTest(
                          imagePath: 'assets/images/cbebirr.png',
                          name: 'CBE Birr',
                          description: 'Commercial Bank of Ethiopia',
                          testCredentials: '0900123456',
                          methodKey: 'cbebirr',
                        ),
                        _buildPaymentMethodWithTest(
                          imagePath: 'assets/images/mpesa.png',
                          name: 'M-Pesa',
                          description: 'Safaricom mobile money',
                          testCredentials: '0700123456',
                          methodKey: 'mpesa',
                        ),
                        _buildPaymentMethodWithTest(
                          imagePath: 'assets/images/cooppay.png',
                          name: 'COOPPay-eBirr',
                          description: 'Cooperative Bank eBirr',
                          testCredentials: '0900881111',
                          methodKey: 'cooppay',
                        ),
                        _buildPaymentMethodWithTest(
                          imagePath: 'assets/images/visa.png',
                          name: 'Visa Card',
                          description: 'International credit card',
                          testCredentials:
                              'Card: 4200 0000 0000 0000\nCVV: 123\nExpiry: 12/34',
                          methodKey: 'visa',
                        ),
                        _buildPaymentMethodWithTest(
                          imagePath: 'assets/images/mastercard.png',
                          name: 'Mastercard',
                          description: 'International credit card',
                          testCredentials:
                              'Card: 6200 0000 0000 0000\nCVV: 123\nExpiry: 12/34',
                          methodKey: 'mastercard',
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pay Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: !_isProcessingPayment
                    ? () => _processSecurePayment(amount)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isProcessingPayment
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Opening Chapa...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.security, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ETB ${amount.toStringAsFixed(2)} Securely',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodWithTest({
    required String imagePath,
    required String name,
    required String description,
    required String testCredentials,
    required String methodKey,
  }) {
    final isExpanded = _expandedMethod == methodKey;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedMethod = isExpanded ? null : methodKey;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Payment method image
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if image not found
                        return Icon(Icons.payment,
                            size: 24, color: Colors.grey[600]);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 24,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Test Credentials',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        testCredentials,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: testCredentials));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('$name test credentials copied!'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Future<void> _processSecurePayment(double amount) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get current user
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        _showErrorDialog('User not authenticated');
        return;
      }

      // Generate unique booking ID and transaction reference
      final bookingId = widget.bookingData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final txRef = 'PARKMEPLUS_${DateTime.now().millisecondsSinceEpoch}';

      if (kDebugMode) {
        print('🚀 Starting secure payment process');
        print('   Booking ID: $bookingId');
        print('   Transaction Ref: $txRef');
        print('   Amount: $amount ETB');
      }

      // Prepare payment data (minimal - let Chapa handle payment method selection)
      final paymentData = {
        'userId': currentUser.id,
        'parkingLocationId': widget.bookingData['parkingLocationId'],
        'bookingId': bookingId,
        'amount': amount,
        'userEmail': currentUser.email,
        'userName': currentUser.fullName,
        'vehiclePlateNumber': widget.bookingData['vehiclePlateNumber'],
        'txRef': txRef,
      };

      // Initialize payment with Chapa
      final result = await ref.read(processPaymentProvider(paymentData).future);

      if (result.success && result.checkoutUrl != null) {
        if (kDebugMode) {
          print('🌐 Opening secure Chapa checkout: ${result.checkoutUrl}');
        }

        // Validate checkout URL format
        if (result.checkoutUrl!.startsWith('https://checkout.chapa.co/')) {
          // Navigate to secure WebView payment screen
          _openSecurePayment(
              result.checkoutUrl!, result.txRef ?? txRef, paymentData);
        } else {
          _showErrorDialog('Invalid payment URL received. Please try again.');
        }
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Payment initialization failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _openSecurePayment(String checkoutUrl, String txRef,
      Map<String, dynamic> paymentData) async {
    try {
      if (kDebugMode) {
        print('🔒 Opening secure WebView payment');
      }

      // Navigate to secure WebView payment screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => WebViewPaymentScreen(
            checkoutUrl: checkoutUrl,
            txRef: txRef,
            paymentData: paymentData,
            onPaymentComplete: (bool success, String message) {
              if (success) {
                _handlePaymentSuccess(txRef, paymentData);
              } else {
                _showErrorDialog(message);
              }
            },
          ),
        ),
      );

      if (kDebugMode) {
        print('🔙 Returned from secure payment: $result');
      }
    } catch (e) {
      _showErrorDialog('Failed to open secure payment: $e');
    }
  }

  Future<void> _handlePaymentSuccess(
      String txRef, Map<String, dynamic> paymentData) async {
    try {
      if (kDebugMode) {
        print('✅ Payment verified successfully, creating booking...');
      }

      // Create booking after verified payment
      final booking = await _createBookingAfterPayment(paymentData, txRef);

      if (booking != null) {
        if (mounted) {
          // Show success dialog with QR code
          _showSuccessDialog(booking);
        }
      } else {
        _showErrorDialog('Failed to create booking after payment');
      }
    } catch (e) {
      _showErrorDialog('Error processing successful payment: $e');
    }
  }

  Future<Booking?> _createBookingAfterPayment(
      Map<String, dynamic> paymentData, String transactionId) async {
    try {
      if (kDebugMode) print('🎫 Creating booking after verified payment...');

      final bookingData = {
        'id': paymentData['bookingId'],
        'userId': paymentData['userId'],
        'parkingLocationId': paymentData['parkingLocationId'],
        'vehiclePlateNumber': paymentData['vehiclePlateNumber'],
        'startTime': widget.bookingData['startTime'],
        'endTime': widget.bookingData['endTime'],
        'totalAmount': paymentData['amount'],
        'paymentMethod': 'chapa', // Chapa handled the method selection
        'transactionId': transactionId,
        'status': 'confirmed', // Confirmed since payment is verified
        'metadata': {
          'paymentProvider': 'chapa',
          'paymentStatus': 'verified',
          'createdFromApp': 'user_app',
          'chapaTransactionId': transactionId,
        },
      };

      final result = await ref.read(createBookingProvider(bookingData).future);

      if (result.success) {
        // 🔥 CRITICAL: Invalidate providers to trigger real-time UI updates
        if (kDebugMode) {
          print('🔄 Invalidating providers for real-time booking display...');
        }
        ref.invalidate(bookingHistoryProvider);
        ref.invalidate(userBookingsProvider);
        ref.invalidate(parkingLocationsProvider);

        return result.booking;
      } else {
        if (kDebugMode) print('❌ Failed to create booking: ${result.message}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating booking after payment: $e');
      return null;
    }
  }

  void _showSuccessDialog(Booking booking) {
    final locationName =
        widget.bookingData['parkingLocationName'] ?? 'Parking Location';
    final amount = widget.bookingData['totalAmount'] as double;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WeParkDialog(
        title: 'Payment Successful!',
        titleIcon: Icons.check_circle,
        titleIconColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Your payment of ETB ${amount.toStringAsFixed(2)} has been verified and your parking spot is confirmed!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Booking ID: ${booking.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Location: $locationName'),
                  Text('Spot: ${booking.spotNumber}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to home with bookings tab selected (index 2)
              context.go('/home', extra: {'initialTab': 2});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
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
}
