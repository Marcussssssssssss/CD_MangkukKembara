import 'package:image_picker/image_picker.dart';

import '../../../core/app_exception.dart';
import '../../../core/backend_config.dart';
import '../../Services/cloudinary_api_service.dart';
import '../../Services/supabase_api_service.dart';
import 'auth_user_model.dart';
import 'profile_model.dart';

class AccountRepository {
  final SupabaseApiService _api;
  final CloudinaryApiService _cloudinary;

  AccountRepository({SupabaseApiService? api, CloudinaryApiService? cloudinary})
    : _api = api ?? SupabaseApiService(),
      _cloudinary = cloudinary ?? CloudinaryApiService(supabase: api);

  AuthUserModel? get currentUser {
    final user = _api.currentUser;
    return user == null ? null : AuthUserModel.fromSupabase(user);
  }

  Stream<void> get authChanges => _api.authStateChanges.map((_) {});

  Future<AuthUserModel> login(String email, String password) async {
    final response = await _api.signIn(email: email, password: password);
    final user = response.user;
    if (user == null) throw const AppException('Login did not return a user.');
    if (user.emailConfirmedAt == null) {
      await _api.signOut();
      throw const AppException(
        'Please verify your email address before logging in.',
      );
    }
    return AuthUserModel.fromSupabase(user);
  }

  Future<void> logout() => _api.signOut();

  Future<AuthUserModel> register({
    required String displayName,
    required String email,
    required String password,
    String? country,
    String? city,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final metadata = <String, dynamic>{
      'display_name': displayName.trim(),
      if (country != null && country.trim().isNotEmpty)
        'country_code': country.trim().toUpperCase(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      if (gender != null && gender.trim().isNotEmpty)
        'gender': gender.trim().toLowerCase(),
    };
    final response = await _api.signUp(
      email: email,
      password: password,
      metadata: metadata,
      emailRedirectTo: BackendConfig.emailConfirmationRedirect,
    );
    final user = response.user;
    if (user == null) {
      throw const AppException('Registration did not return a user.');
    }
    // Supabase normally returns no session when email confirmation is enabled.
    // Sign out defensively so registration never enters the application.
    if (response.session != null) await _api.signOut();
    return AuthUserModel.fromSupabase(user);
  }

  Future<void> resendVerificationEmail(String email) =>
      _api.resendSignupConfirmation(
        email,
        emailRedirectTo: BackendConfig.emailConfirmationRedirect,
      );

  Future<void> sendPasswordResetEmail(String email) =>
      _api.sendPasswordResetEmail(
        email,
        redirectTo: BackendConfig.passwordRecoveryRedirect,
      );

  Future<void> resetPassword(String newPassword) async {
    _api.requireUser();
    await _api.updatePassword(newPassword);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _api.requireUser();
    final email = user.email;
    if (email == null) {
      throw const AppException('The account has no email address.');
    }
    await _api.signIn(email: email, password: currentPassword);
    await _api.updatePassword(newPassword);
  }

  Future<ProfileModel> fetchProfile(String userId) async {
    final current = _api.requireUser();
    if (current.id != userId) {
      throw const AppException('Profile access denied.');
    }
    final json = await _api.guard(
      () => _api.client
          .from('profiles')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle(),
    );
    if (json == null) {
      throw const AppException(
        'Your account profile is missing. Please contact support.',
      );
    }
    return ProfileModel.fromJson(json);
  }

  Future<ProfileModel> updateProfile(ProfileModel updated) async {
    final current = _api.requireUser();
    final ownedProfile = await fetchProfile(current.id);
    if (ownedProfile.id != updated.id) {
      throw const AppException('Profile update denied.');
    }
    final json = await _api.guard(
      () => _api.client
          .from('profiles')
          .update(updated.toUpdateJson())
          .eq('profile_id', updated.id)
          .select()
          .maybeSingle(),
    );
    if (json == null) {
      throw const AppException('Your profile could not be updated.');
    }
    return ProfileModel.fromJson(json);
  }

  Future<String> uploadAvatar(XFile file) async {
    final user = _api.requireUser();
    final result = await _cloudinary.uploadImage(
      file,
      folder: 'mangkukkembara/profiles/${user.id}',
      maxBytes: 5 * 1024 * 1024,
    );
    return result.secureUrl;
  }

  Future<Map<String, int>> fetchProfileStats(String userId) async {
    final current = _api.requireUser();
    if (current.id != userId) {
      throw const AppException('Profile access denied.');
    }
    final profileId = (await fetchProfile(userId)).id;
    final results = await Future.wait<dynamic>([
      _api.client
          .from('v_collection_progress')
          .select('collected_count')
          .eq('profile_id', profileId)
          .maybeSingle(),
      _api.client
          .from('community_posts')
          .count()
          .eq('profile_id', profileId)
          .eq('status', 'published'),
      _api.client
          .from('artwork_submissions')
          .count()
          .eq('profile_id', profileId),
    ]);
    final progress = results[0] as Map<String, dynamic>?;
    return {
      'collections': (progress?['collected_count'] as num? ?? 0).toInt(),
      'posts': results[1] as int,
      'submissions': results[2] as int,
    };
  }

  Future<int> fetchCollectionCount(String userId) async =>
      (await fetchProfileStats(userId))['collections'] ?? 0;
}
