import 'package:flutter/material.dart';

enum KategoriPengeluaran {
  honor('Honor tentor', Icons.co_present_outlined),
  sewa('Sewa tempat', Icons.home_work_outlined),
  listrik('Listrik & air', Icons.bolt_outlined),
  atk('ATK', Icons.edit_outlined),
  fotokopi('Fotokopi', Icons.print_outlined),
  lainnya('Lainnya', Icons.more_horiz);

  const KategoriPengeluaran(this.label, this.ikon);

  final String label;
  final IconData ikon;
}

class Pengeluaran {
  const Pengeluaran({
    required this.id,
    required this.tanggal,
    required this.kategori,
    required this.jumlah,
    required this.keterangan,
  });

  final String id;
  final DateTime tanggal;
  final KategoriPengeluaran kategori;
  final int jumlah;
  final String keterangan;
}
