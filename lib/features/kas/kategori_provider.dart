import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contoh/data_contoh.dart';
import 'pengeluaran.dart';

/// Daftar kategori pengeluaran. Di tahap desain disimpan di memori
/// (hilang saat aplikasi ditutup); mulai Tahap 6 disimpan di Supabase.
final kategoriProvider =
    NotifierProvider<KategoriNotifier, List<KategoriPengeluaran>>(
      KategoriNotifier.new,
    );

class KategoriNotifier extends Notifier<List<KategoriPengeluaran>> {
  @override
  List<KategoriPengeluaran> build() => DataContoh.kategori;

  KategoriPengeluaran denganId(String id) => state.firstWhere(
    (k) => k.id == id,
    orElse: () => KategoriPengeluaran(id: id, nama: id, kodeIkon: 'lainnya'),
  );

  /// Pesan galat untuk nama kategori, atau null jika valid.
  String? validasiNama(String nama, {String? kecualiId}) {
    final bersih = nama.trim();
    if (bersih.isEmpty) return 'Nama kategori wajib diisi';
    if (bersih.length > 30) return 'Maksimal 30 karakter';
    final kembar = state.any(
      (k) => k.id != kecualiId && k.nama.toLowerCase() == bersih.toLowerCase(),
    );
    return kembar ? 'Kategori "$bersih" sudah ada' : null;
  }

  void tambah({required String nama, required String kodeIkon}) {
    state = [
      ...state,
      KategoriPengeluaran(
        id: 'k${DateTime.now().microsecondsSinceEpoch}',
        nama: nama.trim(),
        kodeIkon: kodeIkon,
      ),
    ];
  }

  void ubah(String id, {required String nama, required String kodeIkon}) {
    state = [
      for (final k in state)
        k.id == id ? k.copyWith(nama: nama.trim(), kodeIkon: kodeIkon) : k,
    ];
  }

  void aturArsip(String id, {required bool diarsipkan}) {
    state = [
      for (final k in state)
        k.id == id && !k.otomatis ? k.copyWith(diarsipkan: diarsipkan) : k,
    ];
  }
}
