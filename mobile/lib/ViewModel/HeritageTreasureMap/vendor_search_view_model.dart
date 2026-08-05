import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';

/// View model for vendor search result view.
class VendorSearchViewModel extends ChangeNotifier {
  final TreasureMapRepository _repo;
  VendorSearchViewModel({TreasureMapRepository? repo})
    : _repo = repo ?? TreasureMapRepository();

  List<VendorModel> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _query = '';
  String _selectedState = 'All States';
  String _selectedFoodCategory = 'All';
  int _searchRevision = 0;
  String _sort = 'Nearby';
  String? _locationMessage;
  Position? _position;
  bool _locationChecked = false;

  List<VendorModel> get results => _results;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get query => _query;
  String get selectedState => _selectedState;
  String get selectedFoodCategory => _selectedFoodCategory;
  bool get isEmpty => !_isLoading && !_hasError && _results.isEmpty;
  bool get hasActiveFilters =>
      _selectedState != 'All States' || _selectedFoodCategory != 'All';
  String get sort => _sort;
  String? get locationMessage => _locationMessage;

  Future<void> search(String query, {bool showLoading = true}) async {
    _query = query;
    _searchRevision++;
    if (_isLoading) return;
    final requestedRevision = _searchRevision;
    _isLoading = true;
    _hasError = false;
    if (showLoading) notifyListeners();
    try {
      _results = await _repo.fetchVendors(
        query: query.isEmpty ? null : query,
        state: _selectedState == 'All States' ? null : _selectedState,
        foodCategory: _selectedFoodCategory == 'All'
            ? null
            : _selectedFoodCategory,
      );
      await _sortResults();
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_searchRevision != requestedRevision) {
        search(_query, showLoading: showLoading);
      }
    }
  }

  Future<void> setSort(String value) async {
    if (_sort == value) return;
    _sort = value;
    await _sortResults();
    notifyListeners();
  }

  Future<void> _sortResults() async {
    _locationMessage = null;
    if (_sort == 'Most Rated') {
      _results.sort((a, b) {
        final rating = b.averageRating.compareTo(a.averageRating);
        if (rating != 0) return rating;
        final reviews = b.reviewCount.compareTo(a.reviewCount);
        if (reviews != 0) return reviews;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return;
    }
    await _loadLocation();
    final position = _position;
    if (position == null) {
      _results.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _locationMessage =
          'Location is unavailable. Vendors are shown alphabetically.';
      return;
    }
    _results =
        _results
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
            if (distance != 0) return distance;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
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

  static double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(latitude2 - latitude1);
    final dLon = _radians(longitude2 - longitude1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(latitude1)) *
            math.cos(_radians(latitude2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  void setStateFilter(String s) {
    _selectedState = s;
    search(_query);
  }

  void setFoodCategoryFilter(String c) {
    _selectedFoodCategory = c;
    search(_query);
  }

  void clearFilters() {
    _selectedState = 'All States';
    _selectedFoodCategory = 'All';
    search(_query);
  }
}
