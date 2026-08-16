import 'package:flutter/material.dart';

import '../../Model/Repositories/HeritageCommunity/artwork_submission_model.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';

class MyArtworkSubmissionsViewModel extends ChangeNotifier {
  MyArtworkSubmissionsViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  final HeritageCommunityRepository _repo;
  List<ArtworkSubmissionModel> _submissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ArtworkSubmissionModel> get submissions => _submissions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _submissions = await _repo.fetchMyArtworkSubmissions(userId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
