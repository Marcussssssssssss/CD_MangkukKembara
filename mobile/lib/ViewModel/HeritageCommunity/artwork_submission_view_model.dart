import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageCommunity/heritage_community_repository.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_submission_model.dart';
import 'package:image_picker/image_picker.dart';

enum ArtworkPhotoView {
  frontHero,
  layer1Flat360,
  layer2Flat360,
  layer3Flat360,
  top,
}

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
  String _layer1Meaning = '';
  String _layer2Meaning = '';
  String _layer3Meaning = '';
  final Map<ArtworkPhotoView, XFile> _artworkPhotos = {};

  bool get isSubmitting => _isSubmitting;
  bool get success => _success;
  String? get errorMessage => _errorMessage;
  ArtworkSubmissionModel? get submission => _submission;
  XFile? photoFor(ArtworkPhotoView view) => _artworkPhotos[view];
  bool hasPhoto(ArtworkPhotoView view) => _artworkPhotos.containsKey(view);
  int get completedPhotoCount => _artworkPhotos.length;

  bool get canSubmit =>
      _artworkTitle.trim().isNotEmpty &&
      _designDescription.trim().isNotEmpty &&
      _culturalInspiration.trim().isNotEmpty &&
      _layer1Meaning.trim().isNotEmpty &&
      _layer2Meaning.trim().isNotEmpty &&
      _layer3Meaning.trim().isNotEmpty &&
      ArtworkPhotoView.values.every(_artworkPhotos.containsKey);

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

  void setLayer1Meaning(String value) {
    _layer1Meaning = value;
    notifyListeners();
  }

  void setLayer2Meaning(String value) {
    _layer2Meaning = value;
    notifyListeners();
  }

  void setLayer3Meaning(String value) {
    _layer3Meaning = value;
    notifyListeners();
  }

  void setArtworkPhoto(ArtworkPhotoView view, XFile file) {
    _artworkPhotos[view] = file;
    notifyListeners();
  }

  void removeArtworkPhoto(ArtworkPhotoView view) {
    _artworkPhotos.remove(view);
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
        layer1Meaning: _layer1Meaning,
        layer2Meaning: _layer2Meaning,
        layer3Meaning: _layer3Meaning,
        frontHeroFile: _artworkPhotos[ArtworkPhotoView.frontHero]!,
        layer1Flat360File: _artworkPhotos[ArtworkPhotoView.layer1Flat360]!,
        layer2Flat360File: _artworkPhotos[ArtworkPhotoView.layer2Flat360]!,
        layer3Flat360File: _artworkPhotos[ArtworkPhotoView.layer3Flat360]!,
        topArtworkFile: _artworkPhotos[ArtworkPhotoView.top]!,
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
