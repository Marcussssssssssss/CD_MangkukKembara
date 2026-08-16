import 'package:flutter/material.dart';

import '../../Model/Repositories/HeritageCommunity/community_post_model.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';

class MyReviewsViewModel extends ChangeNotifier {
  MyReviewsViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  final HeritageCommunityRepository _repo;
  List<CommunityPostModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CommunityPostModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _reviews = await _repo.fetchMyPosts(userId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
