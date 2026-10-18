import 'package:al_amin_finance/contoh/data_contoh.dart';
import 'package:al_amin_finance/contoh/pratinjau.dart';
import 'package:al_amin_finance/features/auth/auth_providers.dart';
import 'package:al_amin_finance/features/kas/detail_pengeluaran.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('menampilkan jam dan bisa ditutup', (tester) async {
    final e = DataContoh.pengeluaran.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(RepoPratinjau())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => bukaDetailPengeluaran(context, e),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.text('Detail pengeluaran'.toUpperCase()), findsOneWidget);
    expect(find.text('09.05 WIB'), findsOneWidget);
    expect(find.text(e.keterangan), findsOneWidget);

    await tester.ensureVisible(find.text('Tutup'));
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Detail pengeluaran'.toUpperCase()), findsNothing);
  });
}
