import 'package:al_amin_finance/features/auth/auth_repository.dart';
import 'package:al_amin_finance/features/auth/profil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Profil.dariMap', () {
    test('membaca owner', () {
      final profil = Profil.dariMap({
        'id': 'u1',
        'nama': 'Irfan',
        'peran': 'owner',
        'aktif': true,
      });

      expect(profil.peran, Peran.owner);
      expect(profil.isOwner, isTrue);
      expect(profil.aktif, isTrue);
    });

    test('peran tidak dikenal dianggap admin', () {
      final profil = Profil.dariMap({
        'id': 'u2',
        'nama': 'Admin',
        'peran': 'superuser',
        'aktif': false,
      });

      expect(profil.peran, Peran.admin);
      expect(profil.isOwner, isFalse);
    });
  });

  group('pesanAuth', () {
    test('kredensial salah', () {
      expect(
        pesanAuth(const AuthException('x', code: 'invalid_credentials')),
        'Email atau password salah.',
      );
    });

    test('kode tidak dikenal menampilkan pesan asli', () {
      expect(
        pesanAuth(const AuthException('Server sibuk', code: 'lainnya')),
        'Gagal masuk: Server sibuk',
      );
    });
  });
}
