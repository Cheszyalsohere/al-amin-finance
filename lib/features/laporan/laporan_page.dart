import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_status.dart';
import 'riwayat_page.dart';
import '../siswa/siswa_providers.dart';
import '../../core/widgets/neo_keadaan.dart';

class LaporanPage extends ConsumerStatefulWidget {
  const LaporanPage({super.key});

  @override
  ConsumerState<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends ConsumerState<LaporanPage> {
  late DateTime _bulan = _bulanIni;

  DateTime get _bulanIni {
    final h = ref.read(hariIniProvider);
    return DateTime(h.year, h.month);
  }

  void _geser(int delta) =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final hasil = ref.watch(ringkasanProvider(_bulan));
    final r = hasil.value;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laporan')),
        body: NeoAsync(
          nilai: hasil,
          onCobaLagi: () => ref.invalidate(daftarSiswaProvider),
          isi: (_) => const SizedBox(),
        ),
      );
    }
    final perKategori = r.perKategori;
    final terbesar = perKategori.values.fold(0, (a, b) => a > b ? a : b);
    final bisaMaju = _bulan.isBefore(_bulanIni);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            tooltip: 'Riwayat transaksi',
            icon: const Icon(Icons.history),
            onPressed: () => context.push(Rute.riwayat),
          ),
          IconButton(
            tooltip: 'Export Excel',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => aksiContoh(context, 'Export laporan ke Excel'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              NeoTombol(
                warna: Neo.putih,
                padding: const EdgeInsets.all(10),
                onPressed: () => _geser(-1),
                child: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  bulanTahun(_bulan),
                  textAlign: TextAlign.center,
                  style: teks.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              NeoTombol(
                warna: Neo.putih,
                padding: const EdgeInsets.all(10),
                onPressed: bisaMaju ? () => _geser(1) : null,
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: NeoStatistik(
                  label: 'Pemasukan',
                  nilai: angka(r.pemasukan),
                  ikon: Icons.south_west,
                  warna: Neo.hijau,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoStatistik(
                  label: 'Pengeluaran',
                  nilai: angka(r.pengeluaran),
                  ikon: Icons.north_east,
                  warna: Neo.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoStatistik(
            label: r.saldo >= 0 ? 'Laba bulan ini' : 'Rugi bulan ini',
            nilai: rupiah(r.saldo),
            ikon: Icons.account_balance_outlined,
            warna: r.saldo >= 0 ? Neo.kuning : Neo.merah,
          ),
          const SizedBox(height: 28),
          NeoBagian(
            judul: 'Transaksi terbaru',
            aksi: 'Lihat semua',
            onAksi: () => context.push(Rute.riwayat),
          ),
          if (r.transaksi.isEmpty)
            const NeoKotak(child: Text('Belum ada transaksi bulan ini.')),
          for (final t in r.transaksi.take(5)) ...[
            BarisTransaksi(transaksi: t),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          NeoTombol(
            warna: Neo.biru,
            onPressed: () => context.push(Rute.riwayat),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Text('Riwayat lengkap (${r.transaksi.length} transaksi)'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const NeoBagian(judul: 'Pengeluaran per kategori'),
          if (perKategori.isEmpty)
            const NeoKotak(child: Text('Tidak ada pengeluaran bulan ini.')),
          for (final MapEntry(key: k, value: v) in perKategori.entries) ...[
            Row(
              children: [
                Icon(k.ikon, size: 18, color: Neo.tinta),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    k.nama,
                    style: teks.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  angka(v),
                  style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            NeoProgres(
              nilai: terbesar == 0 ? 0 : v / terbesar,
              warna: Neo.oranye,
              tinggi: 14,
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          NeoBagian(
            judul: 'Tunggakan siswa',
            aksi: 'Lihat',
            onAksi: () => context.push(Rute.tunggakan),
          ),
          NeoItem(
            warna: Neo.pink,
            depan: const Icon(Icons.warning_amber_rounded, size: 28),
            judul: rupiah(r.totalTunggakan),
            subjudul: '${r.menunggak.length} siswa belum lunas',
          ),
          const SizedBox(height: 28),
          NeoTombol(
            warna: Neo.hijau,
            onPressed: () => aksiContoh(context, 'Export laporan ke Excel'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_view_outlined),
                SizedBox(width: 8),
                Text('Export ke Excel'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Export juga berfungsi sebagai backup data.',
            textAlign: TextAlign.center,
            style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
