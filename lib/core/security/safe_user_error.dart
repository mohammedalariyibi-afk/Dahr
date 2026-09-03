import '../models/booking.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps known validation keys to copy. Everything else is a generic message
/// so PostgREST / Auth exceptions never land on screen or in a snackbar.
abstract final class SafeUserError {
  static const knownKeys = {
    'role_not_assignable',
    'write_rejected',
    'not_vendor',
    'event_date_booked',
    'event_date_past',
    'vendor_required',
    'consumer_required',
    'review_not_completed',
    'already_reviewed',
    'quoted_amount_required',
    'date_has_accepted_booking',
    'vendor_not_approved',
    'booking_must_be_pending',
    'guest_count_invalid',
    'profile_required',
    'business_name_required',
    'description_required',
    'whatsapp_required',
    'whatsapp_invalid',
    'price_range_required',
    'price_range_invalid',
    'transfer_note_invalid',
  };

  static String of(AppLocalizations l10n, Object error) {
    if (BookingDateConflict.matches(error)) {
      return l10n.bookingDateBookedError;
    }
    if (error is StateError) {
      return fromKey(l10n, error.message);
    }
    return l10n.errorGeneric;
  }

  static String fromKey(AppLocalizations l10n, String? key) {
    switch (key) {
      case 'event_date_booked':
      case 'date_has_accepted_booking':
        return l10n.bookingDateBookedError;
      case 'event_date_past':
      case 'vendor_required':
      case 'consumer_required':
      case 'profile_required':
        return l10n.requiredField;
      case 'review_not_completed':
        return l10n.reviewNotCompleted;
      case 'already_reviewed':
        return l10n.alreadyReviewed;
      case 'quoted_amount_required':
        return l10n.quotedAmountRequired;
      case 'business_name_required':
        return l10n.businessNameRequired;
      case 'description_required':
        return l10n.descriptionRequired;
      case 'whatsapp_required':
        return l10n.whatsappRequired;
      case 'whatsapp_invalid':
        return l10n.invalidWhatsapp;
      case 'price_range_required':
        return l10n.priceRangeRequired;
      case 'price_range_invalid':
        return l10n.priceRangeInvalid;
      case 'role_not_assignable':
        return l10n.roleNotAssignable;
      case 'transfer_note_invalid':
        return l10n.transferNoteRequired;
      case 'write_rejected':
      case 'not_vendor':
        return l10n.errorGeneric;
      default:
        return l10n.errorGeneric;
    }
  }

  /// True when [message] looks like a library/API exception rather than copy.
  static bool looksInternal(String? message) {
    if (message == null || message.trim().isEmpty) return true;
    if (message.length > 180) return true;
    final lower = message.toLowerCase();
    const needles = [
      'exception',
      'error:',
      'postgrest',
      'pgrst',
      'supabase',
      'jwt',
      'token',
      'stack',
      'eyj',
      'access_token',
      'refresh_token',
      'postgres',
      'permission denied',
      'row-level',
      'rls',
      'authapi',
      'socket',
      'http',
      '{',
      '}',
    ];
    return needles.any(lower.contains);
  }

  static String displayMessage(AppLocalizations l10n, String? message) {
    if (message == null || message.trim().isEmpty || looksInternal(message)) {
      return l10n.errorGeneric;
    }
    return message;
  }
}
