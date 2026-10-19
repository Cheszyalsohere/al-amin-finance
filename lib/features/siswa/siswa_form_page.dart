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
import 'siswa.dart';
import 'siswa_providers.dart';
import 'siswa_repository.dart';

class SiswaFormPage extends ConsumerStatefulWidget {
  const SiswaFormPage({super.key});

  @override
  ConsumerState<SiswaFormPage> createState() => _SiswaFormPageState();
}

class _SiswaFormPageState extends ConsumerState<SiswaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kelas = TextEditingController();
  final _sekolah = TextEditingController();
  final _wali = TextEditingController();
  final _hpWali = TextEditingController();

  Program _program = Program.smp;
  Keringanan _keringanan = Keringanan.reguler;
  Skema _skema = Skema.cicilan;
  bool _menyimpan = false;
  String? _galat;

  @override
  void dispose() {
    for (final c in [_nama, _kelas, _sekolah, _wali, _hpWali]) {
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
      final id = await ref
          .read(siswaRepositoryProvider)
          .daftarkan(
            DataSiswaBaru(
              nama: _nama.text,
              kelas: _kelas.text,
              asalSekolah: _sekolah.text,
              namaWali: _wali.text,
              noHpWali: _hpWali.text,
              program: _program,
              keringanan: _keringanan,
              skema: _skema,
            ),
          );
      ref.invalidate(daftarSiswaProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${_nama.text} terdaftar.')));
      context.pushReplacement(Rute.detailSiswa(id));
    } on GagalSimpan catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasil = ref.watch(aturanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah siswa')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            onPressed: _menyimpan || !hasil.hasValue ? null : _simpan,
            child: _menyimpan
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Simpan siswa'),
          ),
        ),
      ),
      body: NeoAsync(
        nilai: hasil,
        onCobaLagi: () => ref.invalidate(aturanProvider),
        isi: _form,
      ),
    );
  }

  Widget _form(Aturan aturan) {
    final biaya = aturan.biaya[_program];
    final rincian = biaya == null
        ? null
        : hitungTagihan(biaya, _keringanan, _skema);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const NeoBagian(judul: 'Data siswa'),
          TextFormField(
            controller: _nama,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => _wajib(v, 'Nama'),
          ),
          const SizedBox(height: 16),
          Text('Program', style: _gayaLabel(context)),
          const SizedBox(height: 8),
          NeoPilihan<Program>(
            pilihan: Program.values,
            terpilih: _program,
            label: (p) => p.label,
            onPilih: (p) => setState(() => _program = p),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _kelas,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  validator: (v) => _wajib(v, 'Kelas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _sekolah,
                  decoration: const InputDecoration(labelText: 'Asal sekolah'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const NeoBagian(judul: 'Wali murid'),
          TextFormField(
            controller: _wali,
            decoration: const InputDecoration(labelText: 'Nama wali'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => _wajib(v, 'Nama wali'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _hpWali,
            decoration: const InputDecoration(
              labelText: 'No. WhatsApp wali',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => _wajib(v, 'No. WhatsApp'),
          ),
          const SizedBox(height: 28),
          NeoBagian(judul: 'Biaya ${aturan.tahunAjaran}'),
          Text('Keringanan', style: _gayaLabel(context)),
          const SizedBox(height: 8),
          NeoPilihan<Keringanan>(
            pilihan: Keringanan.values,
            terpilih: _keringanan,
            label: (k) => k.persenPotongan == 0
                ? k.label
                : '${k.label} (${k.persenPotongan}%)',
            onPilih: (k) => setState(() => _keringanan = k),
          ),
          if (rincian != null && !rincian.gratis) ...[
            const SizedBox(height: 16),
            Text('Skema pembayaran', style: _gayaLabel(context)),
            const SizedBox(height: 8),
            NeoPilihan<Skema>(
              pilihan: Skema.values,
              terpilih: _skema,
              label: (s) => s.label,
              onPilih: (s) => setState(() => _skema = s),
            ),
          ],
          const SizedBox(height: 20),
          if (rincian == null)
            NeoKotak(
              warna: Neo.merah,
              child: Text(
                'Biaya program ${_program.label} belum diatur owner.',
              ),
            )
          else
            NeoKotak(
              warna: rincian.gratis ? Neo.hijau : Neo.kuning,
              child: Column(
                children: [
                  NeoBarisNilai('Biaya program', rupiah(rincian.biayaPokok)),
                  if (rincian.potongan > 0)
                    NeoBarisNilai(
                      'Potongan ${_keringanan.persenPotongan}%',
                      '− ${rupiah(rincian.potongan)}',
                    ),
                  NeoBarisNilai(
                    'Biaya admin',
                    rincian.biayaAdmin == 0
                        ? 'Gratis'
                        : rupiah(rincian.biayaAdmin),
                  ),
                  const Divider(color: Neo.tinta, thickness: 2, height: 20),
                  NeoBarisNilai(
                    'Total tagihan',
                    rincian.gratis ? 'GRATIS' : rupiah(rincian.total),
                    tebal: true,
                  ),
                  if (!rincian.gratis)
                    NeoBarisNilai(
                      _skema == Skema.lunas
                          ? 'Dibayar saat daftar'
                          : 'Minimal bayar saat daftar',
                      rupiah(rincian.pembayaranPertama),
                    ),
                  if (_skema == Skema.cicilan && !rincian.gratis)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Sisa dicicil bebas, lunas paling lambat '
                        '${tanggal(aturan.batasCicilan)}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_galat != null) ...[
            const SizedBox(height: 16),
            NeoKotak(
              warna: Neo.merah,
              geser: const Offset(2, 2),
              padding: const EdgeInsets.all(12),
              child: Text(
                _galat!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle? _gayaLabel(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
}
