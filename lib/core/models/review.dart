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
    final profile = json['profiles'] ?? json['profile_public'];
    if (profile is Map) {
      final map = Map<String, dynamic>.from(profile);
      name = map['full_name'] as String?;
    }
    name ??= json['consumer_name'] as String?;

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
}

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

  Map<String, dynamic> toJson() => {
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'booking_request_id': bookingRequestId,
        'rating': rating,
        'comment': comment,
      };

  /// Returns null if valid, otherwise an error key.
  String? validate() {
    if (vendorId.isEmpty) return 'vendor_required';
    if (consumerId.isEmpty) return 'consumer_required';
    if (bookingRequestId.isEmpty) return 'booking_required';
    if (rating < 1 || rating > 5) return 'rating_invalid';
    if (comment.length > 2000) return 'comment_too_long';
    return null;
  }
}

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

  DateTime get day => DateTime(date.year, date.month, date.day);

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isDateBooked(Iterable<AvailabilitySlot> slots, DateTime date) {
    final day = dateOnly(date);
    return slots.any((s) => s.isBooked && s.day == day);
  }

  static Set<DateTime> bookedDays(Iterable<AvailabilitySlot> slots) {
    return slots.where((s) => s.isBooked).map((s) => s.day).toSet();
  }

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? 'booked',
    );
  }
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
