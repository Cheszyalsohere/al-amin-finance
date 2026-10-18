import 'package:al_amin_finance/features/kas/kategori_provider.dart';
import 'package:al_amin_finance/features/kas/pengeluaran.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late KategoriNotifier notifier;

  List<KategoriPengeluaran> daftar() => container.read(kategoriProvider);

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(kategoriProvider.notifier);
  });

  group('validasiNama', () {
    test('nama kosong ditolak', () {
      expect(notifier.validasiNama('   '), 'Nama kategori wajib diisi');
    });

    test('nama kembar ditolak tanpa melihat huruf besar/kecil', () {
      expect(notifier.validasiNama('atk'), 'Kategori "atk" sudah ada');
    });

    test('nama sendiri boleh dipakai saat mengubah', () {
      expect(notifier.validasiNama('ATK', kecualiId: 'atk'), isNull);
    });

    test('nama baru yang unik diterima', () {
      expect(notifier.validasiNama('Konsumsi rapat'), isNull);
    });
  });

  test('tambah kategori baru', () {
    final awal = daftar().length;
    notifier.tambah(nama: '  Konsumsi  ', kodeIkon: 'konsumsi');

    expect(daftar(), hasLength(awal + 1));
    expect(daftar().last.nama, 'Konsumsi');
    expect(daftar().last.kodeIkon, 'konsumsi');
  });

  test('ubah nama dan ikon', () {
    notifier.ubah('atk', nama: 'Alat tulis', kodeIkon: 'lainnya');

    final atk = notifier.denganId('atk');
    expect(atk.nama, 'Alat tulis');
    expect(atk.kodeIkon, 'lainnya');
  });

  test('arsipkan lalu pulihkan', () {
    notifier.aturArsip('fotokopi', diarsipkan: true);
    expect(notifier.denganId('fotokopi').diarsipkan, isTrue);

    notifier.aturArsip('fotokopi', diarsipkan: false);
    expect(notifier.denganId('fotokopi').diarsipkan, isFalse);
  });

  test('kategori otomatis tidak bisa diarsipkan', () {
    notifier.aturArsip(KategoriOtomatis.honor, diarsipkan: true);
    expect(notifier.denganId(KategoriOtomatis.honor).diarsipkan, isFalse);
  });
}
