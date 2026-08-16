/// Artwork submission by a user for a campaign.
class ArtworkSubmissionModel {
  final String id;
  final String campaignId;
  final String userId;
  final String artworkTitle;
  final String? artworkFileUrl;
  final Map<String, String> photoUrls;
  final String? designDescription;
  final String? layer1Meaning;
  final String? layer2Meaning;
  final String? layer3Meaning;
  final String? reviewStatus; // 'pending' | 'approved' | 'rejected'
  final DateTime submittedAt;
  final String campaignName;

  const ArtworkSubmissionModel({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.artworkTitle,
    this.artworkFileUrl,
    this.photoUrls = const {},
    this.designDescription,
    this.layer1Meaning,
    this.layer2Meaning,
    this.layer3Meaning,
    this.reviewStatus = 'pending',
    required this.submittedAt,
    required this.campaignName,
  });

  String get reviewStatusLabel {
    switch (reviewStatus) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  factory ArtworkSubmissionModel.fromJson(
    Map<String, dynamic> json, {
    required String campaignName,
  }) {
    final photos = (json['artwork_submission_photos'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    return ArtworkSubmissionModel(
      id: json['artwork_submission_id'] as String,
      campaignId: json['artwork_campaign_id'] as String,
      userId: json['profile_id'] as String,
      artworkTitle: json['artwork_title'] as String,
      artworkFileUrl: json['artwork_file_url'] as String?,
      photoUrls: {
        for (final photo in photos)
          if (photo['view_type'] is String && photo['photo_url'] is String)
            photo['view_type'] as String: photo['photo_url'] as String,
      },
      designDescription: json['design_description'] as String?,
      layer1Meaning: json['layer_1_meaning'] as String?,
      layer2Meaning: json['layer_2_meaning'] as String?,
      layer3Meaning: json['layer_3_meaning'] as String?,
      reviewStatus: switch (json['review_status']) {
        final value => value as String?,
      },
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      campaignName: campaignName,
    );
  }
}
