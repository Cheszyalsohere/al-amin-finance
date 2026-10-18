import '../kas/pengeluaran.dart';
import '../siswa/siswa.dart';

bool _bulanSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

class Transaksi {
  const Transaksi({
    required this.tanggal,
    required this.judul,
    required this.keterangan,
    required this.jumlah,
    required this.masuk,
    this.siswaId,
    this.pembayaranId,
    this.pengeluaran,
  });

  final DateTime tanggal;
  final String judul;
  final String keterangan;
  final int jumlah;
  final bool masuk;

  /// Untuk pemasukan: pembayaran siswa yang bisa dibuka kuitansinya.
  final String? siswaId;
  final String? pembayaranId;

  /// Untuk pengeluaran: data pengeluarannya.
  final Pengeluaran? pengeluaran;
}

class Ringkasan {
  Ringkasan({
    required List<Siswa> siswa,
    required List<Pengeluaran> pengeluaran,
    required List<KategoriPengeluaran> kategori,
    required this.bulan,
    required this.hariIni,
  }) : _siswa = siswa,
       _pengeluaran = pengeluaran,
       _kategori = {for (final k in kategori) k.id: k};

  final List<Siswa> _siswa;
  final List<Pengeluaran> _pengeluaran;
  final Map<String, KategoriPengeluaran> _kategori;
  final DateTime bulan;
  final DateTime hariIni;

  Iterable<(Siswa, Pembayaran)> get _pembayaranBulanIni => [
    for (final s in _siswa)
      for (final p in s.tagihan.pembayaran)
        if (_bulanSama(p.tanggal, bulan)) (s, p),
  ];

  Iterable<Pengeluaran> get pengeluaranBulanIni =>
      _pengeluaran.where((e) => _bulanSama(e.tanggal, bulan));

  int get pemasukan => _pembayaranBulanIni.fold(0, (a, e) => a + e.$2.jumlah);

  int get pengeluaran => pengeluaranBulanIni.fold(0, (a, e) => a + e.jumlah);

  int get saldo => pemasukan - pengeluaran;

  KategoriPengeluaran kategori(String id) =>
      _kategori[id] ??
      KategoriPengeluaran(id: id, nama: 'Tanpa kategori', kodeIkon: 'lainnya');

  Map<KategoriPengeluaran, int> get perKategori {
    final hasil = <KategoriPengeluaran, int>{};
    for (final e in pengeluaranBulanIni) {
      hasil.update(
        kategori(e.kategoriId),
        (v) => v + e.jumlah,
        ifAbsent: () => e.jumlah,
      );
    }
    return Map.fromEntries(
      hasil.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  List<Siswa> get menunggak =>
      _siswa.where((s) => s.tagihan.sisa > 0).toList()
        ..sort((a, b) => b.tagihan.sisa.compareTo(a.tagihan.sisa));

  int get totalTunggakan => menunggak.fold(0, (a, s) => a + s.tagihan.sisa);

  List<Transaksi> get transaksi => [
    for (final (s, p) in _pembayaranBulanIni)
      Transaksi(
        tanggal: p.tanggal,
        judul: s.nama,
        keterangan: 'Pembayaran · ${p.metode.label}',
        jumlah: p.jumlah,
        masuk: true,
        siswaId: s.id,
        pembayaranId: p.id,
      ),
    for (final e in pengeluaranBulanIni)
      Transaksi(
        tanggal: e.tanggal,
        judul: e.keterangan,
        keterangan: kategori(e.kategoriId).nama,
        jumlah: e.jumlah,
        masuk: false,
        pengeluaran: e,
      ),
  ]..sort((a, b) => b.tanggal.compareTo(a.tanggal));
}
