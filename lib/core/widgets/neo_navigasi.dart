import 'package:flutter/material.dart';

import '../theme.dart';

class NeoTujuan {
  const NeoTujuan(this.ikon, this.label);

  final IconData ikon;
  final String label;
}

/// Menu bawah: garis tebal di atas, tujuan aktif diberi kotak kuning.
class NeoNavBawah extends StatelessWidget {
  const NeoNavBawah({
    super.key,
    required this.tujuan,
    required this.aktif,
    required this.onPilih,
  });

  final List<NeoTujuan> tujuan;
  final int aktif;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Neo.putih,
        border: Border(
          top: BorderSide(color: Neo.tinta, width: Neo.garis),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            children: [
              for (final (i, t) in tujuan.indexed)
                Expanded(
                  child: Semantics(
                    selected: i == aktif,
                    button: true,
                    label: t.label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPilih(i),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: i == aktif
                                ? Neo.kotak(
                                    warna: Neo.kuning,
                                    geser: const Offset(2, 2),
                                    radius: 8,
                                  )
                                : BoxDecoration(
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: Neo.garis,
                                    ),
                                  ),
                            child: Icon(t.ikon, color: Neo.tinta),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: teks.labelSmall?.copyWith(
                              fontWeight: i == aktif
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
