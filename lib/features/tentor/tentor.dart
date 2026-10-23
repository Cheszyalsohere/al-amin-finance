/// Model tentor, kehadiran (absensi foto), sesi mengajar, dan honor.
library;

import '../siswa/siswa.dart';

class Tentor {
  const Tentor({
    required this.id,
    required this.nama,
    required this.noHp,
    required this.mapel,
    required this.tarifPerSesi,
    this.aktif = true,
  });

  factory Tentor.dariMap(Map<String, dynamic> m) => Tentor(
    id: m['id'] as String,
    nama: m['nama'] as String,
    noHp: m['no_hp'] as String? ?? '',
    mapel: m['mapel'] as String,
    tarifPerSesi: m['tarif_per_sesi'] as int,
    aktif: m['aktif'] as bool? ?? true,
  );

  final String id;
  final String nama;
  final String noHp;
  final String mapel;
  final int tarifPerSesi;
  final bool aktif;
}

class Sesi {
  const Sesi({
    required this.id,
    required this.program,
    required this.mapel,
    required this.tarif,
    this.dibayar = false,
  });

  factory Sesi.dariMap(Map<String, dynamic> m) => Sesi(
    id: m['id'] as String,
    program: Program.dariKode(m['program'] as String),
    mapel: m['mapel'] as String,
    tarif: m['tarif'] as int,
    dibayar: m['pembayaran_honor_id'] != null,
  );

  final String id;
  final Program program;
  final String mapel;

  /// Salinan tarif tentor saat sesi dicatat.
  final int tarif;

  /// Sudah masuk pembayaran honor.
  final bool dibayar;
}

class Kehadiran {
  const Kehadiran({
    required this.id,
    required this.tentorId,
    required this.waktuDatang,
    required this.sesi,
    this.fotoPath,
  });

  factory Kehadiran.dariMap(Map<String, dynamic> m) => Kehadiran(
    id: m['id'] as String,
    tentorId: m['tentor_id'] as String,
    waktuDatang: DateTime.parse(m['waktu_datang'] as String).toLocal(),
    fotoPath: m['foto_dihapus_pada'] == null ? m['foto_path'] as String? : null,
    sesi: [
      for (final s in (m['sesi_mengajar'] as List? ?? const []))
        Sesi.dariMap(s as Map<String, dynamic>),
    ],
  );

  final String id;
  final String tentorId;
  final DateTime waktuDatang;
  final List<Sesi> sesi;

  /// Path foto di bucket `kehadiran`; null untuk data contoh atau foto yang
  /// sudah dihapus otomatis.
  final String? fotoPath;

  int get honor => sesi.fold(0, (a, s) => a + s.tarif);
  bool get sudahDibayar => sesi.isNotEmpty && sesi.every((s) => s.dibayar);
  Iterable<Sesi> get sesiBelumDibayar => sesi.where((s) => !s.dibayar);
}

class PembayaranHonor {
  const PembayaranHonor({
    required this.id,
    required this.tentorId,
    required this.periode,
    required this.jumlahSesi,
    required this.total,
    required this.tanggalBayar,
    this.metode = Metode.transfer,
  });

  factory PembayaranHonor.dariMap(Map<String, dynamic> m) => PembayaranHonor(
    id: m['id'] as String,
    tentorId: m['tentor_id'] as String,
    periode: DateTime.parse(m['periode'] as String),
    jumlahSesi: m['jumlah_sesi'] as int,
    total: m['total'] as int,
    tanggalBayar: DateTime.parse(m['dibayar_pada'] as String).toLocal(),
    metode: Metode.values.byName(m['metode'] as String),
  );

  final String id;
  final String tentorId;
  final DateTime periode;
  final int jumlahSesi;
  final int total;
  final DateTime tanggalBayar;
  final Metode metode;
}
