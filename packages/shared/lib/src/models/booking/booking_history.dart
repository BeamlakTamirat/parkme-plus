import 'booking.dart';

class BookingHistory {
  final String userId;
  final List<Booking> bookings;
  final int totalBookings;
  final double totalAmountSpent;
  final int totalHoursParked;

  const BookingHistory({
    required this.userId,
    required this.bookings,
    required this.totalBookings,
    required this.totalAmountSpent,
    required this.totalHoursParked,
  });

  List<Booking> get completedBookings => 
      bookings.where((b) => b.isCompleted).toList();

  List<Booking> get activeBookings => 
      bookings.where((b) => b.isActive).toList();

  Booking? get lastBooking => 
      bookings.isEmpty ? null : bookings.first;
} 