import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import 'kategori_provider.dart';

class PengeluaranFormPage extends ConsumerStatefulWidget {
  const PengeluaranFormPage({super.key});

  @override
  ConsumerState<PengeluaranFormPage> createState() =>
      _PengeluaranFormPageState();
}

class _PengeluaranFormPageState extends ConsumerState<PengeluaranFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominal = TextEditingController();
  String? _kategoriId;
  DateTime _tanggal = hariIniContoh;
  TimeOfDay _jam = TimeOfDay.now();

  @override
  void dispose() {
    _nominal.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(context: context, initialTime: _jam);
    if (hasil != null) setState(() => _jam = hasil);
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    aksiContoh(context, 'Pengeluaran dicatat');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    // Honor dan gaji admin dicatat otomatis dari halaman pembayarannya.
    final kategori = ref
        .watch(kategoriProvider)
        .where((k) => !k.otomatis && !k.diarsipkan)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Catat pengeluaran')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.oranye,
            onPressed: _simpan,
            child: const Text('Simpan pengeluaran'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            NeoInputRupiah(
              controller: _nominal,
              validator: (v) =>
                  (v == null || v == 0) ? 'Nominal wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Kategori',
              style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            FormField<String>(
              validator: (_) =>
                  _kategoriId == null ? 'Pilih salah satu kategori' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeoPilihan<String>(
                    pilihan: [for (final k in kategori) k.id],
                    terpilih: _kategoriId,
                    label: (id) => kategori.firstWhere((k) => k.id == id).nama,
                    warna: Neo.oranye,
                    onPilih: (id) {
                      setState(() => _kategoriId = id);
                      field.didChange(id);
                    },
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: teks.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Misal: fotokopi soal latihan',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Keterangan wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),
            NeoItem(
              onTap: _pilihTanggal,
              depan: const Icon(Icons.event_outlined),
              judul: tanggalPanjang(_tanggal),
              subjudul: 'Tanggal pengeluaran',
              belakang: const Icon(Icons.edit_outlined, size: 20),
            ),
            const SizedBox(height: 12),
            NeoItem(
              onTap: _pilihJam,
              depan: const Icon(Icons.schedule_outlined),
              judul: '${jam(DateTime(0, 1, 1, _jam.hour, _jam.minute))} WIB',
              subjudul: 'Jam pengeluaran',
              belakang: const Icon(Icons.edit_outlined, size: 20),
            ),
            const SizedBox(height: 12),
            NeoItem(
              onTap: () => aksiContoh(context, 'Ambil foto nota'),
              depan: const Icon(Icons.add_a_photo_outlined),
              judul: 'Foto nota',
              subjudul: 'Opsional',
              belakang: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
