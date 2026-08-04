# Papan Koordinasi Tim

Aplikasi web sederhana untuk mengganti koordinasi tugas tim yang biasanya dilakukan lewat WhatsApp. Semua tugas tim terlihat dalam satu layar, jadi tidak perlu scroll chat lagi untuk tahu siapa mengerjakan apa.

## Fitur

- Login tanpa password lewat Magic Link (email)
- Tambah tugas baru (nama tugas, penanggung jawab, status)
- Ubah status tugas antara **Belum Mulai**, **Dikerjakan**, dan **Selesai**
- Lihat semua tugas dalam satu papan dengan 3 kolom status, sinkron real-time antar perangkat
- Hapus tugas yang sudah tidak relevan

## Teknologi

Satu halaman `index.html` dengan HTML, CSS, dan JavaScript biasa (tanpa framework, tanpa build step). Data tugas, autentikasi, dan sinkronisasi real-time disediakan oleh [Supabase](https://supabase.com) (Postgres + Auth + Realtime), diakses lewat `@supabase/supabase-js` via CDN.

## Setup Supabase

1. Buat project baru di [supabase.com](https://supabase.com).
2. Buka **SQL Editor**, jalankan seluruh isi `supabase-setup.sql` untuk membuat tabel `tasks`, mengaktifkan Row Level Security, dan mengaktifkan Realtime.
3. Di **Authentication → URL Configuration**, set **Site URL** dan tambahkan **Redirect URLs** untuk tiap alamat tempat aplikasi dibuka (lokal maupun hasil deploy) — lihat bagian "Cara Menjalankan" di bawah.
4. Di **Project Settings → API**, salin **Project URL** dan **`anon` `public` key**, lalu isikan ke konstanta `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di dalam `index.html`.

## Cara Menjalankan

Karena login pakai Magic Link membutuhkan redirect ke URL `http(s)`, aplikasi **tidak bisa** dibuka langsung lewat `file://`. Jalankan lewat server statis lokal, misalnya:

```
npx serve .
```

lalu buka URL yang ditampilkan (mis. `http://localhost:3000`), dan pastikan URL tersebut sudah terdaftar di Redirect URLs Supabase. Untuk produksi, deploy sebagai situs statis (misal ke Vercel) dan tambahkan URL deploy tersebut ke Redirect URLs juga.

## Catatan

Papan tugas ini bersifat satu papan bersama untuk seluruh tim — setiap user yang berhasil login (lewat Magic Link) dapat melihat dan mengubah semua tugas, tidak dipisah per pengguna.
