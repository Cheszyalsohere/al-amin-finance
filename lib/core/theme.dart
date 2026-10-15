import 'package:flutter/material.dart';

const _warnaUtama = Color(0xFF1B6E4F);

ThemeData buatTema() {
  final skema = ColorScheme.fromSeed(seedColor: _warnaUtama);

  return ThemeData(
    colorScheme: skema,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
