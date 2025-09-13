/// Booking model for WePark ecosystem
class Booking {
  final String id;
  final String userId;
  final String parkingLocationId;
  final String spotNumber;
  final String vehiclePlateNumber;
  final String? vehicleModel;
  final String? vehicleColor;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalAmount;
  final String status; // 'pending', 'active', 'completed', 'cancelled'
  final String paymentStatus; // 'pending', 'paid', 'failed', 'refunded'
  final String? qrCode;
  final String? paymentMethod; // 'telebirr', 'cbe_birr', 'credit_card'
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Booking({
    required this.id,
    required this.userId,
    required this.parkingLocationId,
    required this.spotNumber,
    required this.vehiclePlateNumber,
    this.vehicleModel,
    this.vehicleColor,
    required this.startTime,
    this.endTime,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.qrCode,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Create from Appwrite document
  factory Booking.fromDocument(Map<String, dynamic> document) {
    return Booking(
      id: document['\$id'] ?? '',
      userId: document['userId'] ?? '',
      parkingLocationId: document['parkingLocationId'] ?? '',
      spotNumber: document['spotNumber'] ?? '',
      vehiclePlateNumber: document['vehiclePlateNumber'] ?? '',
      vehicleModel: document['vehicleModel'],
      vehicleColor: document['vehicleColor'],
      startTime: DateTime.parse(
          document['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: document['endTime'] != null
          ? DateTime.parse(document['endTime'])
          : null,
      totalAmount: (document['totalAmount'] ?? 0.0).toDouble(),
      status: document['status'] ?? 'pending',
      paymentStatus: document['paymentStatus'] ?? 'pending',
      qrCode: document['qrCode'],
      paymentMethod: document['paymentMethod'],
      transactionId: document['transactionId'],
      createdAt: DateTime.parse(
          document['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          document['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: _parseMetadataFromString(document['metadata']),
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'parkingLocationId': parkingLocationId,
      'spotNumber': spotNumber,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'qrCode': qrCode,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata != null ? _convertMetadataToString(metadata!) : null,
    };
  }

  /// Convert metadata Map to JSON string for database storage
  static String _convertMetadataToString(Map<String, dynamic> metadata) {
    try {
      // Convert to simple key=value format to avoid JSON parsing issues
      final entries =
          metadata.entries.map((e) => '${e.key}=${e.value}').join(';');
      return entries.isNotEmpty ? entries : 'empty';
    } catch (e) {
      return 'error'; // Return simple string if conversion fails
    }
  }

  /// Parse metadata from string format stored in database
  static Map<String, dynamic>? _parseMetadataFromString(dynamic value) {
    if (value == null) return null;

    // If it's already a Map, return it
    if (value is Map<String, dynamic>) {
      return value;
    }

    // If it's a string, parse the key=value;key=value format
    if (value is String) {
      if (value.trim().isEmpty || value == 'empty') return {};

      try {
        final Map<String, dynamic> result = {};
        final pairs = value.split(';');
        for (final pair in pairs) {
          if (pair.contains('=')) {
            final parts = pair.split('=');
            if (parts.length == 2) {
              result[parts[0].trim()] = parts[1].trim();
            }
          }
        }
        return result;
      } catch (e) {
        return {'error': 'parsing_failed'};
      }
    }

    return {};
  }

  /// Create copy with updated fields
  Booking copyWith({
    String? id,
    String? userId,
    String? parkingLocationId,
    String? spotNumber,
    String? vehiclePlateNumber,
    String? vehicleModel,
    String? vehicleColor,
    DateTime? startTime,
    DateTime? endTime,
    double? totalAmount,
    String? status,
    String? paymentStatus,
    String? qrCode,
    String? paymentMethod,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parkingLocationId: parkingLocationId ?? this.parkingLocationId,
      spotNumber: spotNumber ?? this.spotNumber,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      qrCode: qrCode ?? this.qrCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if booking is active
  bool get isActive => status == 'active';

  /// Check if booking is pending
  bool get isPending => status == 'pending';

  /// Check if booking is completed
  bool get isCompleted => status == 'completed';

  /// Check if booking is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if booking is expired
  bool get isExpired => status == 'expired';

  /// Check if booking is overdue (past end time but not completed)
  bool get isOverdue {
    if (endTime == null) return false;
    final now = DateTime.now();
    return now.isAfter(endTime!) && !isCompleted && !isExpired;
  }

  /// Check if payment is completed
  bool get isPaid => paymentStatus == 'paid';

  /// Check if payment is pending
  bool get isPaymentPending => paymentStatus == 'pending';

  /// Calculate duration in hours
  double get durationInHours {
    if (endTime == null) return 0.0;
    return endTime!.difference(startTime).inMinutes / 60.0;
  }

  /// Get formatted total amount
  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)} ETB';

  /// Get formatted start time
  String get formattedStartTime =>
      '${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';

  /// Get formatted end time
  String get formattedEndTime {
    if (endTime == null) return 'Ongoing';
    return '${endTime!.day}/${endTime!.month}/${endTime!.year} ${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted created at date
  String get formattedCreatedAt =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  /// Get formatted updated at date
  String get formattedUpdatedAt =>
      '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';

  @override
  String toString() {
    return 'Booking(id: $id, status: $status, paymentStatus: $paymentStatus, amount: $formattedTotalAmount)';
  }
}

/// Booking result class for operation responses
class BookingResult {
  final bool success;
  final Booking? booking;
  final String message;
  final String? error;

  BookingResult._({
    required this.success,
    this.booking,
    required this.message,
    this.error,
  });

  factory BookingResult.success({
    Booking? booking,
    required String message,
  }) {
    return BookingResult._(
      success: true,
      booking: booking,
      message: message,
    );
  }

  factory BookingResult.error(String message, {String? error}) {
    return BookingResult._(
      success: false,
      message: message,
      error: error,
    );
  }
}
