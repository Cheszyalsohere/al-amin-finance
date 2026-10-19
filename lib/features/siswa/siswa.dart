/// Model siswa, tagihan, dan pembayaran beserta aturan biaya bimbel.
library;

enum Program {
  smp,
  sma;

  static Program dariKode(String kode) =>
      values.firstWhere((p) => p.name == kode);
}

extension ProgramLabel on Program {
  String get label => name.toUpperCase();
}

enum Keringanan {
  reguler('reguler', 'Reguler', 0, adminGratis: false),
  yatimPiatu('yatim_piatu', 'Yatim/piatu', 50, adminGratis: false),
  tidakMampu('tidak_mampu', 'Tidak mampu', 100, adminGratis: true);

  const Keringanan(
    this.kode,
    this.label,
    this.persenPotongan, {
    required this.adminGratis,
  });

  static Keringanan dariKode(String kode) =>
      values.firstWhere((k) => k.kode == kode);

  /// Kode di database.
  final String kode;
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

/// Pengaturan biaya satu program pada tahun ajaran tertentu.
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

/// Tahun ajaran aktif beserta biaya tiap program.
class Aturan {
  const Aturan({
    required this.tahunAjaran,
    required this.batasCicilan,
    required this.biaya,
  });

  final String tahunAjaran;
  final DateTime batasCicilan;
  final Map<Program, AturanBiaya> biaya;
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

  factory Pembayaran.dariMap(Map<String, dynamic> m) => Pembayaran(
    id: m['id'] as String,
    tanggal: DateTime.parse(m['dibayar_pada'] as String).toLocal(),
    jumlah: m['jumlah'] as int,
    metode: Metode.values.byName(m['metode'] as String),
    noKuitansi: m['no_kuitansi'] as String,
    keterangan: m['keterangan'] as String?,
  );
}

class Tagihan {
  const Tagihan({
    this.id = '',
    required this.skema,
    required this.keringanan,
    required this.rincian,
    required this.batasPelunasan,
    required this.pembayaran,
  });

  factory Tagihan.dariMap(Map<String, dynamic> m) => Tagihan(
    id: m['id'] as String,
    skema: Skema.values.byName(m['skema'] as String),
    keringanan: Keringanan.dariKode(m['keringanan'] as String),
    rincian: RincianTagihan(
      biayaPokok: m['biaya_pokok'] as int,
      potongan: m['potongan'] as int,
      biayaAdmin: m['biaya_admin'] as int,
      pembayaranPertama: m['pembayaran_pertama'] as int,
    ),
    batasPelunasan: DateTime.parse(m['batas_pelunasan'] as String),
    pembayaran: [
      for (final p in (m['pembayaran'] as List? ?? const []))
        if (p['dibatalkan'] != true)
          Pembayaran.dariMap(p as Map<String, dynamic>),
    ]..sort((a, b) => a.tanggal.compareTo(b.tanggal)),
  );

  final String id;
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

  /// Baris `siswa` dengan satu tagihan tertanam (tahun ajaran aktif).
  factory Siswa.dariMap(Map<String, dynamic> m) {
    final t = (m['tagihan'] as List).first as Map<String, dynamic>;
    return Siswa(
      id: m['id'] as String,
      nama: m['nama'] as String,
      program: Program.dariKode((t['program'] as Map)['kode'] as String),
      kelas: m['kelas'] as String,
      asalSekolah: m['asal_sekolah'] as String? ?? '',
      namaWali: m['nama_wali'] as String,
      noHpWali: m['no_hp_wali'] as String,
      tagihan: Tagihan.dariMap(t),
    );
  }
}
