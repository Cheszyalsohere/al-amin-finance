import 'package:al_amin_finance/features/siswa/siswa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aturan = AturanBiaya(
    biayaProgram: 2800000,
    uangMuka: 1500000,
    biayaAdmin: 50000,
    batasCicilan: DateTime(2026, 12, 31),
  );

  group('hitungTagihan', () {
    test('reguler lunas: 2.800.000 + admin 50.000', () {
      final r = hitungTagihan(aturan, Keringanan.reguler, Skema.lunas);
      expect(r.total, 2850000);
      expect(r.pembayaranPertama, 2850000);
    });

    test('reguler cicilan: uang muka 1.500.000 + admin', () {
      final r = hitungTagihan(aturan, Keringanan.reguler, Skema.cicilan);
      expect(r.total, 2850000);
      expect(r.pembayaranPertama, 1550000);
    });

    test('yatim/piatu: potongan 50%, admin tetap, uang muka 750.000', () {
      final r = hitungTagihan(aturan, Keringanan.yatimPiatu, Skema.cicilan);
      expect(r.potongan, 1400000);
      expect(r.biayaAdmin, 50000);
      expect(r.total, 1450000);
      expect(r.pembayaranPertama, 800000);
    });

    test('tidak mampu: gratis termasuk admin', () {
      final r = hitungTagihan(aturan, Keringanan.tidakMampu, Skema.cicilan);
      expect(r.total, 0);
      expect(r.gratis, isTrue);
      expect(r.pembayaranPertama, 0);
    });
  });

  group('status tagihan', () {
    Tagihan tagihan(List<int> bayar, {Keringanan k = Keringanan.reguler}) =>
        Tagihan(
          skema: Skema.cicilan,
          keringanan: k,
          rincian: hitungTagihan(aturan, k, Skema.cicilan),
          batasPelunasan: aturan.batasCicilan,
          pembayaran: [
            for (final (i, j) in bayar.indexed)
              Pembayaran(
                id: '$i',
                tanggal: DateTime(2026, 8),
                jumlah: j,
                metode: Metode.tunai,
                noKuitansi: 'KW$i',
              ),
          ],
        );

    final oktober = DateTime(2026, 10, 18);
    final januari = DateTime(2027, 1, 2);

    test('belum bayar sama sekali', () {
      expect(tagihan([]).status(oktober), StatusTagihan.belumBayar);
    });

    test('sudah bayar sebagian', () {
      final t = tagihan([1550000]);
      expect(t.status(oktober), StatusTagihan.cicilan);
      expect(t.sisa, 1300000);
    });

    test('lunas', () {
      expect(tagihan([1550000, 1300000]).status(oktober), StatusTagihan.lunas);
    });

    test('lewat 31 Desember dan masih ada sisa → terlambat', () {
      expect(tagihan([1550000]).status(januari), StatusTagihan.terlambat);
    });

    test('31 Desember masih belum terlambat', () {
      expect(
        tagihan([1550000]).status(DateTime(2026, 12, 31, 20)),
        StatusTagihan.cicilan,
      );
    });

    test('siswa gratis langsung lunas', () {
      expect(
        tagihan([], k: Keringanan.tidakMampu).status(oktober),
        StatusTagihan.lunas,
      );
    });
  });
}
