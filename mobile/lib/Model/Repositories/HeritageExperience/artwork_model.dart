/// Artwork associated with a heritage tiffin.
class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final String artworkMeaning;
  final String culturalInspiration;
  final String imageUrl;
  final String artistId;
  final String? sourceArtworkSubmissionId;

  const ArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.artworkMeaning,
    required this.culturalInspiration,
    required this.imageUrl,
    required this.artistId,
    this.sourceArtworkSubmissionId,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) => ArtworkModel(
    id: json['artwork_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    artworkMeaning: json['artwork_meaning'] as String? ?? '',
    culturalInspiration: json['cultural_inspiration'] as String? ?? '',
    imageUrl: json['image_url'] as String,
    artistId: json['profile_id'] as String,
    sourceArtworkSubmissionId: json['source_artwork_submission_id'] as String?,
  );
}
