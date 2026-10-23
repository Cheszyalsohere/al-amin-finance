import 'dart:typed_data';

import 'package:al_amin_finance/features/tentor/foto_absen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test(
    'foto besar dikecilkan, diberi cap, dan di bawah batas ukuran',
    () async {
      // Foto 3000x4000 berisi pola acak supaya JPEG-nya besar.
      final asli = img.Image(width: 3000, height: 4000);
      for (final p in asli) {
        p
          ..r = (p.x * 7 + p.y * 13) % 256
          ..g = (p.x * p.y) % 256
          ..b = (p.y * 3) % 256;
      }
      final masukan = Uint8List.fromList(img.encodeJpg(asli, quality: 95));

      final hasil = await olahFotoAbsen(masukan, [
        'Kak Rizki Maulana',
        '20 Okt 2026 - 15.50 WIB',
        'Bimbel Al-Amin',
      ]);

      final terbaca = img.decodeJpg(hasil)!;
      expect(terbaca.height, sisiMaksFoto);
      expect(terbaca.width, lessThan(sisiMaksFoto));
      expect(hasil.length, lessThanOrEqualTo(ukuranMaksFoto));

      // Pojok kiri bawah tertutup pita gelap cap waktu.
      final piksel = terbaca.getPixel(2, terbaca.height - 3);
      expect(piksel.r, lessThan(80));
    },
  );

  test('keAscii membuang huruf non-ASCII', () {
    expect(keAscii('18 Okt 2026 · 15.50'), '18 Okt 2026 - 15.50');
    expect(keAscii('Kak Ñina 😀'), 'Kak ina ');
  });
}
