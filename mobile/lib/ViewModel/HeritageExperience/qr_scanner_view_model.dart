import 'package:flutter/material.dart';
import '../../Model/Repositories/HeritageExperience/heritage_experience_repository.dart';
import '../../Model/Repositories/HeritageExperience/qr_scan_result_model.dart';

enum QrScanState { idle, scanning, success, error }

/// View model for the QR scanner view.
class QrScannerViewModel extends ChangeNotifier {
  final HeritageExperienceRepository _repo;
  QrScannerViewModel({HeritageExperienceRepository? repo})
    : _repo = repo ?? HeritageExperienceRepository();

  QrScanState _state = QrScanState.idle;
  QrScanResultModel? _result;
  String? _errorMessage;
  bool _torchOn = false;

  QrScanState get state => _state;
  QrScanResultModel? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get torchOn => _torchOn;

  Future<void> processScan(String userId, String codeValue) async {
    _state = QrScanState.scanning;
    _errorMessage = null;
    notifyListeners();
    try {
      _result = await _repo.scanQrCode(userId, codeValue);
      _state = QrScanState.success;
    } catch (e) {
      _state = QrScanState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void toggleTorch() {
    _torchOn = !_torchOn;
    notifyListeners();
  }

  void reset() {
    _state = QrScanState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
