# Kumi — BRD & PRD

**Versi:** 1.0
**Tanggal:** 19 Oktober 2026
**Status:** Final untuk MVP mata kuliah Pemrograman Mobile
**Pemilik Produk:** Tim Kumi

---

# Bagian I — Business Requirements Document (BRD)

## 1. Executive Summary

Kumi adalah aplikasi *daily assistant* berbasis mobile yang membantu mahasiswa dan pekerja muda mengelola jadwal harian melalui pendekatan yang playful dan gamified. Berbeda dari aplikasi to-do list konvensional yang terasa seperti daftar kewajiban, Kumi menghadirkan maskot rubah interaktif bernama Kumi yang menemani pengguna, memberi dialog kontekstual, dan merayakan setiap tugas yang selesai.

Produk ini dibangun sebagai proyek mata kuliah Pemrograman Mobile dengan arsitektur client-server: aplikasi Flutter sebagai klien, REST API FastAPI sebagai layanan backend, MariaDB sebagai basis data, dan deployment pada VPS publik di balik Nginx dengan HTTPS.

MVP berfokus pada enam kemampuan inti: autentikasi Google, manajemen tugas berbasis waktu, profil pengguna, notifikasi lokal, gamifikasi streak dan milestone, serta micro-interaction maskot yang mengambil dialog dari backend. Fitur yang berpotensi menambah kompleksitas tanpa nilai proporsional untuk MVP — login manual, chatbot NLP, dan model Machine Learning aktif — secara sadar dikeluarkan dari lingkup, sementara skema data disiapkan agar fitur cerdas dapat ditambahkan di masa depan tanpa migrasi besar.

## 2. Problem Statement

Mahasiswa dan pekerja muda menghadapi tiga masalah utama dalam mengelola aktivitas harian:

1. **Beban kognitif tinggi.** Jadwal kuliah, tugas, organisasi, dan pekerjaan tersebar di banyak tempat (chat, catatan, kalender). Pengguna harus mengingat dan menyusun ulang prioritas setiap hari.
2. **Aplikasi terasa seperti kewajiban.** To-do list konvensional menampilkan daftar kosong yang menuntut disiplin tinggi. Tidak ada rasa ditemani, tidak ada apresiasi, dan tidak ada alasan emosional untuk kembali membuka aplikasi.
3. **Umpan balik tidak terasa.** Mencentang tugas sering kali berakhir tanpa konsekuensi positif yang terlihat. Pengguna kehilangan motivasi setelah beberapa hari, sehingga aplikasi ditinggalkan.

Akibatnya, alat produktivitas yang seharusnya membantu justru menambah rasa bersalah ketika daftar tugas tidak terselesaikan. Kebutuhan yang belum terpenuhi bukan sekadar "mencatat tugas", melainkan **menemani pengguna menyelesaikan tugas secara konsisten**.

## 3. Value Proposition

| Dimensi | Aplikasi to-do konvensional | Kumi |
|---|---|---|
| Interaksi | Daftar statis | Maskot rubah yang merespons sentuhan |
| Umpan balik | Centang tanpa apresiasi | Dialog kontekstual, animasi perayaan, streak |
| Motivasi | Bergantung pada disiplin pengguna | Gamifikasi ringan: streak dan milestone badge |
| Nada produk | Netral, korporat | Playful, hangat, personal |
| Retensi | Rendah setelah minggu pertama | Alasan emosional untuk kembali setiap hari |

**Pernyataan nilai:** *Kumi membuat pengelolaan jadwal harian terasa seperti ditemani teman kecil yang merayakan kemajuanmu, bukan seperti daftar kewajiban yang menuntut.*

Tiga pilar nilai:

- **Companion, bukan checklist.** Maskot hadir di layar utama dan memberi respons relevan terhadap waktu dan aktivitas pengguna.
- **Progress yang terlihat.** Progress bar harian, streak, dan badge memberi bukti kemajuan yang konkret.
- **Gesekan rendah.** Login satu ketukan lewat Google, tambah tugas dalam satu modal, notifikasi otomatis di perangkat.

## 4. Target Audience

### 4.1 Segmen utama

**Mahasiswa aktif (18–24 tahun).**
Karakteristik: jadwal kuliah tidak teratur, banyak tugas dengan tenggat berbeda, aktif menggunakan Google Workspace, sensitif terhadap aplikasi yang terasa "berat".
Kebutuhan: melihat jadwal hari ini dengan cepat, diingatkan sebelum tenggat, merasa termotivasi menyelesaikan tugas.

**Pekerja muda / *early career* (22–30 tahun).**
Karakteristik: kombinasi pekerjaan, side project, dan kegiatan pribadi; mobilitas tinggi; menghargai antarmuka yang ringan dan estetis.
Kebutuhan: memisahkan dan memprioritaskan tugas harian, menjaga konsistensi kebiasaan, umpan balik yang menyenangkan.

### 4.2 Segmen sekunder

- **Mahasiswa yang sedang menyusun skripsi/tugas akhir** — membutuhkan pemecahan tugas besar menjadi item harian.
- **Pengguna yang pernah gagal mempertahankan kebiasaan dengan to-do list biasa** — mencari pendekatan yang lebih suportif.

### 4.3 Persona ringkas

**Persona 1 — Rani, 20, mahasiswa semester 4.**
Membuka aplikasi di sela kuliah. Ingin tahu "apa yang harus dikerjakan hari ini" dalam 5 detik. Menyukai ilustrasi lucu. Akan berhenti memakai aplikasi jika harus mengetik banyak atau melihat layar kosong.

**Persona 2 — Dimas, 25, junior analyst.**
Memakai aplikasi pagi dan malam. Ingin menutup hari dengan melihat progres. Menghargai streak sebagai pengingat konsistensi. Tidak ingin aplikasi mengirim notifikasi berlebihan.

## 5. Business Objectives & Success Metrics

| Tujuan | Metrik | Target MVP |
|---|---|---|
| Akuisisi pengguna awal | Pengguna terdaftar melalui Google Sign-In | ≥ 20 akun pada demo kelas |
| Aktivasi | Pengguna yang membuat ≥ 1 tugas dalam 24 jam pertama | ≥ 70% |
| Retensi awal | Pengguna yang kembali pada hari ke-2 | ≥ 40% |
| Keterlibatan inti | Rata-rata tugas diselesaikan per pengguna per minggu | ≥ 5 |
| Keterlibatan maskot | Rasio sesi dengan ≥ 1 tap maskot | ≥ 50% |
| Keandalan | Uptime API selama periode demo | ≥ 99% |
| Performa | Waktu respons API p95 | < 500 ms |

Metrik diukur secara manual dari basis data selama MVP (tidak ada layanan analitik pihak ketiga).

## 6. Business Constraints

- **Waktu:** satu semester, dengan tenggat demo akhir.
- **Sumber daya:** tim kecil; pengembangan dan operasi dilakukan sendiri.
- **Anggaran:** VPS dan domain berskala minimal; tidak ada layanan berbayar tambahan.
- **Kepatuhan:** hanya data yang diperlukan (nama, email, foto profil Google) yang disimpan; tidak ada penyimpanan kata sandi.

## 7. Risks & Mitigation

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Konfigurasi OAuth Google salah (SHA-1, client ID) | Login gagal saat demo | Uji login di perangkat fisik sejak awal; siapkan akun uji |
| VPS/docker down saat demo | Aplikasi tidak dapat dipakai | Siapkan rekaman demo dan lingkungan lokal sebagai cadangan |
| Notifikasi tidak muncul di perangkat tertentu | Fitur tampak rusak | Uji pada Android 13+ (izin notifikasi) dan iOS; sediakan penjelasan izin |
| Cakupan melebar (chatbot, ML) | Proyek tidak selesai | Matriks out-of-scope ditegakkan; perubahan lingkup harus disetujui |
| Data pengguna bocor | Risiko keamanan dan nilai | Secret di `.env`, HTTPS, JWT berumur pendek, validasi token Google |

## 8. Scope Summary

**In-Scope (MVP):** Google Sign-In, CRUD tugas berbasis waktu, profil (data Google, edit nama), notifikasi lokal, gamifikasi (streak & milestone), micro-interaction maskot dengan dialog dari backend, deployment VPS.

**Out-of-Scope (MVP):** login manual (email/kata sandi), chatbot NLP dinamis, model Machine Learning aktif. Skema data tetap disiapkan untuk kebutuhan ML di masa depan.

---

# Bagian II — Product Requirements Document (PRD)

## 9. Product Overview

Kumi adalah aplikasi Flutter yang berkomunikasi dengan REST API FastAPI. Pengguna masuk dengan akun Google, mengelola tugas harian, menerima notifikasi lokal, dan berinteraksi dengan maskot Kumi. Backend menyimpan data pada MariaDB dan mengembalikan dialog kontekstual berdasarkan waktu dan status tugas.

**Prinsip produk:**

1. **Satu layar, satu tujuan.** Setiap layar utama menjawab satu pertanyaan pengguna.
2. **Maskot tidak mengganggu.** Kumi muncul sebagai pendamping, bukan penghalang alur kerja.
3. **Umpan balik instan.** Setiap aksi memberi respons visual dalam < 300 ms (optimistic UI bila perlu).
4. **Ramah jaringan buruk.** Kesalahan jaringan ditampilkan sebagai pesan yang dapat dicoba ulang.

## 10. Technical Constraints

| Aspek | Ketentuan |
|---|---|
| Arsitektur | Client-server |
| Frontend | Flutter (Dart) |
| Backend | FastAPI (Python), Docker & Docker Compose |
| Basis data | MariaDB |
| Autentikasi | Google Sign-In (OAuth2 / ID Token), ditukar dengan JWT lokal |
| Infrastruktur | VPS publik, Nginx reverse proxy, HTTPS Let's Encrypt |
| Notifikasi | Lokal, dijadwalkan oleh perangkat |
| Format API | REST, JSON, prefix `/api/v1` |

## 11. User Stories & Acceptance Criteria

Format acceptance criteria memakai **Given / When / Then**.

### 11.1 Autentikasi Google

**US-AUTH-01 — Masuk dengan akun Google**
*Sebagai pengguna baru, saya ingin masuk menggunakan akun Google saya agar tidak perlu membuat akun dan kata sandi baru.*

- **Given** pengguna membuka aplikasi untuk pertama kali
  **When** pengguna menekan tombol "Lanjutkan dengan Google" dan memilih akun
  **Then** aplikasi mengirim ID Token ke `POST /api/v1/auth/google`, menerima JWT, menyimpannya secara lokal, dan menampilkan Home.
- **Given** pengguna baru berhasil diautentikasi
  **When** backend belum memiliki data pengguna tersebut
  **Then** backend membuat baris `users` baru dengan `google_id`, `email`, `name`, dan `picture_url` dari token.
- **Given** pengguna sudah pernah masuk
  **When** pengguna membuka aplikasi kembali dan JWT masih valid
  **Then** aplikasi langsung menampilkan Home tanpa meminta login ulang.
- **Given** ID Token tidak valid atau kedaluwarsa
  **When** dikirim ke backend
  **Then** backend mengembalikan `401` dan aplikasi menampilkan pesan "Gagal masuk. Coba lagi." tanpa crash.
- **Given** pengguna menekan "Keluar"
  **When** konfirmasi diterima
  **Then** JWT dan data sesi dihapus dari perangkat dan aplikasi kembali ke layar Login.

**US-AUTH-02 — Sesi kedaluwarsa**
*Sebagai pengguna, saya ingin diberi tahu ketika sesi berakhir agar dapat masuk kembali.*

- **Given** JWT sudah kedaluwarsa
  **When** aplikasi memanggil endpoint terproteksi
  **Then** backend mengembalikan `401`; aplikasi menghapus sesi dan mengarahkan ke Login dengan pesan "Sesi berakhir, silakan masuk kembali."

### 11.2 Manajemen Tugas

**US-TASK-01 — Melihat tugas**
*Sebagai pengguna, saya ingin melihat daftar tugas saya agar tahu apa yang harus dikerjakan.*

- **Given** pengguna sudah masuk
  **When** membuka tab Tugas
  **Then** aplikasi menampilkan tugas milik pengguna, dikelompokkan berdasarkan tanggal, dengan status selesai/belum.
- **Given** pengguna memilih tanggal tertentu pada filter
  **When** daftar dimuat
  **Then** hanya tugas dengan `due_time` pada tanggal tersebut yang ditampilkan.
- **Given** pengguna belum punya tugas
  **When** layar dibuka
  **Then** tampil empty state dengan ilustrasi dan tombol "Tambah tugas".

**US-TASK-02 — Menambah tugas**
*Sebagai pengguna, saya ingin menambah tugas beserta tenggat agar dapat merencanakan hari.*

- **Given** pengguna menekan tombol tambah
  **When** mengisi judul (wajib, 1–150 karakter), deskripsi (opsional, ≤ 1000 karakter), dan `due_time`
  **Then** `POST /api/v1/tasks` dipanggil dan tugas baru muncul di daftar tanpa perlu memuat ulang manual.
- **Given** judul kosong
  **When** pengguna menekan Simpan
  **Then** form menampilkan validasi dan tidak mengirim request.
- **Given** `due_time` berada di masa lalu
  **When** pengguna menekan Simpan
  **Then** form menampilkan peringatan; pengguna dapat memperbaiki atau membatalkan.

**US-TASK-03 — Mengubah tugas**
*Sebagai pengguna, saya ingin mengubah detail tugas agar tetap relevan ketika rencana berubah.*

- **Given** pengguna membuka tugas miliknya
  **When** mengubah judul, deskripsi, atau `due_time` lalu menyimpan
  **Then** `PUT /api/v1/tasks/{id}` dipanggil dan daftar menampilkan data terbaru.
- **Given** pengguna mencoba mengubah tugas milik pengguna lain
  **When** request dikirim
  **Then** backend mengembalikan `404` (tidak membocorkan keberadaan data).

**US-TASK-04 — Menghapus tugas**
*Sebagai pengguna, saya ingin menghapus tugas yang tidak lagi relevan.*

- **Given** pengguna membuka menu tugas
  **When** memilih Hapus dan mengonfirmasi
  **Then** `DELETE /api/v1/tasks/{id}` dipanggil, item hilang dari daftar, dan notifikasi terjadwal untuk tugas itu dibatalkan.

**US-TASK-05 — Menandai tugas selesai**
*Sebagai pengguna, saya ingin menandai tugas selesai dengan satu ketukan agar merasakan kemajuan.*

- **Given** tugas belum selesai
  **When** pengguna menekan lingkaran centang
  **Then** `PATCH /api/v1/tasks/{id}/complete` dipanggil, `is_completed` menjadi `true`, `completed_at` terisi, dan maskot menampilkan animasi perayaan beserta dialog "tugas selesai".
- **Given** tugas sudah selesai
  **When** pengguna menekan centang lagi
  **Then** status kembali belum selesai, `completed_at` dikosongkan, dan streak tidak bertambah dua kali untuk tugas yang sama.
- **Given** tugas diselesaikan melewati `due_time`
  **When** status diubah
  **Then** tugas tetap dihitung selesai, tetapi tidak dihitung sebagai "tepat waktu" pada statistik.

### 11.3 Profil

**US-PROF-01 — Melihat profil**
*Sebagai pengguna, saya ingin melihat profil dan statistik saya.*

- **Given** pengguna sudah masuk
  **When** membuka tab Profil
  **Then** tampil foto profil Google, nama, email, streak saat ini, total tugas selesai, dan kisi badge.

**US-PROF-02 — Mengubah nama**
*Sebagai pengguna, saya ingin mengubah nama tampilan agar sesuai preferensi.*

- **Given** pengguna membuka edit profil
  **When** mengubah nama (1–100 karakter) dan menyimpan
  **Then** `PUT /api/v1/user/profile` dipanggil, nama pada Home dan Profil diperbarui.
- **Given** nama kosong atau hanya spasi
  **When** disimpan
  **Then** validasi menolak dan tidak ada request dikirim.
- **Given** pengguna mengubah nama
  **When** masuk kembali dengan Google
  **Then** nama hasil editan tetap dipertahankan (tidak ditimpa otomatis oleh data Google).

**US-PROF-03 — Melihat achievement**
*Sebagai pengguna, saya ingin melihat badge yang telah saya raih agar termotivasi.*

- **Given** pengguna membuka Profil
  **When** data achievement dimuat
  **Then** badge yang diraih tampil berwarna dan yang belum tampil redup dengan kriteria yang terlihat.

### 11.4 Notifikasi Lokal

**US-NOTIF-01 — Pengingat tenggat**
*Sebagai pengguna, saya ingin diingatkan sebelum tenggat agar tidak melewatkan tugas.*

- **Given** pengguna membuat tugas dengan `due_time` di masa depan
  **When** tugas tersimpan
  **Then** perangkat menjadwalkan notifikasi lokal 15 menit sebelum `due_time` (dapat dikonfigurasi 0/15/30 menit).
- **Given** pengguna menyelesaikan atau menghapus tugas
  **When** aksi berhasil
  **Then** notifikasi terjadwal untuk tugas tersebut dibatalkan.
- **Given** izin notifikasi belum diberikan (Android 13+/iOS)
  **When** pengguna pertama kali membuat tugas
  **Then** aplikasi meminta izin; jika ditolak, aplikasi tetap berfungsi dan menampilkan info bahwa pengingat nonaktif.
- **Given** `due_time` sudah lewat
  **When** tugas dibuat
  **Then** tidak ada notifikasi terjadwal yang dibuat.

### 11.5 Gamifikasi

**US-GAME-01 — Streak harian**
*Sebagai pengguna, saya ingin melihat streak hari berturut-turut agar termotivasi konsisten.*

- **Given** pengguna menyelesaikan minimal satu tugas pada hari ini
  **When** data profil dimuat
  **Then** streak hari ini dihitung dan ditampilkan.
- **Given** pengguna menyelesaikan minimal satu tugas kemarin dan hari ini
  **When** profil dimuat
  **Then** streak bertambah satu.
- **Given** pengguna tidak menyelesaikan tugas pada satu hari penuh
  **When** hari berikutnya dimulai
  **Then** streak kembali ke 0 (atau 1 jika hari ini sudah ada tugas selesai).
- **Given** beberapa tugas diselesaikan pada hari yang sama
  **When** streak dihitung
  **Then** hari tersebut hanya dihitung satu kali.

**US-GAME-02 — Milestone badge**
*Sebagai pengguna, saya ingin mendapatkan badge saat mencapai pencapaian agar ada rasa bangga.*

- **Given** pengguna mencapai total 10 tugas selesai
  **When** tugas ke-10 ditandai selesai
  **Then** badge "Langkah Pertama" (first_steps) diberikan, tersimpan di `user_achievements`, dan muncul notifikasi/dialog perayaan.
- **Given** badge yang sama sudah dimiliki
  **When** kondisi terpenuhi kembali
  **Then** tidak ada duplikasi (`UNIQUE(user_id, achievement_id)`).
- **Given** pengguna mencapai streak 7 hari berturut-turut
  **When** profil dimuat
  **Then** badge "Seminggu Konsisten" (streak_7) diberikan.

**Daftar milestone MVP:**

| Kode | Nama | Kriteria |
|---|---|---|
| `first_steps` | Langkah Pertama | Total 1 tugas selesai |
| `task_10` | Produktif | Total 10 tugas selesai |
| `task_50` | Sangat Produktif | Total 50 tugas selesai |
| `streak_3` | Tiga Hari | Streak 3 hari |
| `streak_7` | Seminggu Konsisten | Streak 7 hari |
| `streak_30` | Sebulan Penuh | Streak 30 hari |

### 11.6 Micro-interaction Maskot

**US-KUMI-01 — Tap maskot**
*Sebagai pengguna, saya ingin mengetuk maskot dan mendapat ucapan agar aplikasi terasa hidup.*

- **Given** pengguna berada di Home
  **When** mengetuk maskot
  **Then** aplikasi memanggil `GET /api/v1/kumi/dialog?context=<konteks>` dan menampilkan teks pada speech bubble dengan animasi muncul.
- **Given** waktu perangkat pukul 05.00–11.59
  **When** konteks tidak ditentukan
  **Then** aplikasi meminta konteks `morning`.
- **Given** waktu 12.00–17.59 / 18.00–04.59
  **When** konteks tidak ditentukan
  **Then** aplikasi meminta konteks `afternoon` / `night`.
- **Given** pengguna baru saja menyelesaikan tugas
  **When** mengetuk maskot dalam 60 detik setelahnya
  **Then** aplikasi meminta konteks `task_done`.
- **Given** backend tidak dapat dihubungi
  **When** maskot diketuk
  **Then** aplikasi menampilkan satu dialog cadangan lokal (offline fallback) dan tidak menampilkan error.
- **Given** pengguna mengetuk berulang kali
  **When** bubble masih tampil
  **Then** teks berganti tanpa menumpuk bubble baru.

**US-KUMI-02 — Animasi penyelesaian tugas**
*Sebagai pengguna, saya ingin melihat reaksi maskot saat tugas selesai agar terasa diapresiasi.*

- **Given** pengguna menandai tugas selesai
  **When** respons sukses diterima
  **Then** maskot memutar animasi perayaan (lompat kecil + scale + sparkle) selama ≤ 1,5 detik, lalu menampilkan dialog konteks `task_done`.
- **Given** pengguna menonaktifkan animasi sistem (reduce motion)
  **When** tugas selesai
  **Then** animasi diganti transisi fade singkat tanpa gerakan berlebihan.

### 11.7 Deployment

**US-DEPLOY-01 — Akses publik**
*Sebagai pengguna, saya ingin mengakses aplikasi dari perangkat saya melalui internet.*

- **Given** VPS aktif dan domain mengarah ke VPS
  **When** pengguna membuka `https://api.<domain>` 
  **Then** Nginx meneruskan permintaan ke container FastAPI dan `GET /health` mengembalikan `{"status":"ok"}` dengan HTTPS valid.
- **Given** server dijalankan ulang
  **When** `docker compose up -d` dieksekusi
  **Then** API dan MariaDB kembali aktif tanpa kehilangan data (volume persisten).
- **Given** permintaan berasal dari aplikasi Flutter
  **When** origin diizinkan pada konfigurasi CORS
  **Then** preflight `OPTIONS` berhasil dan respons memuat header CORS yang sesuai.

## 12. Out-of-Scope Matrix

| Fitur | Status MVP | Alasan | Rencana Lanjutan |
|---|---|---|---|
| Login manual (email + kata sandi) | **Out** | Menambah permukaan keamanan (hash, reset, verifikasi) tanpa nilai untuk MVP | Ditinjau ulang setelah MVP stabil |
| Chatbot NLP dinamis | **Out** | Memerlukan layanan LLM, biaya, evaluasi kualitas, dan penanganan penyalahgunaan | Dialog berbasis aturan menjadi fondasi |
| Model Machine Learning aktif (prediksi prioritas, rekomendasi jadwal) | **Out** | Data historis belum cukup; evaluasi model di luar cakupan semester | Skema `tasks.completed_at` dan `due_time` disiapkan sebagai dataset |
| Sinkronisasi multi-perangkat real-time | Out | Kompleksitas WebSocket/conflict resolution | REST cukup untuk MVP |
| Kolaborasi/pembagian tugas antar pengguna | Out | Di luar persona utama | — |
| Integrasi Google Calendar | Out | Menambah dependensi OAuth scope dan sinkronisasi dua arah | Kandidat v1.1 |
| Pembayaran/langganan | Out | Tidak relevan untuk proyek akademik | — |
| Widget home screen | Out | Memerlukan native code per platform | Kandidat v1.1 |
| Dark mode | Out | Nice-to-have; tema tunggal lebih cepat divalidasi | Kandidat v1.1 |
| Analitik pihak ketiga | Out | Privasi dan biaya | Metrik dihitung dari basis data |

## 13. Non-Functional Requirements

| Kategori | Persyaratan |
|---|---|
| Performa | Respons API p95 < 500 ms untuk operasi CRUD pada dataset demo |
| Ketersediaan | API aktif selama periode penilaian; health check tersedia |
| Keamanan | Semua endpoint selain auth memerlukan JWT; verifikasi ID Token ke Google; secret hanya di `.env`; HTTPS wajib |
| Privasi | Hanya menyimpan nama, email, foto profil, dan data tugas; tidak ada kata sandi |
| Usability | Alur tambah tugas ≤ 3 interaksi dari Home; teks minimum 14 sp; target sentuh ≥ 48 dp |
| Aksesibilitas | Label semantik pada tombol ikon; kontras teks memenuhi WCAG AA; dukungan reduce motion |
| Kompatibilitas | Android 8+ dan iOS 13+; Flutter stable terbaru |
| Observabilitas | Log terstruktur pada FastAPI; `GET /health` melaporkan status API dan basis data |
| Lokalisasi | Bahasa Indonesia untuk seluruh teks antarmuka pada MVP |

## 14. Data & Analytics (MVP)

Metrik dihitung langsung dari MariaDB melalui query manual:

- Jumlah pengguna terdaftar: `SELECT COUNT(*) FROM users;`
- Tugas dibuat per hari: `SELECT DATE(created_at), COUNT(*) FROM tasks GROUP BY 1;`
- Completion rate: `SUM(is_completed) / COUNT(*)`.
- Streak: diturunkan dari `tasks.completed_at`.

Tidak ada SDK analitik eksternal pada MVP.

## 15. Release Criteria (Definition of Done)

1. Seluruh user story In-Scope memiliki acceptance criteria yang terpenuhi dan telah diuji manual.
2. Login Google berhasil pada perangkat fisik Android (dan iOS bila tersedia).
3. CRUD tugas berfungsi end-to-end terhadap API produksi.
4. Notifikasi lokal muncul pada perangkat uji.
5. Streak dan minimal dua badge dapat dibuktikan.
6. Tap maskot menampilkan dialog dari backend; fallback offline bekerja.
7. Aplikasi terpasang dapat mengakses API publik melalui HTTPS.
8. Unit test backend (`pytest`) lulus.
9. README memuat langkah menjalankan aplikasi dan API dari nol.

## 16. Glossary

| Istilah | Definisi |
|---|---|
| ID Token | Token JWT yang diterbitkan Google, berisi identitas pengguna, diverifikasi oleh backend |
| JWT lokal | Token yang diterbitkan backend Kumi setelah verifikasi Google, dipakai untuk otorisasi API |
| Streak | Jumlah hari berturut-turut dengan minimal satu tugas selesai |
| Milestone | Ambang pencapaian yang memicu pemberian badge |
| Konteks dialog | Kategori waktu/kejadian yang menentukan teks ucapan Kumi |
| Maskot | Karakter rubah "Kumi" yang tampil pada antarmuka |
