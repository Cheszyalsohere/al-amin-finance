import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import '../theme.dart';
import 'neo.dart';

/// Tampilan saat daftar kosong, gagal dimuat, atau keadaan khusus lain.
class NeoKeadaan extends StatelessWidget {
  const NeoKeadaan({
    super.key,
    required this.ikon,
    required this.judul,
    this.pesan,
    this.tombol,
    this.warna = Neo.kuning,
  });

  const NeoKeadaan.kosong({
    super.key,
    required this.judul,
    this.pesan,
    this.tombol,
  }) : ikon = Icons.inbox_outlined,
       warna = Neo.biru;

  const NeoKeadaan.galat({
    super.key,
    this.judul = 'Gagal memuat data',
    this.pesan = 'Periksa koneksi internet, lalu coba lagi.',
    this.tombol,
  }) : ikon = Icons.wifi_off,
       warna = Neo.merah;

  final IconData ikon;
  final String judul;
  final String? pesan;
  final Widget? tombol;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.06,
              child: NeoKotak(
                warna: warna,
                padding: const EdgeInsets.all(16),
                child: Icon(ikon, size: 40, color: Neo.tinta),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: teks.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (pesan != null) ...[
              const SizedBox(height: 6),
              Text(
                pesan!,
                textAlign: TextAlign.center,
                style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
            if (tombol != null) ...[const SizedBox(height: 20), tombol!],
          ],
        ),
      ),
    );
  }
}

class NeoMemuat extends StatelessWidget {
  const NeoMemuat({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: NeoKotak(
        warna: Neo.kuning,
        padding: EdgeInsets.all(14),
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 3.5),
        ),
      ),
    );
  }
}

/// Menampilkan loading, galat (dengan tombol coba lagi), atau isi data.
class NeoAsync<T> extends StatelessWidget {
  const NeoAsync({
    super.key,
    required this.nilai,
    required this.isi,
    required this.onCobaLagi,
  });

  final AsyncValue<T> nilai;
  final Widget Function(T data) isi;
  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) {
    return switch (nilai) {
      AsyncData(:final value) => isi(value),
      AsyncError(:final error) => NeoKeadaan.galat(
        pesan: '$error',
        tombol: NeoTombol(
          onPressed: onCobaLagi,
          child: const Text('Coba lagi'),
        ),
      ),
      _ => const NeoMemuat(),
    };
  }
}

/// Penanda bahwa layar ini masih memakai data contoh karena belum
/// tersambung ke database. Tidak tampil di mode contoh.
class NeoBelumTersambung extends StatelessWidget {
  const NeoBelumTersambung({super.key, required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    if (Env.pratinjau) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoKotak(
        warna: Neo.pink,
        geser: const Offset(2, 2),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.construction_outlined, color: Neo.tinta),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pesan,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
