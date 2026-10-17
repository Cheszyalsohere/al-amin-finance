import 'package:flutter/material.dart';

import '../../contoh/aksi_contoh.dart';
import '../../contoh/data_contoh.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../kas/pengeluaran.dart';
import '../siswa/siswa.dart';

class PengaturanPage extends StatelessWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = DataContoh.aturan;

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
            onAksi: () => aksiContoh(context, 'Tambah kategori'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in KategoriPengeluaran.values)
                NeoLabel(teks: k.label, ikon: k.ikon, warna: Neo.oranye),
            ],
          ),
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
