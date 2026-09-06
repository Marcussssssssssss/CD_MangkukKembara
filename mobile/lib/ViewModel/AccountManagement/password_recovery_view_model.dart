import 'package:flutter/material.dart';
import '../../Model/Repositories/AccountManagement/account_repository.dart';
import '../../core/app_exception.dart';

/// View model for forgot password and reset password flows.
class PasswordRecoveryViewModel extends ChangeNotifier {
  final AccountRepository _repo;
  PasswordRecoveryViewModel({AccountRepository? repo})
    : _repo = repo ?? AccountRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isCurrentPasswordVerified = false;

  // Change password state
  String _newPassword = '';
  bool get hasMinLength => _newPassword.length >= 8;
  bool get hasUppercase => _newPassword.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => _newPassword.contains(RegExp(r'[a-z]'));
  bool get hasNumber => _newPassword.contains(RegExp(r'[0-9]'));
  bool get hasSpecial =>
      _newPassword.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get isPasswordValid =>
      hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;

  bool get isLoading => _isLoading;
  String? get errorMessage =>
      _errorMessage == null ? null : _friendlyError(_errorMessage!);
  String? get successMessage => _successMessage;
  bool get isCurrentPasswordVerified => _isCurrentPasswordVerified;

  void updateNewPassword(String p) {
    _newPassword = p;
    notifyListeners();
  }

  Future<void> sendResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _repo.sendPasswordResetEmail(email);
      _successMessage = 'Reset link sent to $email. Check your inbox.';
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _successMessage = 'Password changed successfully.';
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyCurrentPassword(String currentPassword) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _repo.verifyCurrentPassword(currentPassword);
      _isCurrentPasswordVerified = true;
      notifyListeners();
      return true;
    } catch (_) {
      _isCurrentPasswordVerified = false;
      _errorMessage = 'The current password is incorrect. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _repo.resetPassword(newPassword);
      _successMessage = 'Password reset successfully.';
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> endRecoverySession() => _repo.logout();

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is AppException) return error.message;

    final details = error.toString().toLowerCase();
    if (details.contains('socket') ||
        details.contains('network') ||
        details.contains('host lookup') ||
        details.contains('timed out')) {
      return 'We could not connect to the service. Check your internet connection and try again.';
    }
    if (error is String &&
        !details.contains('exception') &&
        !details.contains('error:') &&
        !details.contains('uri=')) {
      return error;
    }
    return 'We could not complete that request. Please try again.';
  }
}
