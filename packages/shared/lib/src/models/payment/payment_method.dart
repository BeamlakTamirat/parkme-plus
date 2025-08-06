enum PaymentMethod {
  telebirr,
  cbeBirr,
  creditCard,
  debitCard;

  String get displayName {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'Telebirr';
      case PaymentMethod.cbeBirr:
        return 'CBE Birr';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.telebirr:
        return '📱';
      case PaymentMethod.cbeBirr:
        return '🏦';
      case PaymentMethod.creditCard:
        return '💳';
      case PaymentMethod.debitCard:
        return '💳';
    }
  }
}
