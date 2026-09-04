import '../constants/app_constants.dart';
import 'commission.dart';
import 'enums.dart';

class VendorPhoto {
  const VendorPhoto({
    required this.id,
    required this.vendorId,
    required this.storageUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String vendorId;
  final String storageUrl;
  final int sortOrder;

  factory VendorPhoto.fromJson(Map<String, dynamic> json) {
    return VendorPhoto(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      storageUrl: json['storage_url'] as String,
      sortOrder: CommissionMath.parseLyd(json['sort_order'])?.toInt() ?? 0,
    );
  }

  VendorPhoto copyWith({int? sortOrder, String? storageUrl}) {
    return VendorPhoto(
      id: id,
      vendorId: vendorId,
      storageUrl: storageUrl ?? this.storageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Storage helpers for the public `vendor-photos` bucket.
/// Object path is `{auth.uid}/{uuid}.jpg` so existing RLS matches.
abstract final class VendorPhotoStorage {
  static const String bucket = 'vendor-photos';
  static const String _publicMarker = '/object/public/vendor-photos/';

  static String objectPath(String userId, String fileId) =>
      '$userId/$fileId.jpg';

  /// Extracts `{userId}/{file}` from a public Storage URL.
  static String? objectPathFromPublicUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return null;
    final i = url.indexOf(_publicMarker);
    if (i < 0) return null;
    final rest = url.substring(i + _publicMarker.length).split('?').first;
    if (rest.isEmpty) return null;
    final path = Uri.decodeFull(rest);
    if (!isSafeObjectPath(path)) return null;
    return path;
  }

  static bool isSafeObjectPath(String path) {
    if (path.isEmpty || path.startsWith('/') || path.contains('..')) {
      return false;
    }
    final parts = path.split('/');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
  }

  static bool isOwnedObjectPath(String userId, String path) {
    if (userId.isEmpty || !isSafeObjectPath(path)) return false;
    return path.startsWith('$userId/');
  }

  /// Reorders [photos] and rewrites `sort_order` to 0..n-1.
  ///
  /// [newIndex] is the destination after the item is removed (Flutter
  /// `onReorderItem` semantics).
  static List<VendorPhoto> applyReorder(
    List<VendorPhoto> photos,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 || oldIndex >= photos.length) {
      return List<VendorPhoto>.of(photos);
    }
    var target = newIndex;
    if (target < 0) target = 0;
    if (target > photos.length - 1) target = photos.length - 1;
    final list = List<VendorPhoto>.of(photos);
    final item = list.removeAt(oldIndex);
    if (target > list.length) target = list.length;
    list.insert(target, item);
    return [
      for (var i = 0; i < list.length; i++) list[i].copyWith(sortOrder: i),
    ];
  }
}

/// Validated payload for creating or updating a vendor listing.
class VendorOnboardingPayload {
  const VendorOnboardingPayload({
    required this.profileId,
    required this.businessName,
    required this.category,
    required this.city,
    required this.description,
    required this.whatsappNumber,
    this.priceMin,
    this.priceMax,
    this.services = const [],
  });

  final String profileId;
  final String businessName;
  final VendorCategory category;
  final CityCode city;
  final String description;
  final String whatsappNumber;
  final double? priceMin;
  final double? priceMax;
  final List<String> services;

  factory VendorOnboardingPayload.fromInput({
    required String profileId,
    required String businessName,
    required VendorCategory category,
    required CityCode city,
    required String description,
    required String whatsappNumber,
    required String priceMinRaw,
    required String priceMaxRaw,
    String servicesRaw = '',
  }) {
    final services = servicesRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return VendorOnboardingPayload(
      profileId: profileId,
      businessName: businessName.trim(),
      category: category,
      city: city,
      description: description.trim(),
      whatsappNumber: whatsappNumber.trim(),
      priceMin: double.tryParse(priceMinRaw.trim()),
      priceMax: double.tryParse(priceMaxRaw.trim()),
      services: services,
    );
  }

  /// Returns null if valid, otherwise an error key.
  String? validate() {
    if (profileId.isEmpty) return 'profile_required';
    if (businessName.trim().isEmpty) return 'business_name_required';
    if (description.trim().isEmpty) return 'description_required';
    if (whatsappNumber.trim().isEmpty) return 'whatsapp_required';
    if (!AppConstants.isValidLibyaPhone(whatsappNumber)) {
      return 'whatsapp_invalid';
    }
    if (priceMin == null || priceMax == null) return 'price_range_required';
    if (!priceMin!.isFinite || !priceMax!.isFinite) {
      return 'price_range_required';
    }
    if (priceMin! <= 0 || priceMax! <= 0) return 'price_range_invalid';
    if (priceMin! > priceMax!) return 'price_range_invalid';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'business_name': businessName,
        'category': category.name,
        'city': city.name,
        'description': description,
        'price_min': priceMin,
        'price_max': priceMax,
        'whatsapp_number': AppConstants.toE164Libya(whatsappNumber),
        'services': services,
      };
}

class VendorProfile {
  const VendorProfile({
    required this.id,
    required this.profileId,
    required this.businessName,
    required this.category,
    required this.city,
    this.description = '',
    this.priceMin,
    this.priceMax,
    this.whatsappNumber,
    this.services = const [],
    this.isVerified = false,
    this.isApproved = false,
    this.viewCount = 0,
    this.createdAt,
    this.photos = const [],
    this.avgRating,
    this.reviewCount = 0,
  });

  final String id;
  final String profileId;
  final String businessName;
  final VendorCategory category;
  final CityCode city;
  final String description;
  final num? priceMin;
  final num? priceMax;
  final String? whatsappNumber;
  final List<String> services;
  final bool isVerified;
  final bool isApproved;
  final int viewCount;
  final DateTime? createdAt;
  final List<VendorPhoto> photos;
  final double? avgRating;
  final int reviewCount;

  String? get coverUrl =>
      photos.isNotEmpty ? photos.first.storageUrl : null;

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['vendor_photos'] ?? json['photos'];
    final photos = <VendorPhoto>[];
    if (photosRaw is List) {
      for (final p in photosRaw) {
        if (p is Map) {
          photos.add(VendorPhoto.fromJson(Map<String, dynamic>.from(p)));
        }
      }
      photos.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final servicesRaw = json['services'];
    final services = <String>[];
    if (servicesRaw is List) {
      for (final s in servicesRaw) {
        services.add(s.toString());
      }
    }

    return VendorProfile(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      businessName: json['business_name'] as String,
      category: VendorCategory.fromString(json['category'] as String?),
      city: CityCode.fromString(json['city'] as String?),
      description: (json['description'] as String?) ?? '',
      // NUMERIC columns: parsed like the booking money fields rather than
      // cast, so a quoted value cannot take down Discover.
      priceMin: CommissionMath.parseLyd(json['price_min']),
      priceMax: CommissionMath.parseLyd(json['price_max']),
      whatsappNumber: json['whatsapp_number'] as String?,
      services: services,
      isVerified: json['is_verified'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      viewCount: CommissionMath.parseLyd(json['view_count'])?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      photos: photos,
      avgRating: CommissionMath.parseLyd(json['avg_rating']),
      reviewCount: CommissionMath.parseLyd(json['review_count'])?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'profile_id': profileId,
        'business_name': businessName,
        'category': category.name,
        'city': city.name,
        'description': description,
        'price_min': priceMin,
        'price_max': priceMax,
        'whatsapp_number': whatsappNumber,
        'services': services,
      };

  Map<String, dynamic> toUpdateJson() => {
        'business_name': businessName,
        'category': category.name,
        'city': city.name,
        'description': description,
        'price_min': priceMin,
        'price_max': priceMax,
        'whatsapp_number': whatsappNumber,
        'services': services,
      };

  VendorProfile copyWith({
    String? businessName,
    VendorCategory? category,
    CityCode? city,
    String? description,
    num? priceMin,
    num? priceMax,
    String? whatsappNumber,
    List<String>? services,
    bool? isVerified,
    bool? isApproved,
    int? viewCount,
    List<VendorPhoto>? photos,
    double? avgRating,
    int? reviewCount,
  }) {
    return VendorProfile(
      id: id,
      profileId: profileId,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      city: city ?? this.city,
      description: description ?? this.description,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      services: services ?? this.services,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt,
      photos: photos ?? this.photos,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
