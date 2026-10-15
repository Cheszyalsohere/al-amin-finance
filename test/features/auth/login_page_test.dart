import 'package:al_amin_finance/features/auth/auth_providers.dart';
import 'package:al_amin_finance/features/auth/auth_repository.dart';
import 'package:al_amin_finance/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoPalsu implements AuthRepository {
  _RepoPalsu({this.galat});

  final AuthGagal? galat;
  final percobaan = <(String, String)>[];

  @override
  Future<void> masuk({required String email, required String password}) async {
    percobaan.add((email, password));
    if (galat != null) throw galat!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pasang(WidgetTester tester, AuthRepository repo) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
}

void main() {
  testWidgets('menolak form kosong tanpa memanggil server', (tester) async {
    final repo = _RepoPalsu();
    await _pasang(tester, repo);

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
    expect(repo.percobaan, isEmpty);
  });

  testWidgets('mengirim email dan password yang diisi', (tester) async {
    final repo = _RepoPalsu();
    await _pasang(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin@alamin.id');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia');
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(repo.percobaan, [('admin@alamin.id', 'rahasia')]);
  });

  testWidgets('menampilkan pesan saat login gagal', (tester) async {
    final repo = _RepoPalsu(
      galat: const AuthGagal('Email atau password salah.'),
    );
    await _pasang(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin@alamin.id');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Email atau password salah.'), findsOneWidget);
  });
}
