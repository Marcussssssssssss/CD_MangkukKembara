import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageExperience/heritage_experience_repository.dart';
import '../../Model/Repositories/HeritageExperience/heritage_tiffin_model.dart';
import '../../Model/Repositories/HeritageExperience/artist_model.dart';
import '../../Model/Repositories/HeritageExperience/artwork_model.dart';
import '../../Model/Repositories/HeritageExperience/heritage_story_model.dart';
import '../../Model/Repositories/HeritageExperience/heritage_media_model.dart';
import '../../Model/Repositories/HeritageExperience/heritage_food_model.dart';

/// View model for the Tiffin Experience Overview and sub-detail views.
class TiffinContentViewModel extends ChangeNotifier {
  final HeritageExperienceRepository _repo;
  TiffinContentViewModel({HeritageExperienceRepository? repo})
    : _repo = repo ?? HeritageExperienceRepository();

  HeritageTiffinModel? _tiffin;
  ArtistModel? _artist;
  ArtworkModel? _artwork;
  List<HeritageStoryModel> _stories = [];
  List<HeritageMediaModel> _media = [];
  HeritageMediaModel? _selectedMedia;
  HeritageFoodModel? _food;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCollected = false;
  String? _errorMessage;
  int _currentStoryIndex = 0;

  HeritageTiffinModel? get tiffin => _tiffin;
  ArtistModel? get artist => _artist;
  ArtworkModel? get artwork => _artwork;
  List<HeritageStoryModel> get stories => _stories;
  List<HeritageMediaModel> get media => _media;
  HeritageMediaModel? get selectedMedia => _selectedMedia;
  HeritageFoodModel? get food => _food;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isCollected => _isCollected;
  String? get errorMessage => _errorMessage;
  int get currentStoryIndex => _currentStoryIndex;
  HeritageStoryModel? get currentStory =>
      _stories.isEmpty ? null : _stories[_currentStoryIndex];
  bool get hasPreviousStory => _currentStoryIndex > 0;
  bool get hasNextStory => _currentStoryIndex < _stories.length - 1;

  Future<void> loadTiffin(String tiffinId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _isCollected = false;
    _artist = null;
    _artwork = null;
    _stories = [];
    _media = [];
    if (showLoading) notifyListeners();
    try {
      _tiffin = await _repo.fetchTiffinById(tiffinId);
      if (_tiffin != null) {
        _isCollected = await _repo.isTiffinCollected(tiffinId);
        if (!_isCollected) return;
        if (_tiffin!.artistId != null) {
          _artist = await _repo.fetchArtistById(_tiffin!.artistId!);
        }
        if (_tiffin!.artworkId != null) {
          _artwork = await _repo.fetchArtworkById(_tiffin!.artworkId!);
        }
        _stories = await _repo.fetchStoriesByTiffinId(tiffinId);
        _media = await _repo.fetchMediaByTiffinId(tiffinId);
      }
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadArtist(String artistId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _artist = await _repo.fetchArtistById(artistId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadArtwork(String artworkId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _artwork = await _repo.fetchArtworkById(artworkId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedia(String mediaId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _selectedMedia = await _repo.fetchMediaById(mediaId);
      if (_selectedMedia != null) {
        _media = await _repo.fetchMediaByTiffinId(_selectedMedia!.tiffinId);
      }
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFoodForTiffin(
    String tiffinId, {
    bool showLoading = true,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _food = await _repo.fetchFoodByTiffinId(tiffinId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextStory() {
    if (hasNextStory) {
      _currentStoryIndex++;
      notifyListeners();
    }
  }

  void prevStory() {
    if (hasPreviousStory) {
      _currentStoryIndex--;
      notifyListeners();
    }
  }

  void retry(String id) => loadTiffin(id);
}
