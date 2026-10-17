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
import '../../core/widgets/neo_status.dart';
import '../siswa/siswa.dart';

class CatatPembayaranPage extends StatefulWidget {
  const CatatPembayaranPage({super.key, this.siswaId});

  final String? siswaId;

  @override
  State<CatatPembayaranPage> createState() => _CatatPembayaranPageState();
}

class _CatatPembayaranPageState extends State<CatatPembayaranPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominal = TextEditingController();
  Siswa? _siswa;
  Metode _metode = Metode.tunai;

  @override
  void initState() {
    super.initState();
    if (widget.siswaId != null) {
      _siswa = DataContoh.siswa
          .where((s) => s.id == widget.siswaId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _nominal.dispose();
    super.dispose();
  }

  void _isiNominal(int nilai) {
    _nominal.text = angka(nilai);
    setState(() {});
  }

  Future<void> _pilihSiswa() async {
    final terpilih = await showModalBottomSheet<Siswa>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Neo.putih,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Neo.sudut)),
        side: BorderSide(color: Neo.tinta, width: Neo.garis),
      ),
      builder: (_) => const _PemilihSiswa(),
    );
    if (terpilih != null) {
      setState(() {
        _siswa = terpilih;
        _nominal.clear();
      });
    }
  }

  void _simpan() {
    final siswa = _siswa;
    if (siswa == null || !_formKey.currentState!.validate()) return;

    final baru = Pembayaran(
      id: 'baru',
      tanggal: DateTime.now(),
      jumlah: FormatRupiah.baca(_nominal.text)!,
      metode: _metode,
      noKuitansi: 'KW/2026/10/0999',
    );
    aksiContoh(context, 'Pembayaran dicatat');
    context.pushReplacement(Rute.kuitansi(siswa.id, baru.id), extra: baru);
  }

  @override
  Widget build(BuildContext context) {
    final siswa = _siswa;
    final teks = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Catat pembayaran')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            warna: Neo.hijau,
            onPressed: siswa == null ? null : _simpan,
            child: const Text('Simpan & buat kuitansi'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const NeoBagian(judul: 'Siswa'),
            if (siswa == null)
              NeoItem(
                onTap: _pilihSiswa,
                warna: Neo.kuning,
                depan: const Icon(Icons.person_search_outlined, size: 28),
                judul: 'Pilih siswa',
                subjudul: 'Ketuk untuk mencari siswa',
                belakang: const Icon(Icons.chevron_right),
              )
            else
              NeoItem(
                onTap: widget.siswaId == null ? _pilihSiswa : null,
                depan: NeoInisial(nama: siswa.nama),
                judul: siswa.nama,
                subjudul: '${siswa.program.label} · Kelas ${siswa.kelas}',
                belakang: NeoStatus(siswa.tagihan.status(hariIniContoh)),
              ),
            if (siswa != null) ...[
              const SizedBox(height: 16),
              NeoKotak(
                warna: Neo.kuning,
                child: Column(
                  children: [
                    NeoBarisNilai('Total tagihan', rupiah(siswa.tagihan.total)),
                    NeoBarisNilai(
                      'Sudah dibayar',
                      rupiah(siswa.tagihan.dibayar),
                    ),
                    const Divider(color: Neo.tinta, thickness: 2, height: 20),
                    NeoBarisNilai(
                      'Sisa',
                      rupiah(siswa.tagihan.sisa),
                      tebal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const NeoBagian(judul: 'Pembayaran'),
              NeoInputRupiah(
                controller: _nominal,
                label: 'Nominal dibayar',
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v == 0) return 'Nominal wajib diisi';
                  if (v > siswa.tagihan.sisa) {
                    return 'Melebihi sisa tagihan (${rupiah(siswa.tagihan.sisa)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (siswa.tagihan.dibayar == 0 &&
                      siswa.tagihan.skema == Skema.cicilan)
                    _Cepat(
                      'Uang muka ${angka(siswa.tagihan.rincian.pembayaranPertama)}',
                      () =>
                          _isiNominal(siswa.tagihan.rincian.pembayaranPertama),
                    ),
                  _Cepat(
                    'Lunasi ${angka(siswa.tagihan.sisa)}',
                    () => _isiNominal(siswa.tagihan.sisa),
                  ),
                ],
              ),
              if (siswa.tagihan.dibayar == 0 &&
                  siswa.tagihan.skema == Skema.cicilan) ...[
                const SizedBox(height: 12),
                Text(
                  'Pembayaran pertama minimal uang muka + admin: '
                  '${rupiah(siswa.tagihan.rincian.pembayaranPertama)}.',
                  style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Metode',
                style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              NeoPilihan<Metode>(
                pilihan: Metode.values,
                terpilih: _metode,
                label: (m) => m.label,
                onPilih: (m) => setState(() => _metode = m),
              ),
              if (_metode == Metode.transfer) ...[
                const SizedBox(height: 16),
                NeoItem(
                  onTap: () => aksiContoh(context, 'Ambil foto bukti transfer'),
                  depan: const Icon(Icons.add_a_photo_outlined, size: 26),
                  judul: 'Foto bukti transfer',
                  subjudul: 'Opsional',
                  belakang: const Icon(Icons.chevron_right),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cepat extends StatelessWidget {
  const _Cepat(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoTombol(
      warna: Neo.biru,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onTap,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PemilihSiswa extends StatefulWidget {
  const _PemilihSiswa();

  @override
  State<_PemilihSiswa> createState() => _PemilihSiswaState();
}

class _PemilihSiswaState extends State<_PemilihSiswa> {
  String _cari = '';

  @override
  Widget build(BuildContext context) {
    final daftar = DataContoh.siswa
        .where((s) => s.tagihan.sisa > 0)
        .where((s) => s.nama.toLowerCase().contains(_cari.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NeoBagian(judul: 'Pilih siswa (belum lunas)'),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari nama',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _cari = v),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 6, right: 4),
                itemCount: daftar.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => NeoItem(
                  onTap: () => Navigator.pop(context, daftar[i]),
                  depan: NeoInisial(nama: daftar[i].nama),
                  judul: daftar[i].nama,
                  subjudul: 'Sisa ${rupiah(daftar[i].tagihan.sisa)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
