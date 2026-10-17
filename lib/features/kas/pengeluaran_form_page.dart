import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_input.dart';
import 'pengeluaran.dart';

class PengeluaranFormPage extends StatefulWidget {
  const PengeluaranFormPage({super.key});

  @override
  State<PengeluaranFormPage> createState() => _PengeluaranFormPageState();
}

class _PengeluaranFormPageState extends State<PengeluaranFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominal = TextEditingController();
  KategoriPengeluaran _kategori = KategoriPengeluaran.atk;
  DateTime _tanggal = hariIniContoh;

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

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    aksiContoh(context, 'Pengeluaran dicatat');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    // Honor dicatat otomatis dari halaman Bayar honor.
    final kategori = KategoriPengeluaran.values
        .where((k) => k != KategoriPengeluaran.honor)
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
            NeoPilihan<KategoriPengeluaran>(
              pilihan: kategori,
              terpilih: _kategori,
              label: (k) => k.label,
              warna: Neo.oranye,
              onPilih: (k) => setState(() => _kategori = k),
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
