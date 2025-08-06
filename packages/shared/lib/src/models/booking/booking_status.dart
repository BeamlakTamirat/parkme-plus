enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  completed,
  cancelled,
  expired,
  noShow;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  bool get isActive =>
      this == BookingStatus.confirmed || this == BookingStatus.checkedIn;

  bool get isFinished =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.expired ||
      this == BookingStatus.noShow;
}
