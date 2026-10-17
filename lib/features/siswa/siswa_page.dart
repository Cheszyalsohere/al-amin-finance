import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../../core/widgets/neo_status.dart';
import 'siswa.dart';

class SiswaPage extends StatefulWidget {
  const SiswaPage({super.key});

  @override
  State<SiswaPage> createState() => _SiswaPageState();
}

class _SiswaPageState extends State<SiswaPage> {
  String _cari = '';
  StatusTagihan? _status;

  @override
  Widget build(BuildContext context) {
    final semua = DataContoh.siswa;
    final hasil = semua.where((s) {
      final cocokNama = s.nama.toLowerCase().contains(_cari.toLowerCase());
      final cocokStatus =
          _status == null || s.tagihan.status(hariIniContoh) == _status;
      return cocokNama && cocokStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Siswa · ${DataContoh.tahunAjaran}')),
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
            child: hasil.isEmpty
                ? const NeoKeadaan.kosong(
                    judul: 'Tidak ada siswa',
                    pesan: 'Coba ubah kata kunci atau filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    itemCount: hasil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _BarisSiswa(siswa: hasil[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarisSiswa extends StatelessWidget {
  const _BarisSiswa({required this.siswa});

  final Siswa siswa;

  @override
  Widget build(BuildContext context) {
    final status = siswa.tagihan.status(hariIniContoh);
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
