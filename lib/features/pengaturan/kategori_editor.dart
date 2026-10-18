import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../kas/kategori_provider.dart';
import '../kas/pengeluaran.dart';

/// Buka lembar tambah kategori (jika [kategori] null) atau ubah kategori.
Future<void> bukaEditorKategori(
  BuildContext context, {
  KategoriPengeluaran? kategori,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Neo.putih,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Neo.sudut)),
      side: BorderSide(color: Neo.tinta, width: Neo.garis),
    ),
    builder: (_) => _EditorKategori(kategori: kategori),
  );
}

class _EditorKategori extends ConsumerStatefulWidget {
  const _EditorKategori({this.kategori});

  final KategoriPengeluaran? kategori;

  @override
  ConsumerState<_EditorKategori> createState() => _EditorKategoriState();
}

class _EditorKategoriState extends ConsumerState<_EditorKategori> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.kategori?.nama);
  late String _ikon = widget.kategori?.kodeIkon ?? 'lainnya';

  bool get _baru => widget.kategori == null;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(kategoriProvider.notifier);
    final k = widget.kategori;
    if (k == null) {
      notifier.tambah(nama: _nama.text, kodeIkon: _ikon);
    } else {
      notifier.ubah(k.id, nama: _nama.text, kodeIkon: _ikon);
    }
    Navigator.pop(context);
  }

  void _aturArsip(bool diarsipkan) {
    ref
        .read(kategoriProvider.notifier)
        .aturArsip(widget.kategori!.id, diarsipkan: diarsipkan);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final k = widget.kategori;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeoBagian(judul: _baru ? 'Kategori baru' : 'Ubah kategori'),
                TextFormField(
                  controller: _nama,
                  autofocus: _baru,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                  validator: (v) => ref
                      .read(kategoriProvider.notifier)
                      .validasiNama(v ?? '', kecualiId: k?.id),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ikon',
                  style: teks.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final MapEntry(key: kode, value: ikon)
                        in ikonKategori.entries)
                      Semantics(
                        button: true,
                        selected: kode == _ikon,
                        label: kode,
                        child: GestureDetector(
                          onTap: () => setState(() => _ikon = kode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: const EdgeInsets.all(10),
                            decoration: Neo.kotak(
                              warna: kode == _ikon ? Neo.oranye : Neo.putih,
                              geser: kode == _ikon
                                  ? const Offset(2, 2)
                                  : Offset.zero,
                              radius: 8,
                            ),
                            child: Icon(ikon, color: Neo.tinta),
                          ),
                        ),
                      ),
                  ],
                ),
                if (k != null && k.otomatis) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Kategori ini diisi otomatis oleh aplikasi, jadi tidak '
                    'bisa diarsipkan.',
                    style: teks.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                NeoTombol(
                  warna: Neo.oranye,
                  onPressed: _simpan,
                  child: Text(_baru ? 'Tambah kategori' : 'Simpan perubahan'),
                ),
                if (k != null && !k.otomatis) ...[
                  const SizedBox(height: 12),
                  NeoTombol(
                    warna: k.diarsipkan ? Neo.hijau : Neo.putih,
                    onPressed: () => _aturArsip(!k.diarsipkan),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          k.diarsipkan
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(k.diarsipkan ? 'Pulihkan' : 'Arsipkan'),
                      ],
                    ),
                  ),
                  if (!k.diarsipkan) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Kategori yang diarsipkan tidak muncul saat mencatat '
                      'pengeluaran baru, tapi riwayatnya tetap ada di laporan.',
                      textAlign: TextAlign.center,
                      style: teks.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
