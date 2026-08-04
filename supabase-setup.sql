-- Jalankan seluruh isi file ini di Supabase Dashboard -> SQL Editor
-- setelah project Supabase dibuat.

-- 1. Tabel tugas
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  penanggung_jawab text not null,
  status text not null default 'Belum Mulai'
    check (status in ('Belum Mulai', 'Dikerjakan', 'Selesai')),
  created_at timestamptz not null default now()
);

-- Jika gen_random_uuid() error "function does not exist", jalankan dulu:
-- create extension if not exists pgcrypto;

-- 2. Row Level Security: hanya user yang sudah login (magic link) yang
--    boleh baca/tulis, dan semua user login berbagi papan yang sama.
alter table public.tasks enable row level security;

create policy "Authenticated select" on public.tasks
  for select to authenticated using (true);

create policy "Authenticated insert" on public.tasks
  for insert to authenticated with check (true);

create policy "Authenticated update" on public.tasks
  for update to authenticated using (true) with check (true);

create policy "Authenticated delete" on public.tasks
  for delete to authenticated using (true);

-- 3. Aktifkan Realtime supaya perubahan langsung tersiar ke semua client.
--    Jika publication "supabase_realtime" belum ada di project ini, ganti
--    baris di bawah dengan: create publication supabase_realtime for table public.tasks;
alter publication supabase_realtime add table public.tasks;
