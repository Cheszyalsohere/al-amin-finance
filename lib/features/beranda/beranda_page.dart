import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          FilledButton(
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
    (Icons.payments_outlined, 'Catat Pembayaran'),
    (Icons.groups_outlined, 'Siswa'),
    (Icons.warning_amber_outlined, 'Tunggakan'),
    (Icons.co_present_outlined, 'Absen Tentor'),
    (Icons.receipt_long_outlined, 'Pengeluaran'),
    (Icons.bar_chart_outlined, 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Halo, ${profil.nama}', style: teks.headlineSmall),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: Icon(
              profil.isOwner ? Icons.verified_user : Icons.badge_outlined,
              size: 18,
            ),
            label: Text(profil.peran.label),
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final (ikon, judul) in _menu)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('$judul segera hadir')),
                    ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ikon, size: 32),
                      const SizedBox(height: 8),
                      Text(judul, textAlign: TextAlign.center),
                    ],
                  ),
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
      tombol: OutlinedButton(onPressed: onKeluar, child: const Text('Keluar')),
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
      tombol: OutlinedButton(
        onPressed: onCobaLagi,
        child: const Text('Coba lagi'),
      ),
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
            Icon(ikon, size: 48),
            const SizedBox(height: 16),
            Text(teks, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            tombol,
          ],
        ),
      ),
    );
  }
}
