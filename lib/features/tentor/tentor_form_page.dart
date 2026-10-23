import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../siswa/siswa_repository.dart';
import 'tentor.dart';
import 'tentor_providers.dart';
import 'tentor_repository.dart';

/// Tambah tentor (tentorId null) atau ubah data & tarif. Hanya owner.
class TentorFormPage extends ConsumerWidget {
  const TentorFormPage({super.key, this.tentorId});

  final String? tentorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = tentorId;
    if (id == null) return const _Form(tentor: null);

    final hasil = ref.watch(tentorProvider(id));
    return switch (hasil) {
      AsyncData(value: final t?) => _Form(tentor: t),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: const NeoKeadaan.kosong(judul: 'Tentor tidak ditemukan'),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: NeoAsync(
          nilai: hasil,
          onCobaLagi: () => segarkanDataTentor(ref),
          isi: (_) => const SizedBox(),
        ),
      ),
    };
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.tentor});

  final Tentor? tentor;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.tentor?.nama);
  late final _hp = TextEditingController(text: widget.tentor?.noHp);
  late final _mapel = TextEditingController(text: widget.tentor?.mapel);
  late final _tarif = TextEditingController(
    text: widget.tentor == null ? '' : angka(widget.tentor!.tarifPerSesi),
  );
  late bool _aktif = widget.tentor?.aktif ?? true;
  bool _menyimpan = false;
  String? _galat;

  bool get _baru => widget.tentor == null;

  @override
  void dispose() {
    for (final c in [_nama, _hp, _mapel, _tarif]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _wajib(String? v, String nama) =>
      (v == null || v.trim().isEmpty) ? '$nama wajib diisi' : null;

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    try {
      await ref
          .read(tentorRepositoryProvider)
          .simpanTentor(
            DataTentor(
              id: widget.tentor?.id,
              nama: _nama.text.trim(),
              noHp: _hp.text.trim(),
              mapel: _mapel.text.trim(),
              tarifPerSesi: FormatRupiah.baca(_tarif.text)!,
              aktif: _aktif,
            ),
          );
      segarkanDataTentor(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _baru ? '${_nama.text} ditambahkan.' : 'Data tentor disimpan.',
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
    final teks = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_baru ? 'Tambah tentor' : 'Ubah tentor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            onPressed: _menyimpan ? null : _simpan,
            child: _menyimpan
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(_baru ? 'Tambah tentor' : 'Simpan perubahan'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const NeoBagian(judul: 'Data tentor'),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Misal: Kak Rizki Maulana',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _wajib(v, 'Nama'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mapel,
              decoration: const InputDecoration(labelText: 'Mata pelajaran'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => _wajib(v, 'Mata pelajaran'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hp,
              decoration: const InputDecoration(
                labelText: 'No. HP (opsional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 28),
            const NeoBagian(judul: 'Honor'),
            NeoInputRupiah(
              controller: _tarif,
              label: 'Tarif per sesi',
              validator: (v) =>
                  (v == null || v == 0) ? 'Tarif wajib diisi' : null,
            ),
            if (!_baru) ...[
              const SizedBox(height: 8),
              Text(
                'Tarif baru berlaku untuk sesi berikutnya. Sesi yang sudah '
                'dicatat tetap memakai tarif lama.',
                style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              const NeoBagian(judul: 'Status'),
              NeoPilihan<bool>(
                pilihan: const [true, false],
                terpilih: _aktif,
                label: (a) => a ? 'Aktif' : 'Nonaktif',
                onPilih: (a) => setState(() => _aktif = a),
              ),
              const SizedBox(height: 8),
              Text(
                'Tentor nonaktif tidak muncul saat absen, tapi riwayatnya tetap '
                'tersimpan.',
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
      ),
    );
  }
}
