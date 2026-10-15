/// Konfigurasi yang diisi saat build lewat `--dart-define-from-file=env.json`.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get lengkap =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
