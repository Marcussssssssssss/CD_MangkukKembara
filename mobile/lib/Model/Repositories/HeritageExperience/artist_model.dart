/// Public creator profile associated with a heritage artwork.
class ArtistModel {
  final String id;
  final String fullName;
  final String? stageName;
  final String biography;
  final String? websiteUrl;
  final String? photoUrl;

  const ArtistModel({
    required this.id,
    required this.fullName,
    this.stageName,
    required this.biography,
    this.websiteUrl,
    this.photoUrl,
  });

  String get displayName => stageName ?? fullName;

  factory ArtistModel.fromJson(Map<String, dynamic> json) => ArtistModel(
    id: json['profile_id'] as String,
    fullName: json['display_name'] as String,
    biography: json['biography'] as String? ?? '',
    websiteUrl: json['website_url'] as String?,
    photoUrl: json['avatar_url'] as String?,
  );
}
