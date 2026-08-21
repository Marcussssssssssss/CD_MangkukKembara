/// Artwork campaign model. Submission and voting share one active period.
class ArtworkCampaignModel {
  final String id;
  final String title;
  final String description;
  final String status; // 'active' | 'completed'
  final String stateId;
  final String stateName;
  final DateTime? submissionDeadline;
  final DateTime? submissionStartDate;

  const ArtworkCampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.stateId = '',
    this.stateName = '',
    this.submissionDeadline,
    this.submissionStartDate,
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
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Campaign Ended';
      default:
        return 'Unknown';
    }
  }

  factory ArtworkCampaignModel.fromJson(Map<String, dynamic> json) {
    final state = json['states'] as Map<String, dynamic>?;
    return ArtworkCampaignModel(
      id: json['artwork_campaign_id'] as String,
      title: json['campaign_title'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      stateId: json['state_id'] as String? ?? '',
      stateName: state?['state_name'] as String? ?? '',
      submissionDeadline: DateTime.tryParse(
        json['submission_end_at'] as String? ?? '',
      ),
      submissionStartDate: DateTime.tryParse(
        json['submission_start_at'] as String? ?? '',
      ),
    );
  }
}

/// An artwork entry published in a campaign voting session.
class ArtworkVotingEntryModel {
  final String id;
  final String campaignId;
  final String votingSessionId;
  final String artworkTitle;
  final String designDescription;
  final String culturalInspiration;
  final String layer1Meaning;
  final String layer2Meaning;
  final String layer3Meaning;
  final String submitterName;
  final int voteCount;
  final int currentRank;
  final bool hasCurrentUserVoted;
  final bool isVotingOpen;
  final String artworkUrl;
  final String layer1Flat360Url;
  final String layer2Flat360Url;
  final String layer3Flat360Url;
  final DateTime? publishedAt;

  const ArtworkVotingEntryModel({
    required this.id,
    required this.campaignId,
    required this.votingSessionId,
    required this.artworkTitle,
    required this.designDescription,
    required this.culturalInspiration,
    required this.layer1Meaning,
    required this.layer2Meaning,
    required this.layer3Meaning,
    required this.submitterName,
    this.voteCount = 0,
    this.currentRank = 0,
    this.hasCurrentUserVoted = false,
    this.isVotingOpen = false,
    required this.artworkUrl,
    this.layer1Flat360Url = '',
    this.layer2Flat360Url = '',
    this.layer3Flat360Url = '',
    this.publishedAt,
  });

  ArtworkVotingEntryModel withRank(int rank) => ArtworkVotingEntryModel(
    id: id,
    campaignId: campaignId,
    votingSessionId: votingSessionId,
    artworkTitle: artworkTitle,
    designDescription: designDescription,
    culturalInspiration: culturalInspiration,
    layer1Meaning: layer1Meaning,
    layer2Meaning: layer2Meaning,
    layer3Meaning: layer3Meaning,
    submitterName: submitterName,
    voteCount: voteCount,
    currentRank: rank,
    hasCurrentUserVoted: hasCurrentUserVoted,
    isVotingOpen: isVotingOpen,
    artworkUrl: artworkUrl,
    layer1Flat360Url: layer1Flat360Url,
    layer2Flat360Url: layer2Flat360Url,
    layer3Flat360Url: layer3Flat360Url,
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
    final photos =
        (submission['artwork_submission_photos'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>();
    final photoUrls = <String, String>{
      for (final photo in photos)
        if (photo['view_type'] is String && photo['photo_url'] is String)
          photo['view_type'] as String: photo['photo_url'] as String,
    };
    final artworkUrl = submission['artwork_file_url'] as String? ?? '';
    final now = DateTime.now();
    final votingIsOpen =
        session['status'] == 'active' &&
        votingStart != null &&
        votingEnd != null &&
        !now.isBefore(votingStart) &&
        !now.isAfter(votingEnd);
    return ArtworkVotingEntryModel(
      id: json['artwork_voting_entry_id'] as String,
      campaignId: session['artwork_campaign_id'] as String? ?? '',
      votingSessionId: json['artwork_voting_session_id'] as String,
      artworkTitle: submission['artwork_title'] as String? ?? '',
      designDescription: submission['design_description'] as String? ?? '',
      culturalInspiration: submission['cultural_inspiration'] as String? ?? '',
      layer1Meaning: submission['layer_1_meaning'] as String? ?? '',
      layer2Meaning: submission['layer_2_meaning'] as String? ?? '',
      layer3Meaning: submission['layer_3_meaning'] as String? ?? '',
      submitterName:
          submitter?['display_name'] as String? ?? 'Artist unavailable',
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
      currentRank: rank,
      hasCurrentUserVoted: hasVoted,
      isVotingOpen: votingIsOpen,
      artworkUrl: artworkUrl,
      layer1Flat360Url: photoUrls['layer_1_flat_360'] ?? artworkUrl,
      layer2Flat360Url: photoUrls['layer_2_flat_360'] ?? artworkUrl,
      layer3Flat360Url: photoUrls['layer_3_flat_360'] ?? artworkUrl,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }
}
