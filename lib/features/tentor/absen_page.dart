import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../siswa/siswa.dart';
import 'foto_kehadiran.dart';
import 'tentor.dart';
import 'tentor_page.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key, this.tentorId});

  final String? tentorId;

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  Tentor? _tentor;
  DateTime? _waktuFoto;
  final List<Program> _sesi = [Program.sma];

  @override
  void initState() {
    super.initState();
    if (widget.tentorId != null) {
      _tentor = DataContoh.tentor
          .where((t) => t.id == widget.tentorId)
          .firstOrNull;
    }
  }

  bool get _siap => _tentor != null && _waktuFoto != null && _sesi.isNotEmpty;

  void _simpan() {
    aksiContoh(context, 'Kehadiran ${_tentor!.nama} dicatat');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final tentor = _tentor;

    return Scaffold(
      appBar: AppBar(title: const Text('Absen tentor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.hijau,
            onPressed: _siap ? _simpan : null,
            child: Text(
              tentor == null || _waktuFoto == null
                  ? 'Lengkapi langkah 1 & 2'
                  : 'Simpan ${_sesi.length} sesi · '
                        '${rupiah(_sesi.length * tentor.tarifPerSesi)}',
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const _Langkah(nomor: 1, judul: 'Pilih tentor'),
          NeoPilihan<Tentor>(
            pilihan: DataContoh.tentor,
            terpilih: tentor,
            label: (t) => t.nama.replaceFirst('Kak ', ''),
            warna: Neo.biru,
            onPilih: (t) => setState(() {
              _tentor = t;
              _waktuFoto = null;
            }),
          ),
          const SizedBox(height: 28),
          const _Langkah(nomor: 2, judul: 'Foto kehadiran (wajib)'),
          if (tentor == null)
            const NeoKotak(child: Text('Pilih tentor terlebih dahulu.'))
          else if (_waktuFoto == null)
            NeoTombol(
              warna: Neo.kuning,
              padding: const EdgeInsets.symmetric(vertical: 36),
              onPressed: () => setState(() => _waktuFoto = DateTime.now()),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_camera_outlined, size: 44),
                  const SizedBox(height: 8),
                  const Text('Buka kamera'),
                  Text(
                    'Hanya dari kamera, tidak bisa dari galeri',
                    style: teks.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 220,
                    child: FotoKehadiran(
                      waktu: _waktuFoto!,
                      nama: tentor.nama,
                      warna: warnaTentor(tentor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => setState(() => _waktuFoto = DateTime.now()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Foto ulang'),
                ),
              ],
            ),
          const SizedBox(height: 28),
          const _Langkah(nomor: 3, judul: 'Sesi yang diajar hari ini'),
          for (final (i, program) in _sesi.indexed) ...[
            NeoKotak(
              padding: const EdgeInsets.all(12),
              geser: const Offset(3, 3),
              child: Row(
                children: [
                  Text(
                    'Sesi ${i + 1}',
                    style: teks.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeoPilihan<Program>(
                      pilihan: Program.values,
                      terpilih: program,
                      label: (p) => p.label,
                      onPilih: (p) => setState(() => _sesi[i] = p),
                    ),
                  ),
                  if (_sesi.length > 1)
                    IconButton(
                      tooltip: 'Hapus sesi',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _sesi.removeAt(i)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          NeoTombol(
            warna: Neo.putih,
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: () => setState(() => _sesi.add(_sesi.last)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.add), SizedBox(width: 6), Text('Sesi')],
            ),
          ),
          if (tentor != null) ...[
            const SizedBox(height: 16),
            NeoBarisNilai('Mapel', tentor.mapel),
            NeoBarisNilai('Tarif per sesi', rupiah(tentor.tarifPerSesi)),
          ],
        ],
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({required this.nomor, required this.judul});

  final int nomor;
  final String judul;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: Neo.kotak(
              warna: Neo.tinta,
              geser: Offset.zero,
              radius: 14,
            ),
            child: Text(
              '$nomor',
              style: const TextStyle(
                color: Neo.putih,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            judul.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
