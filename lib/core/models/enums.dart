enum UserRole {
  consumer,
  vendor,
  admin;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.consumer,
    );
  }
}

enum VendorCategory {
  venues,
  photography,
  catering,
  dresses,
  beauty,
  music,
  cars,
  decor,
  other;

  static VendorCategory fromString(String? value) {
    return VendorCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VendorCategory.other,
    );
  }
}

enum CityCode {
  tripoli,
  benghazi;

  static CityCode? tryParse(String? value) {
    if (value == null) return null;
    for (final c in CityCode.values) {
      if (c.name == value) return c;
    }
    return null;
  }

  static CityCode fromString(String? value) {
    return tryParse(value) ?? CityCode.tripoli;
  }
}

enum BookingStatus {
  pending,
  accepted,
  declined,
  completed;

  static BookingStatus fromString(String? value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

enum AvailabilityStatus {
  available,
  booked;

  static AvailabilityStatus fromString(String? value) {
    return AvailabilityStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AvailabilityStatus.booked,
    );
  }
}

enum ReportTarget {
  vendor,
  review;

  static ReportTarget fromString(String? value) {
    return ReportTarget.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportTarget.vendor,
    );
  }
}

enum ReportStatus {
  open,
  dismissed,
  actioned;

  static ReportStatus fromString(String? value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.open,
    );
  }
}
