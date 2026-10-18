import 'package:flutter/material.dart';

/// Ikon yang bisa dipilih untuk kategori pengeluaran.
const ikonKategori = <String, IconData>{
  'honor': Icons.co_present_outlined,
  'gaji': Icons.badge_outlined,
  'sewa': Icons.home_work_outlined,
  'listrik': Icons.bolt_outlined,
  'air': Icons.water_drop_outlined,
  'atk': Icons.edit_outlined,
  'fotokopi': Icons.print_outlined,
  'konsumsi': Icons.restaurant_outlined,
  'kebersihan': Icons.cleaning_services_outlined,
  'transport': Icons.directions_car_outlined,
  'internet': Icons.wifi,
  'perbaikan': Icons.build_outlined,
  'promosi': Icons.campaign_outlined,
  'lainnya': Icons.more_horiz,
};

/// ID kategori yang diisi otomatis oleh aplikasi (tidak bisa dipilih manual
/// dan tidak bisa diarsipkan).
abstract final class KategoriOtomatis {
  static const honor = 'honor';
  static const gajiAdmin = 'gaji-admin';
}

class KategoriPengeluaran {
  const KategoriPengeluaran({
    required this.id,
    required this.nama,
    required this.kodeIkon,
    this.otomatis = false,
    this.diarsipkan = false,
  });

  final String id;
  final String nama;
  final String kodeIkon;

  /// Dicatat otomatis dari bayar honor / gaji admin.
  final bool otomatis;

  /// Disembunyikan dari pilihan saat mencatat, tapi riwayatnya tetap ada.
  final bool diarsipkan;

  IconData get ikon => ikonKategori[kodeIkon] ?? Icons.more_horiz;

  KategoriPengeluaran copyWith({
    String? nama,
    String? kodeIkon,
    bool? diarsipkan,
  }) => KategoriPengeluaran(
    id: id,
    nama: nama ?? this.nama,
    kodeIkon: kodeIkon ?? this.kodeIkon,
    otomatis: otomatis,
    diarsipkan: diarsipkan ?? this.diarsipkan,
  );
}

class Pengeluaran {
  const Pengeluaran({
    required this.id,
    required this.tanggal,
    required this.kategoriId,
    required this.jumlah,
    required this.keterangan,
    this.dicatatOleh = 'Admin',
  });

  final String id;

  /// Tanggal dan jam pengeluaran.
  final DateTime tanggal;
  final String kategoriId;
  final int jumlah;
  final String keterangan;
  final String dicatatOleh;
}
