enum Peran {
  owner('Owner'),
  admin('Admin');

  const Peran(this.label);

  final String label;

  static Peran dariString(String nilai) =>
      Peran.values.firstWhere((p) => p.name == nilai, orElse: () => admin);
}

class Profil {
  const Profil({
    required this.id,
    required this.nama,
    required this.peran,
    required this.aktif,
  });

  factory Profil.dariMap(Map<String, dynamic> map) => Profil(
    id: map['id'] as String,
    nama: map['nama'] as String,
    peran: Peran.dariString(map['peran'] as String),
    aktif: map['aktif'] as bool,
  );

  final String id;
  final String nama;
  final Peran peran;
  final bool aktif;

  bool get isOwner => peran == Peran.owner;
}
