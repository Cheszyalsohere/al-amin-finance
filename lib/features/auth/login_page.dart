import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final warna = Theme.of(context).colorScheme;

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
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: warna.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keuangan Al-Amin',
                    style: teks.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk dengan akun yang diberikan owner',
                    style: teks.bodyMedium?.copyWith(
                      color: warna.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
                      if (!email.contains('@')) return 'Format email salah';
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
                          () => _sembunyikanPassword = !_sembunyikanPassword,
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
                    Text(
                      _galat!,
                      style: TextStyle(color: warna.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _memproses ? null : _masuk,
                    child: _memproses
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Masuk'),
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
