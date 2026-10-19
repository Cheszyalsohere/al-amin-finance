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
import '../../core/widgets/neo_status.dart';
import 'siswa.dart';
import 'siswa_providers.dart';

class SiswaPage extends ConsumerStatefulWidget {
  const SiswaPage({super.key});

  @override
  ConsumerState<SiswaPage> createState() => _SiswaPageState();
}

class _SiswaPageState extends ConsumerState<SiswaPage> {
  String _cari = '';
  StatusTagihan? _status;

  @override
  Widget build(BuildContext context) {
    final hariIni = ref.watch(hariIniProvider);
    final tahunAjaran = ref.watch(aturanProvider).value?.tahunAjaran;

    return Scaffold(
      appBar: AppBar(
        title: Text(tahunAjaran == null ? 'Siswa' : 'Siswa · $tahunAjaran'),
      ),
      floatingActionButton: NeoTombol(
        warna: Neo.kuning,
        onPressed: () => context.push(Rute.tambahSiswa),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.add), SizedBox(width: 6), Text('Siswa')],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama siswa',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _cari = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: NeoPilihan<StatusTagihan?>(
              pilihan: const [null, ...StatusTagihan.values],
              terpilih: _status,
              label: (s) => s?.label ?? 'Semua',
              onPilih: (s) => setState(() => _status = s),
            ),
          ),
          Expanded(
            child: NeoAsync(
              nilai: ref.watch(daftarSiswaProvider),
              onCobaLagi: () => ref.invalidate(daftarSiswaProvider),
              isi: (semua) {
                final hasil = semua.where((s) {
                  final cocokNama = s.nama.toLowerCase().contains(
                    _cari.toLowerCase(),
                  );
                  final cocokStatus =
                      _status == null || s.tagihan.status(hariIni) == _status;
                  return cocokNama && cocokStatus;
                }).toList();

                if (semua.isEmpty) {
                  return const NeoKeadaan.kosong(
                    judul: 'Belum ada siswa',
                    pesan: 'Ketuk tombol + Siswa untuk mendaftarkan siswa.',
                  );
                }
                if (hasil.isEmpty) {
                  return const NeoKeadaan.kosong(
                    judul: 'Tidak ada siswa',
                    pesan: 'Coba ubah kata kunci atau filter.',
                  );
                }
                return RefreshIndicator(
                  color: Neo.tinta,
                  onRefresh: () => ref.refresh(daftarSiswaProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    itemCount: hasil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _BarisSiswa(siswa: hasil[i], hariIni: hariIni),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisSiswa extends StatelessWidget {
  const _BarisSiswa({required this.siswa, required this.hariIni});

  final Siswa siswa;
  final DateTime hariIni;

  @override
  Widget build(BuildContext context) {
    final status = siswa.tagihan.status(hariIni);
    final teks = Theme.of(context).textTheme;

    return NeoItem(
      onTap: () => context.push(Rute.detailSiswa(siswa.id)),
      depan: NeoInisial(
        nama: siswa.nama,
        warna: siswa.program == Program.sma ? Neo.ungu : Neo.biru,
      ),
      judul: siswa.nama,
      subjudul: '${siswa.program.label} · Kelas ${siswa.kelas}',
      belakang: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          NeoStatus(status),
          if (siswa.tagihan.sisa > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Sisa ${angka(siswa.tagihan.sisa)}',
              style: teks.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
