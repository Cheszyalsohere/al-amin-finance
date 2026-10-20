import 'package:url_launcher/url_launcher.dart';

import '../features/siswa/siswa.dart';
import 'format.dart';

/// Ubah nomor HP Indonesia ke format internasional tanpa `+`,
/// misalnya `0812-3456-7890` → `6281234567890`. Null jika tidak valid.
String? nomorWhatsApp(String nomor) {
  var digit = nomor.replaceAll(RegExp(r'[^0-9]'), '');
  if (digit.startsWith('0')) {
    digit = '62${digit.substring(1)}';
  } else if (digit.startsWith('8')) {
    digit = '62$digit';
  }
  if (!digit.startsWith('62') || digit.length < 10 || digit.length > 15) {
    return null;
  }
  return digit;
}

Uri tautanWhatsApp(String nomor, String pesan) =>
    Uri.https('wa.me', '/$nomor', {'text': pesan});

/// Buka chat WhatsApp ke [nomorHp] dengan pesan terisi.
/// Mengembalikan false jika nomor tidak valid atau WhatsApp tidak bisa dibuka.
Future<bool> bukaWhatsApp(String nomorHp, String pesan) async {
  final nomor = nomorWhatsApp(nomorHp);
  if (nomor == null) return false;
  return launchUrl(
    tautanWhatsApp(nomor, pesan),
    mode: LaunchMode.externalApplication,
  );
}

String pesanKuitansi(Siswa siswa, Pembayaran bayar, {required int sisa}) {
  final status = sisa == 0
      ? 'Tagihan tahun ini sudah *LUNAS*. Terima kasih 🙏'
      : 'Sisa tagihan: *${rupiah(sisa)}*, paling lambat '
            '${tanggal(siswa.tagihan.batasPelunasan)}.';

  return [
    'Assalamualaikum ${siswa.namaWali},',
    '',
    'Pembayaran bimbel untuk *${siswa.nama}* sudah kami terima:',
    '• No. kuitansi: ${bayar.noKuitansi}',
    '• Tanggal: ${tanggalJam(bayar.tanggal)} WIB',
    '• Jumlah: *${rupiah(bayar.jumlah)}* (${bayar.metode.label})',
    '',
    status,
    '',
    'Bimbel Al-Amin',
  ].join('\n');
}

String pesanPengingat(Siswa siswa) {
  final t = siswa.tagihan;
  return [
    'Assalamualaikum ${siswa.namaWali},',
    '',
    'Kami ingin mengingatkan pembayaran bimbel untuk *${siswa.nama}*:',
    '• Total tagihan: ${rupiah(t.total)}',
    '• Sudah dibayar: ${rupiah(t.dibayar)}',
    '• Sisa: *${rupiah(t.sisa)}*',
    '',
    'Mohon dilunasi paling lambat ${tanggal(t.batasPelunasan)}. '
        'Abaikan pesan ini jika sudah membayar. Terima kasih 🙏',
    '',
    'Bimbel Al-Amin',
  ].join('\n');
}
