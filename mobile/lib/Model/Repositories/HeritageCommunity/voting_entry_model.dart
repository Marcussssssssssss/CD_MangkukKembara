/// Voting entry used in rankings view.
class VotingEntryModel {
  final String id;
  final String artworkTitle;
  final String submitterName;
  final int rank;
  final int voteCount;
  final bool isWinner;
  final String? artworkUrl;

  const VotingEntryModel({
    required this.id,
    required this.artworkTitle,
    required this.submitterName,
    required this.rank,
    required this.voteCount,
    this.isWinner = false,
    this.artworkUrl,
  });
}
