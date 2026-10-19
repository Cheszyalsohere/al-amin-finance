import 'package:supabase_flutter/supabase_flutter.dart';

import '../../contoh/data_contoh.dart';
import 'siswa.dart';

/// Galat yang pesannya aman ditampilkan ke pengguna.
class GagalSimpan implements Exception {
  const GagalSimpan(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

class DataSiswaBaru {
  const DataSiswaBaru({
    required this.nama,
    required this.kelas,
    required this.asalSekolah,
    required this.namaWali,
    required this.noHpWali,
    required this.program,
    required this.keringanan,
    required this.skema,
  });

  final String nama;
  final String kelas;
  final String asalSekolah;
  final String namaWali;
  final String noHpWali;
  final Program program;
  final Keringanan keringanan;
  final Skema skema;
}

abstract interface class SiswaRepository {
  Future<Aturan> aturan();

  /// Siswa aktif beserta tagihan tahun ajaran aktif.
  Future<List<Siswa>> daftarSiswa();

  /// Mengembalikan id siswa baru.
  Future<String> daftarkan(DataSiswaBaru data);

  Future<Pembayaran> catatPembayaran({
    required String tagihanId,
    required int jumlah,
    required Metode metode,
    String? keterangan,
  });
}

class SiswaRepositorySupabase implements SiswaRepository {
  SiswaRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _kolomSiswa =
      'id, nama, kelas, asal_sekolah, nama_wali, no_hp_wali, '
      'tagihan!inner(id, skema, keringanan, persen_potongan, biaya_pokok, '
      'potongan, biaya_admin, pembayaran_pertama, batas_pelunasan, '
      'tahun_ajaran_id, program(kode), '
      'pembayaran(id, dibayar_pada, jumlah, metode, no_kuitansi, '
      'keterangan, dibatalkan))';

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on PostgrestException catch (e) {
      throw GagalSimpan(e.message);
    } on AuthException catch (e) {
      throw GagalSimpan(e.message);
    } on Exception {
      throw const GagalSimpan(
        'Tidak bisa terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<Map<String, dynamic>> _tahunAjaranAktif() async {
    final ta = await _client
        .from('tahun_ajaran')
        .select('id, nama, batas_cicilan')
        .eq('aktif', true)
        .maybeSingle();
    if (ta == null) {
      throw const GagalSimpan(
        'Belum ada tahun ajaran aktif. Minta owner mengaturnya.',
      );
    }
    return ta;
  }

  @override
  Future<Aturan> aturan() => _jalankan(() async {
    final ta = await _tahunAjaranAktif();
    final batas = DateTime.parse(ta['batas_cicilan'] as String);
    final program = await _client
        .from('program')
        .select('kode, biaya, uang_muka, biaya_admin')
        .eq('tahun_ajaran_id', ta['id'] as int);

    return Aturan(
      tahunAjaran: ta['nama'] as String,
      batasCicilan: batas,
      biaya: {
        for (final p in program)
          Program.dariKode(p['kode'] as String): AturanBiaya(
            biayaProgram: p['biaya'] as int,
            uangMuka: p['uang_muka'] as int,
            biayaAdmin: p['biaya_admin'] as int,
            batasCicilan: batas,
          ),
      },
    );
  });

  @override
  Future<List<Siswa>> daftarSiswa() => _jalankan(() async {
    final ta = await _tahunAjaranAktif();
    final baris = await _client
        .from('siswa')
        .select(_kolomSiswa)
        .eq('aktif', true)
        .eq('tagihan.tahun_ajaran_id', ta['id'] as int)
        .order('nama');
    return [for (final b in baris) Siswa.dariMap(b)];
  });

  @override
  Future<String> daftarkan(DataSiswaBaru d) => _jalankan(() async {
    final id = await _client.rpc<String>(
      'daftar_siswa',
      params: {
        'p_nama': d.nama,
        'p_kelas': d.kelas,
        'p_asal_sekolah': d.asalSekolah,
        'p_nama_wali': d.namaWali,
        'p_no_hp_wali': d.noHpWali,
        'p_program': d.program.name,
        'p_keringanan': d.keringanan.kode,
        'p_skema': d.skema.name,
      },
    );
    return id;
  });

  @override
  Future<Pembayaran> catatPembayaran({
    required String tagihanId,
    required int jumlah,
    required Metode metode,
    String? keterangan,
  }) => _jalankan(() async {
    final hasil = await _client.rpc<Map<String, dynamic>>(
      'catat_pembayaran',
      params: {
        'p_tagihan_id': tagihanId,
        'p_jumlah': jumlah,
        'p_metode': metode.name,
        'p_keterangan': keterangan,
      },
    );
    return Pembayaran.dariMap(hasil);
  });
}

/// Versi di memori untuk mode contoh; aturan sama dengan fungsi di server.
class SiswaRepositoryContoh implements SiswaRepository {
  final List<Siswa> _siswa = [
    for (final s in DataContoh.siswa) _gantiTagihan(s, id: 'tagihan-${s.id}'),
  ];
  var _nomor = 900;

  static Siswa _gantiTagihan(
    Siswa s, {
    String? id,
    List<Pembayaran>? pembayaran,
  }) {
    final t = s.tagihan;
    return Siswa(
      id: s.id,
      nama: s.nama,
      program: s.program,
      kelas: s.kelas,
      asalSekolah: s.asalSekolah,
      namaWali: s.namaWali,
      noHpWali: s.noHpWali,
      tagihan: Tagihan(
        id: id ?? t.id,
        skema: t.skema,
        keringanan: t.keringanan,
        rincian: t.rincian,
        batasPelunasan: t.batasPelunasan,
        pembayaran: pembayaran ?? t.pembayaran,
      ),
    );
  }

  @override
  Future<Aturan> aturan() async => Aturan(
    tahunAjaran: DataContoh.tahunAjaran,
    batasCicilan: DataContoh.aturan.batasCicilan,
    biaya: {for (final p in Program.values) p: DataContoh.aturan},
  );

  @override
  Future<List<Siswa>> daftarSiswa() async =>
      [..._siswa]..sort((a, b) => a.nama.compareTo(b.nama));

  @override
  Future<String> daftarkan(DataSiswaBaru d) async {
    final rincian = hitungTagihan(DataContoh.aturan, d.keringanan, d.skema);
    final id = 'baru-${_siswa.length}';
    _siswa.add(
      Siswa(
        id: id,
        nama: d.nama,
        program: d.program,
        kelas: d.kelas,
        asalSekolah: d.asalSekolah,
        namaWali: d.namaWali,
        noHpWali: d.noHpWali,
        tagihan: Tagihan(
          id: 'tagihan-$id',
          skema: rincian.gratis ? Skema.lunas : d.skema,
          keringanan: d.keringanan,
          rincian: rincian,
          batasPelunasan: DataContoh.aturan.batasCicilan,
          pembayaran: const [],
        ),
      ),
    );
    return id;
  }

  @override
  Future<Pembayaran> catatPembayaran({
    required String tagihanId,
    required int jumlah,
    required Metode metode,
    String? keterangan,
  }) async {
    final i = _siswa.indexWhere((s) => s.tagihan.id == tagihanId);
    if (i < 0) throw const GagalSimpan('Tagihan tidak ditemukan');
    final s = _siswa[i];
    final t = s.tagihan;

    if (jumlah > t.sisa) {
      throw GagalSimpan('Nominal melebihi sisa tagihan (${t.sisa})');
    }
    if (t.dibayar == 0 && jumlah < t.rincian.pembayaranPertama) {
      throw GagalSimpan(
        'Pembayaran pertama minimal ${t.rincian.pembayaranPertama}',
      );
    }

    final sekarang = DateTime.now();
    final baru = Pembayaran(
      id: 'bayar-${_nomor++}',
      tanggal: sekarang,
      jumlah: jumlah,
      metode: metode,
      noKuitansi:
          'KW/${sekarang.year}/${sekarang.month.toString().padLeft(2, '0')}/'
          '${_nomor.toString().padLeft(5, '0')}',
      keterangan: keterangan,
    );
    _siswa[i] = _gantiTagihan(s, pembayaran: [...t.pembayaran, baru]);
    return baru;
  }
}
