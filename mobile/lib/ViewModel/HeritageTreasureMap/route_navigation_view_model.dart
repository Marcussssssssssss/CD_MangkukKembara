import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../../Model/Services/google_map_api_service.dart';
import '../../core/app_exception.dart';

/// Travel mode options for the route navigation.
enum TravelMode { driving, walking, transit }

/// View model for the route navigation view.
class RouteNavigationViewModel extends ChangeNotifier {
  final TreasureMapRepository _repo;
  final GoogleMapApiService _maps;
  RouteNavigationViewModel({
    TreasureMapRepository? repo,
    GoogleMapApiService? maps,
  }) : _repo = repo ?? TreasureMapRepository(),
       _maps = maps ?? GoogleMapApiService();

  VendorModel? _vendor;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  TravelMode _travelMode = TravelMode.driving;

  VendorModel? get vendor => _vendor;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  TravelMode get travelMode => _travelMode;

  String get destinationCoordinates => _vendor == null
      ? ''
      : '${_vendor!.latitude.toStringAsFixed(5)}, '
            '${_vendor!.longitude.toStringAsFixed(5)}';

  Future<void> loadVendor(String vendorId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (showLoading) notifyListeners();
    try {
      _vendor = await _repo.fetchVendorById(vendorId);
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTravelMode(TravelMode mode) {
    _travelMode = mode;
    notifyListeners();
  }

  Future<void> openDirections() async {
    final vendor = _vendor;
    if (vendor == null) {
      throw const AppException('Vendor location is unavailable.');
    }
    final opened = await _maps.openDirections(
      latitude: vendor.latitude,
      longitude: vendor.longitude,
      travelMode: _travelMode.name,
    );
    if (!opened) {
      throw const AppException('Could not open a maps application.');
    }
  }
}
