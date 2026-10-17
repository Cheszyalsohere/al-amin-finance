import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../siswa/siswa.dart';
import 'foto_kehadiran.dart';
import 'tentor_page.dart';

class BayarHonorPage extends StatefulWidget {
  const BayarHonorPage({super.key, required this.tentorId});

  final String tentorId;

  @override
  State<BayarHonorPage> createState() => _BayarHonorPageState();
}

class _BayarHonorPageState extends State<BayarHonorPage> {
  Metode _metode = Metode.transfer;

  @override
  Widget build(BuildContext context) {
    final tentor = DataContoh.tentor
        .where((t) => t.id == widget.tentorId)
        .firstOrNull;
    if (tentor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const NeoKeadaan.kosong(judul: 'Tentor tidak ditemukan'),
      );
    }

    final teks = Theme.of(context).textTheme;
    final bulan = hariIniContoh;
    final awal = DateTime(bulan.year, bulan.month);
    final akhir = DateTime(bulan.year, bulan.month + 1, 0);
    final hadir = kehadiranBulan(tentor.id, bulan);
    final sesi = hadir.fold(0, (a, k) => a + k.sesi.length);
    final total = hadir.fold(0, (a, k) => a + k.honor);
    final warna = warnaTentor(tentor);

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar honor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.hijau,
            onPressed: hadir.isEmpty
                ? null
                : () {
                    aksiContoh(
                      context,
                      'Honor ${tentor.nama} ${rupiah(total)} dibayar',
                    );
                    context.pop();
                  },
            child: Text('Tandai dibayar · ${rupiah(total)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          NeoItem(
            depan: NeoInisial(nama: tentor.nama, warna: warna),
            judul: tentor.nama,
            subjudul: '${tentor.mapel} · ${rupiah(tentor.tarifPerSesi)}/sesi',
          ),
          const SizedBox(height: 16),
          NeoItem(
            onTap: () => aksiContoh(context, 'Ubah periode'),
            warna: Neo.kuning,
            depan: const Icon(Icons.date_range_outlined),
            judul: 'Periode ${bulanTahun(bulan)}',
            subjudul: '${tanggal(awal)} – ${tanggal(akhir)}',
            belakang: const Icon(Icons.edit_outlined, size: 20),
          ),
          const SizedBox(height: 24),
          NeoBagian(judul: 'Rincian ($sesi sesi)'),
          for (final k in hadir) ...[
            NeoItem(
              onTap: () => tampilkanFotoKehadiran(context, tentor, k, warna),
              depan: NeoKotak(
                warna: warna,
                geser: Offset.zero,
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.photo_outlined, color: Neo.tinta),
              ),
              judul: tanggal(k.waktuDatang),
              subjudul:
                  '${k.sesi.length} × ${angka(tentor.tarifPerSesi)} · '
                  '${k.sesi.map((s) => s.program.label).join(', ')}',
              belakang: Text(
                angka(k.honor),
                style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          NeoKotak(
            warna: Neo.hijau,
            child: Column(
              children: [
                NeoBarisNilai('Jumlah sesi', '$sesi'),
                NeoBarisNilai('Tarif', rupiah(tentor.tarifPerSesi)),
                const Divider(color: Neo.tinta, thickness: 2, height: 20),
                NeoBarisNilai('Total honor', rupiah(total), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Dibayar lewat',
            style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          NeoPilihan<Metode>(
            pilihan: Metode.values,
            terpilih: _metode,
            label: (m) => m.label,
            onPilih: (m) => setState(() => _metode = m),
          ),
          const SizedBox(height: 12),
          Text(
            'Setelah ditandai dibayar, honor otomatis tercatat sebagai '
            'pengeluaran.',
            style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
