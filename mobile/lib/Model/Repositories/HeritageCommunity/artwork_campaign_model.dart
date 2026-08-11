/// Artwork campaign model. Submission and voting share one active period.
class ArtworkCampaignModel {
  final String id;
  final String title;
  final String description;
  final String status; // 'active' | 'completed'
  final DateTime? submissionDeadline;
  final DateTime? submissionStartDate;
  final int categoryCount;

  const ArtworkCampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.submissionDeadline,
    this.submissionStartDate,
    this.categoryCount = 0,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  bool get isWithinCampaignPeriod {
    final start = submissionStartDate;
    final end = submissionDeadline;
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return !now.isBefore(start) && !now.isAfter(end);
  }

  bool get canSubmit => isActive && isWithinCampaignPeriod;
  bool get canVote => isActive && isWithinCampaignPeriod;

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Submissions & Voting Open';
      case 'completed':
        return 'Campaign Ended';
      default:
        return 'Unknown';
    }
  }

  factory ArtworkCampaignModel.fromJson(Map<String, dynamic> json) {
    return ArtworkCampaignModel(
      id: json['artwork_campaign_id'] as String,
      title: json['campaign_title'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      submissionDeadline: DateTime.tryParse(
        json['submission_end_at'] as String? ?? '',
      ),
      submissionStartDate: DateTime.tryParse(
        json['submission_start_at'] as String? ?? '',
      ),
      categoryCount:
          (json['artwork_campaign_categories'] as List<dynamic>? ?? const [])
              .length,
    );
  }
}

/// An individual category within a campaign (usually one per state).
class ArtworkCampaignCategoryModel {
  final String id;
  final String campaignId;
  final String categoryName;
  final String stateName;
  final int submissionCount;
  final int voteCount;

  const ArtworkCampaignCategoryModel({
    required this.id,
    required this.campaignId,
    required this.categoryName,
    required this.stateName,
    this.submissionCount = 0,
    this.voteCount = 0,
  });

  factory ArtworkCampaignCategoryModel.fromJson(Map<String, dynamic> json) {
    final state = json['states'] as Map<String, dynamic>?;
    final entries =
        (json['artwork_voting_entries'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>();
    return ArtworkCampaignCategoryModel(
      id: json['artwork_campaign_category_id'] as String,
      campaignId: json['artwork_campaign_id'] as String,
      categoryName: json['category_name'] as String,
      stateName: state?['state_name'] as String? ?? '',
      submissionCount:
          (json['artwork_submissions'] as List<dynamic>? ?? const []).length,
      voteCount: entries.fold<int>(
        0,
        (sum, row) => sum + ((row['vote_count'] as num?)?.toInt() ?? 0),
      ),
    );
  }
}

/// An artwork submission entry for a campaign category.
class ArtworkVotingEntryModel {
  final String id;
  final String categoryId;
  final String artworkTitle;
  final String designDescription;
  final String culturalInspiration;
  final String artistStatement;
  final String submitterName;
  final int voteCount;
  final int currentRank;
  final bool hasCurrentUserVoted;
  final bool isVotingOpen;
  final String artworkUrl;
  final DateTime? publishedAt;

  const ArtworkVotingEntryModel({
    required this.id,
    required this.categoryId,
    required this.artworkTitle,
    required this.designDescription,
    required this.culturalInspiration,
    required this.artistStatement,
    required this.submitterName,
    this.voteCount = 0,
    this.currentRank = 0,
    this.hasCurrentUserVoted = false,
    this.isVotingOpen = false,
    required this.artworkUrl,
    this.publishedAt,
  });

  ArtworkVotingEntryModel withRank(int rank) => ArtworkVotingEntryModel(
    id: id,
    categoryId: categoryId,
    artworkTitle: artworkTitle,
    designDescription: designDescription,
    culturalInspiration: culturalInspiration,
    artistStatement: artistStatement,
    submitterName: submitterName,
    voteCount: voteCount,
    currentRank: rank,
    hasCurrentUserVoted: hasCurrentUserVoted,
    isVotingOpen: isVotingOpen,
    artworkUrl: artworkUrl,
    publishedAt: publishedAt,
  );

  factory ArtworkVotingEntryModel.fromJson(
    Map<String, dynamic> json, {
    required int rank,
    required bool hasVoted,
    Map<String, dynamic>? submitter,
  }) {
    final submission =
        json['artwork_submissions'] as Map<String, dynamic>? ?? const {};
    final session =
        json['artwork_voting_sessions'] as Map<String, dynamic>? ?? const {};
    final votingStart = DateTime.tryParse(
      session['voting_start_at'] as String? ?? '',
    );
    final votingEnd = DateTime.tryParse(
      session['voting_end_at'] as String? ?? '',
    );
    final now = DateTime.now();
    final votingIsOpen =
        session['status'] == 'active' &&
        votingStart != null &&
        votingEnd != null &&
        !now.isBefore(votingStart) &&
        !now.isAfter(votingEnd);
    return ArtworkVotingEntryModel(
      id: json['artwork_voting_entry_id'] as String,
      categoryId: json['artwork_campaign_category_id'] as String,
      artworkTitle: submission['artwork_title'] as String? ?? '',
      designDescription: submission['design_description'] as String? ?? '',
      culturalInspiration: submission['cultural_inspiration'] as String? ?? '',
      artistStatement: submission['artist_statement'] as String? ?? '',
      submitterName:
          submitter?['display_name'] as String? ?? 'Artist unavailable',
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
      currentRank: rank,
      hasCurrentUserVoted: hasVoted,
      isVotingOpen: votingIsOpen,
      artworkUrl: submission['artwork_file_url'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }
}
