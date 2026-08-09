import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../../Model/Repositories/HeritageCommunity/voting_entry_model.dart';

/// View model for category artwork list, detail, voting and rankings.
class ArtworkVotingViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  ArtworkVotingViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  List<ArtworkVotingEntryModel> _entries = [];
  ArtworkVotingEntryModel? _selectedEntry;
  List<VotingEntryModel> _rankings = [];
  List<ArtworkCampaignCategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isVoting = false;
  bool _voteSuccess = false;
  String? _errorMessage;
  String _sort = 'Most Voted';

  List<ArtworkVotingEntryModel> get entries => _entries;
  ArtworkVotingEntryModel? get selectedEntry => _selectedEntry;
  List<VotingEntryModel> get rankings => _rankings;
  List<ArtworkCampaignCategoryModel> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isVoting => _isVoting;
  bool get voteSuccess => _voteSuccess;
  String? get errorMessage => _errorMessage;
  String get sort => _sort;

  Future<void> loadCampaign(
    String campaignId, {
    bool showLoading = true,
    bool loadArtworkEntries = true,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _categories = await _repo.fetchCategoriesByCampaign(campaignId);
      _selectedCategoryId = _categories.isEmpty ? null : _categories.first.id;
      _entries = _selectedCategoryId == null || !loadArtworkEntries
          ? []
          : await _repo.fetchVotingEntries(_selectedCategoryId!, sort: _sort);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    _entries = [];
    notifyListeners();
  }

  Future<void> loadEntries(String categoryId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _selectedCategoryId = categoryId;
    _isLoading = true;
    _hasError = false;
    if (showLoading) notifyListeners();
    try {
      _entries = await _repo.fetchVotingEntries(categoryId, sort: _sort);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isVoting = true;
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
    if (_selectedCategoryId != null) loadEntries(_selectedCategoryId!);
  }

  void clearVoteSuccess() {
    _voteSuccess = false;
    notifyListeners();
  }
}
