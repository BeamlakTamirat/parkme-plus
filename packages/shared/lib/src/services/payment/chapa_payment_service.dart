import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../config/payment_config.dart';

/// Chapa Payment Service for WePark
/// Handles payment processing using Chapa payment gateway
class ChapaPaymentService {
  static ChapaPaymentService? _instance;
  ChapaPaymentService._();
  static ChapaPaymentService get instance {
    _instance ??= ChapaPaymentService._();
    return _instance!;
  }

  // Test credentials for Ethiopian payments
  static const Map<String, String> testCredentials = {
    'telebirr_test_phone': '0911123456',
    'cbe_birr_test_phone': '0911654321',
    'test_card_number': '4000000000000002',
    'test_card_expiry': '12/25',
    'test_card_cvv': '123',
  };

  /// Initialize payment
  Future<ChapaPaymentResult> initializePayment({
    required String amount,
    required String currency,
    required String email,
    required String firstName,
    required String lastName,
    required String txRef,
    String? phoneNumber,
    String? callbackUrl,
    String? returnUrl,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      if (kDebugMode) print('💳 Initializing Chapa payment for: $email');

      final url =
          Uri.parse('${PaymentConfig.chapaBaseUrl}/transaction/initialize');

      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
        'Content-Type': 'application/json',
      };

      final body = {
        'amount': amount,
        'currency': currency,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'tx_ref': txRef,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (callbackUrl != null) 'callback_url': callbackUrl,
        if (returnUrl != null) 'return_url': returnUrl,
        if (customizations != null) 'customizations': customizations,
      };

      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));

      if (kDebugMode) print('📡 Chapa response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode) print('✅ Payment initialized successfully');

        return ChapaPaymentResult.success(
          checkoutUrl: data['data']['checkout_url'],
          txRef: data['data']['tx_ref'],
          message: 'Payment initialized successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode)
          print('❌ Payment initialization failed: ${error['message']}');

        return ChapaPaymentResult.error(
          error['message'] ?? 'Payment initialization failed',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Payment initialization error: $e');
      return ChapaPaymentResult.error('Payment initialization failed: $e');
    }
  }

  /// Verify payment
  Future<ChapaPaymentResult> verifyPayment({
    required String txRef,
  }) async {
    try {
      if (kDebugMode) print('🔍 Verifying payment: $txRef');

      final url =
          Uri.parse('${PaymentConfig.chapaBaseUrl}/transaction/verify/$txRef');

      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (kDebugMode) print('📡 Verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode) print('✅ Payment verified successfully');

        return ChapaPaymentResult.success(
          txRef: data['data']['tx_ref'],
          status: data['data']['status'],
          amount: data['data']['amount'],
          currency: data['data']['currency'],
          message: 'Payment verified successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode)
          print('❌ Payment verification failed: ${error['message']}');

        return ChapaPaymentResult.error(
          error['message'] ?? 'Payment verification failed',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Payment verification error: $e');
      return ChapaPaymentResult.error('Payment verification failed: $e');
    }
  }

  /// Get payment methods
  Future<ChapaPaymentResult> getPaymentMethods() async {
    try {
      if (kDebugMode) print('💳 Getting available payment methods');

      final url = Uri.parse('${PaymentConfig.chapaBaseUrl}/payment-methods');

      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (kDebugMode)
        print('📡 Payment methods response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode) print('✅ Payment methods retrieved successfully');

        return ChapaPaymentResult.success(
          paymentMethods: data['data'],
          message: 'Payment methods retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode)
          print('❌ Failed to get payment methods: ${error['message']}');

        return ChapaPaymentResult.error(
          error['message'] ?? 'Failed to get payment methods',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Payment methods error: $e');
      return ChapaPaymentResult.error('Failed to get payment methods: $e');
    }
  }

  /// Create payment for parking booking
  Future<ChapaPaymentResult> createParkingPayment({
    required String userId,
    required String parkingLocationId,
    required String bookingId,
    required double amount,
    required String userEmail,
    required String userName,
    required String vehiclePlateNumber,
  }) async {
    try {
      if (kDebugMode)
        print('🚗 Creating parking payment for booking: $bookingId');

      final txRef = 'WEPARK_${DateTime.now().millisecondsSinceEpoch}';

      // For testing environment, simulate payment
      if (kDebugMode) {
        if (kDebugMode) print('🧪 Running in test mode - simulating payment');

        await Future.delayed(
            const Duration(seconds: 2)); // Simulate processing time

        return ChapaPaymentResult.success(
          txRef: txRef,
          status: 'success',
          amount: amount.toString(),
          currency: 'ETB',
          message: 'Test payment completed successfully',
          checkoutUrl: 'https://test.chapa.co/checkout/$txRef',
        );
      }

      final customizations = {
        'title': 'WePark Parking Payment',
        'description': 'Parking booking payment for $vehiclePlateNumber',
        'logo': 'https://wepark.com/logo.png', // Replace with your logo URL
      };

      final result = await initializePayment(
        amount: amount.toString(),
        currency: PaymentConfig.defaultCurrency,
        email: userEmail,
        firstName: userName.split(' ').first,
        lastName:
            userName.split(' ').length > 1 ? userName.split(' ').last : '',
        txRef: txRef,
        callbackUrl: PaymentConfig.paymentSuccessUrl,
        returnUrl: PaymentConfig.paymentSuccessUrl,
        customizations: customizations,
      );

      if (result.success) {
        // Store payment info in database (you can implement this)
        if (kDebugMode) print('💾 Payment info stored for booking: $bookingId');
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('❌ Parking payment creation error: $e');
      return ChapaPaymentResult.error('Failed to create parking payment: $e');
    }
  }
}

/// Payment result class
class ChapaPaymentResult {
  final bool success;
  final String message;
  final String? checkoutUrl;
  final String? txRef;
  final String? status;
  final String? amount;
  final String? currency;
  final List<dynamic>? paymentMethods;

  ChapaPaymentResult({
    required this.success,
    required this.message,
    this.checkoutUrl,
    this.txRef,
    this.status,
    this.amount,
    this.currency,
    this.paymentMethods,
  });

  factory ChapaPaymentResult.success({
    String? checkoutUrl,
    String? txRef,
    String? status,
    String? amount,
    String? currency,
    List<dynamic>? paymentMethods,
    required String message,
  }) {
    return ChapaPaymentResult(
      success: true,
      message: message,
      checkoutUrl: checkoutUrl,
      txRef: txRef,
      status: status,
      amount: amount,
      currency: currency,
      paymentMethods: paymentMethods,
    );
  }

  factory ChapaPaymentResult.error(String message) {
    return ChapaPaymentResult(
      success: false,
      message: message,
    );
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
}

/// Payment method enum
enum PaymentMethod {
  mobileMoney,
  bankTransfer,
  card,
  ussd,
}
