import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/operating_hour_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/tiffin_availability_model.dart';

/// View model for the vendor detail view.
class VendorDetailViewModel extends ChangeNotifier {
  final TreasureMapRepository _repo;
  VendorDetailViewModel({TreasureMapRepository? repo})
    : _repo = repo ?? TreasureMapRepository();

  VendorModel? _vendor;
  List<OperatingHourModel> _operatingHours = [];
  List<TiffinAvailabilityModel> _tiffinAvailability = [];
  bool _isLoading = false;
  bool _hasError = false;

  VendorModel? get vendor => _vendor;
  List<OperatingHourModel> get operatingHours => _operatingHours;
  List<TiffinAvailabilityModel> get tiffinAvailability => _tiffinAvailability;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadVendor(String vendorId, {bool showLoading = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    if (showLoading) notifyListeners();
    try {
      _vendor = await _repo.fetchVendorById(vendorId);
      if (_vendor != null) {
        _operatingHours = await _repo.fetchOperatingHours(vendorId);
        _tiffinAvailability = await _repo.fetchTiffinAvailability(vendorId);
      }
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry(String vendorId) => loadVendor(vendorId);
}
