import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final _angka = NumberFormat.decimalPattern('id_ID');

/// `2800000` → `Rp 2.800.000`
String rupiah(int nilai) => _rupiah.format(nilai);

/// `2800000` → `2.800.000`
String angka(int nilai) => _angka.format(nilai);

/// `2026-10-18` → `18 Okt 2026`
String tanggal(DateTime t) => DateFormat('d MMM yyyy', 'id_ID').format(t);

/// `2026-10-18` → `Sabtu, 18 Oktober 2026`
String tanggalPanjang(DateTime t) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(t);

/// `2026-10-18 14:05` → `14.05`
String jam(DateTime t) => DateFormat('HH.mm', 'id_ID').format(t);

/// `2026-10-18` → `Oktober 2026`
String bulanTahun(DateTime t) => DateFormat('MMMM yyyy', 'id_ID').format(t);
