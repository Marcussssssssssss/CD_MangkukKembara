/// Represents a heritage tiffin edition in MangkukKembara.
class HeritageTiffinModel {
  final String id;
  final String editionName;
  final String state;
  final String stateCode;
  final String summary;
  final String? coverImageUrl;
  final bool isActive;
  final String? artistId;
  final String? artworkId;

  const HeritageTiffinModel({
    required this.id,
    required this.editionName,
    required this.state,
    required this.stateCode,
    required this.summary,
    this.coverImageUrl,
    this.isActive = true,
    this.artistId,
    this.artworkId,
  });

  factory HeritageTiffinModel.fromJson(Map<String, dynamic> json) {
    final state = json['states'] as Map<String, dynamic>?;
    final artwork = json['artworks'] as Map<String, dynamic>?;
    return HeritageTiffinModel(
      id: json['heritage_tiffin_id'] as String,
      editionName: json['edition_name'] as String,
      state: state?['state_name'] as String? ?? '',
      stateCode: state?['state_code'] as String? ?? '',
      summary: json['description'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      isActive: json['status'] == 'active',
      artistId: artwork?['profile_id'] as String?,
      artworkId: json['artwork_id'] as String?,
    );
  }
}
