import 'dart:async';

import 'package:flutter/material.dart';
import '../../Model/Repositories/AccountManagement/account_repository.dart';
import '../../Model/Repositories/AccountManagement/auth_user_model.dart';
import '../../Model/Repositories/AccountManagement/profile_model.dart';

/// Global authentication view model.
/// Drives guest vs. logged-in UI state across the entire app.
class AuthViewModel extends ChangeNotifier {
  final AccountRepository _repo;
  StreamSubscription<void>? _authSubscription;

  AuthViewModel({AccountRepository? repo})
    : _repo = repo ?? AccountRepository() {
    _restoreCurrentSession();
    _authSubscription = _repo.authChanges.listen(
      (_) => _restoreCurrentSession(),
    );
  }

  // ── State ─────────────────────────────────────────────────────────────────────

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  AuthUserModel? _currentUser;
  ProfileModel? _profile;
  bool _isInitialized = false;

  // ── Getters ───────────────────────────────────────────────────────────────────

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthUserModel? get currentUser => _currentUser;
  ProfileModel? get profile => _profile;
  bool get isInitialized => _isInitialized;
  String get displayName =>
      _profile?.displayName ?? _currentUser?.email ?? 'Guest';

  // ── Login ─────────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _repo.login(email, password);
      _profile = await _repo.fetchProfile(_currentUser!.id);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      try {
        await _repo.logout();
      } catch (_) {
        // Preserve the original login/profile error.
      }
      _currentUser = null;
      _profile = null;
      _isLoggedIn = false;
      _errorMessage = message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _restoreCurrentSession() async {
    final user = _repo.currentUser;
    _currentUser = user;
    _profile = null;
    _isLoggedIn = false;
    if (user?.isEmailVerified == true) {
      try {
        _profile = await _repo.fetchProfile(user!.id);
        _isLoggedIn = true;
        _errorMessage = null;
      } catch (error) {
        _errorMessage = error.toString();
        _currentUser = null;
        try {
          await _repo.logout();
        } catch (_) {
          // The session remains treated as logged out locally.
        }
      }
    } else {
      if (user != null) await _repo.logout();
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _repo.logout();
      _isLoggedIn = false;
      _currentUser = null;
      _profile = null;
      _clearError();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void clearError() => _clearError();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
