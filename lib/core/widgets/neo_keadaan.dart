import 'package:flutter/material.dart';

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
