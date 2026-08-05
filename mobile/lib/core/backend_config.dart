/// Public mobile configuration.
///
/// The Supabase publishable/anon key is intentionally safe to ship in a client;
/// authorization is enforced by Row Level Security. Cloudinary secrets must only
/// exist in Supabase Edge Function environment variables.
abstract final class BackendConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uifpiyqhzhtclwdpbbxr.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_He5cSZpzDI6EpafVSOQLeg_Q4kyg3dx',
  );

  static const cloudinaryUploadFunction = 'cloudinary-upload';
  static const passwordRecoveryRedirect = String.fromEnvironment(
    'PASSWORD_RECOVERY_REDIRECT',
    defaultValue: 'io.mangkukkembara.app://reset-password',
  );
  static const emailConfirmationRedirect = String.fromEnvironment(
    'EMAIL_CONFIRMATION_REDIRECT',
    defaultValue: 'io.mangkukkembara.app://email-confirmed',
  );
}
