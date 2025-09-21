import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/comprehensive_providers.dart';
import '../../widgets/common/wepark_dialog.dart';
import 'webview_payment_screen.dart';

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
    'telebirr_test_phone': '0900112233',
    'cbe_birr_test_phone': '0900123456',
    'test_card_number': '4200000000000000',
    'test_card_expiry': '12/34',
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

  void _autoFillTestCredentials(String method) {
    // Auto-fill test credentials when payment method is selected
    switch (method) {
      case ChapaPaymentMethods.telebirr:
        _phoneController.text = testCredentials['telebirr_test_phone']!;
        break;
      case ChapaPaymentMethods.cbeBirr:
        _phoneController.text = testCredentials['cbe_birr_test_phone']!;
        break;
      case ChapaPaymentMethods.visa:
      case ChapaPaymentMethods.mastercard:
        _cardNumberController.text = testCredentials['test_card_number']!;
        _expiryController.text = testCredentials['test_card_expiry']!;
        _cvvController.text = testCredentials['test_card_cvv']!;
        break;
    }
  }

  String? _getTestNumber(String method) {
    switch (method) {
      case ChapaPaymentMethods.telebirr:
        return testCredentials['telebirr_test_phone'];
      case ChapaPaymentMethods.cbeBirr:
        return testCredentials['cbe_birr_test_phone'];
      case ChapaPaymentMethods.visa:
      case ChapaPaymentMethods.mastercard:
        return testCredentials['test_card_number'];
      default:
        return null;
    }
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
          imagePath: 'assets/images/telebirr.png',
          color: Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodTile(
          method: ChapaPaymentMethods.cbeBirr,
          title: 'CBE Birr',
          subtitle: 'Pay with CBE Birr',
          imagePath: 'assets/images/cbebirr.png',
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
          imagePath: 'assets/images/visacard.jpg',
          color: Colors.blue[800]!,
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodTile(
          method: ChapaPaymentMethods.mastercard,
          title: 'Mastercard',
          subtitle: 'Pay with Mastercard',
          imagePath: 'assets/images/mastercard.png',
          color: Colors.red[700]!,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String method,
    required String title,
    required String subtitle,
    IconData? icon,
    String? imagePath,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          // Auto-fill test numbers when payment method is selected
          _autoFillTestCredentials(method);
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: imagePath != null ? Colors.grey[50] : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: imagePath != null ? Colors.grey[300]! : color.withOpacity(0.3), 
                  width: 1.5
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        imagePath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    )
                  : Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
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
            hintText: 'Enter phone number (e.g., $testPhone)',
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'Test phone number: $testPhone',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withOpacity(0.8),
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
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: testCredentials['test_card_number'],
            prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey300),
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
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  hintText: testCredentials['test_card_expiry'],
                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: testCredentials['test_card_cvv'],
                  prefixIcon: const Icon(Icons.security, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Test Card Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Card Number: ${testCredentials['test_card_number']!}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Expiry: ${testCredentials['test_card_expiry']!} | CVV: ${testCredentials['test_card_cvv']!}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
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

      if (result.success && result.checkoutUrl != null) {
        // Payment initialization successful - open in-app WebView
        if (kDebugMode) {
          print('🌐 Opening Chapa checkout in WebView: ${result.checkoutUrl}');
        }

        // Navigate to in-app WebView payment screen
        _openInAppPayment(result.checkoutUrl!, result.txRef ?? '', paymentData);
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
        'transactionId': transactionId, // This is the Chapa transaction ID
        'status': 'pending', // Set initial status
        'metadata': {
          'paymentProvider': 'chapa',
          'paymentStatus': 'completed',
          'createdFromApp': 'user_app',
          'chapaTransactionId': transactionId, // Store as metadata too
        },
      };

      if (kDebugMode) {
        print('🔍 DEBUGGING TRANSACTION ID:');
        print('   Transaction ID parameter: $transactionId');
        print('   Booking data transactionId: ${bookingData['transactionId']}');
        print('   Payment data: ${paymentData.keys}');
      }

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

  Future<void> _openInAppPayment(
      String checkoutUrl, String txRef, Map<String, dynamic> paymentData) async {
    try {
      if (kDebugMode) {
        print('🌐 Navigating to WebView payment screen');
      }

      // Navigate to WebView payment screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => WebViewPaymentScreen(
            checkoutUrl: checkoutUrl,
            txRef: txRef,
            paymentData: paymentData,
            onPaymentComplete: (bool success, String message) {
              if (success) {
                _verifyPaymentAndCreateBooking(txRef, paymentData);
              } else {
                _showErrorDialog(message);
              }
            },
          ),
        ),
      );

      if (kDebugMode) {
        print('🔙 Returned from WebView payment screen: $result');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening WebView payment: $e');
      }
      _showErrorDialog('Failed to open payment screen: $e');
    }
  }


  void _showPaymentWaitingDialog(
      String txRef, Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WeParkDialog(
        title: 'Payment Processing...',
        titleIcon: Icons.hourglass_bottom,
        titleIconColor: Colors.blue,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Please wait while we verify your payment...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Transaction ID: $txRef',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          WeParkButton(
            text: 'Cancel Payment',
            icon: Icons.close,
            onPressed: () {
              Navigator.of(context).pop();
              _showErrorDialog('Payment cancelled');
            },
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
      builder: (context) => WeParkDialog(
        title: 'Booking Confirmed!',
        titleIcon: Icons.check_circle,
        titleIconColor: Colors.green,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(height: 6),

              // QR Code Section
              Container(
                padding: const EdgeInsets.only(left: 8.0),
                child: const Text(
                  'Your Check-in QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: booking.qrCode ?? 'booking:${booking.id}',
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${(booking.qrCode ?? booking.id).length > 20 ? '${(booking.qrCode ?? booking.id).substring(0, 20)}...' : (booking.qrCode ?? booking.id)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Show this QR code to the parking attendant for check-in and check-out.',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Booking Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Location', locationName),
                    const SizedBox(height: 8),
                    _buildDetailRow('Spot', booking.spotNumber),
                    const SizedBox(height: 8),
                    _buildDetailRow('Duration', duration),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Total Paid', CurrencyFormatter.format(amount),
                        isAmount: true),
                    const SizedBox(height: 8),
                    _buildDetailRow('Status', booking.status.toUpperCase(),
                        isStatus: true, status: booking.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Access this QR code anytime from your booking history.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          
          WeParkButton(
            text: 'Home',
            icon: Icons.home,
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isAmount = false, bool isStatus = false, String? status}) {
    Color? valueColor;
    FontWeight? fontWeight;

    if (isAmount) {
      valueColor = Colors.green;
      fontWeight = FontWeight.bold;
    } else if (isStatus) {
      fontWeight = FontWeight.bold;
      valueColor = status == 'pending' ? Colors.orange : Colors.green;
    } else {
      fontWeight = FontWeight.w600;
      valueColor = Colors.black87;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: fontWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _verifyPaymentAndCreateBooking(
      String txRef, Map<String, dynamic> paymentData) async {
    try {
      // Show verification loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating your booking...'),
            ],
          ),
        ),
      );

      if (kDebugMode) {
        print('💾 User confirmed payment completion');
        print('🎫 Creating booking with transaction: $txRef');
      }

      // SIMPLE APPROACH: Trust user confirmation for now
      // Since user clicked "I Completed Payment" and we detected success page,
      // proceed with booking creation without complex API verification
      if (kDebugMode) {
        print('✅ User confirmed payment completion - proceeding with booking');
      }

      // Proceed with booking creation
      final booking = await _createBookingAfterPayment(paymentData, txRef);

      // Close verification dialog
      if (mounted) Navigator.of(context).pop();

      if (booking != null) {
        // 🔥 CRITICAL FIX: Force real-time UI updates after booking creation
        ref.invalidate(bookingHistoryProvider);
        ref.invalidate(userBookingsProvider);
        ref.invalidate(currentUserProvider);

        if (kDebugMode) {
          print('✅ Booking created successfully: ${booking.id}');
        }

        _showSuccessDialogWithQR(booking);
      } else {
        _showErrorDialog('Failed to create booking record');
      }

      // TODO: Implement proper Chapa verification once API endpoint is confirmed
      // For now, we trust user confirmation since payment appears in dashboard
    } catch (e) {
      // Close any open dialogs
      if (mounted) Navigator.of(context).pop();

      if (kDebugMode) {
        print('❌ Booking creation error: $e');
      }
      _showErrorDialog('Failed to create booking: $e');
    }
  }

  Future<void> _downloadReceipt(Booking booking) async {
    try {
      if (kDebugMode) print('📄 Generating PDF receipt for booking: ${booking.id}');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating receipt...'),
            ],
          ),
        ),
      );

      // Get current user for receipt details
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        Navigator.of(context).pop();
        _showErrorDialog('User not authenticated');
        return;
      }

      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        Navigator.of(context).pop();
        _showErrorDialog('Storage permission required to save receipt');
        return;
      }

      // Generate PDF
      final pdf = await _generatePdfReceipt(booking, currentUser);
      
      // Save PDF to device
      final filePath = await _savePdfToDevice(pdf, booking.id);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (filePath != null) {
        _showReceiptSavedDialog(filePath);
      } else {
        _showErrorDialog('Failed to save receipt to device');
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (kDebugMode) print('❌ Receipt generation error: $e');
      _showErrorDialog('Failed to generate receipt: $e');
    }
  }

  Future<pw.Document> _generatePdfReceipt(Booking booking, User currentUser) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'WEPARK SMART PARKING',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: const pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),

              // Receipt Details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Receipt Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    _buildPdfRow('Receipt ID:', 'WP-${now.millisecondsSinceEpoch}'),
                    _buildPdfRow('Transaction ID:', booking.transactionId ?? booking.id),
                    _buildPdfRow('Booking ID:', booking.id),
                    _buildPdfRow('Date:', now.toString().split('.')[0]),
                    
                    pw.SizedBox(height: 20),
                    
                    pw.Text(
                      'Customer Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    _buildPdfRow('Name:', currentUser.fullName),
                    _buildPdfRow('Email:', currentUser.email),
                    _buildPdfRow('Phone:', currentUser.phoneNumber ?? 'N/A'),
                    _buildPdfRow('Vehicle Plate:', booking.vehiclePlateNumber ?? 'N/A'),
                    
                    pw.SizedBox(height: 20),
                    
                    pw.Text(
                      'Payment Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    _buildPdfRow('Amount:', '${booking.totalAmount.toStringAsFixed(2)} ETB'),
                    _buildPdfRow('Payment Method:', booking.paymentMethod ?? 'N/A'),
                    _buildPdfRow('Status:', booking.status.toUpperCase()),
                    _buildPdfRow('Parking Location:', widget.bookingData['parkingLocationName'] ?? 'N/A'),
                    
                    pw.SizedBox(height: 20),
                    
                    pw.Text(
                      'Booking Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    _buildPdfRow('Start Time:', booking.startTime.toString().split('.')[0]),
                    _buildPdfRow('End Time:', booking.endTime.toString().split('.')[0]),
                    _buildPdfRow('Duration:', widget.bookingData['duration'] ?? 'Variable'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'WePark Smart Parking System',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Addis Ababa, Ethiopia',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Thank you for using WePark!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<String?> _savePdfToDevice(pw.Document pdf, String bookingId) async {
    try {
      final bytes = await pdf.save();
      
      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (kDebugMode) print('❌ Could not get storage directory');
        return null;
      }

      final fileName = 'WePark_Receipt_${bookingId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      if (kDebugMode) print('✅ PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving PDF: $e');
      return null;
    }
  }

  void _showReceiptSavedDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => WeParkDialog(
        title: 'Receipt Downloaded!',
        titleIcon: Icons.download_done,
        titleIconColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your receipt has been saved to your device!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Saved to: ${filePath.split('/').last}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
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
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your Downloads folder or Files app to view the PDF receipt.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          WeParkButton(
            text: 'OK',
            icon: Icons.check,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

}
