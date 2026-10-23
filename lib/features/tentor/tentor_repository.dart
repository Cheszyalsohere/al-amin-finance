import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../contoh/data_contoh.dart';
import '../siswa/siswa.dart';
import '../siswa/siswa_repository.dart';
import 'tentor.dart';

class DataTentor {
  const DataTentor({
    this.id,
    required this.nama,
    required this.noHp,
    required this.mapel,
    required this.tarifPerSesi,
    this.aktif = true,
  });

  /// Null untuk tentor baru.
  final String? id;
  final String nama;
  final String noHp;
  final String mapel;
  final int tarifPerSesi;
  final bool aktif;
}

typedef SesiBaru = ({Program program, String mapel});

abstract interface class TentorRepository {
  Future<List<Tentor>> daftarTentor();

  /// Kehadiran semua tentor pada bulan [bulan] (tanggal mana saja di bulan itu).
  Future<List<Kehadiran>> kehadiranBulan(DateTime bulan);

  Future<List<PembayaranHonor>> riwayatHonor(String tentorId);

  Future<String> simpanTentor(DataTentor data);

  /// Jam server untuk cap waktu foto.
  Future<DateTime> waktuServer();

  /// Unggah foto JPEG, mengembalikan path di bucket.
  Future<String> unggahFoto(String tentorId, Uint8List jpeg);

  Future<void> catatKehadiran({
    required String tentorId,
    required String fotoPath,
    required List<SesiBaru> sesi,
  });

  Future<PembayaranHonor> bayarHonor({
    required String tentorId,
    required DateTime periode,
    required Metode metode,
  });

  /// Tautan sementara untuk menampilkan foto kehadiran.
  Future<String?> urlFoto(String fotoPath);
}

String _tanggalIso(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

class TentorRepositorySupabase implements TentorRepository {
  TentorRepositorySupabase(this._client);

  final SupabaseClient _client;
  static const _bucket = 'kehadiran';

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on PostgrestException catch (e) {
      throw GagalSimpan(e.message);
    } on StorageException catch (e) {
      throw GagalSimpan('Gagal mengunggah foto: ${e.message}');
    } on AuthException catch (e) {
      throw GagalSimpan(e.message);
    } on Exception {
      throw const GagalSimpan(
        'Tidak bisa terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  @override
  Future<List<Tentor>> daftarTentor() => _jalankan(() async {
    final baris = await _client
        .from('tentor')
        .select('id, nama, no_hp, mapel, tarif_per_sesi, aktif')
        .order('aktif', ascending: false)
        .order('nama');
    return [for (final b in baris) Tentor.dariMap(b)];
  });

  @override
  Future<List<Kehadiran>> kehadiranBulan(DateTime bulan) => _jalankan(() async {
    final awal = DateTime(bulan.year, bulan.month);
    final akhir = DateTime(bulan.year, bulan.month + 1);
    final baris = await _client
        .from('kehadiran_tentor')
        .select(
          'id, tentor_id, waktu_datang, foto_path, foto_dihapus_pada, '
          'sesi_mengajar(id, program, mapel, tarif, pembayaran_honor_id)',
        )
        .gte('waktu_datang', awal.toUtc().toIso8601String())
        .lt('waktu_datang', akhir.toUtc().toIso8601String())
        .order('waktu_datang');
    return [for (final b in baris) Kehadiran.dariMap(b)];
  });

  @override
  Future<List<PembayaranHonor>> riwayatHonor(String tentorId) => _jalankan(
    () async {
      final baris = await _client
          .from('pembayaran_honor')
          .select(
            'id, tentor_id, periode, jumlah_sesi, total, metode, dibayar_pada',
          )
          .eq('tentor_id', tentorId)
          .eq('dibatalkan', false)
          .order('periode', ascending: false);
      return [for (final b in baris) PembayaranHonor.dariMap(b)];
    },
  );

  @override
  Future<String> simpanTentor(DataTentor d) => _jalankan(
    () => _client.rpc<String>(
      'simpan_tentor',
      params: {
        'p_id': d.id,
        'p_nama': d.nama,
        'p_no_hp': d.noHp,
        'p_mapel': d.mapel,
        'p_tarif_per_sesi': d.tarifPerSesi,
        'p_aktif': d.aktif,
      },
    ),
  );

  @override
  Future<DateTime> waktuServer() => _jalankan(() async {
    final waktu = await _client.rpc<String>('waktu_server');
    return DateTime.parse(waktu).toLocal();
  });

  @override
  Future<String> unggahFoto(String tentorId, Uint8List jpeg) =>
      _jalankan(() async {
        final acak = Random.secure().nextInt(1 << 32).toRadixString(16);
        final path =
            '$tentorId/${DateTime.now().millisecondsSinceEpoch}-$acak.jpg';
        await _client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              jpeg,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        return path;
      });

  @override
  Future<void> catatKehadiran({
    required String tentorId,
    required String fotoPath,
    required List<SesiBaru> sesi,
  }) => _jalankan(
    () => _client.rpc<void>(
      'catat_kehadiran',
      params: {
        'p_tentor_id': tentorId,
        'p_foto_path': fotoPath,
        'p_sesi': [
          for (final s in sesi) {'program': s.program.name, 'mapel': s.mapel},
        ],
      },
    ),
  );

  @override
  Future<PembayaranHonor> bayarHonor({
    required String tentorId,
    required DateTime periode,
    required Metode metode,
  }) => _jalankan(() async {
    final hasil = await _client.rpc<Map<String, dynamic>>(
      'bayar_honor',
      params: {
        'p_tentor_id': tentorId,
        'p_periode': _tanggalIso(DateTime(periode.year, periode.month)),
        'p_metode': metode.name,
      },
    );
    return PembayaranHonor.dariMap(hasil);
  });

  @override
  Future<String?> urlFoto(String fotoPath) => _jalankan(
    () => _client.storage.from(_bucket).createSignedUrl(fotoPath, 60 * 10),
  );
}

/// Versi di memori untuk mode contoh.
class TentorRepositoryContoh implements TentorRepository {
  final List<Tentor> _tentor = [...DataContoh.tentor];
  final List<Kehadiran> _kehadiran = [...DataContoh.kehadiran];
  final List<PembayaranHonor> _honor = [...DataContoh.riwayatHonor];
  var _nomor = 0;

  @override
  Future<List<Tentor>> daftarTentor() async => [..._tentor];

  @override
  Future<List<Kehadiran>> kehadiranBulan(DateTime bulan) async => [
    for (final k in _kehadiran)
      if (k.waktuDatang.year == bulan.year &&
          k.waktuDatang.month == bulan.month)
        k,
  ];

  @override
  Future<List<PembayaranHonor>> riwayatHonor(String tentorId) async =>
      _honor.where((h) => h.tentorId == tentorId).toList()
        ..sort((a, b) => b.periode.compareTo(a.periode));

  @override
  Future<String> simpanTentor(DataTentor d) async {
    final id = d.id ?? 'tentor-baru-${_nomor++}';
    final baru = Tentor(
      id: id,
      nama: d.nama,
      noHp: d.noHp,
      mapel: d.mapel,
      tarifPerSesi: d.tarifPerSesi,
      aktif: d.aktif,
    );
    final i = _tentor.indexWhere((t) => t.id == id);
    if (i < 0) {
      _tentor.add(baru);
    } else {
      _tentor[i] = baru;
    }
    return id;
  }

  @override
  Future<DateTime> waktuServer() async => DateTime.now();

  @override
  Future<String> unggahFoto(String tentorId, Uint8List jpeg) async =>
      '$tentorId/contoh-${_nomor++}.jpg';

  @override
  Future<void> catatKehadiran({
    required String tentorId,
    required String fotoPath,
    required List<SesiBaru> sesi,
  }) async {
    if (sesi.isEmpty) throw const GagalSimpan('Minimal satu sesi');
    final t = _tentor.firstWhere((x) => x.id == tentorId);
    final id = 'hadir-${_nomor++}';
    _kehadiran.add(
      Kehadiran(
        id: id,
        tentorId: tentorId,
        waktuDatang: DateTime.now(),
        sesi: [
          for (final (i, s) in sesi.indexed)
            Sesi(
              id: '$id-$i',
              program: s.program,
              mapel: s.mapel,
              tarif: t.tarifPerSesi,
            ),
        ],
      ),
    );
  }

  @override
  Future<PembayaranHonor> bayarHonor({
    required String tentorId,
    required DateTime periode,
    required Metode metode,
  }) async {
    final belum = [
      for (final (i, k) in _kehadiran.indexed)
        if (k.tentorId == tentorId &&
            k.waktuDatang.year == periode.year &&
            k.waktuDatang.month == periode.month &&
            k.sesiBelumDibayar.isNotEmpty)
          (i, k),
    ];
    final sesi = [for (final (_, k) in belum) ...k.sesiBelumDibayar];
    if (sesi.isEmpty) {
      throw const GagalSimpan(
        'Tidak ada sesi yang belum dibayar pada periode ini',
      );
    }
    for (final (i, k) in belum) {
      _kehadiran[i] = Kehadiran(
        id: k.id,
        tentorId: k.tentorId,
        waktuDatang: k.waktuDatang,
        fotoPath: k.fotoPath,
        sesi: [
          for (final s in k.sesi)
            Sesi(
              id: s.id,
              program: s.program,
              mapel: s.mapel,
              tarif: s.tarif,
              dibayar: true,
            ),
        ],
      );
    }
    final honor = PembayaranHonor(
      id: 'honor-${_nomor++}',
      tentorId: tentorId,
      periode: DateTime(periode.year, periode.month),
      jumlahSesi: sesi.length,
      total: sesi.fold(0, (a, s) => a + s.tarif),
      tanggalBayar: DateTime.now(),
      metode: metode,
    );
    _honor.add(honor);
    return honor;
  }

  @override
  Future<String?> urlFoto(String fotoPath) async => null;
}
