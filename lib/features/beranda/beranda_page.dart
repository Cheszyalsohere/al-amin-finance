import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../auth/auth_providers.dart';
import '../auth/profil.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan Al-Amin'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => _konfirmasiKeluar(context, ref),
          ),
        ],
      ),
      body: switch (profil) {
        AsyncData(value: final p?) when p.aktif => _IsiBeranda(profil: p),
        AsyncData() => _AkunTidakAktif(
          onKeluar: () => ref.read(authRepositoryProvider).keluar(),
        ),
        AsyncError() => _GagalMemuat(
          onCobaLagi: () => ref.invalidate(profilProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _konfirmasiKeluar(BuildContext context, WidgetRef ref) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          NeoTombol(
            warna: Neo.merah,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin ?? false) await ref.read(authRepositoryProvider).keluar();
  }
}

class _IsiBeranda extends StatelessWidget {
  const _IsiBeranda({required this.profil});

  final Profil profil;

  static const _menu = [
    (Icons.payments_outlined, 'Catat Pembayaran', Neo.kuning),
    (Icons.groups_outlined, 'Siswa', Neo.biru),
    (Icons.warning_amber_outlined, 'Tunggakan', Neo.pink),
    (Icons.co_present_outlined, 'Absen Tentor', Neo.hijau),
    (Icons.receipt_long_outlined, 'Pengeluaran', Neo.oranye),
    (Icons.bar_chart_outlined, 'Laporan', Neo.ungu),
  ];

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Halo,',
          style: teks.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          profil.nama,
          style: teks.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: NeoLabel(
            teks: profil.peran.label,
            ikon: profil.isOwner ? Icons.verified_user : Icons.badge_outlined,
            warna: profil.isOwner ? Neo.kuning : Neo.biru,
          ),
        ),
        const SizedBox(height: 28),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15,
          children: [
            for (final (ikon, judul, warna) in _menu)
              NeoTombol(
                warna: warna,
                padding: const EdgeInsets.all(12),
                onPressed: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('$judul segera hadir')),
                  ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ikon, size: 36),
                    const SizedBox(height: 10),
                    Text(judul),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AkunTidakAktif extends StatelessWidget {
  const _AkunTidakAktif({required this.onKeluar});

  final VoidCallback onKeluar;

  @override
  Widget build(BuildContext context) {
    return _Pesan(
      ikon: Icons.block,
      teks: 'Akun ini tidak aktif.\nHubungi owner untuk mengaktifkannya.',
      tombol: NeoTombol(onPressed: onKeluar, child: const Text('Keluar')),
    );
  }
}

class _GagalMemuat extends StatelessWidget {
  const _GagalMemuat({required this.onCobaLagi});

  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) {
    return _Pesan(
      ikon: Icons.wifi_off,
      teks: 'Gagal memuat data akun.\nPeriksa koneksi internet.',
      tombol: NeoTombol(onPressed: onCobaLagi, child: const Text('Coba lagi')),
    );
  }
}

class _Pesan extends StatelessWidget {
  const _Pesan({required this.ikon, required this.teks, required this.tombol});

  final IconData ikon;
  final String teks;
  final Widget tombol;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeoKotak(
              warna: Neo.pink,
              padding: const EdgeInsets.all(14),
              child: Icon(ikon, size: 40, color: Neo.tinta),
            ),
            const SizedBox(height: 20),
            Text(
              teks,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            tombol,
          ],
        ),
      ),
    );
  }
}
