import 'package:flutter/material.dart';
import '../../Model/Repositories/AccountManagement/account_repository.dart';
import '../../core/constants.dart';

/// View model for the registration form.
class RegisterViewModel extends ChangeNotifier {
  final AccountRepository _repo;
  RegisterViewModel({AccountRepository? repo})
    : _repo = repo ?? AccountRepository();

  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;
  bool _isResending = false;
  String? _registeredEmail;
  String? _resendMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get success => _success;
  bool get isResending => _isResending;
  String? get registeredEmail => _registeredEmail;
  String? get resendMessage => _resendMessage;

  // Password policy state
  bool get hasMinLength => _password.length >= AppConstants.minPasswordLength;
  bool get hasUppercase => _password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => _password.contains(RegExp(r'[a-z]'));
  bool get hasNumber => _password.contains(RegExp(r'[0-9]'));
  bool get hasSpecial => _password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get isPasswordValid =>
      hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;

  String _password = '';
  void updatePassword(String p) {
    _password = p;
    notifyListeners();
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
    String? country,
    String? city,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.register(
        displayName: displayName,
        email: email,
        password: password,
        country: country,
        city: city,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      _success = true;
      _registeredEmail = email.trim();
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

  Future<bool> resendVerificationEmail() async {
    if (_isResending) return false;
    final email = _registeredEmail;
    if (email == null) return false;
    _isResending = true;
    _errorMessage = null;
    _resendMessage = null;
    notifyListeners();
    try {
      await _repo.resendVerificationEmail(email);
      _resendMessage = 'Verification email sent again.';
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isResending = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
