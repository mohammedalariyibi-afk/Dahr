import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/routing/auth_redirect.dart';
import '../../../core/security/safe_user_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_form_validators.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.channel,
    required this.destination,
    this.returnTo,
  });

  final String channel;
  final String destination;
  final String? returnTo;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isEmail => widget.channel == 'email';

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    if (!_isEmail || widget.destination.trim().isEmpty) {
      setState(() => _error = l10n.errorGeneric);
      return;
    }
    final err = AuthFormValidators.validateOtp(_otpCtrl.text);
    if (err != null) {
      setState(() => _error = l10n.invalidOtp);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      await auth.verifyEmailOtp(
        email: widget.destination,
        token: _otpCtrl.text.trim(),
      );
      await auth.refreshProfile();
      if (!mounted) return;
      context.go(
        resolvePostOtpLocation(
          status: ref.read(authProvider).status,
          returnTo: widget.returnTo,
        ),
      );
    } catch (e) {
      setState(() => _error = SafeUserError.of(l10n, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_isEmail || widget.destination.trim().isEmpty) return;
    try {
      await ref.read(authProvider.notifier).signInWithEmail(widget.destination);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = SafeUserError.of(AppLocalizations.of(context), e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.otpSubtitle),
            const SizedBox(height: 8),
            Text(
              widget.destination,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: InputDecoration(
                labelText: l10n.otpLabel,
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: Text(l10n.verifyOtp),
            ),
            TextButton(
              onPressed: _resend,
              child: Text(l10n.resendOtp),
            ),
          ],
        ),
      ),
    );
  }
}
