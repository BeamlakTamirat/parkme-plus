import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../config/payment_config.dart';
import '../utils/simple_logger.dart';

/// Chapa payment service for processing Ethiopian payments
class ChapaService {
  static ChapaService? _instance;
  late final Dio _dio;
  late final Uuid _uuid;

  ChapaService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: PaymentConfig.chapaBaseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
      },
    ));
    _uuid = const Uuid();
  }

  static ChapaService get instance {
    _instance ??= ChapaService._internal();
    return _instance!;
  }

  /// Initialize payment
  Future<PaymentResult> initializePayment({
    required double amount,
    required String currency,
    required String email,
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String callbackUrl,
    required String returnUrl,
    String? description,
    Map<String, String>? metadata,
  }) async {
    try {
      logger.info('Initializing Chapa payment: $amount $currency');

      final txRef = _generateTransactionReference();
      
      final data = {
        'amount': amount.toString(),
        'currency': currency,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'tx_ref': txRef,
        'callback_url': callbackUrl,
        'return_url': returnUrl,
        'description': description ?? 'ParkMe+ Payment',
        'meta': metadata ?? {},
      };

      final response = await _dio.post('/transaction/initialize', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          logger.info('Payment initialized successfully: $txRef');
          
          return PaymentResult(
            success: true,
            transactionReference: txRef,
            checkoutUrl: responseData['data']['checkout_url'],
            message: 'Payment initialized successfully',
          );
        } else {
          logger.error('Payment initialization failed: ${responseData['message']}');
          return PaymentResult(
            success: false,
            error: 'initialization_failed',
            message: responseData['message'] ?? 'Payment initialization failed',
          );
        }
      } else {
        logger.error('HTTP error during payment initialization: ${response.statusCode}');
        return PaymentResult(
          success: false,
          error: 'http_error',
          message: 'Payment service is temporarily unavailable',
        );
      }
    } on DioException catch (e) {
      logger.error('Dio error during payment initialization: ${e.message}');
      return PaymentResult(
        success: false,
        error: 'network_error',
        message: 'Network error occurred. Please try again',
      );
    } catch (e) {
      logger.error('Unexpected error during payment initialization: $e');
      return PaymentResult(
        success: false,
        error: 'unknown_error',
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Verify payment status
  Future<PaymentResult> verifyPayment(String transactionReference) async {
    try {
      logger.info('Verifying payment: $transactionReference');

      final response = await _dio.get('/transaction/verify/$transactionReference');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          final data = responseData['data'];
          final status = data['status'];
          
          logger.info('Payment verification completed: $status');
          
          return PaymentResult(
            success: status == 'success',
            transactionReference: transactionReference,
            status: _mapChapaStatus(status),
            amount: double.tryParse(data['amount']?.toString() ?? '0'),
            currency: data['currency'],
            message: status == 'success' ? 'Payment successful' : 'Payment failed',
            chapaReference: data['reference'],
          );
        } else {
          logger.error('Payment verification failed: ${responseData['message']}');
          return PaymentResult(
            success: false,
            transactionReference: transactionReference,
            error: 'verification_failed',
            message: responseData['message'] ?? 'Payment verification failed',
          );
        }
      } else {
        logger.error('HTTP error during payment verification: ${response.statusCode}');
        return PaymentResult(
          success: false,
          transactionReference: transactionReference,
          error: 'http_error',
          message: 'Payment verification service is temporarily unavailable',
        );
      }
    } on DioException catch (e) {
      logger.error('Dio error during payment verification: ${e.message}');
      return PaymentResult(
        success: false,
        transactionReference: transactionReference,
        error: 'network_error',
        message: 'Network error occurred. Please try again',
      );
    } catch (e) {
      logger.error('Unexpected error during payment verification: $e');
      return PaymentResult(
        success: false,
        transactionReference: transactionReference,
        error: 'unknown_error',
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Generate transaction reference
  String _generateTransactionReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().substring(0, 8);
    return 'wepark_${timestamp}_$uuid';
  }

  /// Map Chapa status to our payment status
  String _mapChapaStatus(String chapaStatus) {
    switch (chapaStatus.toLowerCase()) {
      case 'success':
        return PaymentConfigStatus.success;
      case 'failed':
        return PaymentConfigStatus.failed;
      case 'pending':
        return PaymentConfigStatus.pending;
      case 'cancelled':
        return PaymentConfigStatus.cancelled;
      default:
        return PaymentConfigStatus.failed;
    }
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? transactionReference;
  final String? checkoutUrl;
  final String? status;
  final double? amount;
  final String? currency;
  final String? error;
  final String message;
  final String? chapaReference;

  PaymentResult({
    required this.success,
    this.transactionReference,
    this.checkoutUrl,
    this.status,
    this.amount,
    this.currency,
    this.error,
    required this.message,
    this.chapaReference,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, txRef: $transactionReference, status: $status, message: $message)';
  }
}
