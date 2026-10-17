import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/neo_navigasi.dart';

/// Kerangka halaman utama dengan menu bawah.
class Shell extends StatelessWidget {
  const Shell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const tujuan = [
    NeoTujuan(Icons.home_outlined, 'Beranda'),
    NeoTujuan(Icons.groups_outlined, 'Siswa'),
    NeoTujuan(Icons.co_present_outlined, 'Tentor'),
    NeoTujuan(Icons.receipt_long_outlined, 'Kas'),
    NeoTujuan(Icons.bar_chart_outlined, 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NeoNavBawah(
        tujuan: tujuan,
        aktif: navigationShell.currentIndex,
        onPilih: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
