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
import '../siswa/siswa.dart';
import 'foto_kehadiran.dart';
import 'tentor.dart';
import 'tentor_page.dart';
import 'tentor_providers.dart';

class TentorDetailPage extends ConsumerWidget {
  const TentorDetailPage({super.key, required this.tentorId});

  final String tentorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasil = ref.watch(tentorProvider(tentorId));
    final tentor = hasil.value;
    if (tentor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: hasil.hasValue
            ? const NeoKeadaan.kosong(judul: 'Tentor tidak ditemukan')
            : NeoAsync(
                nilai: hasil,
                onCobaLagi: () => segarkanDataTentor(ref),
                isi: (_) => const SizedBox(),
              ),
      );
    }
    final bulan = ref.watch(bulanIniProvider);
    final owner = ref.watch(profilProvider).value?.isOwner ?? false;

    final teks = Theme.of(context).textTheme;
    final warna = warnaTentor(tentor);
    final hadir =
        (ref.watch(kehadiranBulanProvider(bulan)).value ?? const <Kehadiran>[])
            .where((k) => k.tentorId == tentor.id)
            .toList()
            .reversed
            .toList();
    final sesi = hadir.fold(0, (a, k) => a + k.sesi.length);
    final honor = hadir.fold(0, (a, k) => a + k.honor);
    final riwayat =
        ref.watch(riwayatHonorProvider(tentor.id)).value ??
        const <PembayaranHonor>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail tentor'),
        actions: [
          if (owner)
            IconButton(
              tooltip: 'Ubah data & tarif',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Rute.ubahTentor(tentor.id)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.hijau,
            onPressed: () => context.push(Rute.honor(tentor.id)),
            child: const Text('Bayar honor bulan ini'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              NeoInisial(nama: tentor.nama, warna: warna, ukuran: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tentor.nama,
                      style: teks.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${tentor.mapel} · ${tentor.noHp}',
                      style: teks.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: NeoStatistik(
                  label: 'Tarif',
                  nilai: angka(tentor.tarifPerSesi),
                  keterangan: 'per sesi',
                  warna: warna,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeoStatistik(
                  label: 'Sesi',
                  nilai: '$sesi',
                  keterangan: 'bulan ini',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeoStatistik(
                  label: 'Honor',
                  nilai: angka(honor),
                  keterangan: 'berjalan',
                  warna: Neo.hijau,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          NeoBagian(judul: 'Kehadiran ${bulanTahun(bulan)}'),
          if (hadir.isEmpty)
            const NeoKotak(child: Text('Belum ada kehadiran bulan ini.')),
          for (final k in hadir) ...[
            NeoItem(
              onTap: () => tampilkanFotoKehadiran(context, tentor, k, warna),
              depan: NeoKotak(
                warna: warna,
                geser: Offset.zero,
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.photo_outlined, color: Neo.tinta),
              ),
              judul: tanggalPanjang(k.waktuDatang),
              subjudul:
                  'Datang ${jam(k.waktuDatang)} · '
                  '${k.sesi.map((s) => s.program.label).join(', ')}',
              belakang: Text(
                '${k.sesi.length}×',
                style: teks.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          const NeoBagian(judul: 'Riwayat honor'),
          for (final h in riwayat) ...[
            NeoItem(
              depan: const NeoKotak(
                warna: Neo.hijau,
                geser: Offset.zero,
                padding: EdgeInsets.all(8),
                child: Icon(Icons.check, color: Neo.tinta),
              ),
              judul: bulanTahun(h.periode),
              subjudul:
                  '${h.jumlahSesi} sesi · dibayar ${tanggalJam(h.tanggalBayar)}',
              belakang: Text(
                angka(h.total),
                style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
