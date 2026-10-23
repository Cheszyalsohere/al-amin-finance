import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Sisi terpanjang foto setelah dikecilkan.
const sisiMaksFoto = 1024;

/// Batas ukuran file; bucket menolak di atas 500 KB.
const ukuranMaksFoto = 450 * 1024;

/// Kecilkan foto, cetak cap waktu di bagian bawah, lalu simpan sebagai JPEG.
/// [baris] adalah teks cap (huruf ASCII saja, karena memakai huruf bitmap).
Future<Uint8List> olahFotoAbsen(Uint8List asli, List<String> baris) =>
    compute(_olah, (asli, baris));

Uint8List _olah((Uint8List, List<String>) masukan) {
  final (asli, baris) = masukan;
  final terbaca = img.decodeImage(asli);
  if (terbaca == null) throw const FormatException('Foto tidak bisa dibaca');

  var foto = img.bakeOrientation(terbaca);
  if (foto.width > sisiMaksFoto || foto.height > sisiMaksFoto) {
    foto = foto.width >= foto.height
        ? img.copyResize(foto, width: sisiMaksFoto)
        : img.copyResize(foto, height: sisiMaksFoto);
  }

  final huruf = foto.width >= 600 ? img.arial24 : img.arial14;
  final tinggiBaris = huruf.lineHeight + 4;
  final tinggiPita = tinggiBaris * baris.length + 16;

  img.fillRect(
    foto,
    x1: 0,
    y1: foto.height - tinggiPita,
    x2: foto.width,
    y2: foto.height,
    color: img.ColorRgba8(17, 17, 17, 200),
  );
  for (final (i, teks) in baris.indexed) {
    img.drawString(
      foto,
      teks,
      font: huruf,
      x: 12,
      y: foto.height - tinggiPita + 8 + i * tinggiBaris,
      color: img.ColorRgb8(255, 255, 255),
    );
  }

  for (final kualitas in [72, 60, 45]) {
    final jpeg = img.encodeJpg(foto, quality: kualitas);
    if (jpeg.length <= ukuranMaksFoto) return jpeg;
  }
  return img.encodeJpg(foto, quality: 35);
}

/// Hilangkan huruf di luar ASCII supaya bisa digambar huruf bitmap.
String keAscii(String teks) =>
    teks.replaceAll('·', '-').replaceAll(RegExp(r'[^\x20-\x7E]'), '');
