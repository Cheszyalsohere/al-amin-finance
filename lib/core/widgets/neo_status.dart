import 'package:flutter/material.dart';

import '../../features/siswa/siswa.dart';
import '../theme.dart';
import 'neo.dart';

extension WarnaStatus on StatusTagihan {
  Color get warna => switch (this) {
    StatusTagihan.lunas => Neo.hijau,
    StatusTagihan.cicilan => Neo.kuning,
    StatusTagihan.belumBayar => Neo.pink,
    StatusTagihan.terlambat => Neo.merah,
  };

  IconData get ikon => switch (this) {
    StatusTagihan.lunas => Icons.check_circle_outline,
    StatusTagihan.cicilan => Icons.timelapse,
    StatusTagihan.belumBayar => Icons.radio_button_unchecked,
    StatusTagihan.terlambat => Icons.error_outline,
  };
}

class NeoStatus extends StatelessWidget {
  const NeoStatus(this.status, {super.key});

  final StatusTagihan status;

  @override
  Widget build(BuildContext context) {
    return NeoLabel(teks: status.label, ikon: status.ikon, warna: status.warna);
  }
}

/// Batang kemajuan pembayaran bergaris tebal.
class NeoProgres extends StatelessWidget {
  const NeoProgres({
    super.key,
    required this.nilai,
    this.warna = Neo.hijau,
    this.tinggi = 18,
  });

  /// 0.0 sampai 1.0
  final double nilai;
  final Color warna;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tinggi,
      decoration: Neo.kotak(geser: Offset.zero, radius: 6),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: nilai.clamp(0, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: warna,
              border: nilai > 0 && nilai < 1
                  ? const Border(
                      right: BorderSide(color: Neo.tinta, width: Neo.garis),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
