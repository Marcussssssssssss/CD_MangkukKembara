import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_exception.dart';

/// The only application service that owns the Supabase SDK client.
/// Repositories use this service for Auth, PostgREST, views, and RPC calls.
class SupabaseApiService {
  final SupabaseClient client;

  SupabaseApiService({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  User requireUser() {
    final user = currentUser;
    if (user == null) throw const AuthenticationRequiredException();
    return user;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => guard(
    () =>
        client.auth.signInWithPassword(email: email.trim(), password: password),
  );

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
    String? emailRedirectTo,
  }) => guard(
    () => client.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
      emailRedirectTo: emailRedirectTo,
    ),
  );

  Future<void> resendSignupConfirmation(String email) => guard(
    () => client.auth.resend(type: OtpType.signup, email: email.trim()),
  );

  Future<void> signOut() => guard(client.auth.signOut);

  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectTo,
  }) => guard(
    () =>
        client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo),
  );

  Future<UserResponse> updatePassword(String password) =>
      guard(() => client.auth.updateUser(UserAttributes(password: password)));

  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on AuthException catch (error) {
      throw AppException(error.message, error);
    } on PostgrestException catch (error) {
      final details = error.details?.toString().trim();
      throw AppException(
        details == null || details.isEmpty
            ? error.message
            : '${error.message}: $details',
        error,
      );
    } catch (error) {
      throw AppException('The service request could not be completed.', error);
    }
  }
}
