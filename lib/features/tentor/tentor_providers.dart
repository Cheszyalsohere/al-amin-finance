import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase_provider.dart';
import '../siswa/siswa_providers.dart';
import 'tentor.dart';
import 'tentor_repository.dart';

final tentorRepositoryProvider = Provider<TentorRepository>(
  (ref) => Env.pratinjau
      ? TentorRepositoryContoh()
      : TentorRepositorySupabase(ref.watch(supabaseClientProvider)),
);

final daftarTentorProvider = FutureProvider<List<Tentor>>(
  (ref) => ref.watch(tentorRepositoryProvider).daftarTentor(),
);

final tentorProvider = Provider.family<AsyncValue<Tentor?>, String>(
  (ref, id) => ref
      .watch(daftarTentorProvider)
      .whenData((daftar) => daftar.where((t) => t.id == id).firstOrNull),
);

/// Kehadiran semua tentor pada satu bulan (kunci: tanggal 1 bulan itu).
final kehadiranBulanProvider = FutureProvider.family<List<Kehadiran>, DateTime>(
  (ref, bulan) => ref.watch(tentorRepositoryProvider).kehadiranBulan(bulan),
);

final bulanIniProvider = Provider<DateTime>((ref) {
  final h = ref.watch(hariIniProvider);
  return DateTime(h.year, h.month);
});

final riwayatHonorProvider =
    FutureProvider.family<List<PembayaranHonor>, String>(
      (ref, tentorId) =>
          ref.watch(tentorRepositoryProvider).riwayatHonor(tentorId),
    );

final urlFotoProvider = FutureProvider.family<String?, String>(
  (ref, path) => ref.watch(tentorRepositoryProvider).urlFoto(path),
);

/// Segarkan semua data tentor setelah ada perubahan.
void segarkanDataTentor(WidgetRef ref) {
  ref
    ..invalidate(daftarTentorProvider)
    ..invalidate(kehadiranBulanProvider)
    ..invalidate(riwayatHonorProvider);
}
