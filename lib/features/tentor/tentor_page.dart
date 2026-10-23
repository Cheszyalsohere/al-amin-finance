import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../auth/auth_providers.dart';
import 'tentor.dart';
import 'tentor_providers.dart';

const _warnaTentor = [Neo.kuning, Neo.biru, Neo.hijau, Neo.pink, Neo.ungu];

/// Warna tetap per tentor (dari id), supaya sama di semua layar.
Color warnaTentor(Tentor t) =>
    _warnaTentor[t.id.codeUnits.fold(0, (a, c) => a + c) % _warnaTentor.length];

class TentorPage extends ConsumerWidget {
  const TentorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teks = Theme.of(context).textTheme;
    final bulan = ref.watch(bulanIniProvider);
    final akhirBulan = DateTime(bulan.year, bulan.month + 1, 0);
    final owner = ref.watch(profilProvider).value?.isOwner ?? false;
    final hasilTentor = ref.watch(daftarTentorProvider);
    final hasilHadir = ref.watch(kehadiranBulanProvider(bulan));

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
      body: NeoAsync(
        nilai: hasilTentor,
        onCobaLagi: () => segarkanDataTentor(ref),
        isi: (semua) {
          final hadir = hasilHadir.value ?? const <Kehadiran>[];
          final aktif = semua.where((t) => t.aktif).toList();
          final nonaktif = semua.where((t) => !t.aktif).toList();
          final totalSesi = hadir.fold(0, (a, k) => a + k.sesi.length);
          final totalHonor = hadir.fold(0, (a, k) => a + k.honor);

          return RefreshIndicator(
            color: Neo.tinta,
            onRefresh: () async => segarkanDataTentor(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
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
                        style: teks.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NeoBagian(
                  judul: '${aktif.length} tentor aktif',
                  aksi: owner ? 'Tambah' : null,
                  onAksi: () => context.push(Rute.tambahTentor),
                ),
                if (aktif.isEmpty)
                  NeoKeadaan.kosong(
                    judul: 'Belum ada tentor',
                    pesan: owner
                        ? 'Ketuk Tambah untuk mendaftarkan tentor.'
                        : 'Minta owner mendaftarkan tentor.',
                  ),
                for (final t in aktif) ...[
                  _BarisTentor(
                    tentor: t,
                    hadir: hadir.where((k) => k.tentorId == t.id).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (nonaktif.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  NeoBagian(judul: '${nonaktif.length} tentor nonaktif'),
                  for (final t in nonaktif) ...[
                    _BarisTentor(
                      tentor: t,
                      hadir: hadir.where((k) => k.tentorId == t.id).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BarisTentor extends StatelessWidget {
  const _BarisTentor({required this.tentor, required this.hadir});

  final Tentor tentor;
  final List<Kehadiran> hadir;

  @override
  Widget build(BuildContext context) {
    final sesi = hadir.fold(0, (a, k) => a + k.sesi.length);
    final honor = hadir.fold(0, (a, k) => a + k.honor);

    return NeoItem(
      onTap: () => context.push(Rute.detailTentor(tentor.id)),
      warna: tentor.aktif ? Neo.putih : const Color(0xFFEDEDED),
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
