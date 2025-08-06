import 'payment_method.dart';
import 'payment_status.dart';

class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? reference;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? failureReason;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.reference,
    required this.createdAt,
    this.processedAt,
    this.failureReason,
  });

  bool get isSuccessful => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
}
