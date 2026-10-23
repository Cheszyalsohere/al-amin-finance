import 'dart:typed_data';

import 'package:al_amin_finance/features/siswa/siswa.dart';
import 'package:al_amin_finance/features/siswa/siswa_repository.dart';
import 'package:al_amin_finance/features/tentor/tentor.dart';
import 'package:al_amin_finance/features/tentor/tentor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kehadiran.dariMap membaca sesi, status bayar, dan foto', () {
    final k = Kehadiran.dariMap({
      'id': 'k1',
      'tentor_id': 't1',
      'waktu_datang': '2026-10-20T08:50:00+00:00',
      'foto_path': 't1/123.jpg',
      'foto_dihapus_pada': null,
      'sesi_mengajar': [
        {
          'id': 's1',
          'program': 'sma',
          'mapel': 'Fisika',
          'tarif': 65000,
          'pembayaran_honor_id': 'h1',
        },
        {
          'id': 's2',
          'program': 'smp',
          'mapel': 'Fisika',
          'tarif': 65000,
          'pembayaran_honor_id': null,
        },
      ],
    });

    expect(k.fotoPath, 't1/123.jpg');
    expect(k.honor, 130000);
    expect(k.sudahDibayar, isFalse);
    expect(k.sesiBelumDibayar.map((s) => s.id), ['s2']);
    expect(k.sesi.first.program, Program.sma);
  });

  test('foto yang sudah dihapus tidak punya path', () {
    final k = Kehadiran.dariMap({
      'id': 'k1',
      'tentor_id': 't1',
      'waktu_datang': '2026-04-01T08:00:00+00:00',
      'foto_path': 't1/lama.jpg',
      'foto_dihapus_pada': '2026-10-01T00:00:00+00:00',
      'sesi_mengajar': [],
    });
    expect(k.fotoPath, isNull);
  });

  group('TentorRepositoryContoh', () {
    late TentorRepositoryContoh repo;
    setUp(() => repo = TentorRepositoryContoh());

    test('catat kehadiran lalu bayar honor bulan itu', () async {
      final id = await repo.simpanTentor(
        const DataTentor(
          nama: 'Kak Uji',
          noHp: '',
          mapel: 'Kimia',
          tarifPerSesi: 70000,
        ),
      );
      final path = await repo.unggahFoto(id, Uint8List(0));
      await repo.catatKehadiran(
        tentorId: id,
        fotoPath: path,
        sesi: const [
          (program: Program.sma, mapel: 'Kimia'),
          (program: Program.smp, mapel: 'IPA'),
        ],
      );

      final sekarang = DateTime.now();
      final honor = await repo.bayarHonor(
        tentorId: id,
        periode: sekarang,
        metode: Metode.tunai,
      );
      expect(honor.jumlahSesi, 2);
      expect(honor.total, 140000);

      // Membayar lagi bulan yang sama ditolak karena tidak ada sesi tersisa.
      expect(
        () => repo.bayarHonor(
          tentorId: id,
          periode: sekarang,
          metode: Metode.tunai,
        ),
        throwsA(isA<GagalSimpan>()),
      );

      final hadir = await repo.kehadiranBulan(sekarang);
      expect(hadir.where((k) => k.tentorId == id).single.sudahDibayar, isTrue);
    });

    test('ubah tarif tidak mengubah sesi lama', () async {
      final id = await repo.simpanTentor(
        const DataTentor(nama: 'A', noHp: '', mapel: 'M', tarifPerSesi: 50000),
      );
      await repo.catatKehadiran(
        tentorId: id,
        fotoPath: 'x',
        sesi: const [(program: Program.sma, mapel: 'M')],
      );
      await repo.simpanTentor(
        DataTentor(
          id: id,
          nama: 'A',
          noHp: '',
          mapel: 'M',
          tarifPerSesi: 90000,
        ),
      );
      final hadir = await repo.kehadiranBulan(DateTime.now());
      expect(hadir.where((k) => k.tentorId == id).single.honor, 50000);
    });
  });
}
