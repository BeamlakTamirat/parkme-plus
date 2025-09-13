import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class EnhancedPaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingData;

  const EnhancedPaymentScreen({
    super.key,
    required this.bookingData,
  });

  @override
  ConsumerState<EnhancedPaymentScreen> createState() =>
      _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends ConsumerState<EnhancedPaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessingPayment = false;
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Test credentials for Ethiopian payments
  static const Map<String, String> testCredentials = {
    'telebirr_test_phone': '0911123456',
    'cbe_birr_test_phone': '0911654321',
    'test_card_number': '4000000000000002',
    'test_card_expiry': '12/25',
    'test_card_cvv': '123',
  };

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.bookingData['totalAmount'] as double;
    final parkingLocationName =
        widget.bookingData['parkingLocationName'] as String;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Payment Summary
            _buildPaymentSummary(amount, parkingLocationName),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Methods
                    _buildPaymentMethods(),

                    const SizedBox(height: 24),

                    // Payment Details Form
                    if (_selectedPaymentMethod != null) _buildPaymentForm(),
                  ],
                ),
              ),
            ),

            // Pay Button
            _buildPayButton(amount),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(double amount, String locationName) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  locationName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: ${widget.bookingData['duration'] ?? 'Variable'}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Mobile Wallets Section
        const Text(
          'Mobile Wallets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          method: ChapaPaymentMethods.telebirr,
          title: 'Telebirr',
          subtitle: 'Pay with your Telebirr account',
          icon: Icons.phone_android,
          color: Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodTile(
          method: ChapaPaymentMethods.cbeBirr,
          title: 'CBE Birr',
          subtitle: 'Pay with CBE Birr',
          icon: Icons.account_balance,
          color: Colors.blue,
        ),

        const SizedBox(height: 24),

        // Credit Cards Section
        const Text(
          'Credit Cards',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          method: ChapaPaymentMethods.visa,
          title: 'Visa Card',
          subtitle: 'Pay with Visa card',
          icon: Icons.credit_card,
          color: Colors.blue[800]!,
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodTile(
          method: ChapaPaymentMethods.mastercard,
          title: 'Mastercard',
          subtitle: 'Pay with Mastercard',
          icon: Icons.credit_card,
          color: Colors.red[700]!,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedPaymentMethod == ChapaPaymentMethods.telebirr ||
        _selectedPaymentMethod == ChapaPaymentMethods.cbeBirr) {
      return _buildMobileWalletForm();
    } else if (_selectedPaymentMethod == ChapaPaymentMethods.visa ||
        _selectedPaymentMethod == ChapaPaymentMethods.mastercard) {
      return _buildCreditCardForm();
    }
    return const SizedBox.shrink();
  }

  Widget _buildMobileWalletForm() {
    final testPhone = _selectedPaymentMethod == ChapaPaymentMethods.telebirr
        ? testCredentials['telebirr_test_phone']!
        : testCredentials['cbe_birr_test_phone']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: testPhone,
            prefixText: '+251 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Test Mode: Use $testPhone for testing',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Card Number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: testCredentials['test_card_number'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  hintText: testCredentials['test_card_expiry'],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: testCredentials['test_card_cvv'],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Test Card Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Test Mode - Use these credentials:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Card: ${testCredentials['test_card_number']}\n'
                'Expiry: ${testCredentials['test_card_expiry']}\n'
                'CVV: ${testCredentials['test_card_cvv']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.info,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(double amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _selectedPaymentMethod != null && !_isProcessingPayment
              ? () => _processPayment(amount)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isProcessingPayment
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Pay ${CurrencyFormatter.format(amount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _processPayment(double amount) async {
    if (_selectedPaymentMethod == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Validate payment details
      String? validationError = _validatePaymentDetails();
      if (validationError != null) {
        _showErrorDialog(validationError);
        return;
      }

      // Get current user
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        _showErrorDialog('User not authenticated');
        return;
      }

      // Prepare payment data
      final paymentData = {
        'userId': currentUser.id,
        'parkingLocationId': widget.bookingData['parkingLocationId'],
        'bookingId': widget.bookingData['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'amount': amount,
        'userEmail': currentUser.email,
        'userName': currentUser.fullName,
        'vehiclePlateNumber': widget.bookingData['vehiclePlateNumber'],
        'paymentMethod': _selectedPaymentMethod,
        'phoneNumber': _phoneController.text.trim(),
        'cardNumber': _cardNumberController.text.trim(),
        'cardExpiry': _expiryController.text.trim(),
        'cardCvv': _cvvController.text.trim(),
      };

      // Process payment
      final result = await ref.read(processPaymentProvider(paymentData).future);

      if (result.success) {
        // Payment successful - now create the booking in database
        final booking =
            await _createBookingAfterPayment(paymentData, result.txRef ?? '');
        if (booking != null) {
          _showSuccessDialogWithQR(booking);
        } else {
          _showErrorDialog('Failed to create booking record');
        }
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Payment processing failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<Booking?> _createBookingAfterPayment(
      Map<String, dynamic> paymentData, String transactionId) async {
    try {
      if (kDebugMode) print('🎫 Creating booking after successful payment...');

      // Prepare booking data for database
      final bookingData = {
        'id': paymentData['bookingId'],
        'userId': paymentData['userId'],
        'parkingLocationId': paymentData['parkingLocationId'],
        'vehiclePlateNumber': paymentData['vehiclePlateNumber'],
        'startTime': widget.bookingData['startTime'],
        'endTime': widget.bookingData['endTime'],
        'totalAmount': paymentData['amount'],
        'paymentMethod': paymentData['paymentMethod'],
        'transactionId': transactionId,
        'metadata': {
          'paymentProvider': 'chapa',
          'paymentStatus': 'completed',
          'createdFromApp': 'user_app',
        },
      };

      // Create booking in database
      final result = await ref.read(createBookingProvider(bookingData).future);

      if (result.success) {
        if (kDebugMode) {
          print('✅ Booking created successfully: ${result.booking?.id}');
        }
        return result.booking; // Return the booking object
      } else {
        if (kDebugMode) print('❌ Failed to create booking: ${result.message}');
        return null; // Return null on failure
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating booking after payment: $e');
      return null; // Return null on error
    }
  }

  String? _validatePaymentDetails() {
    if (_selectedPaymentMethod == ChapaPaymentMethods.telebirr ||
        _selectedPaymentMethod == ChapaPaymentMethods.cbeBirr) {
      if (_phoneController.text.trim().isEmpty) {
        return 'Please enter your phone number';
      }
    } else if (_selectedPaymentMethod == ChapaPaymentMethods.visa ||
        _selectedPaymentMethod == ChapaPaymentMethods.mastercard) {
      if (_cardNumberController.text.trim().isEmpty) {
        return 'Please enter your card number';
      }
      if (_expiryController.text.trim().isEmpty) {
        return 'Please enter card expiry date';
      }
      if (_cvvController.text.trim().isEmpty) {
        return 'Please enter CVV';
      }
    }
    return null;
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

  void _showSuccessDialogWithQR(Booking booking) {
    final locationName =
        widget.bookingData['parkingLocationName'] ?? 'Parking Location';
    final amount = widget.bookingData['totalAmount'] as double;
    final duration = widget.bookingData['duration'] ?? '2 hours';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 6),
            Text('Booking Confirmed!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Parking: booked & \npayment: confirmed.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // QR Code Section
              const Text(
                'Your Check-in QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // QR Code Image
                      QrImageView(
                        data: booking.qrCode ?? 'booking:${booking.id}',
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        booking.qrCode ?? 'booking:${booking.id}',
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Show this QR code to the parking attendant for check-in. Keep it safe for check-out as well.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1565C0), // Colors.blue[800]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                      'Location: $locationName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Spot: ${booking.spotNumber}'),
                    const SizedBox(height: 4),
                    Text('Duration: $duration'),
                    const SizedBox(height: 4),
                    Text(
                      'Total Paid: ${CurrencyFormatter.format(amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${booking.status.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: booking.status == 'pending'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can also access this QR code from your booking history.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }
}
