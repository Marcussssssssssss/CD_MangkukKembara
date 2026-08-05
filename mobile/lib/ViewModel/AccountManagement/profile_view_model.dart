import 'package:flutter/material.dart';
import '../../Model/Repositories/AccountManagement/account_repository.dart';
import '../../Model/Repositories/AccountManagement/profile_model.dart';
import 'package:image_picker/image_picker.dart';

/// View model for the profile and edit profile views.
class ProfileViewModel extends ChangeNotifier {
  final AccountRepository _repo;

  ProfileViewModel({AccountRepository? repo})
    : _repo = repo ?? AccountRepository();

  ProfileModel? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  int _collectedCount = 0;
  int _postCount = 0;
  int _submissionCount = 0;
  XFile? _pendingAvatar;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get collectedCount => _collectedCount;
  int get postCount => _postCount;
  int get submissionCount => _submissionCount;
  XFile? get pendingAvatar => _pendingAvatar;

  Future<void> loadProfile(String userId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _profile = await _repo.fetchProfile(userId);
      final stats = await _repo.fetchProfileStats(userId);
      _collectedCount = stats['collections'] ?? 0;
      _postCount = stats['posts'] ?? 0;
      _submissionCount = stats['submissions'] ?? 0;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String displayName,
    String? country,
    String? city,
    DateTime? dateOfBirth,
    String? gender,
    XFile? avatar,
  }) async {
    if (_profile == null) return false;
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final avatarUrl = avatar == null
          ? _profile!.avatarUrl
          : await _repo.uploadAvatar(avatar);
      final updated = _profile!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
        country: country,
        city: city,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      _profile = await _repo.updateProfile(updated);
      _successMessage = 'Profile updated successfully.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void setPendingAvatar(XFile? avatar) {
    _pendingAvatar = avatar;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
