import '../security/booking_write.dart';
import 'commission.dart';
import 'enums.dart';
import 'review.dart';
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
    this.quotedAmountLyd,
    this.commissionRate = CommissionMath.defaultRate,
    this.commissionAmountLyd,
    this.commissionStatus,
    this.commissionPaidAt,
    this.createdAt,
    this.vendor,
    this.review,
    this.consumerName,
    this.consumerPhone,
  });

  final String id;
  final String vendorId;
  final String consumerId;
  final DateTime eventDate;
  final int? guestCount;
  final String message;
  final BookingStatus status;
  final double? quotedAmountLyd;
  final double commissionRate;
  final double? commissionAmountLyd;
  final CommissionStatus? commissionStatus;
  final DateTime? commissionPaidAt;
  final DateTime? createdAt;
  final VendorProfile? vendor;
  final Review? review;

  /// From `booking_party_contact` — vendor inbox only, never public Discover.
  final String? consumerName;
  final String? consumerPhone;

  bool get hasCoupleWhatsApp =>
      consumerPhone != null && consumerPhone!.trim().isNotEmpty;

  bool get hasQuote => quotedAmountLyd != null;
  bool get isCommissionUnpaid =>
      commissionStatus == CommissionStatus.unpaid;
  bool get showsCouplePlatformFee =>
      hasQuote &&
      commissionAmountLyd != null &&
      (status == BookingStatus.accepted || status == BookingStatus.completed);
  bool get canLeaveReview =>
      status == BookingStatus.completed && review == null;

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    VendorProfile? vendor;
    final vendorRaw = json['vendor_profiles'] ?? json['vendor'];
    if (vendorRaw is Map) {
      vendor = VendorProfile.fromJson(Map<String, dynamic>.from(vendorRaw));
    }

    Review? review;
    final reviewRaw = json['reviews'] ?? json['review'];
    if (reviewRaw is Map) {
      review = Review.fromJson(Map<String, dynamic>.from(reviewRaw));
    } else if (reviewRaw is List && reviewRaw.isNotEmpty) {
      final first = reviewRaw.first;
      if (first is Map<String, dynamic>) {
        review = Review.fromJson(first);
      } else if (first is Map) {
        review = Review.fromJson(Map<String, dynamic>.from(first));
      }
    }

    return BookingRequest(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      consumerId: json['consumer_id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      guestCount: CommissionMath.parseLyd(json['guest_count'])?.toInt(),
      message: (json['message'] as String?) ?? '',
      status: BookingStatus.fromString(json['status'] as String?),
      quotedAmountLyd: CommissionMath.parseLyd(json['quoted_amount_lyd']),
      commissionRate:
          CommissionMath.parseLyd(json['commission_rate']) ??
              CommissionMath.defaultRate,
      commissionAmountLyd:
          CommissionMath.parseLyd(json['commission_amount_lyd']),
      commissionStatus:
          CommissionStatus.tryParse(json['commission_status'] as String?),
      commissionPaidAt: json['commission_paid_at'] != null
          ? DateTime.tryParse(json['commission_paid_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      vendor: vendor,
      review: review,
    );
  }

  BookingRequest withConsumerContact({String? name, String? phone}) =>
      BookingRequest(
        id: id,
        vendorId: vendorId,
        consumerId: consumerId,
        eventDate: eventDate,
        guestCount: guestCount,
        message: message,
        status: status,
        quotedAmountLyd: quotedAmountLyd,
        commissionRate: commissionRate,
        commissionAmountLyd: commissionAmountLyd,
        commissionStatus: commissionStatus,
        commissionPaidAt: commissionPaidAt,
        createdAt: createdAt,
        vendor: vendor,
        review: review,
        consumerName: name,
        consumerPhone: phone,
      );

  Map<String, dynamic> toInsertJson() => BookingStatusWrite.consumerInsert({
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'event_date': eventDate.toIso8601String().split('T').first,
        'guest_count': guestCount,
        'message': message,
        'status': status.name,
      });

  BookingRequest copyWith({
    BookingStatus? status,
    double? quotedAmountLyd,
    double? commissionAmountLyd,
    CommissionStatus? commissionStatus,
    VendorProfile? vendor,
    Review? review,
    String? consumerName,
    String? consumerPhone,
  }) {
    return BookingRequest(
      id: id,
      vendorId: vendorId,
      consumerId: consumerId,
      eventDate: eventDate,
      guestCount: guestCount,
      message: message,
      status: status ?? this.status,
      quotedAmountLyd: quotedAmountLyd ?? this.quotedAmountLyd,
      commissionRate: commissionRate,
      commissionAmountLyd: commissionAmountLyd ?? this.commissionAmountLyd,
      commissionStatus: commissionStatus ?? this.commissionStatus,
      commissionPaidAt: commissionPaidAt,
      createdAt: createdAt,
      vendor: vendor ?? this.vendor,
      review: review ?? this.review,
      consumerName: consumerName ?? this.consumerName,
      consumerPhone: consumerPhone ?? this.consumerPhone,
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

  Map<String, dynamic> toJson() => BookingStatusWrite.consumerInsert({
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'event_date': AvailabilityCalendar.dateKey(eventDate),
        'guest_count': guestCount,
        'message': message,
        'status': BookingStatus.pending.name,
      });

  /// Returns null if valid, otherwise an error key.
  ///
  /// Pass [bookedDateKeys] (`yyyy-MM-dd`) so a couple cannot request a date
  /// the vendor already marked booked.
  String? validate({Iterable<String>? bookedDateKeys}) {
    if (vendorId.isEmpty) return 'vendor_required';
    if (consumerId.isEmpty) return 'consumer_required';
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (eventDate.isBefore(startOfToday)) return 'event_date_past';
    if (guestCount != null && (guestCount! < 1 || guestCount! > 10000)) {
      return 'guest_count_invalid';
    }
    if (message.length > 2000) return 'message_too_long';
    if (bookedDateKeys != null &&
        AvailabilityCalendar.isBookedDate(eventDate, bookedDateKeys)) {
      return BookingDateConflict.clientKey;
    }
    return null;
  }
}

/// Client validation key plus the live trigger exception
/// (`reject_booking_if_date_booked` raises `date_unavailable`).
abstract final class BookingDateConflict {
  static const clientKey = 'event_date_booked';
  static const dbException = 'date_unavailable';

  static bool matches(Object error) {
    final text = error is StateError ? error.message : error.toString();
    return text == clientKey ||
        text.contains(clientKey) ||
        text.contains(dbException) ||
        text.contains('date_has_accepted_booking');
  }
}

/// Vendor accept payload: a quote in LYD is required; commission is 10%.
class AcceptBookingPayload {
  const AcceptBookingPayload({
    required this.bookingId,
    required this.quotedAmountLyd,
  });

  final String bookingId;
  final double quotedAmountLyd;

  static const double commissionRate = CommissionMath.defaultRate;

  double get commissionAmountLyd =>
      CommissionMath.amountDue(quotedAmountLyd, rate: commissionRate);

  Map<String, dynamic> toRpcParams() => {
        'p_booking_id': bookingId,
        'p_quoted_amount_lyd': quotedAmountLyd,
      };

  /// Returns null if valid, otherwise an error key.
  String? validate() {
    if (bookingId.isEmpty) return 'booking_required';
    if (!quotedAmountLyd.isFinite || quotedAmountLyd <= 0) {
      return 'quoted_amount_required';
    }
    return null;
  }

  /// Direct status updates cannot mark a booking accepted — use this payload.
  static void assertNotBareAccept(BookingStatus status) {
    BookingStatusWrite.vendorDirectPatch(status);
  }

  /// Parses vendor input and validates. Null amount → `quoted_amount_required`.
  factory AcceptBookingPayload.fromInput({
    required String bookingId,
    required String quotedAmountRaw,
  }) {
    final parsed = CommissionMath.parseQuotedAmount(quotedAmountRaw);
    return AcceptBookingPayload(
      bookingId: bookingId,
      quotedAmountLyd: parsed ?? 0,
    );
  }
}
