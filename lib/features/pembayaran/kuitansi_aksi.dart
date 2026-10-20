import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../core/whatsapp.dart';
import '../../core/widgets/neo_daftar.dart';
import '../siswa/siswa.dart';
import 'kuitansi_pdf.dart';

/// Huruf Space Grotesk dan logo untuk PDF. Kalau huruf gagal diunduh
/// (misal offline), PDF tetap dibuat dengan huruf bawaan.
final gayaKuitansiProvider = FutureProvider<GayaKuitansi>((ref) async {
  String? logo;
  try {
    logo = await rootBundle.loadString('assets/logo/logo-mark.svg');
  } on Exception {
    logo = null;
  }
  try {
    return GayaKuitansi(
      biasa: await PdfGoogleFonts.spaceGroteskRegular(),
      tebal: await PdfGoogleFonts.spaceGroteskBold(),
      logoSvg: logo,
    );
  } on Exception {
    return GayaKuitansi(logoSvg: logo);
  }
});

void _pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));
}

Future<void> cetakKuitansi(
  BuildContext context,
  WidgetRef ref,
  DataKuitansi data,
) async {
  try {
    final gaya = await ref.read(gayaKuitansiProvider.future);
    await Printing.layoutPdf(
      name: data.namaFile,
      onLayout: (_) => buatKuitansiPdf(data, gaya: gaya),
    );
  } on Exception {
    if (context.mounted) _pesan(context, 'Gagal membuat PDF. Coba lagi.');
  }
}

Future<void> bagikanPdfKuitansi(
  BuildContext context,
  WidgetRef ref,
  DataKuitansi data,
) async {
  try {
    final gaya = await ref.read(gayaKuitansiProvider.future);
    final bytes = await buatKuitansiPdf(data, gaya: gaya);
    await Printing.sharePdf(
      bytes: bytes,
      filename: data.namaFile,
      subject: 'Kuitansi ${data.pembayaran.noKuitansi}',
      body: pesanKuitansi(data.siswa, data.pembayaran, sisa: data.sisa),
    );
  } on Exception {
    if (context.mounted) _pesan(context, 'Gagal membagikan PDF. Coba lagi.');
  }
}

Future<void> kirimPesanKuitansi(BuildContext context, DataKuitansi data) =>
    kirimWhatsAppKeWali(
      context,
      data.siswa,
      pesanKuitansi(data.siswa, data.pembayaran, sisa: data.sisa),
    );

/// Lembar pilihan cara mengirim kuitansi ke wali.
Future<void> bukaKirimKuitansi(
  BuildContext context,
  WidgetRef ref,
  DataKuitansi data,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Neo.putih,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Neo.sudut)),
      side: BorderSide(color: Neo.tinta, width: Neo.garis),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoBagian(judul: 'Kirim ke ${data.siswa.namaWali}'),
            NeoItem(
              warna: Neo.hijau,
              onTap: () {
                Navigator.pop(sheet);
                bagikanPdfKuitansi(context, ref, data);
              },
              depan: const Icon(Icons.picture_as_pdf_outlined, size: 28),
              judul: 'Kirim file PDF',
              subjudul: 'Pilih WhatsApp, lalu pilih chat wali',
              belakang: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 12),
            NeoItem(
              onTap: () {
                Navigator.pop(sheet);
                kirimPesanKuitansi(context, data);
              },
              depan: const Icon(Icons.chat_outlined, size: 28),
              judul: 'Kirim pesan WhatsApp',
              subjudul: 'Langsung ke ${data.siswa.noHpWali}, berisi ringkasan',
              belakang: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Buka chat WhatsApp wali siswa dengan pesan terisi.
Future<void> kirimWhatsAppKeWali(
  BuildContext context,
  Siswa siswa,
  String pesan,
) async {
  final berhasil = await bukaWhatsApp(siswa.noHpWali, pesan);
  if (!berhasil && context.mounted) {
    _pesan(
      context,
      'Tidak bisa membuka WhatsApp. Cek nomor wali: ${siswa.noHpWali}',
    );
  }
}
