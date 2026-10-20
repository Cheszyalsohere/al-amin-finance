import 'dart:io';

import 'package:al_amin_finance/contoh/data_contoh.dart';
import 'package:al_amin_finance/core/whatsapp.dart';
import 'package:al_amin_finance/features/pembayaran/kuitansi_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final bima = DataContoh.siswa.firstWhere((s) => s.id == 's2');
  final bayar = bima.tagihan.pembayaran.last;
  final data = DataKuitansi(
    siswa: bima,
    pembayaran: bayar,
    totalDibayar: bima.tagihan.dibayar,
  );

  group('nomorWhatsApp', () {
    test('awalan 0 jadi 62', () {
      expect(nomorWhatsApp('0812-3456-7801'), '6281234567801');
    });
    test('awalan +62 dan spasi', () {
      expect(nomorWhatsApp('+62 812 3456 7801'), '6281234567801');
    });
    test('awalan 8 saja', () {
      expect(nomorWhatsApp('81234567801'), '6281234567801');
    });
    test('nomor tidak valid', () {
      expect(nomorWhatsApp('123'), isNull);
      expect(nomorWhatsApp(''), isNull);
    });
  });

  test('tautan wa.me menyandikan pesan', () {
    final uri = tautanWhatsApp('6281234567801', 'Halo & terima kasih');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/6281234567801');
    expect(uri.queryParameters['text'], 'Halo & terima kasih');
  });

  test('pesan kuitansi berisi nomor, jumlah, dan sisa', () {
    final pesan = pesanKuitansi(bima, bayar, sisa: data.sisa);
    expect(pesan, contains(bima.namaWali));
    expect(pesan, contains(bayar.noKuitansi));
    expect(pesan, contains('Rp 300.000'));
    expect(pesan, contains('Sisa tagihan: *Rp 500.000*'));
  });

  test('pesan kuitansi lunas', () {
    final pesan = pesanKuitansi(bima, bayar, sisa: 0);
    expect(pesan, contains('LUNAS'));
  });

  test('pesan pengingat berisi sisa dan batas', () {
    final pesan = pesanPengingat(bima);
    expect(pesan, contains('Sisa: *Rp 500.000*'));
    expect(pesan, contains('31 Des 2026'));
  });

  test('nama file kuitansi aman', () {
    expect(data.namaFile, isNot(contains('/')));
    expect(data.namaFile, endsWith('.pdf'));
  });

  test('PDF kuitansi terbentuk, termasuk dengan logo', () async {
    final logo = File('assets/logo/logo-mark.svg').readAsStringSync();
    final bytes = await buatKuitansiPdf(
      data,
      gaya: GayaKuitansi(logoSvg: logo),
      dicetak: DateTime(2026, 10, 20, 9),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
