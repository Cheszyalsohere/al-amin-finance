import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet dan ukuran gaya neo-brutalism: garis hitam tebal, bayangan keras
/// tanpa blur, dan warna solid yang cerah.
abstract final class Neo {
  static const tinta = Color(0xFF111111);
  static const latar = Color(0xFFFFFFFF);
  static const putih = Color(0xFFFFFFFF);

  static const kuning = Color(0xFFFFD23F);
  static const pink = Color(0xFFFF8FB1);
  static const hijau = Color(0xFF5CE1A6);
  static const biru = Color(0xFF7CC6FE);
  static const ungu = Color(0xFFB79CFF);
  static const oranye = Color(0xFFFFA45B);
  static const merah = Color(0xFFFF5C5C);

  static const garis = 2.5;
  static const sudut = 10.0;
  static const bayangan = Offset(4, 4);

  static BoxDecoration kotak({
    Color warna = putih,
    Offset geser = bayangan,
    double radius = sudut,
  }) {
    return BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tinta, width: garis),
      boxShadow: [
        if (geser != Offset.zero) BoxShadow(color: tinta, offset: geser),
      ],
    );
  }
}

ThemeData buatTema() {
  const skema = ColorScheme.light(
    primary: Neo.tinta,
    onPrimary: Neo.putih,
    secondary: Neo.kuning,
    onSecondary: Neo.tinta,
    error: Color(0xFFD62828),
    surface: Neo.latar,
    onSurface: Neo.tinta,
    onSurfaceVariant: Color(0xFF4A4A4A),
    surfaceContainerHighest: Color(0xFFEDEDED),
    outline: Neo.tinta,
  );

  final dasar = ThemeData(colorScheme: skema, useMaterial3: true);
  final teks = GoogleFonts.spaceGroteskTextTheme(
    dasar.textTheme,
  ).apply(bodyColor: Neo.tinta, displayColor: Neo.tinta);

  OutlineInputBorder garisInput(Color warna, [double tebal = Neo.garis]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Neo.sudut),
        borderSide: BorderSide(color: warna, width: tebal),
      );

  return dasar.copyWith(
    scaffoldBackgroundColor: Neo.latar,
    textTheme: teks,
    appBarTheme: AppBarTheme(
      backgroundColor: Neo.latar,
      foregroundColor: Neo.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: teks.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      shape: const Border(
        bottom: BorderSide(color: Neo.tinta, width: Neo.garis),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Neo.putih,
      border: garisInput(Neo.tinta),
      enabledBorder: garisInput(Neo.tinta),
      focusedBorder: garisInput(Neo.tinta, 3.5),
      errorBorder: garisInput(skema.error),
      focusedErrorBorder: garisInput(skema.error, 3.5),
      labelStyle: teks.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      floatingLabelStyle: teks.bodyLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Neo.tinta,
      ),
      prefixIconColor: Neo.tinta,
      suffixIconColor: Neo.tinta,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Neo.putih,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Neo.sudut),
        side: const BorderSide(color: Neo.tinta, width: Neo.garis),
      ),
      titleTextStyle: teks.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Neo.tinta,
      contentTextStyle: teks.bodyMedium?.copyWith(
        color: Neo.putih,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Neo.sudut),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Neo.tinta,
        textStyle: teks.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Neo.tinta),
  );
}
