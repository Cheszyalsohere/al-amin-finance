import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Keuangan Al-Amin',
      debugShowCheckedModeBanner: false,
      theme: buatTema(),
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      // Aplikasi dirancang untuk HP; di layar lebar tampil selebar HP di tengah.
      builder: (context, child) {
        final halaman = ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
        if (!Env.pratinjau) return halaman;
        return Column(
          children: [
            Material(
              color: Neo.pink,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Neo.tinta, width: Neo.garis),
                    ),
                  ),
                  child: const Text(
                    'MODE CONTOH · data tidak tersimpan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Neo.tinta,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: halaman,
              ),
            ),
          ],
        );
      },
    );
  }
}
