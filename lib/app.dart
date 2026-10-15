import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      routerConfig: ref.watch(routerProvider),
    );
  }
}
