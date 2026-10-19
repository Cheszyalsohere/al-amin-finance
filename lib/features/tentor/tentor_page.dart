import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import 'tentor.dart';
import '../../core/widgets/neo_keadaan.dart';

/// Kehadiran seorang tentor pada bulan tertentu (data contoh).
List<Kehadiran> kehadiranBulan(String tentorId, DateTime bulan) => [
  for (final k in DataContoh.kehadiran)
    if (k.tentorId == tentorId &&
        k.waktuDatang.year == bulan.year &&
        k.waktuDatang.month == bulan.month)
      k,
];

const _warnaTentor = [Neo.kuning, Neo.biru, Neo.hijau, Neo.pink, Neo.ungu];

Color warnaTentor(Tentor t) =>
    _warnaTentor[DataContoh.tentor.indexOf(t) % _warnaTentor.length];

class TentorPage extends StatelessWidget {
  const TentorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final bulan = hariIniContoh;
    final akhirBulan = DateTime(bulan.year, bulan.month + 1, 0);

    var totalSesi = 0;
    var totalHonor = 0;
    for (final t in DataContoh.tentor) {
      for (final k in kehadiranBulan(t.id, bulan)) {
        totalSesi += k.sesi.length;
        totalHonor += k.honor;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tentor')),
      floatingActionButton: NeoTombol(
        warna: Neo.biru,
        onPressed: () => context.push(Rute.absen()),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined),
            SizedBox(width: 6),
            Text('Absen'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          const NeoBelumTersambung(
            pesan:
                'Data tentor di bawah masih contoh. Tersambung ke database di Tahap 5.',
          ),
          NeoKotak(
            warna: Neo.hijau,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HONOR ${bulanTahun(bulan).toUpperCase()} (BERJALAN)',
                  style: teks.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(totalHonor),
                  style: teks.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$totalSesi sesi · dibayar ${tanggal(akhirBulan)}',
                  style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NeoBagian(
            judul: '${DataContoh.tentor.length} tentor aktif',
            aksi: 'Tambah',
            onAksi: () => aksiContoh(context, 'Tambah tentor'),
          ),
          for (final t in DataContoh.tentor) ...[
            _BarisTentor(tentor: t, bulan: bulan),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BarisTentor extends StatelessWidget {
  const _BarisTentor({required this.tentor, required this.bulan});

  final Tentor tentor;
  final DateTime bulan;

  @override
  Widget build(BuildContext context) {
    final hadir = kehadiranBulan(tentor.id, bulan);
    final sesi = hadir.fold(0, (a, k) => a + k.sesi.length);
    final honor = hadir.fold(0, (a, k) => a + k.honor);

    return NeoItem(
      onTap: () => context.push(Rute.detailTentor(tentor.id)),
      depan: NeoInisial(nama: tentor.nama, warna: warnaTentor(tentor)),
      judul: tentor.nama,
      subjudul: '${tentor.mapel} · ${rupiah(tentor.tarifPerSesi)}/sesi',
      belakang: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sesi sesi',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            angka(honor),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
