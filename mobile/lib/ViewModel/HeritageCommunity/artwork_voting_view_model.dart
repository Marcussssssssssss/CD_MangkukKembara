import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../../Model/Repositories/HeritageCommunity/voting_entry_model.dart';

/// View model for campaign artwork, detail, voting and rankings.
class ArtworkVotingViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  ArtworkVotingViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  List<ArtworkVotingEntryModel> _entries = [];
  ArtworkVotingEntryModel? _selectedEntry;
  List<VotingEntryModel> _rankings = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _isVoting = false;
  bool _voteSuccess = false;
  String? _errorMessage;
  String _sort = 'Most Voted';
  String? _campaignId;
  int _campaignLoadVersion = 0;

  List<ArtworkVotingEntryModel> get entries => _entries;
  ArtworkVotingEntryModel? get selectedEntry => _selectedEntry;
  List<VotingEntryModel> get rankings => _rankings;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isVoting => _isVoting;
  bool get voteSuccess => _voteSuccess;
  String? get errorMessage => _errorMessage;
  String get sort => _sort;
  bool get hasVotedInCurrentCampaign =>
      _entries.any((entry) => entry.hasCurrentUserVoted);

  Future<void> loadCampaign(
    String campaignId, {
    bool showLoading = true,
  }) async {
    if (_isLoading && _campaignId == campaignId) return;
    final loadVersion = ++_campaignLoadVersion;
    final campaignChanged = _campaignId != campaignId;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (campaignChanged) {
      _campaignId = campaignId;
      _entries = [];
    }
    if (showLoading) notifyListeners();
    try {
      final entries = await _repo.fetchVotingEntries(campaignId, sort: _sort);
      if (loadVersion != _campaignLoadVersion) return;
      _entries = entries;
      _sortEntries();
    } catch (error) {
      if (loadVersion != _campaignLoadVersion) return;
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      if (loadVersion == _campaignLoadVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadEntry(String entryId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    if (showLoading) notifyListeners();
    try {
      _selectedEntry = await _repo.fetchVotingEntryById(entryId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRankings(
    String campaignId, {
    bool showLoading = true,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    if (showLoading) notifyListeners();
    try {
      _rankings = await _repo.fetchRankings(campaignId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> vote(String entryId, String userId) async {
    if (_isVoting) return false;
    _isVoting = true;
    _voteSuccess = false;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.submitVote(entryId, userId);
      _voteSuccess = true;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _isVoting = false;
      notifyListeners();
    }
  }

  void setSort(String s) {
    _sort = s;
    _sortEntries();
    notifyListeners();
  }

  void _sortEntries() {
    if (_sort == 'New') {
      _entries.sort(
        (a, b) => (b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    } else {
      _entries.sort((a, b) => b.voteCount.compareTo(a.voteCount));
    }
    _entries = [
      for (var index = 0; index < _entries.length; index++)
        _entries[index].withRank(index + 1),
    ];
  }

  Future<void> refreshCampaign({bool showLoading = false}) async {
    final campaignId = _campaignId;
    if (campaignId != null) {
      await loadCampaign(campaignId, showLoading: showLoading);
    }
  }

  void clearVoteSuccess() {
    _voteSuccess = false;
    notifyListeners();
  }
}
