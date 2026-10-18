import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo mark Al-Amin Finance (konsep "Bento Grid").
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.ukuran = 80});

  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/logo-mark.svg',
      width: ukuran,
      height: ukuran,
      semanticsLabel: 'Logo Al-Amin Finance',
    );
  }
}

/// Logo mark dengan tulisan "al-amin / FINANCE" di bawahnya.
class LogoLengkap extends StatelessWidget {
  const LogoLengkap({
    super.key,
    this.ukuran = 88,
    this.rata = CrossAxisAlignment.start,
  });

  final double ukuran;
  final CrossAxisAlignment rata;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    // Proporsi dari panduan logo: mark 200px → teks 44px & 16px, jarak 36px.
    final skala = ukuran / 200;

    return Column(
      crossAxisAlignment: rata,
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(ukuran: ukuran),
        SizedBox(height: 36 * skala),
        Text(
          'al-amin',
          style: teks.displaySmall?.copyWith(
            fontSize: 44 * skala * 1.6,
            fontWeight: FontWeight.w700,
            letterSpacing: -2.5 * skala * 1.6,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'FINANCE',
          style: teks.titleMedium?.copyWith(
            fontSize: 16 * skala * 1.6,
            fontWeight: FontWeight.w500,
            letterSpacing: 5 * skala * 1.6,
            height: 1,
          ),
        ),
      ],
    );
  }
}
