import 'package:al_amin_finance/features/auth/auth_providers.dart';
import 'package:al_amin_finance/features/auth/auth_repository.dart';
import 'package:al_amin_finance/features/auth/ganti_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RepoPalsu implements AuthRepository {
  _RepoPalsu({this.galat});

  final AuthGagal? galat;
  final permintaan = <(String, String)>[];

  @override
  Future<void> gantiPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    permintaan.add((passwordLama, passwordBaru));
    if (galat != null) throw galat!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pasang(WidgetTester tester, AuthRepository repo) {
  final router = GoRouter(
    initialLocation: '/password',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Beranda')),
        routes: [
          GoRoute(
            path: 'password',
            builder: (_, _) => const GantiPasswordPage(),
          ),
        ],
      ),
    ],
  );
  return tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

Future<void> _isi(
  WidgetTester tester,
  String lama,
  String baru,
  String ulangi,
) async {
  final kolom = find.byType(TextFormField);
  await tester.enterText(kolom.at(0), lama);
  await tester.enterText(kolom.at(1), baru);
  await tester.enterText(kolom.at(2), ulangi);
  await tester.tap(find.text('Simpan password baru'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menolak password baru yang terlalu pendek', (tester) async {
    final repo = _RepoPalsu();
    await _pasang(tester, repo);

    await _isi(tester, 'lama1234', 'abc', 'abc');

    expect(find.text('Minimal 8 karakter'), findsOneWidget);
    expect(repo.permintaan, isEmpty);
  });

  testWidgets('menolak jika ulangi password tidak sama', (tester) async {
    final repo = _RepoPalsu();
    await _pasang(tester, repo);

    await _isi(tester, 'lama1234', 'baru12345', 'baru12346');

    expect(find.text('Password tidak sama'), findsOneWidget);
    expect(repo.permintaan, isEmpty);
  });

  testWidgets('menolak password baru yang sama dengan lama', (tester) async {
    final repo = _RepoPalsu();
    await _pasang(tester, repo);

    await _isi(tester, 'sama12345', 'sama12345', 'sama12345');

    expect(find.text('Harus berbeda dari password lama'), findsOneWidget);
    expect(repo.permintaan, isEmpty);
  });

  testWidgets('berhasil lalu kembali ke halaman sebelumnya', (tester) async {
    final repo = _RepoPalsu();
    await _pasang(tester, repo);

    await _isi(tester, 'lama1234', 'baru12345', 'baru12345');

    expect(repo.permintaan, [('lama1234', 'baru12345')]);
    expect(find.text('Password berhasil diganti.'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('menampilkan pesan jika password lama salah', (tester) async {
    final repo = _RepoPalsu(galat: const AuthGagal('Password lama salah.'));
    await _pasang(tester, repo);

    await _isi(tester, 'salah123', 'baru12345', 'baru12345');

    expect(find.text('Password lama salah.'), findsOneWidget);
    expect(find.byType(GantiPasswordPage), findsOneWidget);
  });

  test('pesan galat dari Supabase diterjemahkan', () {
    expect(
      pesanGantiPassword(const AuthException('x', code: 'same_password')),
      'Password baru harus berbeda dari password lama.',
    );
    expect(
      pesanGantiPassword(const AuthException('x', code: 'weak_password')),
      contains('terlalu lemah'),
    );
  });
}
