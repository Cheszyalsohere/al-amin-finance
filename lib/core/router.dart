import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_providers.dart';
import '../features/auth/login_page.dart';
import '../features/beranda/beranda_page.dart';

abstract final class Rute {
  static const masuk = '/masuk';
  static const beranda = '/';
}

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final segarkan = _StreamListenable(repo.perubahanAuth);
  ref.onDispose(segarkan.dispose);

  return GoRouter(
    initialLocation: Rute.beranda,
    refreshListenable: segarkan,
    redirect: (context, state) {
      final diHalamanMasuk = state.matchedLocation == Rute.masuk;
      if (!repo.sudahMasuk) return diHalamanMasuk ? null : Rute.masuk;
      if (diHalamanMasuk) return Rute.beranda;
      return null;
    },
    routes: [
      GoRoute(path: Rute.masuk, builder: (_, _) => const LoginPage()),
      GoRoute(path: Rute.beranda, builder: (_, _) => const BerandaPage()),
    ],
  );
});

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
