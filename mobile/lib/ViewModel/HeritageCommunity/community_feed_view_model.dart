import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/community_post_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';

/// View model for the Heritage Community home and search views.
enum CommunityFeedState { initial, loading, content, empty, error }

class CommunityFeedViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  final TreasureMapRepository _treasureMapRepo;
  final String? vendorId;
  CommunityFeedViewModel({
    HeritageCommunityRepository? repo,
    TreasureMapRepository? treasureMapRepo,
    this.vendorId,
    double? initialVendorAverageRating,
  }) : _repo = repo ?? HeritageCommunityRepository(),
       _treasureMapRepo = treasureMapRepo ?? TreasureMapRepository(),
       _vendorAverageRating = initialVendorAverageRating ?? 0;

  List<CommunityPostModel> _posts = [];
  CommunityFeedState _state = CommunityFeedState.initial;
  String? _errorMessage;
  String _searchQuery = '';
  String _sort = 'Popular';
  int _loadRevision = 0;
  final Set<String> _likesInFlight = <String>{};
  double _vendorAverageRating;

  List<CommunityPostModel> get posts => _posts;
  CommunityFeedState get state => _state;
  bool get isLoading => _state == CommunityFeedState.loading;
  bool get hasError => _state == CommunityFeedState.error;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get sort => _sort;
  bool get isEmpty => _state == CommunityFeedState.empty;
  double get vendorAverageRating => _vendorAverageRating;
  bool isTogglingLike(String postId) => _likesInFlight.contains(postId);

  void updatePost(CommunityPostModel updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index == -1) return;
    _posts[index] = updatedPost;
    notifyListeners();
  }

  Future<void> loadPosts({bool showLoading = true}) async {
    _loadRevision++;
    if (isLoading) return;
    final requestedRevision = _loadRevision;
    _state = CommunityFeedState.loading;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _posts = await _repo.fetchPosts(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        sort: _sort,
        vendorId: vendorId,
      );
      if (vendorId != null) {
        final summary = await _treasureMapRepo.fetchVendorRatingSummary(
          vendorId!,
        );
        _vendorAverageRating = summary.averageRating;
      }
      _state = _posts.isEmpty
          ? CommunityFeedState.empty
          : CommunityFeedState.content;
    } catch (error) {
      _state = CommunityFeedState.error;
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
      if (_loadRevision != requestedRevision) {
        loadPosts(showLoading: showLoading);
      }
    }
  }

  void setSort(String sort) {
    _sort = sort;
    loadPosts();
  }

  void setQuery(String q) {
    _searchQuery = q;
    loadPosts();
  }

  Future<void> toggleLike(
    String postId,
    String userId,
    bool currentlyLiked,
  ) async {
    if (_likesInFlight.contains(postId)) return;
    final idx = _posts.indexWhere((post) => post.id == postId);
    if (idx == -1) return;

    final previous = _posts[idx];
    _likesInFlight.add(postId);
    _errorMessage = null;
    _posts[idx] = previous.copyWith(
      isLikedByCurrentUser: !currentlyLiked,
      likeCount: previous.likeCount + (currentlyLiked ? -1 : 1),
    );
    notifyListeners();

    try {
      final updated = await _repo.toggleLike(postId, userId, currentlyLiked);
      final currentIndex = _posts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) {
        _posts[currentIndex] = updated;
        notifyListeners();
      }
    } catch (error) {
      final currentIndex = _posts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) _posts[currentIndex] = previous;
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _likesInFlight.remove(postId);
    }
  }

  Future<void> retry() => loadPosts();
}
