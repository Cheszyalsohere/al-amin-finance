import 'package:flutter/material.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../siswa/siswa.dart';

class KuitansiPage extends StatelessWidget {
  const KuitansiPage({
    super.key,
    required this.siswaId,
    required this.pembayaranId,
    this.pembayaranBaru,
  });

  final String siswaId;
  final String pembayaranId;

  /// Pembayaran yang baru dicatat (belum ada di data).
  final Pembayaran? pembayaranBaru;

  @override
  Widget build(BuildContext context) {
    final siswa = DataContoh.siswa.where((s) => s.id == siswaId).firstOrNull;
    final bayar =
        pembayaranBaru ??
        siswa?.tagihan.pembayaran
            .where((p) => p.id == pembayaranId)
            .firstOrNull;

    if (siswa == null || bayar == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const NeoKeadaan.kosong(judul: 'Kuitansi tidak ditemukan'),
      );
    }

    final teks = Theme.of(context).textTheme;
    final t = siswa.tagihan;
    final sudahTermasuk = t.pembayaran.any((p) => p.id == bayar.id);
    final dibayar = t.dibayar + (sudahTermasuk ? 0 : bayar.jumlah);
    final sisa = (t.total - dibayar).clamp(0, t.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Kuitansi')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: NeoTombol(
                  warna: Neo.putih,
                  onPressed: () => aksiContoh(context, 'Simpan PDF'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined),
                      SizedBox(width: 6),
                      Text('PDF'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: NeoTombol(
                  warna: Neo.hijau,
                  onPressed: () => aksiContoh(
                    context,
                    'Kirim kuitansi ke WhatsApp ${siswa.namaWali}',
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_outlined),
                      SizedBox(width: 6),
                      Text('Kirim ke wali'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          NeoKotak(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Neo.kuning,
                    border: Border(
                      bottom: BorderSide(color: Neo.tinta, width: Neo.garis),
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(Neo.sudut - 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIMBEL AL-AMIN',
                        style: teks.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Kuitansi pembayaran',
                        style: teks.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NeoBarisNilai('No.', bayar.noKuitansi),
                      NeoBarisNilai('Tanggal', tanggal(bayar.tanggal)),
                      NeoBarisNilai('Jam', '${jam(bayar.tanggal)} WIB'),
                      NeoBarisNilai('Siswa', siswa.nama),
                      NeoBarisNilai(
                        'Program',
                        '${siswa.program.label} · ${siswa.kelas}',
                      ),
                      NeoBarisNilai('Metode', bayar.metode.label),
                      const SizedBox(height: 16),
                      NeoKotak(
                        warna: Neo.hijau,
                        geser: Offset.zero,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              'DIBAYAR',
                              style: teks.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                rupiah(bayar.jumlah),
                                style: teks.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeoBarisNilai('Total tagihan', rupiah(t.total)),
                      NeoBarisNilai('Total dibayar', rupiah(dibayar)),
                      NeoBarisNilai(
                        'Sisa',
                        sisa == 0 ? 'LUNAS' : rupiah(sisa),
                        tebal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
