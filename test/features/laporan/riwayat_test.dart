import 'package:al_amin_finance/contoh/data_contoh.dart';
import 'package:al_amin_finance/features/laporan/riwayat_page.dart';
import 'package:al_amin_finance/features/laporan/ringkasan.dart';
import 'package:flutter_test/flutter_test.dart';

Transaksi _t(DateTime waktu, {bool masuk = true}) => Transaksi(
  tanggal: waktu,
  judul: 'x',
  keterangan: 'y',
  jumlah: 1000,
  masuk: masuk,
);

void main() {
  test('kelompokkan per hari, hari dan jam terbaru di atas', () {
    final hasil = kelompokkanPerHari([
      _t(DateTime(2026, 10, 3, 9)),
      _t(DateTime(2026, 10, 5, 8)),
      _t(DateTime(2026, 10, 3, 15)),
    ]);

    expect(hasil.map((e) => e.$1), [
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 3),
    ]);
    expect(hasil[1].$2.map((t) => t.tanggal.hour), [15, 9]);
  });

  test('transaksi membawa sumbernya untuk dibuka detailnya', () {
    final r = Ringkasan(
      siswa: DataContoh.siswa,
      pengeluaran: DataContoh.pengeluaran,
      kategori: DataContoh.kategori,
      bulan: DateTime(2026, 10),
      hariIni: DateTime(2026, 10, 18),
    );

    for (final t in r.transaksi) {
      if (t.masuk) {
        expect(t.siswaId, isNotNull);
        expect(t.pembayaranId, isNotNull);
      } else {
        expect(t.pengeluaran, isNotNull);
      }
    }
    expect(r.transaksi.where((t) => t.masuk), isNotEmpty);
    expect(r.transaksi.where((t) => !t.masuk), isNotEmpty);
  });
}
