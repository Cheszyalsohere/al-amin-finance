import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import 'tentor.dart';

/// Pengganti foto kehadiran di tahap desain: kotak bergambar orang dengan
/// cap tanggal & jam seperti watermark yang nanti dicetak di foto asli.
class FotoKehadiran extends StatelessWidget {
  const FotoKehadiran({
    super.key,
    required this.waktu,
    this.nama,
    this.warna = Neo.biru,
  });

  final DateTime waktu;
  final String? nama;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: Neo.kotak(warna: warna, geser: Offset.zero),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.person, size: 140, color: Neo.tinta),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Neo.tinta.withValues(alpha: 0.8),
                padding: const EdgeInsets.all(8),
                child: Text(
                  [
                    ?nama,
                    '${tanggal(waktu)} · ${jam(waktu)} WIB',
                    'Bimbel Al-Amin',
                  ].join('\n'),
                  style: teks.labelSmall?.copyWith(
                    color: Neo.putih,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> tampilkanFotoKehadiran(
  BuildContext context,
  Tentor tentor,
  Kehadiran kehadiran,
  Color warna,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FotoKehadiran(
              waktu: kehadiran.waktuDatang,
              nama: tentor.nama,
              warna: warna,
            ),
            const SizedBox(height: 12),
            Text(
              '${kehadiran.sesi.length} sesi · ${rupiah(kehadiran.honor)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            NeoTombol(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    ),
  );
}
