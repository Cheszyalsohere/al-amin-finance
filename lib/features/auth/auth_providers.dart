import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_provider.dart';
import 'auth_repository.dart';
import 'profil.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final _perubahanAuthProvider = StreamProvider<void>(
  (ref) => ref.watch(authRepositoryProvider).perubahanAuth,
);

/// ID pengguna yang sedang login. Hanya berubah saat login/logout,
/// tidak saat token diperbarui.
final userIdProvider = Provider<String?>((ref) {
  ref.watch(_perubahanAuthProvider);
  return ref.watch(authRepositoryProvider).userIdSaatIni;
});

/// Profil pengguna yang sedang login.
final profilProvider = FutureProvider<Profil?>((ref) {
  ref.watch(userIdProvider);
  return ref.watch(authRepositoryProvider).profilSaatIni();
});
