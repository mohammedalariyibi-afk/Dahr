/// Operator bank details for the couple → Dahr 10% transfer.
///
/// Empty strings mean unset. Never invent a Libyan account number.
class PlatformBankDetails {
  const PlatformBankDetails({
    this.bankName = '',
    this.accountHolder = '',
    this.accountNumber = '',
    this.bankNote = '',
  });

  static const String table = 'platform_settings';
  static const String singletonId = 'default';

  static const List<String> selectColumns = [
    'bank_name',
    'account_holder',
    'account_number',
    'bank_note',
  ];

  static const String select = 'bank_name, account_holder, account_number, bank_note';

  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String bankNote;

  bool get isConfigured =>
      bankName.trim().isNotEmpty &&
      accountHolder.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty;

  String get optionalNote => bankNote.trim();

  factory PlatformBankDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlatformBankDetails();
    return PlatformBankDetails(
      bankName: (json['bank_name'] as String?)?.trim() ?? '',
      accountHolder: (json['account_holder'] as String?)?.trim() ?? '',
      accountNumber: (json['account_number'] as String?)?.trim() ?? '',
      bankNote: (json['bank_note'] as String?)?.trim() ?? '',
    );
  }

  /// Fail-closed empty config when the settings row is missing.
  static const PlatformBankDetails unset = PlatformBankDetails();
}
