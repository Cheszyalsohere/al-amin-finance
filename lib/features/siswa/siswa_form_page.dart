import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import 'siswa.dart';

class SiswaFormPage extends StatefulWidget {
  const SiswaFormPage({super.key});

  @override
  State<SiswaFormPage> createState() => _SiswaFormPageState();
}

class _SiswaFormPageState extends State<SiswaFormPage> {
  final _formKey = GlobalKey<FormState>();
  Program _program = Program.smp;
  Keringanan _keringanan = Keringanan.reguler;
  Skema _skema = Skema.cicilan;

  String? _wajib(String? v, String nama) =>
      (v == null || v.trim().isEmpty) ? '$nama wajib diisi' : null;

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    aksiContoh(context, 'Siswa ditambahkan');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rincian = hitungTagihan(DataContoh.aturan, _keringanan, _skema);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah siswa')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            onPressed: _simpan,
            child: const Text('Simpan siswa'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const NeoBagian(judul: 'Data siswa'),
            TextFormField(
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
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    validator: (v) => _wajib(v, 'Kelas'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Asal sekolah',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const NeoBagian(judul: 'Wali murid'),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nama wali'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _wajib(v, 'Nama wali'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'No. WhatsApp wali',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => _wajib(v, 'No. WhatsApp'),
            ),
            const SizedBox(height: 28),
            NeoBagian(judul: 'Biaya ${DataContoh.tahunAjaran}'),
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
            if (!rincian.gratis) ...[
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
                        '${tanggal(DataContoh.aturan.batasCicilan)}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _gayaLabel(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
}
