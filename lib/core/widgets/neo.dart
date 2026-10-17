import 'package:flutter/material.dart';

import '../theme.dart';

/// Kotak bergaris tebal dengan bayangan keras.
class NeoKotak extends StatelessWidget {
  const NeoKotak({
    super.key,
    required this.child,
    this.warna = Neo.putih,
    this.padding = const EdgeInsets.all(16),
    this.geser = Neo.bayangan,
  });

  final Widget child;
  final Color warna;
  final EdgeInsetsGeometry padding;
  final Offset geser;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Neo.kotak(warna: warna, geser: geser),
      padding: padding,
      child: child,
    );
  }
}

/// Tombol yang "tertekan" saat disentuh: bayangan hilang dan kotak bergeser.
class NeoTombol extends StatefulWidget {
  const NeoTombol({
    super.key,
    required this.onPressed,
    required this.child,
    this.warna = Neo.kuning,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color warna;
  final EdgeInsetsGeometry padding;

  @override
  State<NeoTombol> createState() => _NeoTombolState();
}

class _NeoTombolState extends State<NeoTombol> {
  bool _ditekan = false;

  void _tekan(bool nilai) {
    if (widget.onPressed != null) setState(() => _ditekan = nilai);
  }

  @override
  Widget build(BuildContext context) {
    final aktif = widget.onPressed != null;
    final geser = _ditekan || !aktif ? Offset.zero : Neo.bayangan;
    final gaya = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Semantics(
      button: true,
      enabled: aktif,
      child: GestureDetector(
        onTapDown: (_) => _tekan(true),
        onTapUp: (_) => _tekan(false),
        onTapCancel: () => _tekan(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(
            Neo.bayangan.dx - geser.dx,
            Neo.bayangan.dy - geser.dy,
            0,
          ),
          decoration: Neo.kotak(
            warna: aktif ? widget.warna : const Color(0xFFE5E5E5),
            geser: geser,
          ),
          padding: widget.padding,
          child: DefaultTextStyle.merge(
            style: gaya,
            textAlign: TextAlign.center,
            child: IconTheme.merge(
              data: const IconThemeData(color: Neo.tinta),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label kecil bergaris, misalnya untuk peran pengguna.
class NeoLabel extends StatelessWidget {
  const NeoLabel({
    super.key,
    required this.teks,
    this.ikon,
    this.warna = Neo.biru,
  });

  final String teks;
  final IconData? ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Neo.kotak(warna: warna, geser: const Offset(2, 2), radius: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 16, color: Neo.tinta),
            const SizedBox(width: 6),
          ],
          Text(
            teks.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
