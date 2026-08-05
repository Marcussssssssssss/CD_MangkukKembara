import 'package:flutter/material.dart';
import '../../Model/Repositories/AccountManagement/account_repository.dart';

/// View model for forgot password and reset password flows.
class PasswordRecoveryViewModel extends ChangeNotifier {
  final AccountRepository _repo;
  PasswordRecoveryViewModel({AccountRepository? repo})
    : _repo = repo ?? AccountRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

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
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

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
    } catch (e) {
      _errorMessage = e.toString();
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
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
