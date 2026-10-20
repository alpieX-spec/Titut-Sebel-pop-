# Titut Sebel (Vercel + Supabase)

Halaman full screen + counter klik + suara + leaderboard. Pemain otomatis dapat nama titut_1, titut_2, ... sesuai urutan.

## 1. Siapkan Supabase (gratis)
1. Buat project di https://supabase.com
2. Buka SQL Editor, New query, tempel isi `supabase.sql`, klik Run.
3. Buka Project Settings, API Keys. Salin Project URL dan anon key (atau publishable key).

## 2. Isi konfigurasi
Buka `index.html`, cari dua baris ini dan isi:

    var SUPABASE_URL = 'https://xxxx.supabase.co';
    var SUPABASE_KEY = 'anon-atau-publishable-key';

Key ini memang publik. Tabel dikunci (RLS), jadi browser hanya bisa memanggil 4 fungsi di `supabase.sql`.

## 3. Deploy ke Vercel
Cara A, lewat GitHub:
1. Upload isi folder ini ke repo GitHub baru.
2. Di https://vercel.com, Add New, Project, pilih repo itu.
3. Framework Preset: Other. Build Command dan Output Directory dikosongkan. Klik Deploy.

Cara B, lewat CLI:

    npm i -g vercel
    cd titut-sebel-vercel
    vercel --prod

## Catatan
- Server membatasi sekitar 12 klik per detik per pemain, jadi angka tidak bisa diloncatkan lewat devtools.
- Nama dan hitungan terikat ke browser (token di localStorage). Hapus data browser berarti jadi pemain baru.
- Untuk mengganti gambar atau suara, timpa `titut_sebel.jpg` dan `klik.mp3`.
