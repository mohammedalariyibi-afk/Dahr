/// PostgREST `select` lists for `booking_requests`.
///
/// Couples must not request commission columns. Vendors may.
abstract final class BookingSelect {
  static const List<String> consumerColumns = [
    'id',
    'vendor_id',
    'consumer_id',
    'event_date',
    'guest_count',
    'message',
    'status',
    'quoted_amount_lyd',
    'created_at',
  ];

  static const List<String> commissionColumns = [
    'commission_rate',
    'commission_amount_lyd',
    'commission_status',
    'commission_paid_at',
  ];

  static const List<String> vendorColumns = [
    ...consumerColumns,
    ...commissionColumns,
  ];

  static const String vendorListingEmbed =
      'vendor_profiles(*, vendor_photos(*))';
  static const String reviewsEmbed = 'reviews(*)';

  /// Couple inbox / bookings list. Quote is visible; commission is not.
  static String get consumerList =>
      '${consumerColumns.join(', ')}, $vendorListingEmbed, $reviewsEmbed';

  /// Couple review / booking-by-id. No commission columns.
  static String get consumerById =>
      '${consumerColumns.join(', ')}, $reviewsEmbed';

  /// Return shape after a couple insert.
  static String get consumerInsert => consumerColumns.join(', ');

  /// Vendor inbox and dashboard. Includes unpaid 10% columns.
  static String get vendor => vendorColumns.join(', ');

  static bool includesCommission(String select) {
    return commissionColumns.any(select.contains);
  }
}
