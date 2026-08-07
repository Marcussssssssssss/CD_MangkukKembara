/// Artwork submission by a user for a campaign category.
class ArtworkSubmissionModel {
  final String id;
  final String categoryId;
  final String userId;
  final String artworkTitle;
  final String? artworkFileUrl;
  final String? designDescription;
  final String? reviewStatus; // 'pending' | 'approved' | 'rejected'
  final DateTime submittedAt;
  final String campaignName;
  final String categoryName;

  const ArtworkSubmissionModel({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.artworkTitle,
    this.artworkFileUrl,
    this.designDescription,
    this.reviewStatus = 'pending',
    required this.submittedAt,
    required this.campaignName,
    required this.categoryName,
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
    required String categoryName,
  }) => ArtworkSubmissionModel(
    id: json['artwork_submission_id'] as String,
    categoryId: json['artwork_campaign_category_id'] as String,
    userId: json['profile_id'] as String,
    artworkTitle: json['artwork_title'] as String,
    artworkFileUrl: json['artwork_file_url'] as String?,
    designDescription: json['design_description'] as String?,
    reviewStatus: switch (json['review_status']) {
      final value => value as String?,
    },
    submittedAt: DateTime.parse(json['submitted_at'] as String),
    campaignName: campaignName,
    categoryName: categoryName,
  );
}
