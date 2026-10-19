import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../kas/detail_pengeluaran.dart';
import 'ringkasan.dart';
import '../siswa/siswa_providers.dart';

enum JenisTransaksi {
  semua('Semua'),
  masuk('Pemasukan'),
  keluar('Pengeluaran');

  const JenisTransaksi(this.label);

  final String label;
}

/// Kelompokkan transaksi per hari, dari yang terbaru.
List<(DateTime, List<Transaksi>)> kelompokkanPerHari(List<Transaksi> daftar) {
  final hasil = <DateTime, List<Transaksi>>{};
  for (final t in daftar) {
    final hari = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
    hasil.putIfAbsent(hari, () => []).add(t);
  }
  final hari = hasil.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final h in hari)
      (h, hasil[h]!..sort((a, b) => b.tanggal.compareTo(a.tanggal))),
  ];
}

class RiwayatPage extends ConsumerStatefulWidget {
  const RiwayatPage({super.key});

  @override
  ConsumerState<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends ConsumerState<RiwayatPage> {
  late DateTime _bulan = _bulanIni;

  DateTime get _bulanIni {
    final h = ref.read(hariIniProvider);
    return DateTime(h.year, h.month);
  }

  JenisTransaksi _jenis = JenisTransaksi.semua;

  void _geser(int delta) =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final hasil = ref.watch(ringkasanProvider(_bulan));
    final r = hasil.value;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat transaksi')),
        body: NeoAsync(
          nilai: hasil,
          onCobaLagi: () => ref.invalidate(daftarSiswaProvider),
          isi: (_) => const SizedBox(),
        ),
      );
    }
    final daftar = r.transaksi.where(
      (t) => switch (_jenis) {
        JenisTransaksi.semua => true,
        JenisTransaksi.masuk => t.masuk,
        JenisTransaksi.keluar => !t.masuk,
      },
    );
    final kelompok = kelompokkanPerHari(daftar.toList());
    final bisaMaju = _bulan.isBefore(_bulanIni);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat transaksi')),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeoStatistik(
                  label: 'Masuk',
                  nilai: angka(r.pemasukan),
                  ikon: Icons.south_west,
                  warna: Neo.hijau,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoStatistik(
                  label: 'Keluar',
                  nilai: angka(r.pengeluaran),
                  ikon: Icons.north_east,
                  warna: Neo.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeoPilihan<JenisTransaksi>(
            pilihan: JenisTransaksi.values,
            terpilih: _jenis,
            label: (j) => j.label,
            onPilih: (j) => setState(() => _jenis = j),
          ),
          const SizedBox(height: 20),
          if (kelompok.isEmpty)
            const NeoKeadaan.kosong(
              judul: 'Tidak ada transaksi',
              pesan: 'Belum ada transaksi di bulan ini.',
            ),
          for (final (hari, isi) in kelompok) ...[
            _JudulHari(hari: hari, isi: isi),
            for (final t in isi) ...[
              BarisTransaksi(transaksi: t, tampilkanTanggal: false),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _JudulHari extends StatelessWidget {
  const _JudulHari({required this.hari, required this.isi});

  final DateTime hari;
  final List<Transaksi> isi;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final bersih = isi.fold(0, (a, t) => a + (t.masuk ? t.jumlah : -t.jumlah));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tanggalPanjang(hari),
              style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${bersih >= 0 ? '+' : '−'}${angka(bersih.abs())}',
            style: teks.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Satu baris transaksi; bisa diketuk untuk membuka kuitansi atau detail.
class BarisTransaksi extends StatelessWidget {
  const BarisTransaksi({
    super.key,
    required this.transaksi,
    this.tampilkanTanggal = true,
  });

  final Transaksi transaksi;
  final bool tampilkanTanggal;

  @override
  Widget build(BuildContext context) {
    final t = transaksi;
    final waktu = tampilkanTanggal ? tanggalJam(t.tanggal) : jam(t.tanggal);

    return NeoItem(
      onTap: () {
        if (t.masuk) {
          context.push(Rute.kuitansi(t.siswaId!, t.pembayaranId!));
        } else {
          bukaDetailPengeluaran(context, t.pengeluaran!);
        }
      },
      depan: NeoKotak(
        warna: t.masuk ? Neo.hijau : Neo.pink,
        geser: Offset.zero,
        padding: const EdgeInsets.all(8),
        child: Icon(
          t.masuk ? Icons.south_west : Icons.north_east,
          size: 20,
          color: Neo.tinta,
        ),
      ),
      judul: t.judul,
      subjudul: '$waktu · ${t.keterangan}',
      belakang: Text(
        '${t.masuk ? '+' : '−'}${angka(t.jumlah)}',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
