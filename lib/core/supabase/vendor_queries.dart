import '../models/models.dart';
import 'supabase_client.dart';

/// Columns a guest is allowed to read after
/// `20260905180100_hide_vendor_whatsapp_from_guests`. `select('*')` as anon
/// now fails because `whatsapp_number` is revoked.
const kVendorPublicSelect =
    'id,profile_id,business_name,category,city,description,price_min,price_max,services,is_verified,is_approved,view_count,created_at,vendor_photos(*)';

Future<List<VendorProfile>> attachVendorContact(
  List<VendorProfile> vendors,
) async {
  if (vendors.isEmpty) return vendors;
  if (DahrSupabase.client.auth.currentUser == null) return vendors;
  try {
    final rows = await DahrSupabase.client
        .from('vendor_contact')
        .select('id, whatsapp_number')
        .inFilter('id', vendors.map((v) => v.id).toList());
    final phones = <String, String>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id'] as String?;
      final wa = map['whatsapp_number'] as String?;
      if (id != null && wa != null && wa.isNotEmpty) {
        phones[id] = wa;
      }
    }
    return [
      for (final v in vendors) v.copyWith(whatsappNumber: phones[v.id]),
    ];
  } catch (_) {
    return vendors;
  }
}
