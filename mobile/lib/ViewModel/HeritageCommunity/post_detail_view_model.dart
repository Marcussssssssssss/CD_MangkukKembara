import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/community_post_model.dart';
import '../../Model/Repositories/HeritageCommunity/community_comment_model.dart';

/// View model for the post detail view.
class PostDetailViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  PostDetailViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  CommunityPostModel? _post;
  List<CommunityCommentModel> _comments = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;
  String? _errorMessage;

  CommunityPostModel? get post => _post;
  List<CommunityCommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isSubmittingComment => _isSubmittingComment;
  bool get isTogglingLike => _isTogglingLike;
  String? get errorMessage => _errorMessage;
  int get totalCommentCount => _comments.fold<int>(
    0,
    (count, comment) => count + 1 + comment.replies.length,
  );

  Future<void> loadPost(String postId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _post = await _repo.fetchPostById(postId);
      _comments = await _repo.fetchCommentsByPostId(postId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String userId) async {
    if (_post == null || _isTogglingLike) return;
    final previous = _post!;
    _isTogglingLike = true;
    _errorMessage = null;
    _post = previous.copyWith(
      isLikedByCurrentUser: !previous.isLikedByCurrentUser,
      likeCount: previous.likeCount + (previous.isLikedByCurrentUser ? -1 : 1),
    );
    notifyListeners();
    try {
      _post = await _repo.toggleLike(
        _post!.id,
        userId,
        previous.isLikedByCurrentUser,
      );
      notifyListeners();
    } catch (error) {
      _post = previous;
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isTogglingLike = false;
      notifyListeners();
    }
  }

  Future<bool> submitComment(
    String postId,
    String body,
    String? parentId,
  ) async {
    if (_isSubmittingComment) return false;
    _isSubmittingComment = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.addComment(postId, body, parentId);
      await loadPost(postId, showLoading: false);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _isSubmittingComment = false;
      notifyListeners();
    }
  }

  Future<void> retry(String postId) => loadPost(postId);
}
