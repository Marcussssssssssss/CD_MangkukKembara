import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../Model/Repositories/HeritageTreasureMap/food_category_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/pasar_malam_model.dart';
import 'heritage_treasure_map_search.dart';

enum MapViewMode { map, list }

/// View model for the Heritage Treasure Map view.
class TreasureMapViewModel extends ChangeNotifier {
  final TreasureMapRepository _repo;

  TreasureMapViewModel({TreasureMapRepository? repo})
    : _repo = repo ?? TreasureMapRepository();

  // ── State ─────────────────────────────────────────────────────────────────────

  /// Unfiltered caches populated on initial/refresh load.
  List<VendorModel> _allVendors = [];
  List<PasarMalamModel> _allPasarMalam = [];

  List<VendorModel> _vendors = [];
  List<VendorModel> _mapVendors = [];
  List<PasarMalamModel> _pasarMalam = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  MapViewMode _viewMode = MapViewMode.map;
  String _searchQuery = '';
  String _selectedState = 'All States';
  String _selectedFoodCategory = 'All';
  String? _selectedFoodCategoryId;
  List<FoodCategoryModel> _foodCategories = [];
  VendorModel? _previewVendor; // bottom sheet preview
  PasarMalamModel? _previewPasarMalam;
  List<VendorModel> _pasarMalamVendors = [];
  bool _isLoadingPasarMalamVendors = false;
  String? _pasarMalamVendorError;
  int _loadRevision = 0;
  String _vendorSort = 'Nearby';
  String? _locationMessage;
  Position? _position;
  bool _locationChecked = false;

  // ── Getters ───────────────────────────────────────────────────────────────────

  List<VendorModel> get vendors => _vendors;
  List<VendorModel> get mapVendors => _mapVendors;
  List<PasarMalamModel> get pasarMalam => _pasarMalam;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  MapViewMode get viewMode => _viewMode;
  String get searchQuery => _searchQuery;
  bool get hasSearchQuery => _searchQuery.trim().isNotEmpty;
  String get selectedState => _selectedState;
  String get selectedFoodCategory => _selectedFoodCategory;
  List<String> get foodCategoryNames => [
    'All',
    ..._foodCategories.map((category) => category.name),
  ];
  VendorModel? get previewVendor => _previewVendor;
  PasarMalamModel? get previewPasarMalam => _previewPasarMalam;
  List<VendorModel> get pasarMalamVendors => _pasarMalamVendors;
  bool get isLoadingPasarMalamVendors => _isLoadingPasarMalamVendors;
  String? get pasarMalamVendorError => _pasarMalamVendorError;
  bool get isEmpty =>
      !_isLoading && !_hasError && _vendors.isEmpty && _pasarMalam.isEmpty;
  String get vendorSort => _vendorSort;
  String? get locationMessage => _locationMessage;
  bool get canShowCurrentLocation => _position != null;

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> loadVendors({bool showLoading = true}) async {
    _loadRevision++;
    if (_isLoading) return;
    final requestedRevision = _loadRevision;
    _isLoading = true;
    _hasError = false;
    if (showLoading) notifyListeners();
    try {
      await _loadFoodCategories();
      // Fetch ALL vendors and pasar malam (unfiltered) and cache them.
      _allVendors = await _repo.fetchVendors();
      _allPasarMalam = await _repo.fetchPasarMalam();
      _applyFilters();
      await _sortVendors();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load vendors. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_loadRevision != requestedRevision) {
        loadVendors(showLoading: showLoading);
      }
    }
  }

  /// Derives [_vendors], [_mapVendors] and [_pasarMalam] from the cached
  /// [_allVendors] / [_allPasarMalam] using the current filter settings.
  /// Pure in-memory operation — no DB call, no [_isLoading] flip.
  void _applyFilters() {
    // Vendors
    final filteredVendors = HeritageTreasureMapSearch.filterVendors(
      _allVendors,
      query: _searchQuery,
      state: _selectedState,
      foodCategory: _selectedFoodCategory,
      foodCategoryId: _selectedFoodCategoryId,
    );
    _vendors = filteredVendors.toList();
    _mapVendors = filteredVendors
        .where(
          (vendor) =>
              vendor.pasarMalamId == null || _searchQuery.trim().isNotEmpty,
        )
        .toList();

    // Pasar Malam
    final normalizedState =
        HeritageTreasureMapSearch.databaseStateName(_selectedState);
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    _pasarMalam = _allPasarMalam.where((market) {
      if (normalizedState != null &&
          market.state.toLowerCase() != normalizedState.toLowerCase()) {
        return false;
      }
      if (normalizedQuery.isNotEmpty &&
          !market.name.toLowerCase().contains(normalizedQuery) &&
          !market.state.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  void setViewMode(MapViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> setVendorSort(String sort) async {
    if (_vendorSort == sort) return;
    _vendorSort = sort;
    await _sortVendors();
    notifyListeners();
  }

  Future<void> _sortVendors() async {
    _locationMessage = null;
    if (_vendorSort == 'Most Rated') {
      _vendors.sort(_compareMostRated);
      return;
    }
    await _loadLocation();
    final position = _position;
    if (position == null) {
      _vendors.sort(_compareByName);
      _locationMessage =
          'Location is unavailable. Vendors are shown alphabetically.';
      return;
    }
    _vendors =
        _vendors
            .map(
              (vendor) => vendor.copyWith(
                distanceKm: _distanceKm(
                  position.latitude,
                  position.longitude,
                  vendor.latitude,
                  vendor.longitude,
                ),
              ),
            )
            .toList()
          ..sort((a, b) {
            final distance = (a.distanceKm ?? double.infinity).compareTo(
              b.distanceKm ?? double.infinity,
            );
            return distance == 0 ? _compareByName(a, b) : distance;
          });
  }

  /// Synchronous re-sort using the already-cached [_position].
  /// Called by local filter methods that don't need the async location lookup
  /// (it was resolved during the initial [_sortVendors] call).
  void _sortVendorsSync() {
    _locationMessage = null;
    if (_vendorSort == 'Most Rated') {
      _vendors.sort(_compareMostRated);
      return;
    }
    final position = _position;
    if (position == null) {
      _vendors.sort(_compareByName);
      if (_locationChecked) {
        _locationMessage =
            'Location is unavailable. Vendors are shown alphabetically.';
      }
      return;
    }
    _vendors =
        _vendors
            .map(
              (vendor) => vendor.copyWith(
                distanceKm: _distanceKm(
                  position.latitude,
                  position.longitude,
                  vendor.latitude,
                  vendor.longitude,
                ),
              ),
            )
            .toList()
          ..sort((a, b) {
            final distance = (a.distanceKm ?? double.infinity).compareTo(
              b.distanceKm ?? double.infinity,
            );
            return distance == 0 ? _compareByName(a, b) : distance;
          });
  }

  Future<void> _loadLocation() async {
    if (_locationChecked) return;
    _locationChecked = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      _position = null;
    }
  }

  static int _compareMostRated(VendorModel a, VendorModel b) {
    final rating = b.averageRating.compareTo(a.averageRating);
    if (rating != 0) return rating;
    final reviews = b.reviewCount.compareTo(a.reviewCount);
    return reviews == 0 ? _compareByName(a, b) : reviews;
  }

  static int _compareByName(VendorModel a, VendorModel b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  static double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(latitude2 - latitude1);
    final dLon = _radians(longitude2 - longitude1);
    final value =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(latitude1)) *
            math.cos(_radians(latitude2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(value), math.sqrt(1 - value));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  void setSearchQuery(String q) {
    _searchQuery = q;
    // Filter locally from cached data — no DB call, no loading flash.
    if (_allVendors.isNotEmpty || _allPasarMalam.isNotEmpty) {
      _applyFilters();
      _sortVendorsSync();
      notifyListeners();
    } else {
      loadVendors();
    }
  }

  void setStateFilter(String state) {
    if (_selectedState == state) return;
    _selectedState = state;
    if (_allVendors.isNotEmpty || _allPasarMalam.isNotEmpty) {
      _applyFilters();
      _sortVendorsSync();
      notifyListeners();
    } else {
      loadVendors();
    }
  }

  void setFoodCategoryFilter(String category) {
    if (_selectedFoodCategory == category) return;
    _selectedFoodCategory = category;
    _selectedFoodCategoryId = _categoryIdForName(category);
    if (_allVendors.isNotEmpty || _allPasarMalam.isNotEmpty) {
      _applyFilters();
      _sortVendorsSync();
      notifyListeners();
    } else {
      loadVendors();
    }
  }

  void clearFilters() {
    _selectedState = 'All States';
    _selectedFoodCategory = 'All';
    _selectedFoodCategoryId = null;
    _searchQuery = '';
    if (_allVendors.isNotEmpty || _allPasarMalam.isNotEmpty) {
      _applyFilters();
      _sortVendorsSync();
      notifyListeners();
    } else {
      loadVendors();
    }
  }

  void showVendorPreview(VendorModel vendor) {
    _previewPasarMalam = null;
    _previewVendor = vendor;
    notifyListeners();
  }

  void clearVendorPreview() {
    _previewVendor = null;
    notifyListeners();
  }

  Future<void> showPasarMalamPreview(
    PasarMalamModel market, {
    bool showLoading = true,
  }) async {
    _previewVendor = null;
    _previewPasarMalam = market;
    _pasarMalamVendors = [];
    _pasarMalamVendorError = null;
    _isLoadingPasarMalamVendors = true;
    if (showLoading) notifyListeners();
    try {
      _pasarMalamVendors = await _repo.fetchVendorsByPasarMalam(market.id);
    } catch (error) {
      _pasarMalamVendorError = error.toString();
    } finally {
      _isLoadingPasarMalamVendors = false;
      notifyListeners();
    }
  }

  void clearPasarMalamPreview() {
    _previewPasarMalam = null;
    _pasarMalamVendors = [];
    _pasarMalamVendorError = null;
    notifyListeners();
  }

  Future<void> retryPasarMalamVendors() async {
    final market = _previewPasarMalam;
    if (market == null || _isLoadingPasarMalamVendors) return;
    await showPasarMalamPreview(market);
  }

  Future<void> refreshPasarMalamVendors() async {
    final market = _previewPasarMalam;
    if (market == null || _isLoadingPasarMalamVendors) return;
    await showPasarMalamPreview(market, showLoading: false);
  }

  Future<void> retry() => loadVendors();

  Future<void> _loadFoodCategories() async {
    if (_foodCategories.isNotEmpty) return;
    _foodCategories = await _repo.fetchFoodCategories();
  }

  String? _categoryIdForName(String name) {
    if (name == 'All') return null;
    for (final category in _foodCategories) {
      if (category.name == name) return category.id;
    }
    return null;
  }
}
