import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';

class GantiPasswordPage extends ConsumerStatefulWidget {
  const GantiPasswordPage({super.key});

  @override
  ConsumerState<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends ConsumerState<GantiPasswordPage> {
  static const panjangMinimal = 8;

  final _formKey = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulangi = TextEditingController();

  bool _memproses = false;
  String? _galat;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulangi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _memproses = true;
      _galat = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .gantiPassword(passwordLama: _lama.text, passwordBaru: _baru.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Password berhasil diganti.')),
        );
      context.pop();
    } on AuthGagal catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ganti password')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeoTombol(
            onPressed: _memproses ? null : _simpan,
            child: _memproses
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Simpan password baru'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            NeoKotak(
              warna: Neo.biru,
              padding: const EdgeInsets.all(12),
              geser: const Offset(2, 2),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Neo.tinta),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Masukkan password lama dulu untuk memastikan ini '
                      'benar-benar kamu.',
                      style: teks.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _KolomPassword(
              controller: _lama,
              label: 'Password lama',
              aktif: !_memproses,
              autofill: AutofillHints.password,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password lama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _KolomPassword(
              controller: _baru,
              label: 'Password baru',
              aktif: !_memproses,
              autofill: AutofillHints.newPassword,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                if (v.length < panjangMinimal) {
                  return 'Minimal $panjangMinimal karakter';
                }
                if (v == _lama.text) {
                  return 'Harus berbeda dari password lama';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _KolomPassword(
              controller: _ulangi,
              label: 'Ulangi password baru',
              aktif: !_memproses,
              autofill: AutofillHints.newPassword,
              onSubmit: _simpan,
              validator: (v) => v != _baru.text ? 'Password tidak sama' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Minimal $panjangMinimal karakter. Campur huruf dan angka supaya '
              'lebih aman.',
              style: teks.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (_galat != null) ...[
              const SizedBox(height: 20),
              NeoKotak(
                warna: Neo.merah,
                geser: const Offset(2, 2),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Neo.tinta),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _galat!,
                        style: teks.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KolomPassword extends StatefulWidget {
  const _KolomPassword({
    required this.controller,
    required this.label,
    required this.aktif,
    required this.autofill,
    required this.validator,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String label;
  final bool aktif;
  final String autofill;
  final FormFieldValidator<String> validator;
  final VoidCallback? onSubmit;

  @override
  State<_KolomPassword> createState() => _KolomPasswordState();
}

class _KolomPasswordState extends State<_KolomPassword> {
  bool _sembunyi = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _sembunyi ? 'Tampilkan password' : 'Sembunyikan password',
          icon: Icon(
            _sembunyi
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _sembunyi = !_sembunyi),
        ),
      ),
      obscureText: _sembunyi,
      enabled: widget.aktif,
      autofillHints: [widget.autofill],
      textInputAction: widget.onSubmit == null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: widget.onSubmit == null
          ? null
          : (_) => widget.onSubmit!(),
      validator: widget.validator,
    );
  }
}
