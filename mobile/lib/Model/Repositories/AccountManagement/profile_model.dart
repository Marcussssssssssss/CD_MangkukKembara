/// Represents a tourist profile in MangkukKembara.
/// Maps to the `profiles` table in Supabase.
class ProfileModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? country;
  final String? city;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isActive;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.country,
    this.city,
    this.dateOfBirth,
    this.gender,
    this.isActive = true,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['profile_id'] as String,
    displayName: json['display_name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    country: json['country_code'] as String?,
    city: json['city'] as String?,
    dateOfBirth: json['date_of_birth'] == null
        ? null
        : DateTime.parse(json['date_of_birth'] as String),
    gender: json['gender'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toUpdateJson() => {
    'display_name': displayName.trim(),
    'avatar_url': avatarUrl,
    'country_code': country?.trim().toUpperCase(),
    'city': city?.trim(),
    'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
    'gender': gender?.toLowerCase(),
  };

  /// Calculated age from date of birth.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  ProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? country,
    String? city,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    return ProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      city: city ?? this.city,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'ProfileModel(id: $id, displayName: $displayName)';
}
