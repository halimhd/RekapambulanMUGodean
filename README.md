# Laporan Layanan AmbulanMu Godean

Web laporan pelayanan untuk driver. Semua driver mengisi lewat satu link, tanpa login. Admin merekap per hari, mengekspor Excel, dan menyalin format WhatsApp.

Fitur: form laporan, duplikat laporan kemarin (HD rutin), tombol Google Maps, rute jemput–tujuan, KM per layanan dan per hari, foto dokumentasi, kas masuk/keluar dengan keterangan, menu Master (crew, armada, keperluan, lokasi), ekspor .xlsx, dan salin WhatsApp.

Isi paket: `index.html` (web), `supabase.sql` (tabel database), `.github/workflows/keepalive.yml` (menjaga proyek tidak dijeda).

---

## TAHAP 1. Buat proyek Supabase (database gratis)

1. Buka https://supabase.com dan daftar (bisa dengan akun GitHub).
2. Klik **New project**, lalu isi nama (mis. `ambulanmu-godean`), **password database** (simpan di tempat aman), dan region terdekat (mis. Singapore).
3. Pada bagian **Security**:
   - **Enable Data API**: centang.
   - **Automatically expose new tables**: hilangkan centang.
   - **Enable automatic RLS**: centang.
   - **Postgres Type**: biarkan default.
4. Klik **Create new project**, tunggu 1–2 menit sampai selesai.

## TAHAP 2. Buat tabel dengan SQL

1. Di menu kiri proyek, buka **SQL Editor**, lalu klik **New query**.
2. Buka file `supabase.sql`, salin **seluruh isinya**, tempel di editor.
3. Klik **Run**. Hasil yang benar: muncul tulisan "Success. No rows returned".
4. Cek: buka **Table Editor**, harus ada tabel `laporan` dan `master`.

## TAHAP 3. Ambil URL dan kunci (key)

Tampilan Supabase sering berubah, jadi nama menu bisa sedikit berbeda. Cara paling mudah:

**URL proyek**
- Klik tombol **Connect** di bagian atas halaman proyek. URL berbentuk `https://xxxxxxxx.supabase.co`.
- Atau buka **Project Settings** (ikon roda gigi di menu kiri bawah) lalu **Data API** (atau **API**); URL tertulis di bagian atas.
- Salin hanya sampai `.supabase.co`, tanpa `/rest/v1`.

**Kunci (key)**
- Buka **Project Settings > API Keys**.
- Tab pertama berisi **Publishable key**, berawalan `sb_publishable_...`. **Pakai ini.**
- Jika proyek Anda masih menampilkan tab **Legacy API Keys**, kunci `anon` (berawalan `eyJ...`) juga boleh dipakai.
- **JANGAN** pernah memakai **Secret key** (`sb_secret_...`) atau **service_role**. Kunci itu melewati semua pengaman dan tidak boleh ada di web.

## TAHAP 4. Isi pengaturan di index.html

Buka `index.html` dengan Notepad atau VS Code. Di bagian atas script ada:

```js
var SB_URL="ISI_PROJECT_URL_SUPABASE";
var SB_KEY="ISI_PUBLISHABLE_ATAU_ANON_KEY";
var ADMIN_PIN="1234";
```

Ganti dengan nilai Anda, contoh:

```js
var SB_URL="https://abcdefgh.supabase.co";
var SB_KEY="sb_publishable_xxxxxxxxxxxxxxxx";
var ADMIN_PIN="758214";
```

Tetap pakai tanda petik. Simpan file.

## TAHAP 5. Unggah ke GitHub

1. Buat repositori baru di https://github.com/new (mis. `laporan-ambulanmu`).
2. Ekstrak zip, buka terminal di dalam folder, lalu jalankan:

```bash
git init
git add .
git commit -m "Web laporan AmbulanMu Godean"
git branch -M main
git remote add origin https://github.com/USERNAME/NAMA-REPO.git
git push -u origin main
```

(Tanpa terminal: di halaman repositori klik **Add file > Upload files**, lalu seret semua isi folder, termasuk folder `.github`.)

## TAHAP 6. Aktifkan GitHub Pages

1. Di repositori: **Settings > Pages**.
2. **Source**: Deploy from a branch. **Branch**: `main`, folder `/ (root)`. Klik **Save**.
3. Tunggu 1–2 menit. Link web muncul: `https://USERNAME.github.io/NAMA-REPO/`. Bagikan link itu ke driver.

## TAHAP 7. Tes

Buka link, isi satu laporan contoh, simpan, lalu cek di tab **Rekap**. Cek juga di Supabase > Table Editor > `laporan` bahwa datanya masuk. Jika status di atas web berbunyi "Gagal terhubung", periksa URL dan key di Tahap 4.

## TAHAP 8. (Disarankan) Cegah proyek dijeda

Proyek Supabase gratis dijeda jika seminggu tanpa aktivitas.
Di repositori GitHub: **Settings > Secrets and variables > Actions > New repository secret**, buat dua secret:
- `SUPABASE_URL` = URL proyek
- `SUPABASE_KEY` = publishable (atau anon) key

Workflow `keepalive.yml` akan menghubungi database dua kali seminggu.

---

## Keamanan, mohon dibaca
- Web ini tanpa login: siapa pun yang tahu link dan melihat kode bisa membaca dan menambah laporan. Bagikan link hanya ke grup driver/admin.
- Driver bisa **mengedit atau menghapus laporan hanya selama 2 hari** sejak dibuat. Setelah itu terkunci; koreksi dilakukan admin di Supabase > Table Editor.
- Data yang tanggalnya lebih dari 1 tahun dihapus otomatis setiap 1 Januari (permanen). Unduh **Excel semua** sebelum itu.
- `ADMIN_PIN` hanya pengaman ringan (terlihat di kode), bukan keamanan sungguhan.
- Data pasien bersifat pribadi. Jangan unggah foto yang menampilkan wajah atau identitas pasien tanpa persetujuan.

## Cadangan data
Unduh **Excel semua** dari menu Rekap secara berkala (mis. tiap akhir bulan). Paket gratis Supabase tidak punya backup otomatis.

---

## PEMBARUAN: fitur Edit/Hapus laporan dan hapus otomatis bertahap tiap bulan

Jika Anda sudah menjalankan `supabase.sql` versi lama:
1. Supabase > **SQL Editor > New query**, tempel isi `update.sql`, klik **Run**.
2. Jika muncul error soal `pg_cron`, buka **Database > Extensions**, cari `pg_cron`, aktifkan, lalu jalankan ulang bagian jadwalnya.
3. Ganti `index.html` di GitHub dengan versi baru (isi ulang `SB_URL`, `SB_KEY`, `ADMIN_PIN`), lalu Ctrl+F5.
4. Cek jadwal hapus otomatis dengan menjalankan: `select * from cron.job;` (harus ada `hapus-laporan-bulanan`). Tiap tanggal 1, bulan yang sudah 12 bulan penuh terhapus; unduh **Excel semua** sebelum tanggal 1 setiap bulan jika ingin menyimpannya.

Jika proyek baru, cukup jalankan `supabase.sql` terbaru (sudah mencakup semuanya).

