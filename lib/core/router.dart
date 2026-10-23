import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_providers.dart';
import '../features/auth/ganti_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/beranda/beranda_page.dart';
import '../features/kas/pengeluaran_form_page.dart';
import '../features/kas/kas_page.dart';
import '../features/laporan/laporan_page.dart';
import '../features/laporan/riwayat_page.dart';
import '../features/pembayaran/catat_pembayaran_page.dart';
import '../features/pembayaran/kuitansi_page.dart';
import '../features/pengaturan/pengaturan_page.dart';
import '../features/siswa/siswa_detail_page.dart';
import '../features/siswa/siswa_form_page.dart';
import '../features/siswa/siswa.dart';
import '../features/siswa/siswa_page.dart';
import '../features/siswa/tunggakan_page.dart';
import '../features/tentor/absen_page.dart';
import '../features/tentor/bayar_honor_page.dart';
import '../features/tentor/tentor_detail_page.dart';
import '../features/tentor/tentor_form_page.dart';
import '../features/tentor/tentor_page.dart';
import 'shell.dart';

abstract final class Rute {
  static const masuk = '/masuk';
  static const beranda = '/';
  static const siswa = '/siswa';
  static const tambahSiswa = '/siswa/tambah';
  static String detailSiswa(String id) => '/siswa/$id';
  static const tunggakan = '/tunggakan';
  static String bayar([String? siswaId]) =>
      siswaId == null ? '/bayar' : '/bayar?siswa=$siswaId';
  static String kuitansi(String siswaId, String pembayaranId) =>
      '/kuitansi/$siswaId/$pembayaranId';
  static const tentor = '/tentor';
  static const tambahTentor = '/tentor/tambah';
  static String detailTentor(String id) => '/tentor/$id';
  static String ubahTentor(String id) => '/tentor/$id/ubah';
  static String absen([String? tentorId]) =>
      tentorId == null ? '/absen' : '/absen?tentor=$tentorId';
  static String honor(String tentorId) => '/honor/$tentorId';
  static const kas = '/kas';
  static const tambahPengeluaran = '/kas/tambah';
  static const laporan = '/laporan';
  static const riwayat = '/riwayat';
  static const pengaturan = '/pengaturan';
  static const gantiPassword = '/akun/password';
}

final _akar = GlobalKey<NavigatorState>(debugLabel: 'akar');

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final segarkan = _StreamListenable(repo.perubahanAuth);
  ref.onDispose(segarkan.dispose);

  GoRoute layarPenuh(String path, Widget Function(GoRouterState) builder) =>
      GoRoute(
        path: path,
        parentNavigatorKey: _akar,
        builder: (_, state) => builder(state),
      );

  return GoRouter(
    navigatorKey: _akar,
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
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => Shell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.beranda,
                builder: (_, _) => const BerandaPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.siswa,
                builder: (_, _) => const SiswaPage(),
                routes: [
                  layarPenuh('tambah', (_) => const SiswaFormPage()),
                  layarPenuh(
                    ':id',
                    (s) => SiswaDetailPage(siswaId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.tentor,
                builder: (_, _) => const TentorPage(),
                routes: [
                  layarPenuh('tambah', (_) => const TentorFormPage()),
                  layarPenuh(
                    ':id',
                    (s) => TentorDetailPage(tentorId: s.pathParameters['id']!),
                  ),
                  layarPenuh(
                    ':id/ubah',
                    (s) => TentorFormPage(tentorId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.kas,
                builder: (_, _) => const KasPage(),
                routes: [
                  layarPenuh('tambah', (_) => const PengeluaranFormPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.laporan,
                builder: (_, _) => const LaporanPage(),
              ),
            ],
          ),
        ],
      ),
      layarPenuh(Rute.tunggakan, (_) => const TunggakanPage()),
      layarPenuh(
        '/bayar',
        (s) => CatatPembayaranPage(siswaId: s.uri.queryParameters['siswa']),
      ),
      layarPenuh(
        '/kuitansi/:siswa/:pembayaran',
        (s) => KuitansiPage(
          siswaId: s.pathParameters['siswa']!,
          pembayaranId: s.pathParameters['pembayaran']!,
          pembayaranBaru: s.extra is Pembayaran ? s.extra! as Pembayaran : null,
        ),
      ),
      layarPenuh(
        '/absen',
        (s) => AbsenPage(tentorId: s.uri.queryParameters['tentor']),
      ),
      layarPenuh(
        '/honor/:tentor',
        (s) => BayarHonorPage(tentorId: s.pathParameters['tentor']!),
      ),
      layarPenuh(Rute.riwayat, (_) => const RiwayatPage()),
      layarPenuh(Rute.pengaturan, (_) => const PengaturanPage()),
      layarPenuh(Rute.gantiPassword, (_) => const GantiPasswordPage()),
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
