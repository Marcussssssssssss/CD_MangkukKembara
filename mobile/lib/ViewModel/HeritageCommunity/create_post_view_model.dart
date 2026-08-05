import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/community_post_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';

/// View model for creating a community post.
class CreatePostViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  final TreasureMapRepository _treasureMapRepository;
  CreatePostViewModel({
    HeritageCommunityRepository? repo,
    TreasureMapRepository? treasureMapRepository,
  }) : _repo = repo ?? HeritageCommunityRepository(),
       _treasureMapRepository =
           treasureMapRepository ?? TreasureMapRepository();

  String? _selectedVendorId;
  String? _selectedVendorName;
  double _rating = 0;
  String _reviewText = '';
  List<XFile> _photos = [];
  bool _isSubmitting = false;
  bool _success = false;
  String? _errorMessage;
  CommunityPostModel? _createdPost;
  List<VendorModel> _vendors = [];
  bool _isLoadingVendors = false;

  String? get selectedVendorId => _selectedVendorId;
  String? get selectedVendorName => _selectedVendorName;
  double get rating => _rating;
  String get reviewText => _reviewText;
  List<XFile> get photos => List.unmodifiable(_photos);
  bool get isSubmitting => _isSubmitting;
  bool get success => _success;
  String? get errorMessage => _errorMessage;
  CommunityPostModel? get createdPost => _createdPost;
  List<VendorModel> get vendors => _vendors;
  bool get isLoadingVendors => _isLoadingVendors;

  bool get canSubmit =>
      _selectedVendorId != null &&
      _rating >= 1 &&
      _reviewText.trim().length >= AppConstants.minReviewLength &&
      _reviewText.trim().length <= AppConstants.maxReviewLength;

  void selectVendor(String id, String name) {
    _selectedVendorId = id;
    _selectedVendorName = name;
    notifyListeners();
  }

  void setRating(double r) {
    _rating = r;
    notifyListeners();
  }

  void setReviewText(String t) {
    _reviewText = t;
    notifyListeners();
  }

  void addPhotos(List<XFile> files) {
    final remaining = AppConstants.maxPostPhotos - _photos.length;
    if (remaining <= 0) return;
    _photos.addAll(files.take(remaining));
    notifyListeners();
  }

  void removePhoto(int index) {
    _photos.removeAt(index);
    notifyListeners();
  }

  Future<void> loadVendors() async {
    if (_isLoadingVendors) return;
    _isLoadingVendors = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _vendors = await _treasureMapRepository.fetchVendors();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoadingVendors = false;
      notifyListeners();
    }
  }

  Future<bool> submitPost(String userId) async {
    if (_isSubmitting) return false;
    final validationError = _validationError;
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _createdPost = await _repo.createPost(
        userId: userId,
        vendorId: _selectedVendorId!,
        rating: _rating,
        reviewText: _reviewText,
        photos: _photos,
      );
      _success = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? get _validationError {
    if (_selectedVendorId == null) return 'Please select a vendor.';
    if (_rating < 1 || _rating > 5) return 'Please choose a rating.';
    final review = _reviewText.trim();
    if (review.isEmpty) return 'Review text is required.';
    if (review.length < AppConstants.minReviewLength) {
      return 'Review must be at least ${AppConstants.minReviewLength} characters.';
    }
    if (review.length > AppConstants.maxReviewLength) {
      return 'Review must be at most ${AppConstants.maxReviewLength} characters.';
    }
    if (_photos.length > AppConstants.maxPostPhotos) {
      return 'Select at most ${AppConstants.maxPostPhotos} photos.';
    }
    return null;
  }

  void reset() {
    _selectedVendorId = null;
    _selectedVendorName = null;
    _rating = 0;
    _reviewText = '';
    _photos = [];
    _success = false;
    _errorMessage = null;
    notifyListeners();
  }
}
