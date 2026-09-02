import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents an authenticated user in MangkukKembara.
/// In production this maps to Supabase Auth user record.
class AuthUserModel {
  final String id;
  final String email;
  final DateTime createdAt;
  final bool isEmailVerified;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.isEmailVerified,
  });

  factory AuthUserModel.fromSupabase(User user) => AuthUserModel(
    id: user.id,
    email: user.email ?? '',
    createdAt: DateTime.parse(user.createdAt),
    isEmailVerified: user.emailConfirmedAt != null,
  );

  @override
  String toString() => 'AuthUserModel(id: $id, email: $email)';
}
