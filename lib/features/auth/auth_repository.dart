import 'package:supabase_flutter/supabase_flutter.dart';

import 'profil.dart';

class AuthGagal implements Exception {
  const AuthGagal(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get perubahanAuth => _client.auth.onAuthStateChange;

  bool get sudahMasuk => _client.auth.currentSession != null;

  String? get userIdSaatIni => _client.auth.currentUser?.id;

  Future<void> masuk({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthGagal(pesanAuth(e));
    } on Exception {
      throw const AuthGagal(
        'Tidak bisa terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<void> keluar() => _client.auth.signOut();

  Future<Profil?> profilSaatIni() async {
    final userId = userIdSaatIni;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select('id, nama, peran, aktif')
        .eq('id', userId)
        .maybeSingle();

    return data == null ? null : Profil.dariMap(data);
  }
}

String pesanAuth(AuthException e) {
  return switch (e.code) {
    'invalid_credentials' => 'Email atau password salah.',
    'email_not_confirmed' => 'Email belum dikonfirmasi.',
    'user_banned' => 'Akun ini diblokir. Hubungi owner.',
    'over_request_rate_limit' || 'over_email_send_rate_limit' =>
      'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.',
    _ => 'Gagal masuk: ${e.message}',
  };
}
