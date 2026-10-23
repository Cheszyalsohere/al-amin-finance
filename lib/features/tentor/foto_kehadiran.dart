import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import 'tentor.dart';
import 'tentor_providers.dart';

/// Foto kehadiran 3:4. Jika [bytes] ada, tampilkan foto itu (cap waktu sudah
/// tercetak di dalamnya). Jika tidak, tampilkan pengganti dengan cap waktu,
/// misalnya untuk data contoh atau foto yang sudah dihapus otomatis.
class FotoKehadiran extends StatelessWidget {
  const FotoKehadiran({
    super.key,
    required this.waktu,
    this.nama,
    this.warna = Neo.biru,
    this.bytes,
    this.url,
    this.keterangan,
  });

  final DateTime waktu;
  final String? nama;
  final Color warna;
  final Uint8List? bytes;
  final String? url;

  /// Teks tambahan di pengganti, misal "Foto sudah dihapus".
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    Widget isi;
    if (bytes != null) {
      isi = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (url != null) {
      isi = Image.network(
        url!,
        fit: BoxFit.cover,
        loadingBuilder: (_, anak, progres) => progres == null
            ? anak
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      );
    } else {
      isi = Stack(
        children: [
          const Center(child: Icon(Icons.person, size: 140, color: Neo.tinta)),
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
                  keterangan ?? 'Bimbel Al-Amin',
                ].join('\n'),
                style: teks.labelSmall?.copyWith(
                  color: Neo.putih,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: Neo.kotak(warna: warna, geser: Offset.zero),
        clipBehavior: Clip.antiAlias,
        child: isi,
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
            _FotoDariServer(tentor: tentor, kehadiran: kehadiran, warna: warna),
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

class _FotoDariServer extends ConsumerWidget {
  const _FotoDariServer({
    required this.tentor,
    required this.kehadiran,
    required this.warna,
  });

  final Tentor tentor;
  final Kehadiran kehadiran;
  final Color warna;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = kehadiran.fotoPath;
    final url = path == null ? null : ref.watch(urlFotoProvider(path)).value;

    return FotoKehadiran(
      waktu: kehadiran.waktuDatang,
      nama: tentor.nama,
      warna: warna,
      url: url,
      keterangan: path == null ? 'Foto tidak tersedia' : null,
    );
  }
}
