import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../siswa/siswa.dart';
import '../siswa/siswa_repository.dart';
import 'foto_kehadiran.dart';
import 'tentor.dart';
import 'tentor_page.dart';
import 'tentor_providers.dart';

class BayarHonorPage extends ConsumerStatefulWidget {
  const BayarHonorPage({super.key, required this.tentorId});

  final String tentorId;

  @override
  ConsumerState<BayarHonorPage> createState() => _BayarHonorPageState();
}

class _BayarHonorPageState extends ConsumerState<BayarHonorPage> {
  Metode _metode = Metode.transfer;
  late DateTime _bulan = ref.read(bulanIniProvider);
  bool _menyimpan = false;
  String? _galat;

  void _geser(int delta) => setState(() {
    _bulan = DateTime(_bulan.year, _bulan.month + delta);
    _galat = null;
  });

  Future<void> _bayar(Tentor tentor) async {
    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    try {
      final honor = await ref
          .read(tentorRepositoryProvider)
          .bayarHonor(tentorId: tentor.id, periode: _bulan, metode: _metode);
      segarkanDataTentor(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Honor ${tentor.nama} ${rupiah(honor.total)} '
              '(${honor.jumlahSesi} sesi) dibayar.',
            ),
          ),
        );
      context.pop();
    } on GagalSimpan catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasil = ref.watch(tentorProvider(widget.tentorId));
    final tentor = hasil.value;
    if (tentor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bayar honor')),
        body: hasil.hasValue
            ? const NeoKeadaan.kosong(judul: 'Tentor tidak ditemukan')
            : NeoAsync(
                nilai: hasil,
                onCobaLagi: () => segarkanDataTentor(ref),
                isi: (_) => const SizedBox(),
              ),
      );
    }

    final teks = Theme.of(context).textTheme;
    final bulanIni = ref.watch(bulanIniProvider);
    final awal = DateTime(_bulan.year, _bulan.month);
    final akhir = DateTime(_bulan.year, _bulan.month + 1, 0);
    final hasilHadir = ref.watch(kehadiranBulanProvider(awal));
    final hadir = (hasilHadir.value ?? const <Kehadiran>[])
        .where((k) => k.tentorId == tentor.id)
        .toList();
    final belum = [
      for (final k in hadir)
        if (k.sesiBelumDibayar.isNotEmpty) k,
    ];
    final sesiBelum = [for (final k in belum) ...k.sesiBelumDibayar];
    final total = sesiBelum.fold(0, (a, s) => a + s.tarif);
    final sudahDibayar = hadir.where((k) => k.sudahDibayar).length;
    final warna = warnaTentor(tentor);

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar honor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.hijau,
            onPressed: sesiBelum.isEmpty || _menyimpan
                ? null
                : () => _bayar(tentor),
            child: _menyimpan
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    sesiBelum.isEmpty
                        ? 'Tidak ada sesi untuk dibayar'
                        : 'Tandai dibayar · ${rupiah(total)}',
                  ),
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
          Row(
            children: [
              NeoTombol(
                warna: Neo.putih,
                padding: const EdgeInsets.all(10),
                onPressed: () => _geser(-1),
                child: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Periode ${bulanTahun(_bulan)}',
                      style: teks.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${tanggal(awal)} – ${tanggal(akhir)}',
                      style: teks.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              NeoTombol(
                warna: Neo.putih,
                padding: const EdgeInsets.all(10),
                onPressed: _bulan.isBefore(bulanIni) ? () => _geser(1) : null,
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 24),
          NeoBagian(judul: 'Belum dibayar (${sesiBelum.length} sesi)'),
          if (!hasilHadir.hasValue)
            NeoAsync(
              nilai: hasilHadir,
              onCobaLagi: () => segarkanDataTentor(ref),
              isi: (_) => const SizedBox(),
            )
          else if (belum.isEmpty)
            NeoKotak(
              warna: sudahDibayar > 0 ? Neo.hijau : Neo.putih,
              child: Text(
                sudahDibayar > 0
                    ? 'Semua sesi bulan ini sudah dibayar.'
                    : 'Tidak ada kehadiran di bulan ini.',
                style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          for (final k in belum) ...[
            NeoItem(
              onTap: () => tampilkanFotoKehadiran(context, tentor, k, warna),
              depan: NeoKotak(
                warna: warna,
                geser: Offset.zero,
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.photo_outlined, color: Neo.tinta),
              ),
              judul: tanggalJam(k.waktuDatang),
              subjudul: k.sesiBelumDibayar
                  .map((s) => '${s.program.label} ${angka(s.tarif)}')
                  .join(' · '),
              belakang: Text(
                angka(k.sesiBelumDibayar.fold(0, (a, s) => a + s.tarif)),
                style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (sesiBelum.isNotEmpty) ...[
            const SizedBox(height: 10),
            NeoKotak(
              warna: Neo.hijau,
              child: Column(
                children: [
                  NeoBarisNilai('Jumlah sesi', '${sesiBelum.length}'),
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
              'Total dihitung ulang di server dari sesi yang belum dibayar. '
              'Tarif mengikuti tarif saat sesi dicatat.',
              style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (_galat != null) ...[
            const SizedBox(height: 16),
            NeoKotak(
              warna: Neo.merah,
              geser: const Offset(2, 2),
              padding: const EdgeInsets.all(12),
              child: Text(
                _galat!,
                style: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
