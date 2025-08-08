import 'package:flutter/foundation.dart';

/// Payment gateway configuration for Chapa and other providers
class PaymentConfig {
  // Chapa configuration
  static String get chapaSecretKey {
    if (kDebugMode) {
      return 'CHASECK_TEST-your-test-secret-key';
    } else {
      return 'CHASECK-your-production-secret-key';
    }
  }
  
  static String get chapaPublicKey {
    if (kDebugMode) {
      return 'CHAPUBK_TEST-your-test-public-key';
    } else {
      return 'CHAPUBK-your-production-public-key';
    }
  }
  
  static String get chapaBaseUrl {
    if (kDebugMode) {
      return 'https://api.chapa.co/v1';
    } else {
      return 'https://api.chapa.co/v1';
    }
  }
  
  // Payment configuration
  static const String defaultCurrency = 'ETB';
  static const double minimumAmount = 10.0; // Minimum 10 ETB
  static const double maximumAmount = 50000.0; // Maximum 50,000 ETB
  static const int paymentTimeoutMinutes = 15;
  
  // Supported payment methods
  static const List<String> supportedPaymentMethods = [
    'telebirr',
    'cbe_birr',
    'awash_birr',
    'ebirr',
    'mpesa',
    'visa',
    'mastercard',
  ];
  
  // Transaction fees (percentage)
  static const Map<String, double> transactionFees = {
    'telebirr': 0.025, // 2.5%
    'cbe_birr': 0.02, // 2%
    'awash_birr': 0.02, // 2%
    'ebirr': 0.025, // 2.5%
    'mpesa': 0.03, // 3%
    'visa': 0.035, // 3.5%
    'mastercard': 0.035, // 3.5%
  };

  // Payment callback URLs
  static String get paymentSuccessUrl {
    if (kDebugMode) {
      return 'https://dev.wepark.et/payment/success';
    } else {
      return 'https://wepark.et/payment/success';
    }
  }

  static String get paymentFailureUrl {
    if (kDebugMode) {
      return 'https://dev.wepark.et/payment/failure';
    } else {
      return 'https://wepark.et/payment/failure';
    }
  }

  static String get paymentCancelUrl {
    if (kDebugMode) {
      return 'https://dev.wepark.et/payment/cancel';
    } else {
      return 'https://wepark.et/payment/cancel';
    }
  }

  // Webhook configuration
  static String get webhookSecret {
    if (kDebugMode) {
      return 'your-test-webhook-secret';
    } else {
      return 'your-production-webhook-secret';
    }
  }

  static String get webhookUrl {
    if (kDebugMode) {
      return 'https://dev-api.wepark.et/webhooks/chapa';
    } else {
      return 'https://api.wepark.et/webhooks/chapa';
    }
  }

  // Refund configuration
  static const int refundProcessingDays = 3;
  static const double refundFeePercentage = 0.01; // 1% refund fee
  static const double fullRefundWindowHours = 1; // Full refund within 1 hour

  // Payment retry configuration
  static const int maxPaymentRetries = 3;
  static const Duration paymentRetryDelay = Duration(minutes: 5);

  // Security configuration
  static const int transactionIdLength = 32;
  static const String transactionIdPrefix = 'WP';
  static const Duration paymentSessionTimeout = Duration(minutes: 30);
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
