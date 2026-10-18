import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../auth/auth_providers.dart';
import 'kategori_provider.dart';
import 'pengeluaran.dart';

Future<void> bukaDetailPengeluaran(BuildContext context, Pengeluaran e) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Neo.putih,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Neo.sudut)),
      side: BorderSide(color: Neo.tinta, width: Neo.garis),
    ),
    builder: (_) => _DetailPengeluaran(pengeluaran: e),
  );
}

class _DetailPengeluaran extends ConsumerWidget {
  const _DetailPengeluaran({required this.pengeluaran});

  final Pengeluaran pengeluaran;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = pengeluaran;
    final teks = Theme.of(context).textTheme;
    ref.watch(kategoriProvider);
    final kategori = ref.read(kategoriProvider.notifier).denganId(e.kategoriId);
    final owner = ref.watch(profilProvider).value?.isOwner ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeoBagian(judul: 'Detail pengeluaran'),
            NeoKotak(
              warna: Neo.oranye,
              child: Row(
                children: [
                  NeoKotak(
                    warna: Neo.putih,
                    geser: Offset.zero,
                    padding: const EdgeInsets.all(10),
                    child: Icon(kategori.ikon, color: Neo.tinta, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kategori.nama.toUpperCase(),
                          style: teks.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rupiah(e.jumlah),
                            style: teks.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeoKotak(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeoBarisNilai('Tanggal', tanggal(e.tanggal)),
                  NeoBarisNilai('Jam', '${jam(e.tanggal)} WIB'),
                  NeoBarisNilai('Dicatat oleh', e.dicatatOleh),
                  const Divider(color: Neo.tinta, thickness: 2, height: 20),
                  Text(
                    'Keterangan',
                    style: teks.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.keterangan,
                    style: teks.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NeoItem(
              onTap: () => aksiContoh(context, 'Lihat foto nota'),
              depan: const Icon(Icons.receipt_outlined),
              judul: 'Foto nota',
              subjudul: 'Ketuk untuk melihat',
              belakang: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 20),
            NeoTombol(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            if (owner) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => aksiContoh(
                  context,
                  'Batalkan pengeluaran (wajib isi alasan)',
                ),
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Batalkan transaksi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
