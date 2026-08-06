-- Jalankan seluruh isi file ini di Supabase Dashboard -> SQL Editor
-- setelah project Supabase dibuat.

-- 1. Tabel tugas
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  penanggung_jawab text not null,
  status text not null default 'Belum Mulai'
    check (status in ('Belum Mulai', 'Dikerjakan', 'Selesai')),
  created_at timestamptz not null default now(),
  dikerjakan_at timestamptz,
  selesai_at timestamptz
);

-- Jika tabel `tasks` sudah ada sebelumnya (project yang sudah live), jalankan
-- dua baris ini di Supabase Dashboard -> SQL Editor untuk menambah kolom
-- tanggal tanpa menghapus data yang sudah ada:
-- alter table public.tasks add column if not exists dikerjakan_at timestamptz;
-- alter table public.tasks add column if not exists selesai_at timestamptz;

-- Jika gen_random_uuid() error "function does not exist", jalankan dulu:
-- create extension if not exists pgcrypto;

-- 2. Row Level Security: hanya user yang sudah login (magic link) yang
--    boleh baca/tulis, dan semua user login berbagi papan yang sama.
--    Kecuali hapus: hanya penanggung jawab tugas itu sendiri yang boleh
--    (dicocokkan dengan email login, jadi field "Penanggung Jawab" HARUS
--    diisi persis sama dengan email login orang tsb).
alter table public.tasks enable row level security;

create policy "Authenticated select" on public.tasks
  for select to authenticated using (true);

create policy "Authenticated insert" on public.tasks
  for insert to authenticated with check (true);

create policy "Authenticated update" on public.tasks
  for update to authenticated using (true) with check (true);

create policy "PJ sendiri boleh hapus" on public.tasks
  for delete to authenticated using (lower(penanggung_jawab) = lower(auth.email()));

-- 3. Aktifkan Realtime supaya perubahan langsung tersiar ke semua client.
--    Jika publication "supabase_realtime" belum ada di project ini, ganti
--    baris di bawah dengan: create publication supabase_realtime for table public.tasks;
alter publication supabase_realtime add table public.tasks;

-- 4. Backfill SATU KALI untuk tugas lama yang statusnya sudah Dikerjakan/
--    Selesai dari sebelum kolom tanggal ini ada, supaya tidak kosong.
--    Asumsi: tanggal perubahan status = hari ini, karena histori aslinya
--    memang tidak pernah tercatat. Aman dijalankan ulang (tidak menimpa
--    tanggal yang sudah terisi).
update public.tasks set dikerjakan_at = now()
  where status in ('Dikerjakan', 'Selesai') and dikerjakan_at is null;
update public.tasks set selesai_at = now()
  where status = 'Selesai' and selesai_at is null;

-- 5. Arsip otomatis: tugas berstatus "Selesai" dipindah ke tabel arsip lalu
--    dihapus dari papan utama 3 hari setelah tanggal selesainya, supaya
--    papan tetap ringkas tapi datanya tidak pernah hilang.

create table if not exists public.tasks_archive (
  id uuid primary key,
  nama text not null,
  penanggung_jawab text not null,
  status text not null,
  created_at timestamptz not null,
  dikerjakan_at timestamptz,
  selesai_at timestamptz,
  archived_at timestamptz not null default now()
);

alter table public.tasks_archive enable row level security;

create policy "Authenticated select arsip" on public.tasks_archive
  for select to authenticated using (true);

alter publication supabase_realtime add table public.tasks_archive;

create or replace function public.arsipkan_tugas_selesai()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.tasks_archive
    (id, nama, penanggung_jawab, status, created_at, dikerjakan_at, selesai_at)
  select id, nama, penanggung_jawab, status, created_at, dikerjakan_at, selesai_at
  from public.tasks
  where status = 'Selesai'
    and selesai_at is not null
    and selesai_at < now() - interval '3 days'
  on conflict (id) do nothing;

  delete from public.tasks
  where status = 'Selesai'
    and selesai_at is not null
    and selesai_at < now() - interval '3 days';
end;
$$;

-- Jadwalkan fungsi di atas berjalan otomatis tiap hari jam 01:00 (waktu
-- server = UTC). Butuh extension pg_cron. Jika baris "create extension"
-- di bawah error karena izin, aktifkan dulu manual lewat Supabase
-- Dashboard -> Database -> Extensions -> cari "pg_cron" -> Enable, baru
-- jalankan ulang dari baris create extension ini ke bawah.
create extension if not exists pg_cron;

select cron.schedule(
  'arsip-tugas-selesai-harian',
  '0 1 * * *',
  $$select public.arsipkan_tugas_selesai();$$
);

-- 6. Migrasi: batasi hapus tugas hanya untuk penanggung jawabnya sendiri.
--    Jalankan SEKALI di SQL Editor kalau tabel `tasks` sudah live (policy
--    lama "Authenticated delete" mengizinkan siapa saja menghapus apa saja).
--    Fungsi arsip otomatis (langkah 5 di atas) TIDAK terpengaruh karena
--    jalan sebagai `security definer`, jadi tetap bisa hapus tugas Selesai
--    yang sudah 3 hari meski pemiliknya tidak login saat itu.
drop policy if exists "Authenticated delete" on public.tasks;

create policy "PJ sendiri boleh hapus" on public.tasks
  for delete to authenticated using (lower(penanggung_jawab) = lower(auth.email()));

-- Opsional tapi penting: tugas LAMA yang Penanggung Jawab-nya masih nama
-- biasa (RINA, ALFI, dst, bukan email) jadi tidak bisa dihapus siapa pun
-- setelah migrasi ini, karena tidak ada email yang cocok dengan teks itu.
-- Perbaiki dengan ganti ke email asli tiap orang, contoh (sesuaikan dulu):
-- update public.tasks set penanggung_jawab = 'rina@esajaya.com' where penanggung_jawab = 'RINA';
-- update public.tasks set penanggung_jawab = 'alfi@esajaya.com' where penanggung_jawab = 'ALFI';
-- update public.tasks set penanggung_jawab = 'arira@esajaya.com' where penanggung_jawab = 'ARIRA';
-- update public.tasks set penanggung_jawab = 'indrawahyudi.1979@gmail.com' where penanggung_jawab in ('Indra', 'INDRA');
