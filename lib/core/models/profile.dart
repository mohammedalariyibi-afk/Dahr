import 'enums.dart';

class Profile {
  const Profile({
    required this.id,
    this.phone,
    this.fullName,
    required this.role,
    this.city,
    this.weddingDate,
    this.locale = 'ar',
    this.createdAt,
  });

  final String id;
  final String? phone;
  final String? fullName;
  final UserRole role;
  final CityCode? city;
  final DateTime? weddingDate;
  final String locale;
  final DateTime? createdAt;

  bool get isProfileComplete =>
      fullName != null &&
      fullName!.trim().isNotEmpty &&
      city != null;

  bool get needsRoleSelection =>
      fullName == null || fullName!.trim().isEmpty;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      city: CityCode.tryParse(json['city'] as String?),
      weddingDate: json['wedding_date'] != null
          ? DateTime.tryParse(json['wedding_date'] as String)
          : null,
      locale: (json['locale'] as String?) ?? 'ar',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'full_name': fullName,
        'role': role.name,
        'city': city?.name,
        'wedding_date': weddingDate?.toIso8601String().split('T').first,
        'locale': locale,
      };

  Profile copyWith({
    String? phone,
    String? fullName,
    UserRole? role,
    CityCode? city,
    DateTime? weddingDate,
    String? locale,
  }) {
    return Profile(
      id: id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      city: city ?? this.city,
      weddingDate: weddingDate ?? this.weddingDate,
      locale: locale ?? this.locale,
      createdAt: createdAt,
    );
  }
}
