import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';
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
    _authSubscription = _repo.authChanges.listen(_handleAuthEvent);
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
  /// Error text intended for presentation. This second safeguard prevents an
  /// asynchronous auth-state update from exposing raw backend errors.
  String? get errorMessage => _errorMessage == null
      ? null
      : _friendlyLoginError(_errorMessage!);
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
    } catch (error) {
      try {
        await _repo.logout();
      } catch (_) {
        // Preserve the original login/profile error.
      }
      _currentUser = null;
      _profile = null;
      _isLoggedIn = false;
      _errorMessage = _friendlyLoginError(error);
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
        _errorMessage = _friendlyLoginError(error);
        if (!_isTemporaryConnectionFailure(error)) {
          _currentUser = null;
          try {
            await _repo.logout();
          } catch (_) {
            // The session remains treated as logged out locally.
          }
        }
      }
    } else {
      if (user != null) await _repo.logout();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> retrySessionRestore() async {
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
    await _restoreCurrentSession();
  }

  void _handleAuthEvent(AuthChangeEvent event) {
    if (event == AuthChangeEvent.passwordRecovery) {
      _currentUser = null;
      _profile = null;
      _isLoggedIn = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }
    _restoreCurrentSession();
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

  bool _isTemporaryConnectionFailure(Object error) {
    final cause = error is AppException ? error.cause : null;
    final details = '$error ${cause ?? ''}'.toLowerCase();
    return details.contains('socket') ||
        details.contains('network') ||
        details.contains('host lookup') ||
        details.contains('connection refused') ||
        details.contains('timed out') ||
        details.contains('clientexception');
  }

  /// Keeps implementation details (such as HTTP, socket, and DNS errors) out
  /// of the login interface while preserving errors the app intentionally
  /// exposes to its users.
  String _friendlyLoginError(Object error) {
    if (error is AppException) {
      if (_isTemporaryConnectionFailure(error)) {
        return 'We could not connect to the service. Check your internet connection and try again.';
      }
      return error.message;
    }

    // Values already produced by this view model are safe to show. Keeping
    // them intact also makes the getter above safe for asynchronous updates.
    if (error is String &&
        !error.toLowerCase().contains('exception') &&
        !error.toLowerCase().contains('socket') &&
        !error.toLowerCase().contains('host lookup')) {
      return error;
    }

    final details = error.toString().toLowerCase();
    if (details.contains('socket') ||
        details.contains('network') ||
        details.contains('host lookup') ||
        details.contains('failed host lookup') ||
        details.contains('connection refused') ||
        details.contains('timed out')) {
      return 'We could not connect to the service. Check your internet connection and try again.';
    }

    return 'We could not sign you in right now. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
