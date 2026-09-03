import 'enums.dart';
import 'vendor.dart';

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.vendorId,
    required this.consumerId,
    required this.eventDate,
    this.guestCount,
    this.message = '',
    this.status = BookingStatus.pending,
    this.createdAt,
    this.vendor,
  });

  final String id;
  final String vendorId;
  final String consumerId;
  final DateTime eventDate;
  final int? guestCount;
  final String message;
  final BookingStatus status;
  final DateTime? createdAt;
  final VendorProfile? vendor;

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    VendorProfile? vendor;
    final vendorRaw = json['vendor_profiles'] ?? json['vendor'];
    if (vendorRaw is Map<String, dynamic>) {
      vendor = VendorProfile.fromJson(vendorRaw);
    }

    return BookingRequest(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      consumerId: json['consumer_id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      guestCount: (json['guest_count'] as num?)?.toInt(),
      message: (json['message'] as String?) ?? '',
      status: BookingStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      vendor: vendor,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'event_date': eventDate.toIso8601String().split('T').first,
        'guest_count': guestCount,
        'message': message,
        'status': status.name,
      };

  BookingRequest copyWith({
    BookingStatus? status,
    VendorProfile? vendor,
  }) {
    return BookingRequest(
      id: id,
      vendorId: vendorId,
      consumerId: consumerId,
      eventDate: eventDate,
      guestCount: guestCount,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      vendor: vendor ?? this.vendor,
    );
  }
}

/// Payload used when creating a booking request (validated before insert).
class BookingRequestPayload {
  const BookingRequestPayload({
    required this.vendorId,
    required this.consumerId,
    required this.eventDate,
    this.guestCount,
    this.message = '',
  });

  final String vendorId;
  final String consumerId;
  final DateTime eventDate;
  final int? guestCount;
  final String message;

  Map<String, dynamic> toJson() => {
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'event_date': eventDate.toIso8601String().split('T').first,
        'guest_count': guestCount,
        'message': message,
        'status': BookingStatus.pending.name,
      };

  /// Returns null if valid, otherwise an error key.
  String? validate() {
    if (vendorId.isEmpty) return 'vendor_required';
    if (consumerId.isEmpty) return 'consumer_required';
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (eventDate.isBefore(startOfToday)) return 'event_date_past';
    if (guestCount != null && guestCount! < 1) return 'guest_count_invalid';
    if (message.length > 2000) return 'message_too_long';
    return null;
  }
}
