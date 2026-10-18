import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contoh/aksi_contoh.dart';
import '../../core/format.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/widgets/neo.dart';
import '../../core/widgets/neo_daftar.dart';
import '../../core/widgets/neo_keadaan.dart';
import '../auth/auth_providers.dart';
import '../auth/profil.dart';
import '../laporan/ringkasan.dart';

enum _MenuAkun { gantiPassword, keluar }

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan Al-Amin'),
        actions: [
          if (profil.value?.isOwner ?? false)
            IconButton(
              tooltip: 'Pengaturan',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(Rute.pengaturan),
            ),
          PopupMenuButton<_MenuAkun>(
            tooltip: 'Akun',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (pilihan) => switch (pilihan) {
              _MenuAkun.gantiPassword => context.push(Rute.gantiPassword),
              _MenuAkun.keluar => _konfirmasiKeluar(context, ref),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuAkun.gantiPassword,
                child: ListTile(
                  leading: Icon(Icons.key_outlined),
                  title: Text('Ganti password'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MenuAkun.keluar,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Keluar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: switch (profil) {
        AsyncData(value: final p?) when p.aktif => _IsiBeranda(profil: p),
        AsyncData() => NeoKeadaan(
          ikon: Icons.block,
          warna: Neo.pink,
          judul: 'Akun tidak aktif',
          pesan: 'Hubungi owner untuk mengaktifkannya.',
          tombol: NeoTombol(
            onPressed: () => ref.read(authRepositoryProvider).keluar(),
            child: const Text('Keluar'),
          ),
        ),
        AsyncError() => NeoKeadaan.galat(
          tombol: NeoTombol(
            onPressed: () => ref.invalidate(profilProvider),
            child: const Text('Coba lagi'),
          ),
        ),
        _ => const NeoMemuat(),
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

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final r = ringkasanContoh();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo,',
                    style: teks.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    profil.nama,
                    style: teks.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            NeoLabel(
              teks: profil.peran.label,
              ikon: profil.isOwner ? Icons.verified_user : Icons.badge_outlined,
              warna: profil.isOwner ? Neo.kuning : Neo.biru,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _KartuSaldo(ringkasan: r),
        const SizedBox(height: 16),
        _KartuTunggakan(ringkasan: r),
        const SizedBox(height: 24),
        const NeoBagian(judul: 'Catat cepat'),
        Row(
          children: [
            Expanded(
              child: _AksiCepat(
                ikon: Icons.payments_outlined,
                label: 'Bayar',
                warna: Neo.hijau,
                onTap: () => context.push(Rute.bayar()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AksiCepat(
                ikon: Icons.photo_camera_outlined,
                label: 'Absen',
                warna: Neo.biru,
                onTap: () => context.push(Rute.absen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AksiCepat(
                ikon: Icons.shopping_bag_outlined,
                label: 'Keluar',
                warna: Neo.oranye,
                onTap: () => context.push(Rute.tambahPengeluaran),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        NeoBagian(
          judul: 'Transaksi terbaru',
          aksi: 'Laporan',
          onAksi: () => context.go(Rute.laporan),
        ),
        for (final t in r.transaksi.take(5)) ...[
          _BarisTransaksi(transaksi: t),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _KartuSaldo extends StatelessWidget {
  const _KartuSaldo({required this.ringkasan});

  final Ringkasan ringkasan;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return NeoKotak(
      warna: Neo.kuning,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO ${bulanTahun(ringkasan.bulan).toUpperCase()}',
            style: teks.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(ringkasan.saldo),
              style: teks.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Arus(
                  label: 'Masuk',
                  nilai: ringkasan.pemasukan,
                  ikon: Icons.south_west,
                  warna: Neo.hijau,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Arus(
                  label: 'Keluar',
                  nilai: ringkasan.pengeluaran,
                  ikon: Icons.north_east,
                  warna: Neo.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Arus extends StatelessWidget {
  const _Arus({
    required this.label,
    required this.nilai,
    required this.ikon,
    required this.warna,
  });

  final String label;
  final int nilai;
  final IconData ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: Neo.kotak(warna: warna, geser: Offset.zero, radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 16, color: Neo.tinta),
              const SizedBox(width: 4),
              Text(
                label,
                style: teks.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(nilai),
              style: teks.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuTunggakan extends StatelessWidget {
  const _KartuTunggakan({required this.ringkasan});

  final Ringkasan ringkasan;

  @override
  Widget build(BuildContext context) {
    return NeoItem(
      warna: Neo.pink,
      onTap: () => context.push(Rute.tunggakan),
      depan: const NeoKotak(
        warna: Neo.putih,
        geser: Offset.zero,
        padding: EdgeInsets.all(8),
        child: Icon(Icons.warning_amber_rounded, color: Neo.tinta),
      ),
      judul: '${ringkasan.menunggak.length} siswa belum lunas',
      subjudul: 'Total sisa ${rupiah(ringkasan.totalTunggakan)}',
      belakang: const Icon(Icons.chevron_right, color: Neo.tinta),
    );
  }
}

class _AksiCepat extends StatelessWidget {
  const _AksiCepat({
    required this.ikon,
    required this.label,
    required this.warna,
    required this.onTap,
  });

  final IconData ikon;
  final String label;
  final Color warna;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoTombol(
      warna: warna,
      padding: const EdgeInsets.symmetric(vertical: 14),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 28),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _BarisTransaksi extends StatelessWidget {
  const _BarisTransaksi({required this.transaksi});

  final Transaksi transaksi;

  @override
  Widget build(BuildContext context) {
    final t = transaksi;
    return NeoItem(
      depan: NeoKotak(
        warna: t.masuk ? Neo.hijau : Neo.pink,
        geser: Offset.zero,
        padding: const EdgeInsets.all(8),
        child: Icon(
          t.masuk ? Icons.south_west : Icons.north_east,
          size: 20,
          color: Neo.tinta,
        ),
      ),
      judul: t.judul,
      subjudul: '${tanggal(t.tanggal)} · ${t.keterangan}',
      belakang: Text(
        '${t.masuk ? '+' : '−'}${angka(t.jumlah)}',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
