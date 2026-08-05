import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';

/// View model for the Artwork Campaign Home view.
class ArtworkCampaignViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  ArtworkCampaignViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  List<ArtworkCampaignModel> _campaigns = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<ArtworkCampaignModel> get campaigns => _campaigns;
  List<ArtworkCampaignModel> get openSubmissionCampaigns =>
      _campaigns.where((c) => c.isOpenSubmission).toList();
  List<ArtworkCampaignModel> get votingCampaigns =>
      _campaigns.where((c) => c.isVoting).toList();
  List<ArtworkCampaignModel> get completedCampaigns =>
      _campaigns.where((c) => c.isCompleted).toList();
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && !_hasError && _campaigns.isEmpty;

  Future<void> loadCampaigns({bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _campaigns = await _repo.fetchCampaigns();
    } catch (error, stackTrace) {
      debugPrint('Artwork campaign load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _hasError = true;
      _errorMessage =
          'Artwork campaigns could not be loaded. ${error.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => loadCampaigns();
}
