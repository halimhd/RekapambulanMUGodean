-- Jalankan di Supabase: menu SQL Editor > New query > tempel > Run

create table if not exists laporan (
  id text primary key,
  tgl date not null,
  data jsonb not null,
  foto jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);
create index if not exists laporan_tgl_idx on laporan (tgl);

create table if not exists master (
  id text primary key,
  data jsonb not null
);

alter table laporan enable row level security;
alter table master enable row level security;

-- Driver (tanpa login) boleh MELIHAT dan MENAMBAH laporan; edit/hapus hanya 2 hari (lihat bawah)
create policy "baca laporan" on laporan for select to anon using (true);
create policy "tambah laporan" on laporan for insert to anon with check (true);

-- Menu Master (daftar crew, armada, dll.)
create policy "baca master" on master for select to anon using (true);
create policy "tambah master" on master for insert to anon with check (true);
create policy "ubah master" on master for update to anon using (true) with check (true);

-- Izin akses untuk Data API (diperlukan jika "Automatically expose new tables" dimatikan; aman jika dibiarkan aktif)
grant usage on schema public to anon;
grant select, insert, update, delete on public.laporan to anon;
grant select, insert, update on public.master to anon;

-- 1) Driver boleh mengedit dan menghapus laporan, hanya selama 2 hari sejak dibuat
--    (jika ingin ganti jumlah hari, ubah '2 days' DAN EDIT_HARI di index.html)
create policy "ubah laporan 2 hari" on laporan for update to anon
  using (created_at > now() - interval '2 days')
  with check (true);

create policy "hapus laporan 2 hari" on laporan for delete to anon
  using (created_at > now() - interval '2 days');

-- 2) Hapus otomatis data lama bertahap tiap bulan (bulan yang sudah lewat 12 bulan)
--    Data 12 bulan terakhir tetap tersimpan.
create extension if not exists pg_cron with schema pg_catalog;

-- Matikan jadwal tahunan lama (aman dijalankan walau jadwalnya tidak ada)
do $$ begin perform cron.unschedule('hapus-laporan-lama-tahunan'); exception when others then null; end $$;

-- Hapus BERTAHAP tiap bulan: setiap tanggal 1 pukul 10.00 WIB (03.00 UTC), bulan yang sudah lewat 12 bulan penuh dihapus.
-- Contoh: pada 1 Februari 2026 yang terhapus bulan Januari 2025; pada 1 Maret 2026 yang terhapus Februari 2025; dst.
-- Data 12 bulan terakhir selalu aman. Jika sebuah bulan terlewat, bulan lama itu ikut terhapus pada jadwal berikutnya.
select cron.schedule(
  'hapus-laporan-bulanan',
  '0 3 1 * *',
  $$ delete from public.laporan where tgl < (date_trunc('month', current_date) - interval '12 months')::date $$
);

-- Cek jadwal:      select * from cron.job;
-- Hentikan jadwal: select cron.unschedule('hapus-laporan-bulanan');
