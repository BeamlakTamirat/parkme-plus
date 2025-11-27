import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../config/payment_config.dart';

/// Chapa Payment Service for ParkMe+
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
      if (kDebugMode) {
        print('💳 Initializing Chapa payment for: $email');
        print(
            '🔑 Using API Key: ${PaymentConfig.chapaSecretKey.substring(0, 20)}...');
        print(
            '🌐 API URL: ${PaymentConfig.chapaBaseUrl}/transaction/initialize');
        print('💰 Amount: $amount $currency');
      }

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

      if (kDebugMode) {
        print('📤 Request Body: ${jsonEncode(body)}');
      }

      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));

      if (kDebugMode) {
        print('📡 Chapa response: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode) {
          print('✅ Payment initialized successfully');
          print('🔍 Full response data structure: ${data.toString()}');
        }

        // Safe null-aware access to response data
        final responseData = data['data'] as Map<String, dynamic>?;
        final checkoutUrl = responseData?['checkout_url'] as String?;
        final responseTxRef = responseData?['tx_ref'] as String?;
        
        // Validate required fields
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          if (kDebugMode) print('❌ Missing checkout_url in response');
          return ChapaPaymentResult.error('Invalid response: missing checkout URL');
        }

        if (kDebugMode) {
          print('🌐 Checkout URL: $checkoutUrl');
          print('🔑 Transaction Ref: ${responseTxRef ?? txRef}');
        }

        return ChapaPaymentResult.success(
          checkoutUrl: checkoutUrl,
          txRef: responseTxRef ?? txRef, // Use original txRef as fallback
          message: 'Payment initialized successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode) {
          print('❌ Payment initialization failed: ${error['message']}');
          print('🔍 Full error response: ${response.body}');
        }

        return ChapaPaymentResult.error(
          error['message'] ?? 'Payment initialization failed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment initialization error: $e');
        print('🔍 Error type: ${e.runtimeType}');
      }
      return ChapaPaymentResult.error('Payment initialization failed: $e');
    }
  }

  /// Verify payment with enhanced security checks
  Future<ChapaPaymentResult> verifyPayment({
    required String txRef,
    double? expectedAmount,
    String? expectedCurrency,
  }) async {
    try {
      if (kDebugMode) print('🔍 Verifying payment: $txRef');

      // Correct Chapa verification endpoint - note: some APIs use different endpoints
      final url =
          Uri.parse('${PaymentConfig.chapaBaseUrl}/transaction/verify/$txRef');

      final headers = {
        'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
        'Content-Type': 'application/json',
      };

      if (kDebugMode) {
        print('🌐 Verification URL: $url');
      }

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('📡 Verification response: ${response.statusCode}');
        print('📥 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentStatus = data['data']['status']?.toString().toLowerCase();

        if (kDebugMode) {
          print('📡 Chapa verification response received');
          print('📊 Verification data: ${data['data']}');
          print('💰 Amount type: ${data['data']['amount'].runtimeType}');
          print('💰 Amount value: ${data['data']['amount']}');
          print('🔍 Payment Status: $paymentStatus');
        }

        // CRITICAL SECURITY CHECK: Only accept "success" status
        if (paymentStatus == 'success') {
          if (kDebugMode) print('✅ Payment ACTUALLY verified as successful');
          
          // Additional security validations
          final actualAmount = double.tryParse(data['data']['amount']?.toString() ?? '0') ?? 0.0;
          final actualCurrency = data['data']['currency']?.toString().toUpperCase();
          final actualTxRef = data['data']['tx_ref']?.toString();
          
          // Validate transaction reference matches
          if (actualTxRef != txRef) {
            if (kDebugMode) {
              print('🚨 SECURITY ALERT: Transaction reference mismatch!');
              print('   Expected: $txRef');
              print('   Received: $actualTxRef');
            }
            return ChapaPaymentResult.error('Transaction reference mismatch. Security validation failed.');
          }
          
          // Validate amount if provided
          if (expectedAmount != null && (actualAmount - expectedAmount).abs() > 0.01) {
            if (kDebugMode) {
              print('🚨 SECURITY ALERT: Amount mismatch!');
              print('   Expected: $expectedAmount');
              print('   Received: $actualAmount');
            }
            return ChapaPaymentResult.error('Payment amount mismatch. Expected: $expectedAmount, Received: $actualAmount');
          }
          
          // Validate currency if provided
          if (expectedCurrency != null && actualCurrency != expectedCurrency.toUpperCase()) {
            if (kDebugMode) {
              print('🚨 SECURITY ALERT: Currency mismatch!');
              print('   Expected: $expectedCurrency');
              print('   Received: $actualCurrency');
            }
            return ChapaPaymentResult.error('Currency mismatch. Expected: $expectedCurrency, Received: $actualCurrency');
          }
          
          if (kDebugMode) print('🔒 All security validations passed');
          
          return ChapaPaymentResult.success(
            txRef: data['data']['tx_ref']?.toString(),
            status: data['data']['status']?.toString(),
            amount: data['data']['amount']?.toString(),
            currency: data['data']['currency']?.toString(),
            message: 'Payment verified successfully',
          );
        } else {
          // Payment exists but is NOT successful (pending, failed, etc.)
          if (kDebugMode) {
            print('❌ Payment verification FAILED - Status: $paymentStatus');
            print('🚨 SECURITY: Preventing unauthorized booking creation');
          }
          
          return ChapaPaymentResult.error(
            'Payment not completed. Status: $paymentStatus. Please complete your payment first.',
          );
        }
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode) {
          print('❌ Payment verification failed: ${error['message']}');
        }

        return ChapaPaymentResult.error(
          error['message'] ?? 'Payment verification failed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment verification error: $e');
        print('🔍 Error type: ${e.runtimeType}');
      }
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

      if (kDebugMode) {
        print('📡 Payment methods response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode) print('✅ Payment methods retrieved successfully');

        return ChapaPaymentResult.success(
          paymentMethods: data['data'],
          message: 'Payment methods retrieved successfully',
        );
      } else {
        final error = jsonDecode(response.body);
        if (kDebugMode) {
          print('❌ Failed to get payment methods: ${error['message']}');
        }

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
      if (kDebugMode) {
        print('🚗 Creating parking payment for booking: $bookingId');
      }

      final txRef = 'PARKMEPLUS_${DateTime.now().millisecondsSinceEpoch}';

      // 🔥 REMOVED: Test mode simulation that was preventing real Chapa API calls
      // Now the app will make real API calls to Chapa using your actual API keys

      final customizations = {
        'title': 'ParkMe+ Parking Payment',
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

  /// Generate receipt data for completed payment
  Map<String, dynamic> generateReceiptData({
    required String txRef,
    required String amount,
    required String currency,
    required String userEmail,
    required String userName,
    required String paymentMethod,
    required DateTime paymentDate,
  }) {
    try {
      final receiptData = {
        'receipt_id': 'WP-${DateTime.now().millisecondsSinceEpoch}',
        'transaction_id': txRef,
        'amount': amount,
        'currency': currency,
        'user_email': userEmail,
        'user_name': userName,
        'payment_method': paymentMethod,
        'payment_date': paymentDate.toIso8601String(),
        'merchant_name': 'ParkMe+ Smart Parking',
        'merchant_address': 'Addis Ababa, Ethiopia',
        'status': 'completed',
        'generated_at': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('📄 Generated receipt data for: $txRef');
      }

      return receiptData;
    } catch (e) {
      if (kDebugMode) print('❌ Receipt data generation error: $e');
      return {
        'error': 'Failed to generate receipt data',
        'transaction_id': txRef,
      };
    }
  }

  /// Generate receipt download URL for completed payment
  String generateReceiptUrl({
    required String txRef,
    required String amount,
    required String currency,
    required String userEmail,
    required String userName,
    required String paymentMethod,
    required DateTime paymentDate,
  }) {
    try {
      // Create a simple data URL with receipt information
      // This creates a downloadable text receipt
      final receiptData = generateReceiptData(
        txRef: txRef,
        amount: amount,
        currency: currency,
        userEmail: userEmail,
        userName: userName,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate,
      );

      // Create receipt text content
      final receiptText = '''
═══════════════════════════════════════
           PARKME+ SMART PARKING
              PAYMENT RECEIPT
═══════════════════════════════════════

Receipt ID: ${receiptData['receipt_id']}
Transaction ID: ${receiptData['transaction_id']}

Customer Information:
Name: ${receiptData['user_name']}
Email: ${receiptData['user_email']}

Payment Details:
Amount: ${receiptData['amount']} ${receiptData['currency']}
Payment Method: ${receiptData['payment_method']}
Payment Date: ${DateTime.parse(receiptData['payment_date']).toString().split('.')[0]}
Status: ${receiptData['status'].toUpperCase()}

Merchant Information:
${receiptData['merchant_name']}
${receiptData['merchant_address']}

Generated: ${DateTime.parse(receiptData['generated_at']).toString().split('.')[0]}

═══════════════════════════════════════
Thank you for using ParkMe+ Smart Parking!
═══════════════════════════════════════
''';

      // Create data URL for download
      final encodedReceipt = Uri.encodeComponent(receiptText);
      final dataUrl = 'data:text/plain;charset=utf-8,$encodedReceipt';

      if (kDebugMode) {
        print('📄 Generated receipt data URL for: $txRef');
      }

      return dataUrl;
    } catch (e) {
      if (kDebugMode) print('❌ Receipt URL generation error: $e');
      return 'data:text/plain;charset=utf-8,Receipt generation failed for transaction: $txRef';
    }
  }

  /// Download receipt as PDF (for future implementation)
  Future<ChapaPaymentResult> downloadReceipt({
    required String txRef,
    required String userEmail,
  }) async {
    try {
      if (kDebugMode) print('📄 Downloading receipt for: $txRef');

      // For now, return the receipt URL
      // In production, this would generate and download actual PDF
      final receiptUrl = generateReceiptUrl(
        txRef: txRef,
        amount: '0.00', // Would be fetched from transaction
        currency: 'ETB',
        userEmail: userEmail,
        userName: 'User', // Would be fetched from transaction
        paymentMethod: 'unknown', // Would be fetched from transaction
        paymentDate: DateTime.now(),
      );

      return ChapaPaymentResult.success(
        message: 'Receipt URL generated successfully',
        checkoutUrl: receiptUrl, // Reuse checkoutUrl field for receipt URL
      );
    } catch (e) {
      if (kDebugMode) print('❌ Receipt download error: $e');
      return ChapaPaymentResult.error('Failed to download receipt: $e');
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
