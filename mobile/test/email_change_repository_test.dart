import 'package:flutter_test/flutter_test.dart';
import 'package:mangkuk_kembara/Model/Repositories/AccountManagement/account_repository.dart';
import 'package:mangkuk_kembara/Model/Services/supabase_api_service.dart';
import 'package:mangkuk_kembara/core/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AccountRepository.requestEmailChange', () {
    test(
      'reauthenticates the same user before starting verification',
      () async {
        final api = _FakeSupabaseApiService();
        final repository = AccountRepository(api: api);

        final pendingEmail = await repository.requestEmailChange(
          newEmail: '  NEW.Address@Example.com ',
          currentPassword: 'current-password',
        );

        expect(api.signedInEmail, 'current@example.com');
        expect(api.signedInPassword, 'current-password');
        expect(api.updatedEmail, 'new.address@example.com');
        expect(api.updateCurrentPassword, 'current-password');
        expect(api.updateRedirect, BackendConfig.emailConfirmationRedirect);
        expect(pendingEmail, 'new.address@example.com');
        expect(api.calls, ['signIn', 'updateEmail']);
      },
    );

    test(
      'does not update email if reauthentication returns another user',
      () async {
        final api = _FakeSupabaseApiService(
          signedInUser: _user(id: 'different-user'),
        );
        final repository = AccountRepository(api: api);

        await expectLater(
          repository.requestEmailChange(
            newEmail: 'new@example.com',
            currentPassword: 'current-password',
          ),
          throwsA(isA<Exception>()),
        );

        expect(api.updatedEmail, isNull);
        expect(api.didSignOut, isTrue);
        expect(api.calls, ['signIn', 'signOut']);
      },
    );
  });
}

class _FakeSupabaseApiService extends Fake implements SupabaseApiService {
  _FakeSupabaseApiService({User? signedInUser})
    : _signedInUser = signedInUser ?? _user();

  final User _currentUser = _user();
  final User _signedInUser;
  final List<String> calls = [];
  String? signedInEmail;
  String? signedInPassword;
  String? updatedEmail;
  String? updateCurrentPassword;
  String? updateRedirect;
  bool didSignOut = false;

  @override
  User requireUser() => _currentUser;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn');
    signedInEmail = email;
    signedInPassword = password;
    return AuthResponse(user: _signedInUser);
  }

  @override
  Future<UserResponse> updateEmail(
    String email, {
    required String currentPassword,
    required String emailRedirectTo,
  }) async {
    calls.add('updateEmail');
    updatedEmail = email;
    updateCurrentPassword = currentPassword;
    updateRedirect = emailRedirectTo;
    return UserResponse.fromJson({
      ..._currentUser.toJson(),
      'new_email': email,
    });
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    didSignOut = true;
  }
}

User _user({String id = 'current-user'}) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'current@example.com',
  createdAt: '2026-01-01T00:00:00.000Z',
  emailConfirmedAt: '2026-01-01T00:00:00.000Z',
);
