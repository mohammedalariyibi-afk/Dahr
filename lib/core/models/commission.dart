/// 10% platform fee on an accepted booking quote (LYD).
///
/// The **couple** pays this amount to Dahr by online bank transfer.
/// The rest of the quote is settled with the vendor off-platform.
///
/// Matches Postgres `ROUND(quoted_amount_lyd * commission_rate, 2)` for
/// typical 2-decimal currency inputs (half away from zero).
abstract final class CommissionMath {
  static const double defaultRate = 0.10;

  /// Parses a quote typed by the vendor. A comma is a decimal if there is no
  /// `.`; otherwise commas are thousands separators.
  static double? parseQuotedAmount(String? raw) {
    if (raw == null) return null;
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(',') && !trimmed.contains('.')) {
      trimmed = trimmed.replaceAll(',', '.');
    } else {
      trimmed = trimmed.replaceAll(',', '');
    }
    return double.tryParse(trimmed);
  }

  static double? parseLyd(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Commission due in LYD. Throws [ArgumentError] if [quotedAmountLyd] is
  /// not a finite amount greater than 0.
  static double amountDue(
    num quotedAmountLyd, {
    num rate = defaultRate,
  }) {
    if (!_isValidQuote(quotedAmountLyd)) {
      throw ArgumentError.value(
        quotedAmountLyd,
        'quotedAmountLyd',
        'quoted amount must be greater than 0',
      );
    }
    if (!rate.isFinite || rate <= 0 || rate > 1) {
      throw ArgumentError.value(rate, 'rate', 'rate must be in (0, 1]');
    }
    final quotedCents = _lydToCents(quotedAmountLyd);
    final rateBasisPoints = (rate * 10000).round(); // 0.10 → 1000
    final raw = quotedCents * rateBasisPoints;
    final commissionCents = _roundHalfAwayFromZeroDiv(raw, 10000);
    return commissionCents / 100.0;
  }

  static bool _isValidQuote(num value) => value.isFinite && value > 0;

  /// Converts a LYD amount to integer cents using a 2-decimal string so
  /// `10.05` does not become `1004` from binary float noise.
  static int _lydToCents(num lyd) {
    final normalized = lyd.toStringAsFixed(2);
    final negative = normalized.startsWith('-');
    final digits = normalized.replaceAll('.', '').replaceAll('-', '');
    final cents = int.parse(digits);
    return negative ? -cents : cents;
  }

  /// Integer division with round-half-away-from-zero (Postgres NUMERIC ROUND).
  static int _roundHalfAwayFromZeroDiv(int numerator, int denominator) {
    if (denominator <= 0) {
      throw ArgumentError.value(denominator, 'denominator');
    }
    final absNum = numerator.abs();
    final rounded = (absNum + denominator ~/ 2) ~/ denominator;
    return numerator.isNegative ? -rounded : rounded;
  }

  /// Display helper used by the accept dialog (same rounding as [amountDue]).
  static String formatPreview(num quotedAmountLyd, {num rate = defaultRate}) {
    return amountDue(quotedAmountLyd, rate: rate).toStringAsFixed(2);
  }
}
