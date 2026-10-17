/// Model siswa, tagihan, dan pembayaran beserta aturan biaya bimbel.
library;

enum Program { smp, sma }

extension ProgramLabel on Program {
  String get label => name.toUpperCase();
}

enum Keringanan {
  reguler('Reguler', 0, adminGratis: false),
  yatimPiatu('Yatim/piatu', 50, adminGratis: false),
  tidakMampu('Tidak mampu', 100, adminGratis: true);

  const Keringanan(
    this.label,
    this.persenPotongan, {
    required this.adminGratis,
  });

  final String label;
  final int persenPotongan;
  final bool adminGratis;
}

enum Skema {
  lunas('Lunas di awal'),
  cicilan('Cicilan');

  const Skema(this.label);

  final String label;
}

/// Pengaturan biaya per tahun ajaran (nanti diambil dari database).
class AturanBiaya {
  const AturanBiaya({
    required this.biayaProgram,
    required this.uangMuka,
    required this.biayaAdmin,
    required this.batasCicilan,
  });

  final int biayaProgram;
  final int uangMuka;
  final int biayaAdmin;
  final DateTime batasCicilan;
}

class RincianTagihan {
  const RincianTagihan({
    required this.biayaPokok,
    required this.potongan,
    required this.biayaAdmin,
    required this.pembayaranPertama,
  });

  final int biayaPokok;
  final int potongan;
  final int biayaAdmin;

  /// Minimal yang dibayar saat mendaftar: lunas penuh, atau uang muka + admin.
  final int pembayaranPertama;

  int get total => biayaPokok - potongan + biayaAdmin;
  bool get gratis => total == 0;
}

RincianTagihan hitungTagihan(
  AturanBiaya aturan,
  Keringanan keringanan,
  Skema skema,
) {
  final persen = keringanan.persenPotongan;
  final potongan = aturan.biayaProgram * persen ~/ 100;
  final admin = keringanan.adminGratis ? 0 : aturan.biayaAdmin;
  final total = aturan.biayaProgram - potongan + admin;
  final uangMuka = aturan.uangMuka * (100 - persen) ~/ 100;

  return RincianTagihan(
    biayaPokok: aturan.biayaProgram,
    potongan: potongan,
    biayaAdmin: admin,
    pembayaranPertama: skema == Skema.lunas || total == 0
        ? total
        : uangMuka + admin,
  );
}

enum StatusTagihan {
  lunas('Lunas'),
  cicilan('Cicilan'),
  belumBayar('Belum bayar'),
  terlambat('Terlambat');

  const StatusTagihan(this.label);

  final String label;
}

enum Metode {
  tunai('Tunai'),
  transfer('Transfer');

  const Metode(this.label);

  final String label;
}

class Pembayaran {
  const Pembayaran({
    required this.id,
    required this.tanggal,
    required this.jumlah,
    required this.metode,
    required this.noKuitansi,
    this.keterangan,
  });

  final String id;
  final DateTime tanggal;
  final int jumlah;
  final Metode metode;
  final String noKuitansi;
  final String? keterangan;
}

class Tagihan {
  const Tagihan({
    required this.skema,
    required this.keringanan,
    required this.rincian,
    required this.batasPelunasan,
    required this.pembayaran,
  });

  final Skema skema;
  final Keringanan keringanan;
  final RincianTagihan rincian;
  final DateTime batasPelunasan;
  final List<Pembayaran> pembayaran;

  int get total => rincian.total;
  int get dibayar => pembayaran.fold(0, (a, p) => a + p.jumlah);
  int get sisa => (total - dibayar).clamp(0, total);
  double get progres => total == 0 ? 1 : (dibayar / total).clamp(0, 1);

  StatusTagihan status(DateTime hariIni) {
    if (sisa == 0) return StatusTagihan.lunas;
    final hari = DateTime(hariIni.year, hariIni.month, hariIni.day);
    if (hari.isAfter(batasPelunasan)) return StatusTagihan.terlambat;
    if (dibayar == 0) return StatusTagihan.belumBayar;
    return StatusTagihan.cicilan;
  }
}

class Siswa {
  const Siswa({
    required this.id,
    required this.nama,
    required this.program,
    required this.kelas,
    required this.asalSekolah,
    required this.namaWali,
    required this.noHpWali,
    required this.tagihan,
  });

  final String id;
  final String nama;
  final Program program;
  final String kelas;
  final String asalSekolah;
  final String namaWali;
  final String noHpWali;
  final Tagihan tagihan;
}
