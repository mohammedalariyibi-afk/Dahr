import 'enums.dart';

class Review {
  const Review({
    required this.id,
    required this.vendorId,
    required this.consumerId,
    required this.bookingRequestId,
    required this.rating,
    this.comment = '',
    this.isHidden = false,
    this.createdAt,
    this.consumerName,
  });

  final String id;
  final String vendorId;
  final String consumerId;
  final String bookingRequestId;
  final int rating;
  final String comment;
  final bool isHidden;
  final DateTime? createdAt;
  final String? consumerName;

  factory Review.fromJson(Map<String, dynamic> json) {
    String? name;
    final profile = json['profiles'];
    if (profile is Map) {
      name = Map<String, dynamic>.from(profile)['full_name'] as String?;
    }

    return Review(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      consumerId: json['consumer_id'] as String,
      bookingRequestId: json['booking_request_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: (json['comment'] as String?) ?? '',
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      consumerName: name,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'booking_request_id': bookingRequestId,
        'rating': rating,
        'comment': comment,
      };

  bool get isVisibleToPublic => !isHidden;
}

/// Public vendor pages must not show hidden reviews.
List<Review> visibleReviews(Iterable<Review> reviews) =>
    reviews.where((r) => r.isVisibleToPublic).toList();

/// Couple review payload. The DB trigger also enforces completed bookings.
class ReviewPayload {
  const ReviewPayload({
    required this.vendorId,
    required this.consumerId,
    required this.bookingRequestId,
    required this.rating,
    this.comment = '',
  });

  final String vendorId;
  final String consumerId;
  final String bookingRequestId;
  final int rating;
  final String comment;

  /// Returns null if valid, otherwise an error key.
  String? validate({
    required BookingStatus bookingStatus,
    bool alreadyReviewed = false,
  }) {
    if (vendorId.isEmpty) return 'vendor_required';
    if (consumerId.isEmpty) return 'consumer_required';
    if (bookingRequestId.isEmpty) return 'booking_required';
    if (bookingStatus != BookingStatus.completed) {
      return 'review_not_completed';
    }
    if (alreadyReviewed) return 'already_reviewed';
    if (rating < 1 || rating > 5) return 'rating_invalid';
    if (comment.length > 2000) return 'comment_too_long';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'booking_request_id': bookingRequestId,
        'rating': rating,
        'comment': comment,
      };
}

/// True when the couple may open the leave-review screen.
bool canLeaveReview({
  required BookingStatus status,
  required bool alreadyReviewed,
}) =>
    status == BookingStatus.completed && !alreadyReviewed;

class Favorite {
  const Favorite({
    required this.id,
    required this.consumerId,
    required this.vendorId,
    this.createdAt,
  });

  final String id;
  final String consumerId;
  final String vendorId;
  final DateTime? createdAt;

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      consumerId: json['consumer_id'] as String,
      vendorId: json['vendor_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.vendorId,
    required this.date,
    required this.status,
  });

  final String id;
  final String vendorId;
  final DateTime date;
  final String status; // available | booked — use AvailabilityStatus in UI

  bool get isBooked =>
      AvailabilityStatus.fromString(status) == AvailabilityStatus.booked;

  AvailabilityStatus get statusEnum => AvailabilityStatus.fromString(status);

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? 'booked',
    );
  }
}

/// Pure calendar helpers (unit-tested). Vendor toggles booked/available;
/// couples only see [booked] dates when requesting.
abstract final class AvailabilityCalendar {
  static String dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static AvailabilityStatus toggle(AvailabilityStatus current) {
    return current == AvailabilityStatus.booked
        ? AvailabilityStatus.available
        : AvailabilityStatus.booked;
  }

  /// Next status when the vendor taps [date] on the calendar.
  static AvailabilityStatus nextStatusForDate({
    required DateTime date,
    required Iterable<AvailabilitySlot> slots,
  }) {
    AvailabilitySlot? match;
    for (final s in slots) {
      if (isSameDay(s.date, date)) {
        match = s;
        break;
      }
    }
    if (match == null) return AvailabilityStatus.booked;
    return toggle(match.statusEnum);
  }

  static Set<String> bookedDateKeys(Iterable<AvailabilitySlot> slots) {
    return {
      for (final s in slots)
        if (s.isBooked) dateKey(s.date),
    };
  }

  static bool isBookedDate(DateTime date, Iterable<String> bookedKeys) =>
      bookedKeys.contains(dateKey(date));

  static List<DateTime> upcomingBookedDates(
    Iterable<AvailabilitySlot> slots, {
    DateTime? from,
  }) {
    final start = from ?? DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final dates = <DateTime>[];
    for (final s in slots) {
      if (!s.isBooked) continue;
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      if (!d.isBefore(startDay)) dates.add(d);
    }
    dates.sort();
    return dates;
  }

  static Map<String, dynamic> upsertJson({
    required String vendorId,
    required DateTime date,
    required AvailabilityStatus status,
  }) =>
      {
        'vendor_id': vendorId,
        'date': dateKey(date),
        'status': status.name,
      };
}

class Report {
  const Report({
    required this.id,
    required this.reportedBy,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.status = 'open',
    this.createdAt,
  });

  final String id;
  final String reportedBy;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime? createdAt;

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reportedBy: json['reported_by'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'reported_by': reportedBy,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
      };
}
