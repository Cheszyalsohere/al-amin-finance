/// Konfigurasi yang diisi saat build lewat `--dart-define-from-file=env.json`.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Mode pratinjau desain: tanpa Supabase, memakai data contoh.
  static const pratinjau = bool.fromEnvironment('PRATINJAU');

  static bool get lengkap =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
