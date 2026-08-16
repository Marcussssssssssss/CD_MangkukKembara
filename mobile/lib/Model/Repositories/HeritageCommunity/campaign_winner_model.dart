/// Campaign winner record.
class CampaignWinnerModel {
  final String id;
  final String campaignId;
  final String campaignName;
  final String stateName;
  final String artworkTitle;
  final String winnerName;
  final String designDescription;
  final String culturalInspiration;
  final String layer1Meaning;
  final String layer2Meaning;
  final String layer3Meaning;
  final int finalVoteCount;
  final DateTime announcedAt;
  final String? artworkUrl;

  const CampaignWinnerModel({
    required this.id,
    required this.campaignId,
    required this.campaignName,
    required this.stateName,
    required this.artworkTitle,
    required this.winnerName,
    required this.designDescription,
    required this.culturalInspiration,
    required this.layer1Meaning,
    required this.layer2Meaning,
    required this.layer3Meaning,
    required this.finalVoteCount,
    required this.announcedAt,
    this.artworkUrl,
  });
}
