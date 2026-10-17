import 'package:flutter/material.dart';

import '../theme.dart';
import 'neo.dart';

/// Kotak inisial nama, misalnya "AP" untuk Aisyah Putri.
class NeoInisial extends StatelessWidget {
  const NeoInisial({
    super.key,
    required this.nama,
    this.warna = Neo.biru,
    this.ukuran = 44,
  });

  final String nama;
  final Color warna;
  final double ukuran;

  static String ambil(String nama) {
    final kata = nama
        .replaceFirst(RegExp(r'^(Kak|Ibu|Bapak)\s+'), '')
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    return kata.take(2).map((k) => k[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: Neo.kotak(warna: warna, geser: Offset.zero, radius: 8),
      child: Text(
        ambil(nama),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Baris daftar berbentuk kartu yang bisa diketuk.
class NeoItem extends StatelessWidget {
  const NeoItem({
    super.key,
    required this.judul,
    this.subjudul,
    this.depan,
    this.belakang,
    this.onTap,
    this.warna = Neo.putih,
  });

  final String judul;
  final String? subjudul;
  final Widget? depan;
  final Widget? belakang;
  final VoidCallback? onTap;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    final isi = Row(
      children: [
        if (depan != null) ...[depan!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: teks.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subjudul != null)
                Text(
                  subjudul!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: teks.bodySmall?.copyWith(
                    color: const Color(0xFF4A4A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (belakang != null) ...[const SizedBox(width: 8), belakang!],
      ],
    );

    if (onTap == null) {
      return NeoKotak(
        warna: warna,
        geser: const Offset(3, 3),
        padding: const EdgeInsets.all(12),
        child: isi,
      );
    }

    return NeoTombol(
      onPressed: onTap,
      warna: warna,
      padding: const EdgeInsets.all(12),
      child: DefaultTextStyle.merge(textAlign: TextAlign.start, child: isi),
    );
  }
}

/// Judul bagian dengan tombol aksi opsional di kanan.
class NeoBagian extends StatelessWidget {
  const NeoBagian({super.key, required this.judul, this.aksi, this.onAksi});

  final String judul;
  final String? aksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              judul.toUpperCase(),
              style: teks.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (aksi != null)
            InkWell(
              onTap: onAksi,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$aksi →',
                  style: teks.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kotak statistik: label kecil di atas, angka besar di bawah.
class NeoStatistik extends StatelessWidget {
  const NeoStatistik({
    super.key,
    required this.label,
    required this.nilai,
    this.ikon,
    this.warna = Neo.putih,
    this.keterangan,
  });

  final String label;
  final String nilai;
  final IconData? ikon;
  final Color warna;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return NeoKotak(
      warna: warna,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ikon != null) ...[
                Icon(ikon, size: 18, color: Neo.tinta),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: teks.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: teks.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (keterangan != null)
            Text(
              keterangan!,
              style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

/// Baris "label ........ nilai" untuk rincian biaya.
class NeoBarisNilai extends StatelessWidget {
  const NeoBarisNilai(this.label, this.nilai, {super.key, this.tebal = false});

  final String label;
  final String nilai;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: tebal ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gaya)),
          Text(nilai, style: gaya?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
