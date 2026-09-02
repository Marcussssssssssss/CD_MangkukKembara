import 'package:flutter/foundation.dart';

import '../../Model/Repositories/AccountManagement/account_repository.dart';

class EmailChangeViewModel extends ChangeNotifier {
  final AccountRepository _repo;

  EmailChangeViewModel({AccountRepository? repo})
    : _repo = repo ?? AccountRepository();

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<String?> requestChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _repo.requestEmailChange(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid credentials')) {
      return 'The current password is incorrect. Please try again.';
    }
    if (normalized.contains('already') || normalized.contains('registered')) {
      return 'That email address is already in use.';
    }
    if (normalized.contains('rate') || normalized.contains('too many')) {
      return 'Too many requests. Please wait a few minutes and try again.';
    }
    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('host lookup') ||
        normalized.contains('timed out')) {
      return 'We could not connect. Check your internet connection and try again.';
    }
    return message;
  }
}
