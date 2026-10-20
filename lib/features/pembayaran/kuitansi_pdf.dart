import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../siswa/siswa.dart';

/// Isi satu kuitansi pembayaran.
class DataKuitansi {
  const DataKuitansi({
    required this.siswa,
    required this.pembayaran,
    required this.totalDibayar,
  });

  final Siswa siswa;
  final Pembayaran pembayaran;

  /// Total yang sudah dibayar termasuk pembayaran ini.
  final int totalDibayar;

  int get total => siswa.tagihan.total;
  int get sisa => (total - totalDibayar).clamp(0, total);

  /// `KW/2026/10/00001` → `kuitansi-KW-2026-10-00001.pdf`
  String get namaFile =>
      'kuitansi-${pembayaran.noKuitansi.replaceAll('/', '-')}.pdf';
}

/// Huruf dan logo untuk PDF; dibuat terpisah supaya bisa dimuat sekali dan
/// diganti di tes (tanpa internet).
class GayaKuitansi {
  const GayaKuitansi({this.biasa, this.tebal, this.logoSvg});

  final pw.Font? biasa;
  final pw.Font? tebal;
  final String? logoSvg;
}

const _tinta = PdfColor.fromInt(0xFF111111);
const _kuning = PdfColor.fromInt(0xFFFFD23F);
const _hijau = PdfColor.fromInt(0xFF5CE1A6);
const _abu = PdfColor.fromInt(0xFF4A4A4A);

Future<Uint8List> buatKuitansiPdf(
  DataKuitansi d, {
  GayaKuitansi gaya = const GayaKuitansi(),
  DateTime? dicetak,
}) {
  final doc = pw.Document(
    title: 'Kuitansi ${d.pembayaran.noKuitansi}',
    author: 'Bimbel Al-Amin',
  );
  final tema = pw.ThemeData.withFont(base: gaya.biasa, bold: gaya.tebal);
  final b = d.pembayaran;
  final s = d.siswa;

  pw.Widget kotak({
    required pw.Widget child,
    PdfColor warna = PdfColors.white,
    double bayangan = 4,
    pw.EdgeInsets padding = const pw.EdgeInsets.all(14),
  }) {
    return pw.Container(
      margin: pw.EdgeInsets.only(right: bayangan, bottom: bayangan),
      decoration: pw.BoxDecoration(
        color: warna,
        border: pw.Border.all(color: _tinta, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: bayangan == 0
            ? null
            : [
                pw.BoxShadow(
                  color: _tinta,
                  offset: PdfPoint(bayangan, -bayangan),
                ),
              ],
      ),
      padding: padding,
      child: child,
    );
  }

  pw.Widget baris(String label, String nilai, {bool tebal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: tebal ? _tinta : _abu,
                fontWeight: tebal ? pw.FontWeight.bold : null,
              ),
            ),
          ),
          pw.Text(
            nilai,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      theme: tema,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          kotak(
            warna: _kuning,
            child: pw.Row(
              children: [
                if (gaya.logoSvg != null) ...[
                  pw.SizedBox(
                    width: 40,
                    height: 40,
                    child: pw.SvgImage(svg: gaya.logoSvg!),
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BIMBEL AL-AMIN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Kuitansi pembayaran',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  b.noKuitansi,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          kotak(
            child: pw.Column(
              children: [
                baris('Tanggal', tanggalPanjang(b.tanggal)),
                baris('Jam', '${jam(b.tanggal)} WIB'),
                baris('Nama siswa', s.nama),
                baris('Program', '${s.program.label} · Kelas ${s.kelas}'),
                baris('Wali murid', s.namaWali),
                baris('Metode', b.metode.label),
                if (b.keterangan != null && b.keterangan!.isNotEmpty)
                  baris('Keterangan', b.keterangan!),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          kotak(
            warna: _hijau,
            child: pw.Column(
              children: [
                pw.Text(
                  'DIBAYAR',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  rupiah(b.jumlah),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          kotak(
            child: pw.Column(
              children: [
                baris('Total tagihan', rupiah(d.total)),
                baris('Total sudah dibayar', rupiah(d.totalDibayar)),
                pw.Divider(color: _tinta, thickness: 1.5),
                baris(
                  'Sisa tagihan',
                  d.sisa == 0 ? 'LUNAS' : rupiah(d.sisa),
                  tebal: true,
                ),
                if (d.sisa > 0)
                  baris('Batas pelunasan', tanggal(s.tagihan.batasPelunasan)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Text(
            'Kuitansi ini dibuat oleh aplikasi Keuangan Al-Amin dan sah tanpa '
            'tanda tangan. Dicetak ${tanggalJam(dicetak ?? DateTime.now())}.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: _abu),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
