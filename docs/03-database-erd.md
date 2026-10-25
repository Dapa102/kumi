# Kumi — Skema Basis Data & ERD

**Versi:** 1.0
**DBMS:** MariaDB 11.4
**Charset:** `utf8mb4` / `utf8mb4_unicode_ci`
**Storage engine:** InnoDB

---

## 1. Prinsip Perancangan

1. **Normalisasi hingga 3NF.** Tidak ada data yang terduplikasi kecuali yang memang denormalisasi terkontrol (`users.current_streak`).
2. **Kunci utama numerik.** `BIGINT UNSIGNED AUTO_INCREMENT` untuk performa indeks dan stabilitas referensi.
3. **Waktu dalam UTC.** Semua kolom `DATETIME` disimpan UTC; konversi ke zona waktu pengguna dilakukan di klien.
4. **Data siap ML.** `tasks.completed_at`, `tasks.due_time`, dan `tasks.created_at` disimpan lengkap agar dapat menjadi dataset di masa depan tanpa perubahan skema.
5. **Penghapusan terkendali.** `tasks` memakai hard delete pada MVP; `users` tidak dihapus otomatis. `user_achievements` memakai `ON DELETE CASCADE`.

---

## 2. ERD

### 2.1 Diagram relasi

```
┌──────────────────────┐
│        users         │
├──────────────────────┤
│ id            PK     │
│ google_id     UQ     │
│ email         UQ     │
│ name                 │
│ picture_url          │
│ current_streak       │
│ last_completed_date  │
│ created_at           │
└──────┬───────────────┘
       │ 1
       │
       │ N
┌──────▼───────────────┐          ┌──────────────────────┐
│        tasks         │          │     achievements     │
├──────────────────────┤          ├──────────────────────┤
│ id            PK     │          │ id            PK     │
│ user_id       FK     │          │ code          UQ     │
│ title                │          │ name                 │
│ description          │          │ description          │
│ due_time             │          │ icon                 │
│ is_completed         │          │ criteria_type        │
│ completed_at         │          │ criteria_value       │
│ created_at           │          │ created_at           │
│ updated_at           │          └──────────┬───────────┘
└──────────────────────┘                     │ 1
                                             │
                                             │ N
                                  ┌──────────▼────────────────┐
                                  │    user_achievements      │
                                  ├───────────────────────────┤
                                  │ id             PK         │
                                  │ user_id        FK         │
                                  │ achievement_id FK         │
                                  │ earned_at                 │
                                  │ UQ(user_id, achievement_id)│
                                  └───────────────────────────┘

┌──────────────────────┐
│     kumi_dialogs     │   (master data, tidak terhubung FK)
├──────────────────────┤
│ id            PK     │
│ context              │
│ text                 │
│ is_active            │
│ created_at           │
└──────────────────────┘
```

### 2.2 Ringkasan relasi

| Relasi | Kardinalitas | Implementasi | Catatan |
|---|---|---|---|
| `users` — `tasks` | One-to-Many | `tasks.user_id` FK | Satu pengguna memiliki banyak tugas; tugas selalu milik satu pengguna |
| `users` — `achievements` | Many-to-Many | `user_achievements` (junction) | Satu pengguna dapat meraih banyak badge; satu badge dapat diraih banyak pengguna |
| `kumi_dialogs` — lainnya | Standalone | Tidak ada FK | Master data dialog, dipilih berdasarkan konteks |

---

## 3. Definisi Tabel

### 3.1 `users`

Menyimpan identitas pengguna yang berasal dari Google Sign-In.

| Nama Kolom | Tipe Data | Key | Constraints | Deskripsi |
|---|---|---|---|---|
| `id` | `BIGINT UNSIGNED` | PK | `AUTO_INCREMENT` | Identitas internal pengguna |
| `google_id` | `VARCHAR(64)` | UQ | `NOT NULL`, `UNIQUE` | Klaim `sub` dari ID Token Google; kunci identitas eksternal |
| `email` | `VARCHAR(255)` | UQ | `NOT NULL`, `UNIQUE` | Email dari Google; dipakai untuk identifikasi dan komunikasi |
| `name` | `VARCHAR(100)` | — | `NOT NULL` | Nama tampilan; dapat diubah pengguna, tidak ditimpa otomatis oleh Google |
| `picture_url` | `VARCHAR(512)` | — | `NULL` | URL foto profil Google |
| `current_streak` | `INT UNSIGNED` | — | `NOT NULL`, `DEFAULT 0` | Cache jumlah hari berturut-turut dengan minimal satu tugas selesai |
| `last_completed_date` | `DATE` | — | `NULL` | Tanggal (UTC) terakhir pengguna menyelesaikan tugas; dasar perhitungan streak |
| `created_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Waktu pendaftaran |
| `updated_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Waktu perubahan terakhir |

**Catatan desain:**

- `google_id` unik karena satu akun Google hanya boleh memetakan ke satu pengguna.
- `email` unik untuk mencegah duplikasi akun bila `sub` berubah (kasus langka).
- `name` sengaja tidak ditimpa saat login ulang agar hasil edit pengguna dihormati (lihat US-PROF-02).
- `current_streak` adalah denormalisasi terkontrol; sumber kebenaran tetap `tasks.completed_at`, dan nilai ini dapat dihitung ulang.

### 3.2 `tasks`

Menyimpan tugas milik pengguna, berbasis waktu.

| Nama Kolom | Tipe Data | Key | Constraints | Deskripsi |
|---|---|---|---|---|
| `id` | `BIGINT UNSIGNED` | PK | `AUTO_INCREMENT` | Identitas tugas |
| `user_id` | `BIGINT UNSIGNED` | FK | `NOT NULL`, `REFERENCES users(id)` `ON DELETE CASCADE` | Pemilik tugas |
| `title` | `VARCHAR(150)` | — | `NOT NULL` | Judul tugas; wajib, 1–150 karakter |
| `description` | `TEXT` | — | `NULL` | Deskripsi opsional, maksimum 1000 karakter (divalidasi aplikasi) |
| `due_time` | `DATETIME` | — | `NOT NULL` | Tenggat tugas (UTC); dasar pengurutan dan notifikasi |
| `is_completed` | `TINYINT(1)` | — | `NOT NULL`, `DEFAULT 0` | Status selesai (0/1) |
| `completed_at` | `DATETIME` | — | `NULL` | Waktu penyelesaian (UTC); `NULL` bila belum selesai. **Kolom dataset ML** |
| `created_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Waktu pembuatan |
| `updated_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | Waktu perubahan terakhir |

**Aturan integritas:**

- `is_completed = 1` jika dan hanya jika `completed_at IS NOT NULL` (dijaga di lapisan aplikasi; dapat ditambah `CHECK` pada MariaDB 10.2+).
- `ON DELETE CASCADE` pada `user_id` memastikan tidak ada tugas yatim bila pengguna dihapus.

**Catatan ML:** pasangan `due_time`, `created_at`, `completed_at`, dan `is_completed` memungkinkan perhitungan fitur seperti *lead time*, *on-time completion*, dan pola waktu penyelesaian tanpa migrasi skema di masa depan.

### 3.3 `kumi_dialogs`

Master data teks ucapan maskot, dipilih berdasarkan konteks.

| Nama Kolom | Tipe Data | Key | Constraints | Deskripsi |
|---|---|---|---|---|
| `id` | `BIGINT UNSIGNED` | PK | `AUTO_INCREMENT` | Identitas dialog |
| `context` | `ENUM('morning','afternoon','night','task_done','idle')` | IDX | `NOT NULL` | Kategori konteks; menentukan kapan dialog ditampilkan |
| `text` | `VARCHAR(255)` | — | `NOT NULL` | Teks ucapan Kumi |
| `is_active` | `TINYINT(1)` | — | `NOT NULL`, `DEFAULT 1` | Menonaktifkan dialog tanpa menghapus |
| `created_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Waktu pembuatan |

**Definisi konteks:**

| Konteks | Kapan dipakai |
|---|---|
| `morning` | 05.00–11.59 waktu lokal pengguna |
| `afternoon` | 12.00–17.59 |
| `night` | 18.00–04.59 |
| `task_done` | Dalam 60 detik setelah tugas ditandai selesai |
| `idle` | Tidak ada tugas hari ini, atau fallback umum |

**Catatan:** `ENUM` dipilih agar nilai konteks terkendali dan query cepat. Bila kategori baru dibutuhkan, diperlukan `ALTER TABLE` — dapat diterima karena perubahan master data jarang.

### 3.4 `achievements`

Master badge yang dapat diraih.

| Nama Kolom | Tipe Data | Key | Constraints | Deskripsi |
|---|---|---|---|---|
| `id` | `BIGINT UNSIGNED` | PK | `AUTO_INCREMENT` | Identitas badge |
| `code` | `VARCHAR(50)` | UQ | `NOT NULL`, `UNIQUE` | Kode stabil untuk referensi di kode aplikasi (mis. `streak_7`) |
| `name` | `VARCHAR(100)` | — | `NOT NULL` | Nama tampilan badge |
| `description` | `VARCHAR(255)` | — | `NOT NULL` | Kriteria yang dapat dibaca pengguna |
| `icon` | `VARCHAR(50)` | — | `NOT NULL` | Nama ikon aset (mis. `badge_streak`) |
| `criteria_type` | `ENUM('total_completed','streak')` | — | `NOT NULL` | Jenis ambang pencapaian |
| `criteria_value` | `INT UNSIGNED` | — | `NOT NULL` | Nilai ambang (mis. 7 untuk streak 7 hari) |
| `created_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Waktu pembuatan |

**Catatan:** `criteria_type` + `criteria_value` membuat penambahan badge baru cukup lewat data, tanpa perubahan kode evaluasi.

### 3.5 `user_achievements`

Riwayat badge yang diraih pengguna.

| Nama Kolom | Tipe Data | Key | Constraints | Deskripsi |
|---|---|---|---|---|
| `id` | `BIGINT UNSIGNED` | PK | `AUTO_INCREMENT` | Identitas riwayat |
| `user_id` | `BIGINT UNSIGNED` | FK | `NOT NULL`, `REFERENCES users(id)` `ON DELETE CASCADE` | Pengguna penerima |
| `achievement_id` | `BIGINT UNSIGNED` | FK | `NOT NULL`, `REFERENCES achievements(id)` `ON DELETE CASCADE` | Badge yang diraih |
| `earned_at` | `DATETIME` | — | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Waktu badge diberikan |

**Constraint:** `UNIQUE KEY uq_user_achievement (user_id, achievement_id)` mencegah badge ganda.

---

## 4. DDL MariaDB

```sql
CREATE DATABASE IF NOT EXISTS kumi
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE kumi;

CREATE TABLE users (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  google_id           VARCHAR(64)     NOT NULL,
  email               VARCHAR(255)    NOT NULL,
  name                VARCHAR(100)    NOT NULL,
  picture_url         VARCHAR(512)    NULL,
  current_streak      INT UNSIGNED    NOT NULL DEFAULT 0,
  last_completed_date DATE            NULL,
  created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_google_id (google_id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE tasks (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  title        VARCHAR(150)    NOT NULL,
  description  TEXT            NULL,
  due_time     DATETIME        NOT NULL,
  is_completed TINYINT(1)      NOT NULL DEFAULT 0,
  completed_at DATETIME        NULL,
  created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tasks_user_due (user_id, due_time),
  KEY idx_tasks_user_completed (user_id, is_completed),
  KEY idx_tasks_completed_at (completed_at),
  CONSTRAINT fk_tasks_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE kumi_dialogs (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  context    ENUM('morning','afternoon','night','task_done','idle') NOT NULL,
  text       VARCHAR(255)    NOT NULL,
  is_active  TINYINT(1)      NOT NULL DEFAULT 1,
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_dialogs_context_active (context, is_active)
) ENGINE=InnoDB;

CREATE TABLE achievements (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code           VARCHAR(50)     NOT NULL,
  name           VARCHAR(100)    NOT NULL,
  description    VARCHAR(255)    NOT NULL,
  icon           VARCHAR(50)     NOT NULL,
  criteria_type  ENUM('total_completed','streak') NOT NULL,
  criteria_value INT UNSIGNED    NOT NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_achievements_code (code)
) ENGINE=InnoDB;

CREATE TABLE user_achievements (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id        BIGINT UNSIGNED NOT NULL,
  achievement_id BIGINT UNSIGNED NOT NULL,
  earned_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_achievement (user_id, achievement_id),
  KEY idx_ua_achievement (achievement_id),
  CONSTRAINT fk_ua_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ua_achievement
    FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE
) ENGINE=InnoDB;
```

---

## 5. Rekomendasi Indeks

| Tabel | Indeks | Kolom | Alasan |
|---|---|---|---|
| `users` | `uq_users_google_id` | `google_id` | Lookup utama saat login (setiap autentikasi) |
| `users` | `uq_users_email` | `email` | Mencegah duplikasi; lookup alternatif |
| `tasks` | `idx_tasks_user_due` | `(user_id, due_time)` | Query utama: daftar tugas pengguna diurutkan berdasarkan tenggat |
| `tasks` | `idx_tasks_user_completed` | `(user_id, is_completed)` | Hitung tugas selesai/belum per pengguna |
| `tasks` | `idx_tasks_completed_at` | `(completed_at)` | Agregasi harian untuk streak dan dataset ML |
| `kumi_dialogs` | `idx_dialogs_context_active` | `(context, is_active)` | `WHERE context = ? AND is_active = 1` |
| `achievements` | `uq_achievements_code` | `code` | Lookup badge berdasarkan kode stabil |
| `user_achievements` | `uq_user_achievement` | `(user_id, achievement_id)` | Mencegah duplikasi; sekaligus indeks untuk daftar badge pengguna |
| `user_achievements` | `idx_ua_achievement` | `(achievement_id)` | Mendukung `ON DELETE CASCADE` dan statistik per badge |

**Prinsip:** indeks komposit mengikuti urutan selektivitas dan pola query (`user_id` selalu menjadi filter pertama karena semua query terisolasi per pengguna).

---

## 6. Query Referensi

```sql
-- Daftar tugas pengguna pada satu tanggal (UTC)
SELECT id, title, description, due_time, is_completed, completed_at
FROM tasks
WHERE user_id = ?
  AND due_time >= ? AND due_time < ?
ORDER BY due_time ASC;

-- Jumlah tugas selesai hari ini (dasar streak)
SELECT COUNT(*) AS completed_today
FROM tasks
WHERE user_id = ?
  AND completed_at >= ? AND completed_at < ?;

-- Total tugas selesai (dasar badge total_completed)
SELECT COUNT(*) FROM tasks WHERE user_id = ? AND is_completed = 1;

-- Dialog acak untuk konteks
SELECT id, context, text
FROM kumi_dialogs
WHERE context = ? AND is_active = 1
ORDER BY RAND()
LIMIT 1;

-- Rekap harian untuk dataset ML
SELECT DATE(completed_at) AS day,
       COUNT(*) AS completed,
       AVG(TIMESTAMPDIFF(MINUTE, created_at, completed_at)) AS avg_lead_minutes
FROM tasks
WHERE user_id = ? AND completed_at IS NOT NULL
GROUP BY DATE(completed_at)
ORDER BY day DESC;
```

Catatan: `ORDER BY RAND()` memadai untuk tabel dialog berukuran kecil (puluhan baris). Bila tabel tumbuh besar, gunakan pemilihan acak berbasis `id` acak atau cache di aplikasi.

---

## 7. Seed Data

### 7.1 Achievements

```sql
INSERT INTO achievements (code, name, description, icon, criteria_type, criteria_value) VALUES
('first_steps', 'Langkah Pertama', 'Selesaikan tugas pertamamu', 'badge_first', 'total_completed', 1),
('task_10',     'Produktif',       'Selesaikan 10 tugas',        'badge_ten',   'total_completed', 10),
('task_50',     'Sangat Produktif','Selesaikan 50 tugas',        'badge_fifty', 'total_completed', 50),
('streak_3',    'Tiga Hari',       'Streak 3 hari berturut-turut','badge_fire3', 'streak', 3),
('streak_7',    'Seminggu Konsisten','Streak 7 hari berturut-turut','badge_fire7','streak', 7),
('streak_30',   'Sebulan Penuh',   'Streak 30 hari berturut-turut','badge_fire30','streak', 30);
```

### 7.2 Dialogs

```sql
INSERT INTO kumi_dialogs (context, text) VALUES
('morning',   'Selamat pagi! Hari ini kita mulai pelan-pelan, ya.'),
('morning',   'Pagi yang cerah! Mau lihat tugas pertama hari ini?'),
('morning',   'Aku sudah bangun lebih dulu. Kamu juga sudah siap?'),
('afternoon', 'Sudah makan siang? Setelah itu kita cek satu tugas, yuk.'),
('afternoon', 'Setengah hari sudah lewat. Satu langkah kecil masih berarti.'),
('night',     'Malam sudah datang. Bagaimana harimu?'),
('night',     'Waktunya istirahat. Besok kita coba lagi, ya.'),
('night',     'Terima kasih sudah berusaha hari ini.'),
('task_done', 'Yeay! Satu tugas selesai. Aku bangga sama kamu!'),
('task_done', 'Keren! Terus begini, nanti kita lihat streak-nya tumbuh.'),
('task_done', 'Selesai! Sedikit lagi menuju hari yang produktif.'),
('idle',      'Belum ada tugas hari ini. Mau tambah satu?'),
('idle',      'Aku menunggu di sini. Kalau butuh bantuan, ketuk saja aku.');
```

---

## 8. Migrasi & Versi Skema

Untuk MVP, tabel dibuat melalui skrip inisialisasi saat container pertama kali dijalankan (`docker-entrypoint-initdb.d`) atau melalui `Base.metadata.create_all()` pada startup aplikasi. Rekomendasi jangka panjang:

1. Tambahkan Alembic setelah skema stabil.
2. Setiap perubahan destruktif wajib disertai backup dan catatan rollback.
3. Perubahan aditif (kolom nullable, indeks baru) aman dilakukan tanpa downtime.

**Catatan untuk dataset ML (masa depan):** tabel `tasks` sudah memuat sinyal yang cukup untuk melatih model prioritas atau prediksi penyelesaian. Bila volume data bertambah, pertimbangkan tabel turunan `task_events` (append-only) untuk mencatat setiap perubahan status tanpa mengubah data operasional.
