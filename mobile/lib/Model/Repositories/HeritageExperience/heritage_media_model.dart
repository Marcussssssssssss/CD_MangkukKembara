/// Heritage media (video or image) linked to a tiffin.
class HeritageMediaModel {
  final String id;
  final String tiffinId;
  final String mediaType; // 'video' | 'image'
  final String title;
  final String? caption;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;

  const HeritageMediaModel({
    required this.id,
    required this.tiffinId,
    required this.mediaType,
    required this.title,
    this.caption,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  bool get isVideo => mediaType == 'video';

  String? get durationLabel {
    if (durationSeconds == null) return null;
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory HeritageMediaModel.fromJson(Map<String, dynamic> json) =>
      HeritageMediaModel(
        id: json['heritage_media_id'] as String,
        tiffinId: json['heritage_tiffin_id'] as String,
        mediaType: json['media_type'] as String,
        title: json['title'] as String,
        caption: json['caption'] as String?,
        mediaUrl: json['media_url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      );
}
