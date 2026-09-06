/// Client-side OTP resend cooldown and in-flight guard.
///
/// The verify screen used to fire [signInWithEmail] with no loading, no
/// success feedback, and no throttle — Resend was silent and spammable.
class OtpResendGate {
  OtpResendGate({
    this.cooldown = defaultCooldown,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const Duration defaultCooldown = Duration(seconds: 30);

  final Duration cooldown;
  final DateTime Function() _clock;

  DateTime? _availableAt;
  bool _inFlight = false;

  bool get inFlight => _inFlight;

  bool get isCoolingDown {
    final until = _availableAt;
    if (until == null) return false;
    return _clock().isBefore(until);
  }

  Duration get remaining {
    final until = _availableAt;
    if (until == null) return Duration.zero;
    final left = until.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// Ceil so a leftover 200ms still shows 1s, not 0s.
  int get remainingSeconds {
    final ms = remaining.inMilliseconds;
    if (ms <= 0) return 0;
    return (ms + 999) ~/ 1000;
  }

  bool get canResend => !_inFlight && !isCoolingDown;

  /// Start the cooldown (user just received a code from login or a resend).
  void armFromPriorSend() {
    _availableAt = _clock().add(cooldown);
  }

  /// Marks the request in-flight. Returns false when resend is blocked.
  bool begin() {
    if (!canResend) return false;
    _inFlight = true;
    return true;
  }

  void succeed() {
    _inFlight = false;
    armFromPriorSend();
  }

  /// Failed send does not start a cooldown so the user can retry.
  void fail() {
    _inFlight = false;
  }
}
