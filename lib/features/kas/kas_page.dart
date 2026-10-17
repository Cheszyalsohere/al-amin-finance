import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import 'pengeluaran.dart';

class KasPage extends StatefulWidget {
  const KasPage({super.key});

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  KategoriPengeluaran? _kategori;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final r = ringkasanContoh();
    final daftar =
        r.pengeluaranBulanIni
            .where((e) => _kategori == null || e.kategori == _kategori)
            .toList()
          ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final total = daftar.fold(0, (a, e) => a + e.jumlah);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      floatingActionButton: NeoTombol(
        warna: Neo.oranye,
        onPressed: () => context.push(Rute.tambahPengeluaran),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.add), SizedBox(width: 6), Text('Catat')],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          NeoKotak(
            warna: Neo.oranye,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENGELUARAN ${bulanTahun(r.bulan).toUpperCase()}',
                  style: teks.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(total),
                  style: teks.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _kategori == null
                      ? '${daftar.length} transaksi'
                      : '${daftar.length} transaksi · ${_kategori!.label}',
                  style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: NeoPilihan<KategoriPengeluaran?>(
              pilihan: const [null, ...KategoriPengeluaran.values],
              terpilih: _kategori,
              label: (k) => k?.label ?? 'Semua',
              warna: Neo.oranye,
              onPilih: (k) => setState(() => _kategori = k),
            ),
          ),
          const SizedBox(height: 20),
          if (daftar.isEmpty)
            const NeoKeadaan.kosong(
              judul: 'Belum ada pengeluaran',
              pesan: 'Pengeluaran yang dicatat akan muncul di sini.',
            ),
          for (final e in daftar) ...[
            NeoItem(
              onTap: () => aksiContoh(context, 'Lihat detail pengeluaran'),
              depan: NeoKotak(
                warna: Neo.oranye,
                geser: Offset.zero,
                padding: const EdgeInsets.all(8),
                child: Icon(e.kategori.ikon, color: Neo.tinta),
              ),
              judul: e.keterangan,
              subjudul: '${tanggal(e.tanggal)} · ${e.kategori.label}',
              belakang: Text(
                angka(e.jumlah),
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
