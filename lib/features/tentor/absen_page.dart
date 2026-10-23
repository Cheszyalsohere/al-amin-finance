import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../siswa/siswa.dart';
import '../siswa/siswa_repository.dart';
import 'foto_absen.dart';
import 'foto_kehadiran.dart';
import 'tentor.dart';
import 'tentor_page.dart';
import 'tentor_providers.dart';

class AbsenPage extends ConsumerStatefulWidget {
  const AbsenPage({super.key, this.tentorId});

  final String? tentorId;

  @override
  ConsumerState<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends ConsumerState<AbsenPage> {
  late String? _tentorId = widget.tentorId;
  Uint8List? _foto;
  DateTime? _waktuFoto;
  final List<Program> _sesi = [Program.sma];
  bool _memotret = false;
  bool _menyimpan = false;
  String? _galat;

  Future<void> _ambilFoto(Tentor tentor) async {
    setState(() {
      _memotret = true;
      _galat = null;
    });
    try {
      // Hanya dari kamera, tidak dari galeri.
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (file == null) return;

      final repo = ref.read(tentorRepositoryProvider);
      final waktu = await repo.waktuServer();
      final foto = await olahFotoAbsen(await file.readAsBytes(), [
        keAscii(tentor.nama),
        keAscii('${tanggal(waktu)} - ${jam(waktu)} WIB'),
        'Bimbel Al-Amin',
      ]);
      if (!mounted) return;
      setState(() {
        _foto = foto;
        _waktuFoto = waktu;
      });
    } on GagalSimpan catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } on Exception {
      if (mounted) {
        setState(() => _galat = 'Gagal mengambil foto. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _memotret = false);
    }
  }

  Future<void> _simpan(Tentor tentor) async {
    final foto = _foto;
    if (foto == null || _sesi.isEmpty) return;

    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    try {
      final repo = ref.read(tentorRepositoryProvider);
      final path = await repo.unggahFoto(tentor.id, foto);
      await repo.catatKehadiran(
        tentorId: tentor.id,
        fotoPath: path,
        sesi: [for (final p in _sesi) (program: p, mapel: tentor.mapel)],
      );
      segarkanDataTentor(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kehadiran ${tentor.nama} tercatat (${_sesi.length} sesi).',
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
    final hasil = ref.watch(daftarTentorProvider);
    final aktif = (hasil.value ?? const <Tentor>[])
        .where((t) => t.aktif)
        .toList();
    final tentor = aktif.where((t) => t.id == _tentorId).firstOrNull;
    final siap = tentor != null && _foto != null && _sesi.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Absen tentor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.hijau,
            onPressed: siap && !_menyimpan ? () => _simpan(tentor) : null,
            child: _menyimpan
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    tentor == null || _foto == null
                        ? 'Lengkapi langkah 1 & 2'
                        : 'Simpan ${_sesi.length} sesi · '
                              '${rupiah(_sesi.length * tentor.tarifPerSesi)}',
                  ),
          ),
        ),
      ),
      body: !hasil.hasValue
          ? NeoAsync(
              nilai: hasil,
              onCobaLagi: () => segarkanDataTentor(ref),
              isi: (_) => const SizedBox(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const _Langkah(nomor: 1, judul: 'Pilih tentor'),
                if (aktif.isEmpty)
                  const NeoKotak(child: Text('Belum ada tentor aktif.'))
                else
                  NeoPilihan<String>(
                    pilihan: [for (final t in aktif) t.id],
                    terpilih: _tentorId,
                    label: (id) => aktif
                        .firstWhere((t) => t.id == id)
                        .nama
                        .replaceFirst(RegExp(r'^Kak\s+'), ''),
                    warna: Neo.biru,
                    onPilih: (id) => setState(() {
                      _tentorId = id;
                      _foto = null;
                      _waktuFoto = null;
                    }),
                  ),
                const SizedBox(height: 28),
                const _Langkah(nomor: 2, judul: 'Foto kehadiran (wajib)'),
                if (tentor == null)
                  const NeoKotak(child: Text('Pilih tentor terlebih dahulu.'))
                else if (_foto == null)
                  NeoTombol(
                    warna: Neo.kuning,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    onPressed: _memotret ? null : () => _ambilFoto(tentor),
                    child: _memotret
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text('Memproses foto…'),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_outlined, size: 44),
                              const SizedBox(height: 8),
                              const Text('Buka kamera'),
                              Text(
                                'Hanya dari kamera, tidak bisa dari galeri',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
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
                            bytes: _foto,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _menyimpan || _memotret
                            ? null
                            : () => _ambilFoto(tentor),
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 6),
                      Text('Sesi'),
                    ],
                  ),
                ),
                if (tentor != null) ...[
                  const SizedBox(height: 16),
                  NeoBarisNilai('Mapel', tentor.mapel),
                  NeoBarisNilai('Tarif per sesi', rupiah(tentor.tarifPerSesi)),
                ],
                if (_galat != null) ...[
                  const SizedBox(height: 16),
                  NeoKotak(
                    warna: Neo.merah,
                    geser: const Offset(2, 2),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _galat!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
