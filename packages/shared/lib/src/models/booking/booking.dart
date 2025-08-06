import '../common/time_slot.dart';
import 'booking_status.dart';

class Booking {
  final String id;
  final String userId;
  final String locationId;
  final String spotId;
  final String vehicleId;
  final TimeSlot timeSlot;
  final BookingStatus status;
  final double totalAmount;
  final double hourlyRate;
  final DateTime bookedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? qrCode;
  final String? paymentId;
  final String? notes;
  final bool isExtended;
  final DateTime? originalEndTime;

  const Booking({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.spotId,
    required this.vehicleId,
    required this.timeSlot,
    required this.status,
    required this.totalAmount,
    required this.hourlyRate,
    required this.bookedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.qrCode,
    this.paymentId,
    this.notes,
    required this.isExtended,
    this.originalEndTime,
  });

  bool get isActive =>
      status == BookingStatus.confirmed || status == BookingStatus.checkedIn;

  bool get canCheckIn =>
      status == BookingStatus.confirmed &&
      DateTime.now()
          .isAfter(timeSlot.startTime.subtract(Duration(minutes: 15)));

  bool get canCheckOut => status == BookingStatus.checkedIn;

  bool get isCompleted =>
      status == BookingStatus.completed || status == BookingStatus.cancelled;

  bool get canExtend =>
      status == BookingStatus.checkedIn &&
      DateTime.now().isBefore(timeSlot.endTime);

  Duration get actualDuration {
    if (checkedInAt != null && checkedOutAt != null) {
      return checkedOutAt!.difference(checkedInAt!);
    }
    return Duration.zero;
  }

  String get displayId => id.substring(0, 8).toUpperCase();
}
