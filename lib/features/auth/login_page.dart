import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _memproses = false;
  bool _sembunyikanPassword = true;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _memproses = true;
      _galat = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .masuk(email: _email.text, password: _password.text);
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: const NeoKotak(
                        warna: Neo.kuning,
                        padding: EdgeInsets.all(14),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 40,
                          color: Neo.tinta,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'KEUANGAN\nAL-AMIN',
                    style: teks.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Masuk dengan akun yang diberikan owner.',
                    style: teks.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  NeoKotak(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_memproses,
                          validator: (nilai) {
                            final email = nilai?.trim() ?? '';
                            if (email.isEmpty) return 'Email wajib diisi';
                            if (!email.contains('@')) {
                              return 'Format email salah';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _sembunyikanPassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              icon: Icon(
                                _sembunyikanPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _sembunyikanPassword =
                                    !_sembunyikanPassword,
                              ),
                            ),
                          ),
                          obscureText: _sembunyikanPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !_memproses,
                          onFieldSubmitted: (_) => _masuk(),
                          validator: (nilai) => (nilai == null || nilai.isEmpty)
                              ? 'Password wajib diisi'
                              : null,
                        ),
                        if (_galat != null) ...[
                          const SizedBox(height: 16),
                          NeoKotak(
                            warna: Neo.merah,
                            geser: const Offset(2, 2),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Neo.tinta,
                                ),
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
                        const SizedBox(height: 24),
                        NeoTombol(
                          onPressed: _memproses ? null : _masuk,
                          child: _memproses
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('Masuk'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
