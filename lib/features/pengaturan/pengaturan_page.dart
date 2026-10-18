import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../kas/kategori_provider.dart';
import '../siswa/siswa.dart';
import 'kategori_editor.dart';

class PengaturanPage extends ConsumerWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = DataContoh.aturan;
    final kategori = ref.watch(kategoriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const NeoBagian(judul: 'Tahun ajaran'),
          NeoItem(
            warna: Neo.kuning,
            onTap: () => aksiContoh(context, 'Ganti tahun ajaran'),
            depan: const Icon(Icons.school_outlined, size: 28),
            judul: DataContoh.tahunAjaran,
            subjudul: 'Aktif · batas cicilan ${tanggal(a.batasCicilan)}',
            belakang: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 24),
          NeoBagian(
            judul: 'Program & biaya',
            aksi: 'Ubah',
            onAksi: () => aksiContoh(context, 'Ubah biaya'),
          ),
          NeoKotak(
            child: Column(
              children: [
                for (final p in Program.values)
                  NeoBarisNilai('Program ${p.label}', rupiah(a.biayaProgram)),
                NeoBarisNilai('Uang muka cicilan', rupiah(a.uangMuka)),
                NeoBarisNilai('Biaya admin pendaftaran', rupiah(a.biayaAdmin)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const NeoBagian(judul: 'Keringanan'),
          NeoKotak(
            child: Column(
              children: [
                for (final k in Keringanan.values)
                  NeoBarisNilai(
                    k.label,
                    k.persenPotongan == 0
                        ? '—'
                        : '${k.persenPotongan}%${k.adminGratis ? ' + admin' : ''}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NeoBagian(
            judul: 'Kategori pengeluaran',
            aksi: 'Tambah',
            onAksi: () => bukaEditorKategori(context),
          ),
          for (final k in kategori) ...[
            NeoItem(
              onTap: () => bukaEditorKategori(context, kategori: k),
              warna: k.diarsipkan ? const Color(0xFFEDEDED) : Neo.putih,
              depan: NeoKotak(
                warna: k.diarsipkan ? Neo.putih : Neo.oranye,
                geser: Offset.zero,
                padding: const EdgeInsets.all(8),
                child: Icon(k.ikon, color: Neo.tinta),
              ),
              judul: k.nama,
              subjudul: k.otomatis
                  ? 'Otomatis dari pembayaran'
                  : k.diarsipkan
                  ? 'Diarsipkan'
                  : null,
              belakang: const Icon(Icons.edit_outlined, size: 20),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 28),
          NeoBagian(
            judul: 'Akun',
            aksi: 'Tambah admin',
            onAksi: () => aksiContoh(context, 'Tambah akun admin'),
          ),
          const NeoItem(
            depan: NeoInisial(nama: 'Irfan', warna: Neo.kuning),
            judul: 'Irfan',
            subjudul: 'Owner',
            belakang: NeoLabel(teks: 'Aktif', warna: Neo.hijau),
          ),
          const SizedBox(height: 10),
          NeoItem(
            onTap: () => aksiContoh(context, 'Atur akun admin'),
            depan: const NeoInisial(nama: 'Admin Bimbel', warna: Neo.biru),
            judul: 'Admin Bimbel',
            subjudul: 'Admin',
            belakang: const NeoLabel(teks: 'Aktif', warna: Neo.hijau),
          ),
        ],
      ),
    );
  }
}
