import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/auth_repository.dart';
import '../features/auth/profil.dart';

/// Pengganti AuthRepository untuk mode pratinjau desain
/// (`--dart-define=PRATINJAU=true`): tanpa Supabase, selalu login sebagai
/// owner contoh.
class RepoPratinjau implements AuthRepository {
  @override
  Stream<AuthState> get perubahanAuth => const Stream.empty();

  @override
  bool get sudahMasuk => true;

  @override
  String? get userIdSaatIni => 'pratinjau';

  @override
  Future<void> masuk({required String email, required String password}) async {}

  @override
  Future<void> keluar() async {}

  @override
  Future<Profil?> profilSaatIni() async => const Profil(
    id: 'pratinjau',
    nama: 'Irfan',
    peran: Peran.owner,
    aktif: true,
  );
}
