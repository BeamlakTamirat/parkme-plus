import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Payment gateway configuration for Chapa and other providers
class PaymentConfig {
  // Chapa configuration
  static String get chapaSecretKey {
    if (kDebugMode) {
      // Use your real test secret key from the screenshot
      final key = dotenv.env['CHAPA_SECRET_KEY_TEST'] ??
          'CHASECK_TEST-qHxmxQJXBth9waI2hWGrJOYhQck50n1v'; // Your real test key
      print('🔑 Loading Chapa Secret Key: ${key.substring(0, 20)}...');
      return key;
    } else {
      return dotenv.env['CHAPA_SECRET_KEY_PROD'] ??
          'CHASECK-your-production-secret-key';
    }
  }

  static String get chapaPublicKey {
    if (kDebugMode) {
      // Use your real test public key from the screenshot  
      final key = dotenv.env['CHAPA_PUBLIC_KEY_TEST'] ??
          'CHAPUBK_TEST-qHxmxQJXBth9waI2hWGrJOYhQck50n1v'; // Your real test key
      print('🔑 Loading Chapa Public Key: ${key.substring(0, 20)}...');
      return key;
    } else {
      return dotenv.env['CHAPA_PUBLIC_KEY_PROD'] ??
          'CHAPUBK-your-production-public-key';
    }
  }

  static String get chapaBaseUrl {
    if (kDebugMode) {
      return dotenv.env['CHAPA_BASE_URL_TEST'] ?? 'https://api.chapa.co/v1';
    } else {
      return dotenv.env['CHAPA_BASE_URL_PROD'] ?? 'https://api.chapa.co/v1';
    }
  }

  // Payment configuration
  static String get defaultCurrency {
    return dotenv.env['DEFAULT_CURRENCY'] ?? 'ETB';
  }

  static double get minimumAmount {
    return double.parse(dotenv.env['MINIMUM_AMOUNT'] ?? '10.0');
  }

  static double get maximumAmount {
    return double.parse(dotenv.env['MAXIMUM_AMOUNT'] ?? '50000.0');
  }

  static int get paymentTimeoutMinutes {
    return int.parse(dotenv.env['PAYMENT_TIMEOUT_MINUTES'] ?? '15');
  }

  // Supported payment methods
  static List<String> get supportedPaymentMethods {
    return dotenv.env['SUPPORTED_PAYMENT_METHODS']?.split(',') ??
        [
          'telebirr',
          'cbe_birr',
          'awash_birr',
          'ebirr',
          'mpesa',
          'visa',
          'mastercard',
        ];
  }

  // Transaction fees (percentage)
  static Object get transactionFees {
    final fees = dotenv.env['TRANSACTION_FEES'];
    if (fees != null) {
      return fees.split(',').map((fee) {
        final parts = fee.split(':');
        return MapEntry(parts[0], double.parse(parts[1]));
      }).toList();
    } else {
      return {
        'telebirr': 0.025, // 2.5%
        'cbe_birr': 0.02, // 2%
        'awash_birr': 0.02, // 2%
        'ebirr': 0.025, // 2.5%
        'mpesa': 0.03, // 3%
        'visa': 0.035, // 3.5%
        'mastercard': 0.035, // 3.5%
      };
    }
  }

  // Payment callback URLs - REMOVED to keep Chapa receipt visible
  static String? get paymentSuccessUrl {
    // Return null to prevent automatic redirect from Chapa receipt
    return null;
  }

  static String? get paymentFailureUrl {
    // Return null to prevent automatic redirect from Chapa receipt
    return null;
  }

  static String? get paymentCancelUrl {
    // Return null to prevent automatic redirect from Chapa receipt
    return null;
  }

  // Webhook configuration
  static String get webhookSecret {
    if (kDebugMode) {
      return dotenv.env['WEBHOOK_SECRET_TEST'] ?? 'wepark_webhook_secret_2024';
    } else {
      return dotenv.env['WEBHOOK_SECRET_PROD'] ??
          'your-production-webhook-secret';
    }
  }

  static String get webhookUrl {
    if (kDebugMode) {
      // You need to get a unique webhook.site URL and set it in your Chapa dashboard
      return dotenv.env['WEBHOOK_URL_TEST'] ??
          'https://webhook.site/your-unique-id-here';
    } else {
      return dotenv.env['WEBHOOK_URL_PROD'] ??
          'https://api.wepark.et/webhooks/chapa';
    }
  }

  // Refund configuration
  static int get refundProcessingDays {
    return int.parse(dotenv.env['REFUND_PROCESSING_DAYS'] ?? '3');
  }

  static double get refundFeePercentage {
    return double.parse(dotenv.env['REFUND_FEE_PERCENTAGE'] ?? '0.01');
  }

  static double get fullRefundWindowHours {
    return double.parse(dotenv.env['FULL_REFUND_WINDOW_HOURS'] ?? '1');
  }

  // Payment retry configuration
  static int get maxPaymentRetries {
    return int.parse(dotenv.env['MAX_PAYMENT_RETRIES'] ?? '3');
  }

  static Duration get paymentRetryDelay {
    return Duration(
        minutes: int.parse(dotenv.env['PAYMENT_RETRY_DELAY_MINUTES'] ?? '5'));
  }

  // Security configuration
  static int get transactionIdLength {
    return int.parse(dotenv.env['TRANSACTION_ID_LENGTH'] ?? '32');
  }

  static String get transactionIdPrefix {
    return dotenv.env['TRANSACTION_ID_PREFIX'] ?? 'WP';
  }

  static Duration get paymentSessionTimeout {
    return Duration(
        minutes:
            int.parse(dotenv.env['PAYMENT_SESSION_TIMEOUT_MINUTES'] ?? '30'));
  }
}

/// Chapa payment method configurations
class ChapaPaymentMethods {
  static const String telebirr = 'telebirr';
  static const String cbeBirr = 'cbe_birr';
  static const String awashBirr = 'awash_birr';
  static const String eBirr = 'ebirr';
  static const String mpesa = 'mpesa';
  static const String visa = 'visa';
  static const String mastercard = 'mastercard';

  // Payment method display names
  static const Map<String, String> displayNames = {
    telebirr: 'Telebirr',
    cbeBirr: 'CBE Birr',
    awashBirr: 'Awash Birr',
    eBirr: 'E-Birr',
    mpesa: 'M-Pesa',
    visa: 'Visa Card',
    mastercard: 'Mastercard',
  };

  // Payment method icons
  static const Map<String, String> iconPaths = {
    telebirr: 'assets/icons/telebirr.png',
    cbeBirr: 'assets/icons/cbe_birr.png',
    awashBirr: 'assets/icons/awash_birr.png',
    eBirr: 'assets/icons/ebirr.png',
    mpesa: 'assets/icons/mpesa.png',
    visa: 'assets/icons/visa.png',
    mastercard: 'assets/icons/mastercard.png',
  };

  // Payment method categories
  static const List<String> mobileWallets = [
    telebirr,
    cbeBirr,
    awashBirr,
    eBirr,
    mpesa,
  ];

  static const List<String> creditCards = [
    visa,
    mastercard,
  ];

  // Payment method availability by time
  static const Map<String, Map<String, dynamic>> availability = {
    telebirr: {
      'available_24_7': true,
      'maintenance_window': null,
    },
    cbeBirr: {
      'available_24_7': false,
      'available_hours': {'start': 6, 'end': 22}, // 6 AM to 10 PM
      'maintenance_window': {'start': 2, 'end': 4}, // 2 AM to 4 AM
    },
    awashBirr: {
      'available_24_7': false,
      'available_hours': {'start': 6, 'end': 22}, // 6 AM to 10 PM
      'maintenance_window': {'start': 1, 'end': 3}, // 1 AM to 3 AM
    },
    eBirr: {
      'available_24_7': true,
      'maintenance_window': null,
    },
    mpesa: {
      'available_24_7': true,
      'maintenance_window': null,
    },
    visa: {
      'available_24_7': true,
      'maintenance_window': null,
    },
    mastercard: {
      'available_24_7': true,
      'maintenance_window': null,
    },
  };
}

/// Payment status values for configuration
class PaymentConfigStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String success = 'success';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';
  static const String expired = 'expired';
}

/// Payment error codes
class PaymentErrorCodes {
  static const String insufficientFunds = 'insufficient_funds';
  static const String invalidCard = 'invalid_card';
  static const String cardExpired = 'card_expired';
  static const String networkError = 'network_error';
  static const String serviceUnavailable = 'service_unavailable';
  static const String invalidAmount = 'invalid_amount';
  static const String duplicateTransaction = 'duplicate_transaction';
  static const String fraudSuspected = 'fraud_suspected';
  static const String paymentMethodNotSupported =
      'payment_method_not_supported';
  static const String userCancelled = 'user_cancelled';
  static const String sessionExpired = 'session_expired';
  static const String invalidCredentials = 'invalid_credentials';
  static const String accountBlocked = 'account_blocked';
  static const String dailyLimitExceeded = 'daily_limit_exceeded';
  static const String monthlyLimitExceeded = 'monthly_limit_exceeded';
  static const String unknownError = 'unknown_error';

  // Error messages for display
  static const Map<String, String> errorMessages = {
    insufficientFunds: 'Insufficient funds in your account',
    invalidCard: 'Invalid card details',
    cardExpired: 'Your card has expired',
    networkError: 'Network connection error. Please try again',
    serviceUnavailable: 'Payment service is temporarily unavailable',
    invalidAmount: 'Invalid payment amount',
    duplicateTransaction: 'Duplicate transaction detected',
    fraudSuspected: 'Transaction flagged for security review',
    paymentMethodNotSupported: 'Payment method not supported',
    userCancelled: 'Payment cancelled by user',
    sessionExpired: 'Payment session has expired',
    invalidCredentials: 'Invalid payment credentials',
    accountBlocked: 'Your account is temporarily blocked',
    dailyLimitExceeded: 'Daily transaction limit exceeded',
    monthlyLimitExceeded: 'Monthly transaction limit exceeded',
    unknownError: 'An unexpected error occurred',
  };
}
