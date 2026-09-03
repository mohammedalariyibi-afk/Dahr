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
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
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
        if (p is Map<String, dynamic>) {
          photos.add(VendorPhoto.fromJson(p));
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
      priceMin: json['price_min'] as num?,
      priceMax: json['price_max'] as num?,
      whatsappNumber: json['whatsapp_number'] as String?,
      services: services,
      isVerified: json['is_verified'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      photos: photos,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
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
