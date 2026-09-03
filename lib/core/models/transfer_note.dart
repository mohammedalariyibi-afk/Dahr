class CommissionTransferNote {
  const CommissionTransferNote({
    required this.id,
    required this.bookingId,
    required this.consumerId,
    required this.referenceNote,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final String consumerId;
  final String referenceNote;
  final DateTime? createdAt;

  factory CommissionTransferNote.fromJson(Map<String, dynamic> json) {
    return CommissionTransferNote(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      consumerId: json['consumer_id'] as String,
      referenceNote: (json['reference_note'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
