import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
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

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
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
      if (widget.channel == 'email') {
        await auth.verifyEmailOtp(
          email: widget.destination,
          token: _otpCtrl.text.trim(),
        );
      } else {
        await auth.verifyPhoneOtp(
          e164Phone: widget.destination,
          token: _otpCtrl.text.trim(),
        );
      }
      await auth.refreshProfile();
      if (!mounted) return;
      final status = ref.read(authProvider).status;
      final returnTo = _safeReturnPath(widget.returnTo);
      if (returnTo != null && status == AuthFlowStatus.authenticated) {
        context.go(returnTo);
      } else if (status == AuthFlowStatus.needsRole) {
        context.go('/auth/role');
      } else if (status == AuthFlowStatus.needsProfile) {
        context.go('/auth/profile-setup');
      } else {
        context.go('/discover');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final auth = ref.read(authProvider.notifier);
    if (widget.channel == 'email') {
      await auth.signInWithEmail(widget.destination);
    } else {
      await auth.signInWithPhone(widget.destination);
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

String? _safeReturnPath(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final decoded = Uri.decodeComponent(raw);
  if (!decoded.startsWith('/') || decoded.startsWith('//')) return null;
  return decoded;
}
