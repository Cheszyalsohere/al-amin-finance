/// Data contoh untuk Tahap 2 (desain tampilan). Akan diganti data dari
/// Supabase mulai Tahap 3.
library;

import '../features/kas/pengeluaran.dart';
import '../features/siswa/siswa.dart';
import '../features/tentor/tentor.dart';

abstract final class DataContoh {
  static const tahunAjaran = '2026/2027';

  static final aturan = AturanBiaya(
    biayaProgram: 2800000,
    uangMuka: 1500000,
    biayaAdmin: 50000,
    batasCicilan: DateTime(2026, 12, 31),
  );

  static Tagihan _tagihan(
    Keringanan keringanan,
    Skema skema,
    List<(int bulan, int hari, int jumlah, Metode metode)> bayar,
  ) {
    var no = 0;
    return Tagihan(
      skema: skema,
      keringanan: keringanan,
      rincian: hitungTagihan(aturan, keringanan, skema),
      batasPelunasan: aturan.batasCicilan,
      pembayaran: [
        for (final (bulan, hari, jumlah, metode) in bayar)
          Pembayaran(
            id: 'p${bulan}_${hari}_${no++}',
            tanggal: DateTime(2026, bulan, hari, 10, 15),
            jumlah: jumlah,
            metode: metode,
            noKuitansi:
                'KW/2026/${bulan.toString().padLeft(2, '0')}/'
                '${(100 + no).toString().padLeft(4, '0')}',
          ),
      ],
    );
  }

  static final siswa = <Siswa>[
    Siswa(
      id: 's1',
      nama: 'Aisyah Putri Rahmawati',
      program: Program.sma,
      kelas: '12 IPA',
      asalSekolah: 'SMAN 1 Sleman',
      namaWali: 'Ibu Sri Wahyuni',
      noHpWali: '081234567801',
      tagihan: _tagihan(Keringanan.reguler, Skema.lunas, [
        (7, 14, 2850000, Metode.transfer),
      ]),
    ),
    Siswa(
      id: 's2',
      nama: 'Bima Arya Saputra',
      program: Program.smp,
      kelas: '9B',
      asalSekolah: 'SMPN 4 Depok',
      namaWali: 'Bapak Joko Susilo',
      noHpWali: '081234567802',
      tagihan: _tagihan(Keringanan.reguler, Skema.cicilan, [
        (7, 15, 1550000, Metode.tunai),
        (8, 20, 500000, Metode.tunai),
        (9, 22, 300000, Metode.transfer),
      ]),
    ),
    Siswa(
      id: 's3',
      nama: 'Citra Lestari',
      program: Program.sma,
      kelas: '11 IPS',
      asalSekolah: 'MAN 2 Yogyakarta',
      namaWali: 'Ibu Ratna Dewi',
      noHpWali: '081234567803',
      tagihan: _tagihan(Keringanan.reguler, Skema.cicilan, [
        (7, 16, 1550000, Metode.transfer),
        (10, 8, 650000, Metode.transfer),
      ]),
    ),
    Siswa(
      id: 's4',
      nama: 'Dimas Pratama',
      program: Program.smp,
      kelas: '8A',
      asalSekolah: 'SMPN 1 Ngaglik',
      namaWali: 'Ibu Siti Aminah',
      noHpWali: '081234567804',
      tagihan: _tagihan(Keringanan.yatimPiatu, Skema.cicilan, [
        (7, 18, 800000, Metode.tunai),
        (9, 10, 300000, Metode.tunai),
        (10, 5, 350000, Metode.tunai),
      ]),
    ),
    Siswa(
      id: 's5',
      nama: 'Erlangga Nur Hidayat',
      program: Program.sma,
      kelas: '12 IPA',
      asalSekolah: 'SMAN 3 Yogyakarta',
      namaWali: 'Bapak Agus Salim',
      noHpWali: '081234567805',
      tagihan: _tagihan(Keringanan.tidakMampu, Skema.lunas, []),
    ),
    Siswa(
      id: 's6',
      nama: 'Fadhila Zahra',
      program: Program.smp,
      kelas: '9A',
      asalSekolah: 'SMPN 4 Depok',
      namaWali: 'Ibu Nur Hasanah',
      noHpWali: '081234567806',
      tagihan: _tagihan(Keringanan.reguler, Skema.cicilan, []),
    ),
    Siswa(
      id: 's7',
      nama: 'Galih Ramadhan',
      program: Program.sma,
      kelas: '10',
      asalSekolah: 'SMAN 1 Sleman',
      namaWali: 'Bapak Hendra Gunawan',
      noHpWali: '081234567807',
      tagihan: _tagihan(Keringanan.reguler, Skema.cicilan, [
        (8, 1, 1550000, Metode.transfer),
        (9, 5, 650000, Metode.transfer),
        (10, 3, 650000, Metode.transfer),
      ]),
    ),
    Siswa(
      id: 's8',
      nama: 'Hana Safitri',
      program: Program.smp,
      kelas: '7C',
      asalSekolah: 'MTsN 1 Sleman',
      namaWali: 'Ibu Wulan Sari',
      noHpWali: '081234567808',
      tagihan: _tagihan(Keringanan.reguler, Skema.cicilan, [
        (7, 20, 1550000, Metode.tunai),
        (10, 12, 400000, Metode.tunai),
      ]),
    ),
    Siswa(
      id: 's9',
      nama: 'Indra Kusuma Wardana',
      program: Program.smp,
      kelas: '9C',
      asalSekolah: 'SMPN 2 Sleman',
      namaWali: 'Bapak Bambang Kusuma',
      noHpWali: '081234567809',
      tagihan: _tagihan(Keringanan.reguler, Skema.lunas, [
        (10, 2, 2850000, Metode.transfer),
      ]),
    ),
  ];

  static const tentor = <Tentor>[
    Tentor(
      id: 't1',
      nama: 'Kak Rizki Maulana',
      noHp: '085600000001',
      mapel: 'Matematika',
      tarifPerSesi: 60000,
    ),
    Tentor(
      id: 't2',
      nama: 'Kak Nadia Paramitha',
      noHp: '085600000002',
      mapel: 'Bahasa Inggris',
      tarifPerSesi: 50000,
    ),
    Tentor(
      id: 't3',
      nama: 'Kak Fajar Nugroho',
      noHp: '085600000003',
      mapel: 'Fisika',
      tarifPerSesi: 65000,
    ),
    Tentor(
      id: 't4',
      nama: 'Kak Laila Kurniasih',
      noHp: '085600000004',
      mapel: 'Biologi',
      tarifPerSesi: 55000,
    ),
  ];

  static Kehadiran _hadir(
    String id,
    Tentor t,
    int hari,
    int jamDatang,
    List<Program> sesi,
  ) {
    return Kehadiran(
      id: id,
      tentorId: t.id,
      waktuDatang: DateTime(2026, 10, hari, jamDatang, 50),
      sesi: [
        for (final (i, p) in sesi.indexed)
          Sesi(id: '$id-$i', program: p, mapel: t.mapel, tarif: t.tarifPerSesi),
      ],
    );
  }

  static final kehadiran = <Kehadiran>[
    _hadir('k1', tentor[0], 1, 15, [Program.sma, Program.sma]),
    _hadir('k2', tentor[1], 2, 15, [Program.smp]),
    _hadir('k3', tentor[2], 3, 16, [Program.sma]),
    _hadir('k4', tentor[0], 5, 15, [Program.smp, Program.sma]),
    _hadir('k5', tentor[3], 6, 15, [Program.sma]),
    _hadir('k6', tentor[1], 8, 15, [Program.smp, Program.smp]),
    _hadir('k7', tentor[0], 9, 15, [Program.sma]),
    _hadir('k8', tentor[2], 10, 16, [Program.sma, Program.sma]),
    _hadir('k9', tentor[0], 12, 15, [Program.sma, Program.smp]),
    _hadir('k10', tentor[3], 13, 15, [Program.sma]),
    _hadir('k11', tentor[1], 15, 15, [Program.smp]),
    _hadir('k12', tentor[0], 16, 15, [Program.sma, Program.sma]),
    _hadir('k13', tentor[2], 17, 16, [Program.sma]),
  ];

  static final riwayatHonor = <PembayaranHonor>[
    for (final (i, t) in tentor.indexed) ...[
      PembayaranHonor(
        id: 'h${t.id}-9',
        tentorId: t.id,
        periode: DateTime(2026, 9),
        jumlahSesi: 14 - i * 2,
        total: (14 - i * 2) * t.tarifPerSesi,
        tanggalBayar: DateTime(2026, 9, 30, 16, 30),
      ),
      PembayaranHonor(
        id: 'h${t.id}-8',
        tentorId: t.id,
        periode: DateTime(2026, 8),
        jumlahSesi: 12 - i,
        total: (12 - i) * t.tarifPerSesi,
        tanggalBayar: DateTime(2026, 8, 31, 16, 15),
      ),
    ],
  ];

  static const kategori = <KategoriPengeluaran>[
    KategoriPengeluaran(
      id: KategoriOtomatis.honor,
      nama: 'Honor tentor',
      kodeIkon: 'honor',
      otomatis: true,
    ),
    KategoriPengeluaran(
      id: KategoriOtomatis.gajiAdmin,
      nama: 'Gaji admin',
      kodeIkon: 'gaji',
      otomatis: true,
    ),
    KategoriPengeluaran(id: 'sewa', nama: 'Sewa tempat', kodeIkon: 'sewa'),
    KategoriPengeluaran(
      id: 'listrik',
      nama: 'Listrik & air',
      kodeIkon: 'listrik',
    ),
    KategoriPengeluaran(id: 'atk', nama: 'ATK', kodeIkon: 'atk'),
    KategoriPengeluaran(id: 'fotokopi', nama: 'Fotokopi', kodeIkon: 'fotokopi'),
    KategoriPengeluaran(id: 'lainnya', nama: 'Lainnya', kodeIkon: 'lainnya'),
  ];

  static final pengeluaran = <Pengeluaran>[
    Pengeluaran(
      id: 'e1',
      tanggal: DateTime(2026, 10, 1, 9, 5),
      kategoriId: 'sewa',
      jumlah: 1500000,
      keterangan: 'Sewa ruko bulan Oktober',
      dicatatOleh: 'Irfan',
    ),
    Pengeluaran(
      id: 'e2',
      tanggal: DateTime(2026, 10, 3, 13, 40),
      kategoriId: 'atk',
      jumlah: 85000,
      keterangan: 'Spidol & penghapus papan',
    ),
    Pengeluaran(
      id: 'e3',
      tanggal: DateTime(2026, 10, 7, 11, 20),
      kategoriId: 'fotokopi',
      jumlah: 120000,
      keterangan: 'Fotokopi soal latihan UTS',
    ),
    Pengeluaran(
      id: 'e4',
      tanggal: DateTime(2026, 10, 10, 8, 45),
      kategoriId: 'listrik',
      jumlah: 350000,
      keterangan: 'Token listrik',
    ),
    Pengeluaran(
      id: 'e5',
      tanggal: DateTime(2026, 10, 14, 16, 10),
      kategoriId: 'lainnya',
      jumlah: 60000,
      keterangan: 'Air galon',
    ),
    Pengeluaran(
      id: 'e6',
      tanggal: DateTime(2026, 9, 30, 16, 30),
      kategoriId: KategoriOtomatis.honor,
      jumlah: 2420000,
      keterangan: 'Honor tentor September',
      dicatatOleh: 'Irfan',
    ),
  ];

  static Tentor tentorDenganId(String id) =>
      tentor.firstWhere((t) => t.id == id);

  static Siswa siswaDenganId(String id) => siswa.firstWhere((s) => s.id == id);
}
