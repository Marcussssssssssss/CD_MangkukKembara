import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageExperience/heritage_experience_repository.dart';
import '../../Model/Repositories/HeritageExperience/heritage_tiffin_model.dart';

/// View model for the Heritage Experience home view.
class HeritageExperienceViewModel extends ChangeNotifier {
  final HeritageExperienceRepository _repo;
  HeritageExperienceViewModel({HeritageExperienceRepository? repo})
    : _repo = repo ?? HeritageExperienceRepository();

  List<HeritageTiffinModel> _allTiffins = [];
  List<HeritageTiffinModel> _tiffins = [];
  Set<String> _collectedIds = {};
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _selectedState = 'All States';
  String? _userId;
  int _totalActiveCount = 0;

  List<HeritageTiffinModel> get tiffins => _tiffins;
  Set<String> get collectedIds => _collectedIds;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get selectedState => _selectedState;
  bool get isEmpty => !_isLoading && !_hasError && _tiffins.isEmpty;

  int get collectedCount => _collectedIds.length;
  int get totalCount => _totalActiveCount;

  bool isCollected(String tiffinId) => _collectedIds.contains(tiffinId);

  Future<void> loadTiffins({String? userId, bool showLoading = true}) async {
    if (_isLoading) return;
    _userId = userId;
    await _loadCurrentCollection(showLoading: showLoading);
  }

  Future<void> _loadCurrentCollection({bool showLoading = true}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      if (_userId == null) {
        _allTiffins = [];
        _tiffins = [];
        _collectedIds = {};
        _totalActiveCount = 0;
      } else {
        _collectedIds = await _repo.fetchCollectedTiffinIds(_userId!);
        // Fetch ALL collected tiffins once (no state filter) and cache them.
        _allTiffins = await _repo.fetchCollectedTiffins(_userId!);
        _totalActiveCount = await _repo.fetchTotalActiveTiffinCount();
        _applyStateFilter();
      }
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Derives [_tiffins] from the cached [_allTiffins] using the current
  /// [_selectedState]. Pure in-memory operation — no DB call.
  void _applyStateFilter() {
    if (_selectedState == 'All States') {
      _tiffins = List.of(_allTiffins);
    } else {
      _tiffins = _allTiffins
          .where((t) => t.state == _selectedState)
          .toList();
    }
  }

  void setStateFilter(String state) {
    if (_selectedState == state) return;
    _selectedState = state;
    _applyStateFilter();
    notifyListeners();
  }

  Future<void> retry({String? userId}) => loadTiffins(userId: userId);
}
