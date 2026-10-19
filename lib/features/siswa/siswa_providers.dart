import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/env.dart';
import '../../core/supabase_provider.dart';
import '../kas/kategori_provider.dart';
import '../laporan/ringkasan.dart';
import 'siswa.dart';
import 'siswa_repository.dart';

final siswaRepositoryProvider = Provider<SiswaRepository>(
  (ref) => Env.pratinjau
      ? SiswaRepositoryContoh()
      : SiswaRepositorySupabase(ref.watch(supabaseClientProvider)),
);

/// Tanggal hari ini; mode contoh memakai tanggal tetap supaya angka konsisten.
final hariIniProvider = Provider<DateTime>(
  (ref) => Env.pratinjau ? hariIniContoh : DateTime.now(),
);

final aturanProvider = FutureProvider<Aturan>(
  (ref) => ref.watch(siswaRepositoryProvider).aturan(),
);

final daftarSiswaProvider = FutureProvider<List<Siswa>>(
  (ref) => ref.watch(siswaRepositoryProvider).daftarSiswa(),
);

/// Ringkasan keuangan satu bulan. Pengeluaran baru tersambung di Tahap 6,
/// jadi di luar mode contoh daftarnya masih kosong.
final ringkasanProvider = Provider.family<AsyncValue<Ringkasan>, DateTime>((
  ref,
  bulan,
) {
  final kategori = ref.watch(kategoriProvider);
  final hariIni = ref.watch(hariIniProvider);
  return ref
      .watch(daftarSiswaProvider)
      .whenData(
        (siswa) => Ringkasan(
          siswa: siswa,
          pengeluaran: Env.pratinjau ? DataContoh.pengeluaran : const [],
          kategori: kategori,
          bulan: bulan,
          hariIni: hariIni,
        ),
      );
});

/// Ringkasan bulan berjalan.
final ringkasanBulanIniProvider = Provider<AsyncValue<Ringkasan>>((ref) {
  final h = ref.watch(hariIniProvider);
  return ref.watch(ringkasanProvider(DateTime(h.year, h.month)));
});

/// Satu siswa berdasarkan id (null jika tidak ada).
final siswaProvider = Provider.family<AsyncValue<Siswa?>, String>(
  (ref, id) => ref
      .watch(daftarSiswaProvider)
      .whenData((daftar) => daftar.where((s) => s.id == id).firstOrNull),
);
