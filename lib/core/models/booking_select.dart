/// PostgREST `select` lists for `booking_requests`.
///
/// Couples may **read** commission columns so they can transfer the 10%
/// fee. They still must not write those columns. Inserts stay money-free.
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

  static const List<String> consumerReadColumns = [
    ...consumerColumns,
    ...commissionColumns,
  ];

  static const List<String> vendorColumns = [
    ...consumerColumns,
    ...commissionColumns,
  ];

  static const String vendorListingEmbed =
      'vendor_profiles(*, vendor_photos(*))';
  static const String reviewsEmbed = 'reviews(*)';

  /// Couple inbox / bookings list. Quote + 10% fee status are visible.
  static String get consumerList =>
      '${consumerReadColumns.join(', ')}, $vendorListingEmbed, $reviewsEmbed';

  /// Couple booking detail / review. Includes fee amount and status.
  static String get consumerById =>
      '${consumerReadColumns.join(', ')}, $reviewsEmbed';

  /// Return shape after a couple insert. No commission columns on write.
  static String get consumerInsert => consumerColumns.join(', ');

  /// Vendor inbox and dashboard. Fee status only — vendors do not pay.
  static String get vendor => vendorColumns.join(', ');

  static bool includesCommission(String select) {
    return commissionColumns.any(select.contains);
  }
}
