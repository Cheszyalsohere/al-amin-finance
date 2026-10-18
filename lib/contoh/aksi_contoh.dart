import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/kas/kategori_provider.dart';

import 'data_contoh.dart';
import '../features/laporan/ringkasan.dart';

/// Tanggal "hari ini" untuk data contoh, supaya angka di layar konsisten.
final hariIniContoh = DateTime(2026, 10, 18);

Ringkasan ringkasanContoh(WidgetRef ref, [DateTime? bulan]) => Ringkasan(
  siswa: DataContoh.siswa,
  pengeluaran: DataContoh.pengeluaran,
  kategori: ref.watch(kategoriProvider),
  bulan: bulan ?? hariIniContoh,
  hariIni: hariIniContoh,
);

/// Pengganti aksi yang belum tersambung ke database.
void aksiContoh(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$pesan (contoh, belum tersimpan)')));
}
