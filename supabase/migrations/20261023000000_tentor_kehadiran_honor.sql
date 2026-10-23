-- Tahap 5: tentor, absensi foto, sesi mengajar, dan pembayaran honor
--
-- Pola sama dengan Tahap 3: tabel hanya bisa dibaca pengguna aktif, semua
-- penulisan lewat fungsi (RPC). Foto kehadiran disimpan di bucket privat
-- "kehadiran" dengan path {tentor_id}/{nama-file}.jpg.

-- ---------------------------------------------------------------------------
-- Tabel
-- ---------------------------------------------------------------------------

create table public.tentor (
  id             uuid primary key default gen_random_uuid(),
  nama           text not null check (length(trim(nama)) > 0),
  no_hp          text not null default '',
  mapel          text not null check (length(trim(mapel)) > 0),
  tarif_per_sesi integer not null check (tarif_per_sesi >= 0),
  aktif          boolean not null default true,
  created_at     timestamptz not null default now()
);

-- Satu baris per kedatangan, wajib dengan foto.
create table public.kehadiran_tentor (
  id                uuid primary key default gen_random_uuid(),
  tentor_id         uuid not null references public.tentor (id),
  waktu_datang      timestamptz not null default now(),
  foto_path         text not null unique,
  foto_dihapus_pada timestamptz,
  created_by        uuid references auth.users (id),
  created_at        timestamptz not null default now()
);

create index kehadiran_tentor_waktu_idx
  on public.kehadiran_tentor (tentor_id, waktu_datang);

create table public.pembayaran_honor (
  id              uuid primary key default gen_random_uuid(),
  tentor_id       uuid not null references public.tentor (id),
  periode         date not null check (extract(day from periode) = 1),
  jumlah_sesi     integer not null check (jumlah_sesi > 0),
  total           integer not null check (total >= 0),
  metode          public.metode_bayar not null,
  dibayar_pada    timestamptz not null default now(),
  created_by      uuid references auth.users (id),
  dibatalkan      boolean not null default false,
  dibatalkan_oleh uuid references auth.users (id),
  dibatalkan_pada timestamptz,
  alasan_batal    text,
  check (
    not dibatalkan
    or (alasan_batal is not null and length(trim(alasan_batal)) > 0)
  )
);

create index pembayaran_honor_tentor_idx
  on public.pembayaran_honor (tentor_id, periode);

-- Tarif disalin saat sesi dicatat, jadi kenaikan tarif tidak mengubah
-- honor sesi lama.
create table public.sesi_mengajar (
  id                  uuid primary key default gen_random_uuid(),
  kehadiran_id        uuid not null references public.kehadiran_tentor (id),
  tentor_id           uuid not null references public.tentor (id),
  program             text not null check (program in ('smp', 'sma')),
  mapel               text not null,
  tarif               integer not null check (tarif >= 0),
  pembayaran_honor_id uuid references public.pembayaran_honor (id),
  created_at          timestamptz not null default now()
);

create index sesi_mengajar_kehadiran_idx on public.sesi_mengajar (kehadiran_id);
create index sesi_mengajar_belum_dibayar_idx
  on public.sesi_mengajar (tentor_id)
  where pembayaran_honor_id is null;

-- ---------------------------------------------------------------------------
-- Hak akses: hanya baca untuk pengguna aktif
-- ---------------------------------------------------------------------------

alter table public.tentor enable row level security;
alter table public.kehadiran_tentor enable row level security;
alter table public.sesi_mengajar enable row level security;
alter table public.pembayaran_honor enable row level security;

revoke all on public.tentor, public.kehadiran_tentor, public.sesi_mengajar,
  public.pembayaran_honor
  from anon, authenticated;

grant select on public.tentor, public.kehadiran_tentor, public.sesi_mengajar,
  public.pembayaran_honor
  to authenticated;

create policy "pengguna aktif membaca tentor"
  on public.tentor for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca kehadiran"
  on public.kehadiran_tentor for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca sesi"
  on public.sesi_mengajar for select to authenticated
  using ((select private.pengguna_aktif()));

create policy "pengguna aktif membaca honor"
  on public.pembayaran_honor for select to authenticated
  using ((select private.pengguna_aktif()));

-- ---------------------------------------------------------------------------
-- Penyimpanan foto kehadiran (bucket privat, maks 500 KB, hanya JPEG)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('kehadiran', 'kehadiran', false, 512000, array['image/jpeg']);

create policy "pengguna aktif mengunggah foto kehadiran"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'kehadiran'
    and (select private.pengguna_aktif())
  );

create policy "pengguna aktif melihat foto kehadiran"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'kehadiran'
    and (select private.pengguna_aktif())
  );

-- ---------------------------------------------------------------------------
-- Fungsi (RPC)
-- ---------------------------------------------------------------------------

-- Jam server, dipakai untuk cap waktu di foto supaya jam HP tidak bisa
-- dipakai mengakali kehadiran.
create or replace function public.waktu_server()
returns timestamptz
language sql
stable
set search_path = ''
as $$
  select now();
$$;

-- Tambah (p_id null) atau ubah tentor. Hanya owner.
create or replace function public.simpan_tentor(
  p_id             uuid,
  p_nama           text,
  p_no_hp          text,
  p_mapel          text,
  p_tarif_per_sesi integer,
  p_aktif          boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not private.is_owner() then
    raise exception 'Hanya owner yang bisa mengatur data tentor'
      using errcode = '42501';
  end if;

  if p_id is null then
    insert into public.tentor (nama, no_hp, mapel, tarif_per_sesi, aktif)
    values (trim(p_nama), trim(coalesce(p_no_hp, '')), trim(p_mapel),
            p_tarif_per_sesi, coalesce(p_aktif, true))
    returning id into v_id;
  else
    update public.tentor
    set nama = trim(p_nama),
        no_hp = trim(coalesce(p_no_hp, '')),
        mapel = trim(p_mapel),
        tarif_per_sesi = p_tarif_per_sesi,
        aktif = coalesce(p_aktif, aktif)
    where id = p_id
    returning id into v_id;

    if v_id is null then
      raise exception 'Tentor tidak ditemukan' using errcode = 'P0001';
    end if;
  end if;

  return v_id;
end;
$$;

-- Catat kedatangan tentor beserta sesi yang diajar.
-- p_sesi: [{"program": "smp", "mapel": "Matematika"}, ...]
create or replace function public.catat_kehadiran(
  p_tentor_id uuid,
  p_foto_path text,
  p_sesi      jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tentor       public.tentor;
  v_kehadiran_id uuid;
  v_sesi         jsonb;
begin
  if not private.pengguna_aktif() then
    raise exception 'Akun tidak aktif' using errcode = '42501';
  end if;

  select * into v_tentor
  from public.tentor
  where id = p_tentor_id and aktif;
  if not found then
    raise exception 'Tentor tidak ditemukan atau tidak aktif'
      using errcode = 'P0001';
  end if;

  if p_sesi is null
     or jsonb_typeof(p_sesi) <> 'array'
     or jsonb_array_length(p_sesi) = 0 then
    raise exception 'Minimal satu sesi harus dicatat' using errcode = 'P0001';
  end if;

  -- Foto wajib sudah terunggah di folder milik tentor ini.
  if split_part(coalesce(p_foto_path, ''), '/', 1) <> p_tentor_id::text
     or not exists (
       select 1 from storage.objects
       where bucket_id = 'kehadiran' and name = p_foto_path
     ) then
    raise exception 'Foto kehadiran belum terunggah' using errcode = 'P0001';
  end if;

  insert into public.kehadiran_tentor (tentor_id, foto_path, created_by)
  values (p_tentor_id, p_foto_path, auth.uid())
  returning id into v_kehadiran_id;

  for v_sesi in select * from jsonb_array_elements(p_sesi) loop
    if coalesce(v_sesi ->> 'program', '') not in ('smp', 'sma') then
      raise exception 'Program sesi tidak valid' using errcode = 'P0001';
    end if;

    insert into public.sesi_mengajar
      (kehadiran_id, tentor_id, program, mapel, tarif)
    values (
      v_kehadiran_id, p_tentor_id, v_sesi ->> 'program',
      coalesce(nullif(trim(v_sesi ->> 'mapel'), ''), v_tentor.mapel),
      v_tentor.tarif_per_sesi
    );
  end loop;

  return v_kehadiran_id;
end;
$$;

-- Bayar honor semua sesi yang belum dibayar pada bulan p_periode.
create or replace function public.bayar_honor(
  p_tentor_id uuid,
  p_periode   date,
  p_metode    public.metode_bayar
)
returns public.pembayaran_honor
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_awal   date := date_trunc('month', p_periode)::date;
  v_akhir  date := (date_trunc('month', p_periode) + interval '1 month')::date;
  v_jumlah integer;
  v_total  integer;
  v_hasil  public.pembayaran_honor;
begin
  if not private.pengguna_aktif() then
    raise exception 'Akun tidak aktif' using errcode = '42501';
  end if;

  -- Kunci tentor supaya honor tidak dibayar dobel bersamaan.
  perform 1 from public.tentor where id = p_tentor_id for update;
  if not found then
    raise exception 'Tentor tidak ditemukan' using errcode = 'P0001';
  end if;

  select count(*), coalesce(sum(s.tarif), 0)
  into v_jumlah, v_total
  from public.sesi_mengajar s
  join public.kehadiran_tentor k on k.id = s.kehadiran_id
  where s.tentor_id = p_tentor_id
    and s.pembayaran_honor_id is null
    and (k.waktu_datang at time zone 'Asia/Jakarta')::date >= v_awal
    and (k.waktu_datang at time zone 'Asia/Jakarta')::date < v_akhir;

  if v_jumlah = 0 then
    raise exception 'Tidak ada sesi yang belum dibayar pada periode ini'
      using errcode = 'P0001';
  end if;

  insert into public.pembayaran_honor
    (tentor_id, periode, jumlah_sesi, total, metode, created_by)
  values (p_tentor_id, v_awal, v_jumlah, v_total, p_metode, auth.uid())
  returning * into v_hasil;

  update public.sesi_mengajar s
  set pembayaran_honor_id = v_hasil.id
  from public.kehadiran_tentor k
  where k.id = s.kehadiran_id
    and s.tentor_id = p_tentor_id
    and s.pembayaran_honor_id is null
    and (k.waktu_datang at time zone 'Asia/Jakarta')::date >= v_awal
    and (k.waktu_datang at time zone 'Asia/Jakarta')::date < v_akhir;

  return v_hasil;
end;
$$;

-- Batalkan pembayaran honor (hanya owner, wajib alasan). Sesinya kembali
-- berstatus belum dibayar.
create or replace function public.batalkan_honor(
  p_honor_id uuid,
  p_alasan   text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_owner() then
    raise exception 'Hanya owner yang bisa membatalkan pembayaran honor'
      using errcode = '42501';
  end if;
  if p_alasan is null or length(trim(p_alasan)) = 0 then
    raise exception 'Alasan pembatalan wajib diisi' using errcode = 'P0001';
  end if;

  update public.pembayaran_honor
  set dibatalkan = true,
      dibatalkan_oleh = auth.uid(),
      dibatalkan_pada = now(),
      alasan_batal = trim(p_alasan)
  where id = p_honor_id and not dibatalkan;

  if not found then
    raise exception 'Pembayaran honor tidak ditemukan atau sudah dibatalkan'
      using errcode = 'P0001';
  end if;

  update public.sesi_mengajar
  set pembayaran_honor_id = null
  where pembayaran_honor_id = p_honor_id;
end;
$$;

revoke all on function public.waktu_server() from public, anon;
revoke all on function public.simpan_tentor(uuid, text, text, text, integer, boolean)
  from public, anon;
revoke all on function public.catat_kehadiran(uuid, text, jsonb) from public, anon;
revoke all on function public.bayar_honor(uuid, date, public.metode_bayar)
  from public, anon;
revoke all on function public.batalkan_honor(uuid, text) from public, anon;

grant execute on function public.waktu_server() to authenticated;
grant execute on function public.simpan_tentor(uuid, text, text, text, integer, boolean)
  to authenticated;
grant execute on function public.catat_kehadiran(uuid, text, jsonb) to authenticated;
grant execute on function public.bayar_honor(uuid, date, public.metode_bayar)
  to authenticated;
grant execute on function public.batalkan_honor(uuid, text) to authenticated;
