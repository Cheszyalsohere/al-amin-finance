-- Tahap 3: siswa, tagihan, dan pembayaran
--
-- Tabel hanya bisa DIBACA langsung oleh pengguna aktif. Semua penulisan
-- lewat fungsi (RPC) di bawah, supaya aturan biaya, batas sisa tagihan, dan
-- nomor kuitansi selalu dihitung di server dan tidak bisa diakali dari HP.

-- ---------------------------------------------------------------------------
-- Fungsi bantu
-- ---------------------------------------------------------------------------

create or replace function private.pengguna_aktif()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and aktif
  );
$$;

revoke all on function private.pengguna_aktif() from public;
grant execute on function private.pengguna_aktif() to authenticated;

-- ---------------------------------------------------------------------------
-- Pengaturan biaya
-- ---------------------------------------------------------------------------

create table public.tahun_ajaran (
  id              bigint generated always as identity primary key,
  nama            text not null unique,
  tanggal_mulai   date not null,
  tanggal_selesai date not null,
  batas_cicilan   date not null,
  aktif           boolean not null default false,
  check (tanggal_mulai < tanggal_selesai)
);

-- Hanya boleh ada satu tahun ajaran aktif.
create unique index tahun_ajaran_satu_aktif
  on public.tahun_ajaran (aktif)
  where aktif;

create table public.program (
  id              bigint generated always as identity primary key,
  tahun_ajaran_id bigint not null references public.tahun_ajaran (id),
  kode            text not null check (kode in ('smp', 'sma')),
  nama            text not null,
  biaya           integer not null check (biaya >= 0),
  uang_muka       integer not null check (uang_muka >= 0),
  biaya_admin     integer not null check (biaya_admin >= 0),
  unique (tahun_ajaran_id, kode)
);

create table public.keringanan (
  kode            text primary key
                  check (kode in ('reguler', 'yatim_piatu', 'tidak_mampu')),
  nama            text not null,
  persen_potongan integer not null check (persen_potongan between 0 and 100),
  gratis_admin    boolean not null default false
);

-- ---------------------------------------------------------------------------
-- Siswa, tagihan, pembayaran
-- ---------------------------------------------------------------------------

create type public.skema_bayar as enum ('lunas', 'cicilan');
create type public.metode_bayar as enum ('tunai', 'transfer');

create table public.siswa (
  id           uuid primary key default gen_random_uuid(),
  nama         text not null check (length(trim(nama)) > 0),
  kelas        text not null check (length(trim(kelas)) > 0),
  asal_sekolah text,
  nama_wali    text not null check (length(trim(nama_wali)) > 0),
  no_hp_wali   text not null check (length(trim(no_hp_wali)) > 0),
  aktif        boolean not null default true,
  created_by   uuid references auth.users (id),
  created_at   timestamptz not null default now()
);

-- Satu tagihan per siswa per tahun ajaran. Nominal disalin saat dibuat,
-- jadi perubahan harga tahun depan tidak mengubah tagihan lama.
create table public.tagihan (
  id                 uuid primary key default gen_random_uuid(),
  siswa_id           uuid not null references public.siswa (id),
  tahun_ajaran_id    bigint not null references public.tahun_ajaran (id),
  program_id         bigint not null references public.program (id),
  skema              public.skema_bayar not null,
  keringanan         text not null references public.keringanan (kode),
  persen_potongan    integer not null,
  biaya_pokok        integer not null check (biaya_pokok >= 0),
  potongan           integer not null check (potongan >= 0),
  biaya_admin        integer not null check (biaya_admin >= 0),
  pembayaran_pertama integer not null check (pembayaran_pertama >= 0),
  total              integer generated always as
                       (biaya_pokok - potongan + biaya_admin) stored,
  batas_pelunasan    date not null,
  created_by         uuid references auth.users (id),
  created_at         timestamptz not null default now(),
  unique (siswa_id, tahun_ajaran_id)
);

create index tagihan_tahun_ajaran_idx on public.tagihan (tahun_ajaran_id);

create sequence public.nomor_kuitansi;

create table public.pembayaran (
  id              uuid primary key default gen_random_uuid(),
  tagihan_id      uuid not null references public.tagihan (id),
  dibayar_pada    timestamptz not null default now(),
  jumlah          integer not null check (jumlah > 0),
  metode          public.metode_bayar not null,
  no_kuitansi     text not null unique,
  keterangan      text,
  created_by      uuid references auth.users (id),
  created_at      timestamptz not null default now(),
  dibatalkan      boolean not null default false,
  dibatalkan_oleh uuid references auth.users (id),
  dibatalkan_pada timestamptz,
  alasan_batal    text,
  check (
    not dibatalkan
    or (alasan_batal is not null and length(trim(alasan_batal)) > 0)
  )
);

create index pembayaran_tagihan_idx on public.pembayaran (tagihan_id);

-- ---------------------------------------------------------------------------
-- Hak akses: hanya baca untuk pengguna aktif
-- ---------------------------------------------------------------------------

alter table public.tahun_ajaran enable row level security;
alter table public.program enable row level security;
alter table public.keringanan enable row level security;
alter table public.siswa enable row level security;
alter table public.tagihan enable row level security;
alter table public.pembayaran enable row level security;

revoke all on public.tahun_ajaran, public.program, public.keringanan,
  public.siswa, public.tagihan, public.pembayaran
  from anon, authenticated;
revoke all on sequence public.nomor_kuitansi from anon, authenticated;

grant select on public.tahun_ajaran, public.program, public.keringanan,
  public.siswa, public.tagihan, public.pembayaran
  to authenticated;

create policy "pengguna aktif membaca tahun ajaran"
  on public.tahun_ajaran for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca program"
  on public.program for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca keringanan"
  on public.keringanan for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca siswa"
  on public.siswa for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca tagihan"
  on public.tagihan for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca pembayaran"
  on public.pembayaran for select to authenticated
  using ((select private.pengguna_aktif()));

-- ---------------------------------------------------------------------------
-- Fungsi tulis (RPC)
-- ---------------------------------------------------------------------------

-- Daftarkan siswa baru beserta tagihannya untuk tahun ajaran aktif.
create or replace function public.daftar_siswa(
  p_nama         text,
  p_kelas        text,
  p_asal_sekolah text,
  p_nama_wali    text,
  p_no_hp_wali   text,
  p_program      text,
  p_keringanan   text,
  p_skema        public.skema_bayar
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ta        public.tahun_ajaran;
  v_program   public.program;
  v_kr        public.keringanan;
  v_potongan  integer;
  v_admin     integer;
  v_total     integer;
  v_skema     public.skema_bayar := p_skema;
  v_pertama   integer;
  v_siswa_id  uuid;
begin
  if not private.pengguna_aktif() then
    raise exception 'Akun tidak aktif' using errcode = '42501';
  end if;

  select * into v_ta from public.tahun_ajaran where aktif;
  if not found then
    raise exception 'Belum ada tahun ajaran aktif' using errcode = 'P0001';
  end if;

  select * into v_program
  from public.program
  where tahun_ajaran_id = v_ta.id and kode = p_program;
  if not found then
    raise exception 'Program % tidak ada', p_program using errcode = 'P0001';
  end if;

  select * into v_kr from public.keringanan where kode = p_keringanan;
  if not found then
    raise exception 'Keringanan % tidak ada', p_keringanan
      using errcode = 'P0001';
  end if;

  v_potongan := v_program.biaya * v_kr.persen_potongan / 100;
  v_admin := case when v_kr.gratis_admin then 0 else v_program.biaya_admin end;
  v_total := v_program.biaya - v_potongan + v_admin;

  -- Siswa gratis tidak perlu dicicil.
  if v_total = 0 then
    v_skema := 'lunas';
  end if;

  v_pertama := case
    when v_skema = 'lunas' then v_total
    else v_program.uang_muka * (100 - v_kr.persen_potongan) / 100 + v_admin
  end;

  insert into public.siswa
    (nama, kelas, asal_sekolah, nama_wali, no_hp_wali, created_by)
  values (
    trim(p_nama), trim(p_kelas), nullif(trim(p_asal_sekolah), ''),
    trim(p_nama_wali), trim(p_no_hp_wali), auth.uid()
  )
  returning id into v_siswa_id;

  insert into public.tagihan (
    siswa_id, tahun_ajaran_id, program_id, skema, keringanan,
    persen_potongan, biaya_pokok, potongan, biaya_admin,
    pembayaran_pertama, batas_pelunasan, created_by
  ) values (
    v_siswa_id, v_ta.id, v_program.id, v_skema, v_kr.kode,
    v_kr.persen_potongan, v_program.biaya, v_potongan, v_admin,
    v_pertama, v_ta.batas_cicilan, auth.uid()
  );

  return v_siswa_id;
end;
$$;

-- Catat pembayaran. Nominal tidak boleh melebihi sisa, dan pembayaran
-- pertama minimal sebesar uang muka + admin (atau lunas penuh).
create or replace function public.catat_pembayaran(
  p_tagihan_id uuid,
  p_jumlah     integer,
  p_metode     public.metode_bayar,
  p_keterangan text default null
)
returns public.pembayaran
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tagihan public.tagihan;
  v_dibayar integer;
  v_sisa    integer;
  v_hasil   public.pembayaran;
begin
  if not private.pengguna_aktif() then
    raise exception 'Akun tidak aktif' using errcode = '42501';
  end if;

  -- Kunci tagihan supaya dua pembayaran bersamaan tidak melebihi sisa.
  select * into v_tagihan
  from public.tagihan
  where id = p_tagihan_id
  for update;
  if not found then
    raise exception 'Tagihan tidak ditemukan' using errcode = 'P0001';
  end if;

  select coalesce(sum(jumlah), 0) into v_dibayar
  from public.pembayaran
  where tagihan_id = p_tagihan_id and not dibatalkan;

  v_sisa := v_tagihan.total - v_dibayar;

  if p_jumlah is null or p_jumlah <= 0 then
    raise exception 'Nominal harus lebih dari 0' using errcode = 'P0001';
  end if;
  if p_jumlah > v_sisa then
    raise exception 'Nominal melebihi sisa tagihan (%)', v_sisa
      using errcode = 'P0001';
  end if;
  if v_dibayar = 0 and p_jumlah < v_tagihan.pembayaran_pertama then
    raise exception 'Pembayaran pertama minimal %',
      v_tagihan.pembayaran_pertama
      using errcode = 'P0001';
  end if;

  insert into public.pembayaran
    (tagihan_id, jumlah, metode, no_kuitansi, keterangan, created_by)
  values (
    p_tagihan_id, p_jumlah, p_metode,
    'KW/' || to_char(now() at time zone 'Asia/Jakarta', 'YYYY/MM') || '/'
      || lpad(nextval('public.nomor_kuitansi')::text, 5, '0'),
    nullif(trim(p_keterangan), ''),
    auth.uid()
  )
  returning * into v_hasil;

  return v_hasil;
end;
$$;

-- Batalkan pembayaran (hanya owner, wajib alasan). Data tidak dihapus.
create or replace function public.batalkan_pembayaran(
  p_pembayaran_id uuid,
  p_alasan        text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_owner() then
    raise exception 'Hanya owner yang bisa membatalkan pembayaran'
      using errcode = '42501';
  end if;
  if p_alasan is null or length(trim(p_alasan)) = 0 then
    raise exception 'Alasan pembatalan wajib diisi' using errcode = 'P0001';
  end if;

  update public.pembayaran
  set dibatalkan = true,
      dibatalkan_oleh = auth.uid(),
      dibatalkan_pada = now(),
      alasan_batal = trim(p_alasan)
  where id = p_pembayaran_id and not dibatalkan;

  if not found then
    raise exception 'Pembayaran tidak ditemukan atau sudah dibatalkan'
      using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.daftar_siswa(
  text, text, text, text, text, text, text, public.skema_bayar
) from public, anon;
revoke all on function public.catat_pembayaran(
  uuid, integer, public.metode_bayar, text
) from public, anon;
revoke all on function public.batalkan_pembayaran(uuid, text)
  from public, anon;

grant execute on function public.daftar_siswa(
  text, text, text, text, text, text, text, public.skema_bayar
) to authenticated;
grant execute on function public.catat_pembayaran(
  uuid, integer, public.metode_bayar, text
) to authenticated;
grant execute on function public.batalkan_pembayaran(uuid, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Data awal tahun ajaran 2026/2027
-- ---------------------------------------------------------------------------

insert into public.keringanan (kode, nama, persen_potongan, gratis_admin) values
  ('reguler', 'Reguler', 0, false),
  ('yatim_piatu', 'Yatim/piatu', 50, false),
  ('tidak_mampu', 'Tidak mampu', 100, true);

with ta as (
  insert into public.tahun_ajaran
    (nama, tanggal_mulai, tanggal_selesai, batas_cicilan, aktif)
  values ('2026/2027', '2026-07-01', '2027-06-30', '2026-12-31', true)
  returning id
)
insert into public.program
  (tahun_ajaran_id, kode, nama, biaya, uang_muka, biaya_admin)
select ta.id, p.kode, p.nama, 2800000, 1500000, 50000
from ta, (values ('smp', 'SMP'), ('sma', 'SMA')) as p (kode, nama);
