import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_submission_model.dart';
import 'package:image_picker/image_picker.dart';

/// View model for the Submit Artwork form.
class ArtworkSubmissionViewModel extends ChangeNotifier {
  final HeritageCommunityRepository _repo;
  ArtworkSubmissionViewModel({HeritageCommunityRepository? repo})
    : _repo = repo ?? HeritageCommunityRepository();

  bool _isSubmitting = false;
  bool _success = false;
  String? _errorMessage;
  ArtworkSubmissionModel? _submission;
  String _artworkTitle = '';
  String _designDescription = '';
  String _culturalInspiration = '';
  String _artistStatement = '';
  XFile? _artworkFile;

  bool get isSubmitting => _isSubmitting;
  bool get success => _success;
  String? get errorMessage => _errorMessage;
  ArtworkSubmissionModel? get submission => _submission;
  bool get hasUploadedFile => _artworkFile != null;
  XFile? get artworkFile => _artworkFile;

  bool get canSubmit =>
      _artworkTitle.trim().isNotEmpty &&
      _designDescription.trim().isNotEmpty &&
      _culturalInspiration.trim().isNotEmpty &&
      _artistStatement.trim().isNotEmpty &&
      _artworkFile != null;

  void setArtworkTitle(String v) {
    _artworkTitle = v;
    notifyListeners();
  }

  void setDesignDescription(String v) {
    _designDescription = v;
    notifyListeners();
  }

  void setCulturalInspiration(String v) {
    _culturalInspiration = v;
    notifyListeners();
  }

  void setArtistStatement(String v) {
    _artistStatement = v;
    notifyListeners();
  }

  void setArtworkFile(XFile file) {
    _artworkFile = file;
    notifyListeners();
  }

  void removeFile() {
    _artworkFile = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String campaignId,
    required String userId,
  }) async {
    if (!canSubmit) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _submission = await _repo.submitArtwork(
        campaignId: campaignId,
        userId: userId,
        artworkTitle: _artworkTitle,
        designDescription: _designDescription,
        culturalInspiration: _culturalInspiration,
        artistStatement: _artistStatement,
        artworkFile: _artworkFile!,
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
}
