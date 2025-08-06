enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isFinished => 
      this == PaymentStatus.completed || 
      this == PaymentStatus.failed || 
      this == PaymentStatus.cancelled ||
      this == PaymentStatus.refunded;
} 