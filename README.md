# Papan Koordinasi Tim

Aplikasi web sederhana untuk mengganti koordinasi tugas tim yang biasanya dilakukan lewat WhatsApp. Semua tugas tim terlihat dalam satu layar, jadi tidak perlu scroll chat lagi untuk tahu siapa mengerjakan apa.

## Fitur

- Tambah tugas baru (nama tugas, penanggung jawab, status)
- Ubah status tugas antara **Belum Mulai**, **Dikerjakan**, dan **Selesai**
- Lihat semua tugas dalam satu papan dengan 3 kolom status
- Hapus tugas yang sudah tidak relevan

## Teknologi

Satu halaman `index.html` dengan HTML, CSS, dan JavaScript biasa (tanpa framework). Data tugas disimpan di `localStorage` browser, jadi tidak butuh database atau backend.

## Cara Menjalankan

Buka `index.html` langsung di browser, atau deploy sebagai situs statis (misal ke Vercel).

## Catatan

Karena data disimpan di `localStorage`, data hanya tersimpan di browser dan perangkat yang dipakai untuk membuka aplikasi ini. Tidak ada sinkronisasi antar perangkat.
