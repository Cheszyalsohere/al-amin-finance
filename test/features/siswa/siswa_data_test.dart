import 'package:al_amin_finance/features/siswa/siswa.dart';
import 'package:al_amin_finance/features/siswa/siswa_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Siswa.dariMap (bentuk data dari Supabase)', () {
    final baris = <String, dynamic>{
      'id': 'a1',
      'nama': 'Budi',
      'kelas': '9A',
      'asal_sekolah': null,
      'nama_wali': 'Pak Budi',
      'no_hp_wali': '0811',
      'tagihan': [
        {
          'id': 't1',
          'skema': 'cicilan',
          'keringanan': 'yatim_piatu',
          'persen_potongan': 50,
          'biaya_pokok': 2800000,
          'potongan': 1400000,
          'biaya_admin': 50000,
          'pembayaran_pertama': 800000,
          'batas_pelunasan': '2026-12-31',
          'tahun_ajaran_id': 1,
          'program': {'kode': 'smp'},
          'pembayaran': [
            {
              'id': 'p2',
              'dibayar_pada': '2026-10-05T03:15:00+00:00',
              'jumlah': 200000,
              'metode': 'transfer',
              'no_kuitansi': 'KW/2026/10/00002',
              'keterangan': null,
              'dibatalkan': false,
            },
            {
              'id': 'p1',
              'dibayar_pada': '2026-07-20T03:15:00+00:00',
              'jumlah': 800000,
              'metode': 'tunai',
              'no_kuitansi': 'KW/2026/07/00001',
              'keterangan': 'DP',
              'dibatalkan': false,
            },
            {
              'id': 'p3',
              'dibayar_pada': '2026-10-06T03:15:00+00:00',
              'jumlah': 100000,
              'metode': 'tunai',
              'no_kuitansi': 'KW/2026/10/00003',
              'keterangan': null,
              'dibatalkan': true,
            },
          ],
        },
      ],
    };

    test('membaca siswa, tagihan, dan pembayaran', () {
      final s = Siswa.dariMap(baris);

      expect(s.program, Program.smp);
      expect(s.asalSekolah, '');
      expect(s.tagihan.id, 't1');
      expect(s.tagihan.keringanan, Keringanan.yatimPiatu);
      expect(s.tagihan.skema, Skema.cicilan);
      expect(s.tagihan.total, 1450000);
    });

    test('pembayaran dibatalkan diabaikan dan urut dari terlama', () {
      final t = Siswa.dariMap(baris).tagihan;

      expect(t.pembayaran.map((p) => p.id), ['p1', 'p2']);
      expect(t.dibayar, 1000000);
      expect(t.sisa, 450000);
      expect(t.pembayaran.first.metode, Metode.tunai);
    });
  });

  group('SiswaRepositoryContoh (aturan sama dengan server)', () {
    late SiswaRepositoryContoh repo;

    setUp(() => repo = SiswaRepositoryContoh());

    Future<Siswa> daftar(Keringanan k, Skema s) async {
      final id = await repo.daftarkan(
        DataSiswaBaru(
          nama: 'Uji',
          kelas: '9',
          asalSekolah: '',
          namaWali: 'Wali',
          noHpWali: '1',
          program: Program.smp,
          keringanan: k,
          skema: s,
        ),
      );
      return (await repo.daftarSiswa()).firstWhere((x) => x.id == id);
    }

    test('siswa tidak mampu langsung lunas', () async {
      final s = await daftar(Keringanan.tidakMampu, Skema.cicilan);
      expect(s.tagihan.total, 0);
      expect(s.tagihan.skema, Skema.lunas);
    });

    test('pembayaran pertama di bawah uang muka ditolak', () async {
      final s = await daftar(Keringanan.reguler, Skema.cicilan);
      expect(
        () => repo.catatPembayaran(
          tagihanId: s.tagihan.id,
          jumlah: 1000000,
          metode: Metode.tunai,
        ),
        throwsA(isA<GagalSimpan>()),
      );
    });

    test(
      'nominal melebihi sisa ditolak, cicilan berikutnya diterima',
      () async {
        final s = await daftar(Keringanan.reguler, Skema.cicilan);
        await repo.catatPembayaran(
          tagihanId: s.tagihan.id,
          jumlah: 1550000,
          metode: Metode.tunai,
        );

        expect(
          () => repo.catatPembayaran(
            tagihanId: s.tagihan.id,
            jumlah: 1300001,
            metode: Metode.tunai,
          ),
          throwsA(isA<GagalSimpan>()),
        );

        final p = await repo.catatPembayaran(
          tagihanId: s.tagihan.id,
          jumlah: 300000,
          metode: Metode.transfer,
        );
        expect(p.noKuitansi, startsWith('KW/'));

        final terbaru = (await repo.daftarSiswa()).firstWhere(
          (x) => x.id == s.id,
        );
        expect(terbaru.tagihan.sisa, 1000000);
      },
    );
  });
}
