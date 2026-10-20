import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../../core/widgets/neo_status.dart';
import '../../core/whatsapp.dart';
import '../pembayaran/kuitansi_aksi.dart';
import 'siswa_providers.dart';

class TunggakanPage extends ConsumerWidget {
  const TunggakanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hariIni = ref.watch(hariIniProvider);
    final batas = ref.watch(aturanProvider).value?.batasCicilan;
    final hasil = ref.watch(ringkasanBulanIniProvider);
    final r = hasil.value;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tunggakan')),
        body: NeoAsync(
          nilai: hasil,
          onCobaLagi: () => ref.invalidate(daftarSiswaProvider),
          isi: (_) => const SizedBox(),
        ),
      );
    }
    final daftar = r.menunggak;
    final teks = Theme.of(context).textTheme;
    final sisaHari = batas
        ?.difference(DateTime(hariIni.year, hariIni.month, hariIni.day))
        .inDays;

    return Scaffold(
      appBar: AppBar(title: const Text('Tunggakan')),
      body: daftar.isEmpty
          ? const NeoKeadaan(
              ikon: Icons.celebration_outlined,
              warna: Neo.hijau,
              judul: 'Semua sudah lunas',
              pesan: 'Tidak ada siswa yang menunggak.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: NeoStatistik(
                        label: 'Total sisa',
                        nilai: rupiah(r.totalTunggakan),
                        warna: Neo.pink,
                        ikon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeoStatistik(
                        label: 'Batas lunas',
                        nilai: switch (sisaHari) {
                          null => '-',
                          < 0 => 'Lewat',
                          final h => '$h hari',
                        },
                        keterangan: batas == null
                            ? null
                            : 'sampai ${tanggal(batas)}',
                        warna: Neo.kuning,
                        ikon: Icons.event_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                NeoBagian(judul: '${daftar.length} siswa belum lunas'),
                for (final s in daftar) ...[
                  NeoKotak(
                    padding: const EdgeInsets.all(12),
                    geser: const Offset(3, 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    context.push(Rute.detailSiswa(s.id)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.nama,
                                      style: teks.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Sisa ${rupiah(s.tagihan.sisa)}',
                                      style: teks.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            NeoStatus(s.tagihan.status(hariIni)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        NeoProgres(nilai: s.tagihan.progres, tinggi: 12),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: NeoTombol(
                                warna: Neo.hijau,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                onPressed: () => kirimWhatsAppKeWali(
                                  context,
                                  s,
                                  pesanPengingat(s),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('Ingatkan'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: NeoTombol(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                onPressed: () => context.push(Rute.bayar(s.id)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.payments_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('Catat bayar'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}
