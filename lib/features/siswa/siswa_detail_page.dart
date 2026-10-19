import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../../core/widgets/neo_status.dart';
import 'siswa.dart';
import 'siswa_providers.dart';

class SiswaDetailPage extends ConsumerWidget {
  const SiswaDetailPage({super.key, required this.siswaId});

  final String siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasil = ref.watch(siswaProvider(siswaId));
    final siswa = hasil.value;
    if (siswa == null) {
      return Scaffold(
        appBar: AppBar(),
        body: hasil.hasValue
            ? const NeoKeadaan.kosong(judul: 'Siswa tidak ditemukan')
            : NeoAsync(
                nilai: hasil,
                onCobaLagi: () => ref.invalidate(daftarSiswaProvider),
                isi: (_) => const SizedBox(),
              ),
      );
    }

    final t = siswa.tagihan;
    final teks = Theme.of(context).textTheme;
    final status = t.status(ref.watch(hariIniProvider));
    final tahunAjaran = ref.watch(aturanProvider).value?.tahunAjaran ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail siswa'),
        actions: [
          IconButton(
            tooltip: 'Ubah data',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => aksiContoh(context, 'Ubah data siswa'),
          ),
        ],
      ),
      bottomNavigationBar: t.sisa == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: NeoTombol(
                  warna: Neo.hijau,
                  onPressed: () => context.push(Rute.bayar(siswa.id)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined),
                      SizedBox(width: 8),
                      Text('Catat pembayaran'),
                    ],
                  ),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              NeoInisial(
                nama: siswa.nama,
                ukuran: 60,
                warna: siswa.program == Program.sma ? Neo.ungu : Neo.biru,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siswa.nama,
                      style: teks.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${siswa.program.label} · Kelas ${siswa.kelas} · '
                      '${siswa.asalSekolah}',
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
          NeoKotak(
            warna: status.warna,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TAGIHAN $tahunAjaran',
                        style: teks.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    NeoLabel(
                      teks: status.label,
                      ikon: status.ikon,
                      warna: Neo.putih,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.sisa == 0 ? 'Lunas' : 'Sisa ${rupiah(t.sisa)}',
                  style: teks.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                NeoProgres(nilai: t.progres, warna: Neo.tinta),
                const SizedBox(height: 8),
                Text(
                  'Dibayar ${rupiah(t.dibayar)} dari ${rupiah(t.total)}',
                  style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (t.sisa > 0)
                  Text(
                    'Batas pelunasan ${tanggal(t.batasPelunasan)}',
                    style: teks.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeoKotak(
            child: Column(
              children: [
                NeoBarisNilai('Skema', t.skema.label),
                NeoBarisNilai('Keringanan', t.keringanan.label),
                NeoBarisNilai('Biaya program', rupiah(t.rincian.biayaPokok)),
                if (t.rincian.potongan > 0)
                  NeoBarisNilai('Potongan', '− ${rupiah(t.rincian.potongan)}'),
                NeoBarisNilai('Biaya admin', rupiah(t.rincian.biayaAdmin)),
                const Divider(color: Neo.tinta, thickness: 2, height: 20),
                NeoBarisNilai('Total', rupiah(t.total), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const NeoBagian(judul: 'Wali murid'),
          NeoItem(
            depan: NeoInisial(nama: siswa.namaWali, warna: Neo.oranye),
            judul: siswa.namaWali,
            subjudul: siswa.noHpWali,
            belakang: NeoTombol(
              warna: Neo.hijau,
              padding: const EdgeInsets.all(10),
              onPressed: () => aksiContoh(context, 'Buka WhatsApp wali'),
              child: const Icon(Icons.chat_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          NeoBagian(judul: 'Riwayat pembayaran (${t.pembayaran.length})'),
          if (t.pembayaran.isEmpty)
            NeoKotak(
              warna: t.rincian.gratis ? Neo.hijau : Neo.putih,
              child: Text(
                t.rincian.gratis
                    ? 'Siswa ini mendapat keringanan penuh, tidak ada tagihan.'
                    : 'Belum ada pembayaran.',
                style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          for (final p in t.pembayaran.reversed) ...[
            NeoItem(
              onTap: () => context.push(Rute.kuitansi(siswa.id, p.id)),
              depan: const NeoKotak(
                warna: Neo.hijau,
                geser: Offset.zero,
                padding: EdgeInsets.all(8),
                child: Icon(Icons.receipt_outlined, color: Neo.tinta),
              ),
              judul: rupiah(p.jumlah),
              subjudul: '${tanggalJam(p.tanggal)} · ${p.metode.label}',
              belakang: const Icon(Icons.chevron_right, color: Neo.tinta),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
