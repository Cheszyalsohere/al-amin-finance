-- Tahap 1: akun pengguna (owner & admin)
--
-- Setiap akun di auth.users otomatis mendapat baris di public.profiles dengan
-- peran 'admin'. Peran owner diberikan manual lewat SQL (lihat README),
-- jadi tidak ada pengguna yang bisa mengangkat dirinya sendiri.

create type public.peran as enum ('owner', 'admin');

create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  nama       text not null,
  peran      public.peran not null default 'admin',
  aktif      boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.profiles is 'Akun pengguna aplikasi: owner atau admin.';

alter table public.profiles enable row level security;

-- Fungsi bantu di skema private (tidak diekspos lewat Data API).
create schema if not exists private;

create or replace function private.is_owner()
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
      and peran = 'owner'
      and aktif
  );
$$;

revoke all on function private.is_owner() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_owner() to authenticated;

-- Buat profil otomatis saat akun baru dibuat. Peran selalu 'admin';
-- nama boleh diambil dari metadata karena bukan data otorisasi.
create or replace function private.buat_profil_baru()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, nama)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'nama'), ''), new.email)
  );
  return new;
end;
$$;

revoke all on function private.buat_profil_baru() from public;

create trigger saat_akun_dibuat
  after insert on auth.users
  for each row execute function private.buat_profil_baru();

-- Hak akses tabel
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (nama, peran, aktif) on public.profiles to authenticated;

-- Setiap pengguna bisa melihat profilnya sendiri; owner bisa melihat semua.
create policy "lihat profil sendiri atau owner"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id or (select private.is_owner()));

-- Hanya owner yang bisa mengubah profil (nama, peran, status aktif).
create policy "owner mengubah profil"
  on public.profiles for update
  to authenticated
  using ((select private.is_owner()))
  with check ((select private.is_owner()));
