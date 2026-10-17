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
  });

  final String id;
  final String nama;
  final String noHp;
  final String mapel;
  final int tarifPerSesi;
}

class Sesi {
  const Sesi({
    required this.id,
    required this.program,
    required this.mapel,
    required this.tarif,
  });

  final String id;
  final Program program;
  final String mapel;

  /// Salinan tarif tentor saat sesi dicatat.
  final int tarif;
}

class Kehadiran {
  const Kehadiran({
    required this.id,
    required this.tentorId,
    required this.waktuDatang,
    required this.sesi,
    this.sudahDibayar = false,
  });

  final String id;
  final String tentorId;
  final DateTime waktuDatang;
  final List<Sesi> sesi;
  final bool sudahDibayar;

  int get honor => sesi.fold(0, (a, s) => a + s.tarif);
}

class PembayaranHonor {
  const PembayaranHonor({
    required this.id,
    required this.tentorId,
    required this.periode,
    required this.jumlahSesi,
    required this.total,
    required this.tanggalBayar,
  });

  final String id;
  final String tentorId;
  final DateTime periode;
  final int jumlahSesi;
  final int total;
  final DateTime tanggalBayar;
}
