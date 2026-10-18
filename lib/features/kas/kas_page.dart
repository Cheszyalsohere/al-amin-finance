import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import 'detail_pengeluaran.dart';
import 'kategori_provider.dart';

class KasPage extends ConsumerStatefulWidget {
  const KasPage({super.key});

  @override
  ConsumerState<KasPage> createState() => _KasPageState();
}

class _KasPageState extends ConsumerState<KasPage> {
  String? _kategoriId;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final r = ringkasanContoh(ref);
    final semuaKategori = ref.watch(kategoriProvider);
    final kategoriTerpilih = _kategoriId == null
        ? null
        : r.kategori(_kategoriId!);
    final daftar =
        r.pengeluaranBulanIni
            .where((e) => _kategoriId == null || e.kategoriId == _kategoriId)
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
                  kategoriTerpilih == null
                      ? '${daftar.length} transaksi'
                      : '${daftar.length} transaksi · ${kategoriTerpilih.nama}',
                  style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: NeoPilihan<String?>(
              pilihan: [
                null,
                for (final k in semuaKategori)
                  if (!k.diarsipkan) k.id,
              ],
              terpilih: _kategoriId,
              label: (id) => id == null ? 'Semua' : r.kategori(id).nama,
              warna: Neo.oranye,
              onPilih: (id) => setState(() => _kategoriId = id),
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
              onTap: () => bukaDetailPengeluaran(context, e),
              depan: NeoKotak(
                warna: Neo.oranye,
                geser: Offset.zero,
                padding: const EdgeInsets.all(8),
                child: Icon(r.kategori(e.kategoriId).ikon, color: Neo.tinta),
              ),
              judul: e.keterangan,
              subjudul:
                  '${tanggalJam(e.tanggal)} · ${r.kategori(e.kategoriId).nama}',
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
