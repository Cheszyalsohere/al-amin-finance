# Keuangan Al-Amin

Aplikasi Android untuk mencatat keuangan Bimbel Al-Amin: pembayaran siswa,
honor tentor, pengeluaran, dan laporan. Dibuat dengan Flutter + Supabase.

## Status

- [x] Tahap 1: login owner/admin
- [ ] Tahap 2: siswa, tagihan, pembayaran, tunggakan
- [ ] Tahap 3: kuitansi PDF
- [ ] Tahap 4: tentor, absensi foto, sesi, honor
- [ ] Tahap 5: pengeluaran, laporan, export Excel
- [ ] Tahap 6: pengaturan dan APK rilis

## Setup Supabase (sekali saja)

1. **Buat project** di [supabase.com](https://supabase.com) dengan paket Free.
   Pilih region Singapore supaya lebih cepat dari Indonesia.
2. **Jalankan SQL.** Buka **SQL Editor**, lalu tempel dan jalankan isi file
   [`supabase/migrations/20261016000000_profiles_dan_peran.sql`](supabase/migrations/20261016000000_profiles_dan_peran.sql).
3. **Matikan pendaftaran publik.** Buka **Authentication → Sign In / Providers**,
   matikan **Allow new users to sign up**. Akun hanya dibuat oleh owner.
4. **Buat akun.** Buka **Authentication → Users → Add user → Create new user**.
   Isi email dan password, centang **Auto Confirm User**. Buat satu akun untuk
   owner dan satu untuk admin.
5. **Jadikan akunmu owner.** Jalankan di SQL Editor (ganti emailnya):

   ```sql
   update public.profiles
   set peran = 'owner', nama = 'Nama Owner'
   where id = (select id from auth.users where email = 'owner@contoh.com');

   update public.profiles
   set nama = 'Nama Admin'
   where id = (select id from auth.users where email = 'admin@contoh.com');
   ```

6. **Ambil kunci API.** Buka **Project Settings → API Keys**. Salin
   **Project URL** dan **Publishable key** (`sb_publishable_...`).
   Jangan pakai *secret key* di aplikasi.

## Menjalankan aplikasi

1. Salin `env.example.json` menjadi `env.json`, lalu isi dengan URL dan
   publishable key dari langkah 6. File `env.json` tidak ikut di-commit.
2. Sambungkan HP Android (aktifkan *USB debugging*) atau buka emulator, lalu:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

## Membuat APK untuk dikirim ke admin

```bash
flutter build apk --release --dart-define-from-file=env.json
```

File APK ada di `build/app/outputs/flutter-apk/app-release.apk`. Kirim lewat
WhatsApp atau Google Drive, lalu install di HP admin (izinkan *install dari
sumber tidak dikenal* saat diminta).

## Tes

```bash
flutter test
```
