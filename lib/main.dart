import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.lengkap) {
    runApp(const _KonfigurasiKosong());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  runApp(const ProviderScope(child: App()));
}

class _KonfigurasiKosong extends StatelessWidget {
  const _KonfigurasiKosong();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Konfigurasi Supabase belum diisi.\n\n'
              'Jalankan dengan:\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
