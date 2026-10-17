import 'package:flutter/material.dart';

import 'data_contoh.dart';
import '../features/laporan/ringkasan.dart';

/// Tanggal "hari ini" untuk data contoh, supaya angka di layar konsisten.
final hariIniContoh = DateTime(2026, 10, 18);

Ringkasan ringkasanContoh([DateTime? bulan]) => Ringkasan(
  siswa: DataContoh.siswa,
  pengeluaran: DataContoh.pengeluaran,
  bulan: bulan ?? hariIniContoh,
  hariIni: hariIniContoh,
);

/// Pengganti aksi yang belum tersambung ke database.
void aksiContoh(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$pesan (contoh, belum tersimpan)')));
}
