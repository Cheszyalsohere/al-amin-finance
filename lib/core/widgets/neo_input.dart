import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../theme.dart';

/// Memformat angka saat diketik: `1500000` → `1.500.000`.
class FormatRupiah extends TextInputFormatter {
  static int? baca(String teks) {
    final digit = teks.replaceAll(RegExp(r'[^0-9]'), '');
    return digit.isEmpty ? null : int.parse(digit);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final nilai = baca(newValue.text);
    if (nilai == null) return newValue.copyWith(text: '');
    final teks = angka(nilai);
    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}

/// Kolom isian nominal rupiah dengan awalan "Rp".
class NeoInputRupiah extends StatelessWidget {
  const NeoInputRupiah({
    super.key,
    required this.controller,
    this.label = 'Nominal',
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<int?>? validator;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        prefixStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      keyboardType: TextInputType.number,
      inputFormatters: [FormatRupiah()],
      validator: validator == null
          ? null
          : (teks) => validator!(FormatRupiah.baca(teks ?? '')),
      onChanged: onChanged == null
          ? null
          : (teks) => onChanged!(FormatRupiah.baca(teks)),
    );
  }
}

/// Pilihan tunggal berbentuk deretan tombol bergaris.
class NeoPilihan<T> extends StatelessWidget {
  const NeoPilihan({
    super.key,
    required this.pilihan,
    required this.terpilih,
    required this.label,
    required this.onPilih,
    this.warna = Neo.kuning,
  });

  final List<T> pilihan;
  final T? terpilih;
  final String Function(T) label;
  final ValueChanged<T> onPilih;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in pilihan)
          Semantics(
            selected: p == terpilih,
            button: true,
            child: GestureDetector(
              onTap: () => onPilih(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: Neo.kotak(
                  warna: p == terpilih ? warna : Neo.putih,
                  geser: p == terpilih ? const Offset(2, 2) : Offset.zero,
                  radius: 8,
                ),
                child: Text(
                  label(p),
                  style: teks.labelLarge?.copyWith(
                    fontWeight: p == terpilih
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
