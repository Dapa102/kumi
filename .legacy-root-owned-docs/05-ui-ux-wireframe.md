# Kumi — UI/UX Wireframe & Screen Flow

**Versi:** 1.0
**Platform:** Flutter (Android & iOS)
**Bahasa antarmuka:** Indonesia

---

## 1. Prinsip Desain

1. **Hangat, bukan kekanak-kanakan.** Playful lewat maskot dan gerak, bukan lewat warna yang berlebihan.
2. **Satu fokus per layar.** Home menjawab "apa hari ini", Tugas menjawab "apa saja", Profil menjawab "bagaimana kemajuanku".
3. **Kumi hadir, tidak menghalangi.** Maskot menempati area tetap di Home; tidak muncul sebagai pop-up di tengah alur.
4. **Umpan balik instan.** Setiap aksi terlihat hasilnya < 300 ms; operasi jaringan memakai optimistic update bila aman.
5. **Aksesibel sejak awal.** Target sentuh ≥ 48 dp, kontras WCAG AA, dukungan reduce motion.

---

## 2. Design Tokens

### 2.1 Warna

| Token | Hex | Penggunaan |
|---|---|---|
| `kumiPrimary` | `#E07A3F` | Aksi utama, aksen rubah (oranye hangat) |
| `kumiPrimaryDark` | `#B85E2A` | Tekanan/pressed state |
| `kumiSecondary` | `#2F4858` | Teks utama, header |
| `kumiSurface` | `#FFF8F2` | Latar utama (krem hangat) |
| `kumiSurfaceAlt` | `#FFFFFF` | Kartu |
| `kumiAccent` | `#5FA88A` | Status selesai, progress |
| `kumiWarning` | `#D9A441` | Tenggat dekat (< 2 jam) |
| `kumiDanger` | `#C7524A` | Hapus, terlambat |
| `kumiMuted` | `#8A8F94` | Teks sekunder, badge belum diraih |

### 2.2 Tipografi

| Peran | Ukuran | Berat | Catatan |
|---|---|---|---|
| Display (angka streak) | 40 sp | Bold | Line height 1.1 |
| H1 (judul layar) | 24 sp | Bold | — |
| H2 (judul kartu) | 18 sp | SemiBold | — |
| Body | 14 sp | Regular | Minimum 14 sp untuk teks utama |
| Caption | 12 sp | Regular | Hanya untuk metadata, kontras tetap AA |
| Speech bubble | 15 sp | Medium | Maksimum 3 baris |

### 2.3 Spasi & radius

- Skala spasi: 4 / 8 / 12 / 16 / 24 / 32.
- Padding layar: 20 horizontal.
- Radius kartu: 16; radius tombol: 14; radius chip: 999.

### 2.4 Motion

| Nama | Durasi | Kurva |
|---|---|---|
| Fast | 150 ms | `easeOut` |
| Base | 250 ms | `easeInOut` |
| Celebratory | 900–1500 ms | `easeOutBack` (maskot) |
| Bubble appear | 200 ms | `easeOut` |

---

## 3. Screen Flow

```
┌─────────────┐
│   Splash    │  (1,2 s: cek token)
└──────┬──────┘
       │
       ├── token valid ──────────────────────────────┐
       │                                             │
       ▼                                             │
┌─────────────┐    tap Google    ┌──────────────┐    │
│    Login    │ ───────────────> │  Home        │ <──┘
└─────────────┘                  └──────┬───────┘
                                        │
                     ┌──────────────────┼──────────────────┐
                     │                  │                  │
                     ▼                  ▼                  ▼
              ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
              │   Tasks     │    │   Profile   │    │  Task Form  │
              └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
                     │                  │                  │
                     │                  ▼                  │
                     │           ┌─────────────┐           │
                     │           │ Achievements│           │
                     │           └─────────────┘           │
                     │                                     │
                     └──────────> [modal] <────────────────┘
                                   simpan/hapus
```

Navigasi utama memakai `BottomNavigationBar` dengan tiga tab: **Home**, **Tugas**, **Profil**. Form tugas dibuka sebagai `ModalBottomSheet` (bukan halaman penuh) agar konteks daftar tetap terlihat.

---

## 4. Splash Screen

### 4.1 Tujuan

Menentukan tujuan awal: Home (token valid) atau Login.

### 4.2 Tata letak

```
┌───────────────────────────────┐
│                               │
│                               │
│           ╭─────╮             │
│           │ 🦊  │             │  ← logo/maskot 120 dp
│           ╰─────╯             │
│                               │
│            KUMI               │  ← 28 sp, bold
│   Teman kecil untuk harimu   │  ← 14 sp, muted
│                               │
│                               │
│         ● ● ●                 │  ← indikator 3 titik (subtle)
│                               │
└───────────────────────────────┘
```

### 4.3 Perilaku

| Kondisi | Aksi |
|---|---|
| Token ada dan valid | `Navigator.pushReplacement` ke Home |
| Token tidak ada/kedaluwarsa | `Navigator.pushReplacement` ke Login |
| Durasi minimum | 1,2 detik agar tidak berkedip |
| Gagal cek token | Ke Login, tanpa pesan error |

---

## 5. Login Screen

### 5.1 Tata letak

```
┌───────────────────────────────┐
│                               │
│         ╭─────────╮           │
│         │   🦊    │           │  ← ilustrasi 160 dp
│         ╰─────────╯           │
│                               │
│      Halo, aku Kumi!          │  ← 24 sp bold
│  Aku bantu kamu mengatur      │  ← 14 sp, 2 baris
│  hari jadi lebih ringan.      │
│                               │
│  ┌─────────────────────────┐  │
│  │  G  Lanjutkan dengan    │  │  ← tombol utama, tinggi 52
│  │     Google              │  │
│  └─────────────────────────┘  │
│                               │
│  Dengan masuk, kamu setuju    │  ← 12 sp muted
│  pada Ketentuan Layanan.      │
│                               │
└───────────────────────────────┘
```

### 5.2 Elemen & perilaku

| Elemen | Detail |
|---|---|
| Tombol Google | Latar putih, border `kumiSecondary` 1 dp, ikon "G" resmi, teks 16 sp |
| State loading | Tombol menampilkan spinner dan dinonaktifkan selama proses |
| State error | SnackBar di bawah: "Gagal masuk. Coba lagi." |
| Tanpa login manual | Tidak ada field email/kata sandi (out-of-scope) |

### 5.3 Alur teknis

1. Tap tombol → `GoogleSignIn().signIn()`.
2. Ambil `idToken`; bila `null` → tampilkan error.
3. `POST /api/v1/auth/google`.
4. Simpan JWT di secure storage.
5. Bila `is_new_user` → tampilkan dialog sambutan singkat sekali.
6. Navigasi ke Home.

---

## 6. Home / Dashboard

### 6.1 Tujuan

Menjawab "apa yang perlu aku lakukan hari ini" dan memberi kehangatan lewat maskot.

### 6.2 Tata letak

```
┌───────────────────────────────┐
│  Hai, Rani          [🔔] [👤] │  ← greeting + ikon
│  Senin, 19 Oktober            │  ← 12 sp muted
│                               │
│  ┌─────────────────────────┐  │
│  │        ╭───────╮        │  │
│  │        │  🦊   │        │  │  ← maskot 140 dp, area tap
│  │        ╰───────╯        │  │
│  │   ╭───────────────────╮ │  │
│  │   │ Selamat pagi! ... │ │  │  ← speech bubble
│  │   ╰───────────────────╯ │  │
│  └─────────────────────────┘  │
│                               │
│  Hari ini            2 / 5    │  ← label + angka
│  ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░    │  ← progress bar 8 dp
│                               │
│  Jadwal berikutnya            │
│  ┌─────────────────────────┐  │
│  │ ○ 09.00  Kuis Mobile    │  │
│  ├─────────────────────────┤  │
│  │ ○ 15.00  Revisi Bab 3   │  │
│  ├─────────────────────────┤  │
│  │ ✓ 08.40  Baca jurnal    │  │  ← selesai, teks coret
│  └─────────────────────────┘  │
│                               │
│  Lihat semua tugas →          │
│                               │
│ [ Home ] [ Tugas ] [ Profil ] │
└───────────────────────────────┘
```

### 6.3 Elemen

| Elemen | Detail |
|---|---|
| Greeting | "Hai, {nama}" + tanggal lokal |
| Maskot | Area tap ≥ 120×120 dp; `Semantics(label: "Kumi, ketuk untuk bicara")` |
| Speech bubble | Muncul setelah tap; teks dari API; maksimum 3 baris; hilang setelah 6 detik atau tap di luar |
| Progress | `completed_today / total_today`; bila total 0 → teks "Belum ada tugas hari ini" |
| Daftar jadwal | Maksimum 3 item terdekat; item selesai tetap tampil dengan gaya redup |
| Empty state | Ilustrasi kecil + tombol "Tambah tugas" |

### 6.4 Interaksi

| Aksi | Hasil |
|---|---|
| Tap maskot | Ambil dialog (konteks waktu / `task_done` bila baru selesai), tampilkan bubble |
| Tap item jadwal | Buka detail/edit tugas |
| Tap lingkaran centang | Tandai selesai + animasi perayaan |
| Tap "Lihat semua" | Pindah ke tab Tugas |
| Pull-to-refresh | Muat ulang profil + tugas hari ini |

### 6.5 State

| State | Tampilan |
|---|---|
| Loading awal | Skeleton pada kartu maskot dan daftar |
| Error jaringan | Kartu inline "Gagal memuat. Coba lagi." + tombol |
| Offline | Data cache terakhir (bila ada) + banner tipis "Mode offline" |

---

## 7. Task Management Screen

### 7.1 Tata letak daftar

```
┌───────────────────────────────┐
│  Tugas                        │
│  ┌─────────────────────────┐  │
│  │ ◀  19 Okt 2026  ▶      │  │  ← pemilih tanggal
│  └─────────────────────────┘  │
│  [ Semua ] [ Belum ] [ Selesai]│ ← filter chips
│                               │
│  BELUM SELESAI (3)            │
│  ┌─────────────────────────┐  │
│  │ ○  Revisi Bab 3         │  │
│  │    15.00 · 2 jam lagi   │  │  ← warna warning bila < 2 jam
│  │                    [⋮]  │  │
│  └─────────────────────────┘  │
│  ┌─────────────────────────┐  │
│  │ ○  Kuis Mobile          │  │
│  │    09.00 · Terlambat    │  │  ← danger
│  └─────────────────────────┘  │
│                               │
│  SELESAI (1)                  │
│  ┌─────────────────────────┐  │
│  │ ✓  Baca jurnal          │  │
│  │    08.40                │  │
│  └─────────────────────────┘  │
│                               │
│                        ( + )  │  ← FAB
│ [ Home ] [ Tugas ] [ Profil ] │
└───────────────────────────────┘
```

### 7.2 Elemen

| Elemen | Detail |
|---|---|
| Pemilih tanggal | Panah kiri/kanan + tap untuk date picker; default hari ini |
| Filter chips | Single-select: Semua / Belum / Selesai |
| Grup | Header "BELUM SELESAI (n)" dan "SELESAI (n)" |
| Kartu tugas | Judul 16 sp, meta 12 sp, indikator status warna |
| Menu `⋮` | Edit, Hapus |
| FAB | Tambah tugas, `kumiPrimary` |
| Swipe | Geser kanan → selesai; geser kiri → hapus (dengan konfirmasi) |

### 7.3 Form tambah/edit (modal)

```
┌───────────────────────────────┐
│  ───                          │  ← drag handle
│  Tugas baru                   │
│                               │
│  Judul *                      │
│  ┌─────────────────────────┐  │
│  │ Revisi Bab 3            │  │
│  └─────────────────────────┘  │
│                               │
│  Deskripsi                    │
│  ┌─────────────────────────┐  │
│  │                         │  │
│  │                         │  │  ← multiline, maks 1000
│  └─────────────────────────┘  │
│                               │
│  Tenggat *                    │
│  ┌─────────────────────────┐  │
│  │ 19 Okt 2026, 15.00   📅 │  │
│  └─────────────────────────┘  │
│                               │
│  Pengingat                    │
│  [ Tidak ] [ 15 mnt ] [ 30 mnt]│
│                               │
│  ┌─────────────────────────┐  │
│  │         Simpan          │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
```

### 7.4 Aturan validasi & perilaku

| Kasus | Perilaku |
|---|---|
| Judul kosong | Border error + "Judul wajib diisi"; tombol Simpan tetap aktif tetapi memblokir submit |
| Judul > 150 karakter | Counter merah, submit diblokir |
| Tenggat di masa lalu | Peringatan kuning "Tenggat sudah lewat" + konfirmasi |
| Simpan sukses | Tutup modal, item muncul di posisi terurut, jadwalkan notifikasi |
| Simpan gagal | Modal tetap terbuka, SnackBar error, data tidak hilang |
| Hapus | Dialog konfirmasi "Hapus tugas ini?" → batal/hapus |
| Keyboard | Modal naik mengikuti keyboard; tombol Simpan tetap terlihat |

---

## 8. Profile & Achievement Screen

### 8.1 Tata letak

```
┌───────────────────────────────┐
│  Profil                       │
│                               │
│        ╭─────────╮            │
│        │  foto   │            │  ← avatar 88 dp, border 3 dp
│        ╰─────────╯            │
│        Rani Putri             │  ← 20 sp semibold
│     rani@example.com          │  ← 12 sp muted
│        [ Edit nama ]          │
│                               │
│  ┌───────────┬───────────┐    │
│  │    4      │    18     │    │
│  │  Streak   │  Selesai  │    │  ← stat cards
│  └───────────┴───────────┘    │
│                               │
│  Achievement          2 / 6   │
│  ┌─────┬─────┬─────┐          │
│  │ 🏅  │ 🏅  │ 🔒  │          │  ← grid 3 kolom
│  ├─────┼─────┼─────┤          │
│  │ 🔒  │ 🔒  │ 🔒  │          │
│  └─────┴─────┴─────┘          │
│                               │
│  ┌─────────────────────────┐  │
│  │        Keluar           │  │
│  └─────────────────────────┘  │
│ [ Home ] [ Tugas ] [ Profil ] │
└───────────────────────────────┘
```

### 8.2 Elemen

| Elemen | Detail |
|---|---|
| Avatar | `CircleAvatar` dari `picture_url`; fallback inisial nama |
| Nama | Hasil edit pengguna, bukan selalu nama Google |
| Stat cards | Streak saat ini dan total tugas selesai |
| Grid badge | 3 kolom; badge diraih berwarna, belum diraih `kumiMuted` + ikon kunci |
| Tap badge | Bottom sheet: nama, deskripsi kriteria, tanggal diraih (bila ada) |
| Edit nama | Dialog dengan `TextField`, validasi 1–100 karakter |
| Keluar | Dialog konfirmasi; hapus token + data sesi |

### 8.3 State

| State | Tampilan |
|---|---|
| Belum ada badge | Grid tetap tampil dengan semua item terkunci + teks "Selesaikan tugas pertamamu" |
| Gagal memuat | Pesan + tombol coba lagi |
| Foto gagal dimuat | Fallback inisial |

---

## 9. Micro-interaction Maskot Kumi

### 9.1 Prinsip

- Animasi **memperkuat** aksi pengguna, bukan menarik perhatian tanpa alasan.
- Durasi total perayaan ≤ 1,5 detik agar tidak memperlambat alur.
- Selalu ada versi tanpa gerak untuk pengguna dengan reduce motion.

### 9.2 Idle state

| Properti | Nilai |
|---|---|
| Gerak | Naik-turun halus 4 dp |
| Durasi | 2,4 detik, `easeInOut`, `repeat(reverse: true)` |
| Pemicu | Selalu aktif saat Home terlihat dan tidak ada dialog |
| Penghentian | Saat bubble tampil atau saat tugas diselesaikan |

Implementasi: `AnimationController` + `SlideTransition`, atau `TweenAnimationBuilder` dengan `repeat`.

### 9.3 Tap maskot

```
Tap
 ├─ Scale 1.0 → 0.94 (80 ms, easeOut)
 ├─ Scale 0.94 → 1.06 (120 ms, easeOutBack)
 ├─ Scale 1.06 → 1.0 (100 ms, easeInOut)
 └─ Bubble muncul (fade + slide up 8 dp, 200 ms)
```

- Haptic ringan (`HapticFeedback.lightImpact`) saat tap.
- Bila API gagal: bubble tetap muncul dengan teks fallback lokal.

### 9.4 Tugas selesai (perayaan)

| Tahap | Waktu | Aksi |
|---|---|---|
| 1 | 0–120 ms | Maskot squash (scaleY 0.92) |
| 2 | 120–420 ms | Lompat: `translateY -24 dp` + scale 1.05 |
| 3 | 420–700 ms | Mendarat: kembali ke posisi, scale 1.0 |
| 4 | 500–1200 ms | Sparkle: 6–8 partikel kecil menyebar lalu fade |
| 5 | 700 ms | Bubble `task_done` muncul |
| 6 | 1500 ms | Semua animasi selesai; maskot kembali idle |

- Haptic: `mediumImpact` pada tahap 2.
- Bila ada badge baru: setelah tahap 6, tampil bottom sheet badge (dapat ditutup).
- Reduce motion: hanya fade 200 ms pada bubble dan perubahan warna progress bar.

### 9.5 Progress bar

| Perubahan | Animasi |
|---|---|
| Nilai bertambah | `TweenAnimationBuilder` 400 ms `easeOutCubic` |
| Nilai penuh (100%) | Warna berubah ke `kumiAccent` + pulse halus 1× |

### 9.6 Spesifikasi aset maskot

| Aset | Ukuran | Format | Catatan |
|---|---|---|---|
| `kumi_idle` | 512×512 | PNG transparan / SVG | Posisi duduk, mata terbuka |
| `kumi_happy` | 512×512 | PNG transparan / SVG | Untuk perayaan |
| `kumi_sleepy` | 512×512 | PNG transparan / SVG | Konteks malam (opsional) |
| Ikon badge | 96×96 | PNG / SVG | 6 badge |

Placeholder MVP memakai ilustrasi vektor sederhana; animasi dilakukan pada widget (bukan frame-by-frame) agar tidak membutuhkan aset animasi tambahan.

---

## 10. Komponen Reusable

| Komponen | Digunakan di | Properti |
|---|---|---|
| `KumiMascot` | Home | `size`, `state` (idle/happy/sleepy), `onTap` |
| `KumiSpeechBubble` | Home | `text`, `visible`, `onDismiss` |
| `TaskCard` | Home, Tasks | `task`, `onToggle`, `onTap`, `onMenu` |
| `DailyProgressBar` | Home | `completed`, `total` |
| `StatCard` | Profile | `label`, `value`, `icon` |
| `AchievementTile` | Profile | `achievement`, `earned`, `onTap` |
| `EmptyState` | Tasks, Home | `illustration`, `title`, `actionLabel`, `onAction` |
| `ErrorRetry` | Semua | `message`, `onRetry` |

---

## 11. Aksesibilitas

| Aspek | Ketentuan |
|---|---|
| Semantik | Semua tombol ikon memakai `Semantics(label: ...)` atau `tooltip` |
| Maskot | `Semantics(label: "Kumi, ketuk untuk bicara", button: true)` |
| Kontras | Teks utama ≥ 4.5:1; teks besar ≥ 3:1 |
| Ukuran teks | Menghormati `MediaQuery.textScaler` hingga 1.3× tanpa overflow |
| Reduce motion | Cek `MediaQuery.disableAnimations`; ganti animasi gerak dengan fade |
| Fokus | Urutan fokus logis pada form; tombol Simpan dapat dicapai dengan keyboard |
| Status | Status selesai tidak hanya dibedakan warna (ada ikon centang + coretan) |

---

## 12. Inventaris Layar & Rute

| Layar | Rute | Argumen |
|---|---|---|
| Splash | `/` | — |
| Login | `/login` | — |
| Home | `/home` | — |
| Tasks | `/tasks` | `date?` |
| Profile | `/profile` | — |
| Achievements | `/profile/achievements` | — |
| Task form | modal | `task?` (null = tambah) |

Navigasi memakai `go_router` dengan redirect berbasis status autentikasi: belum login → `/login`; sudah login dan membuka `/login` → `/home`.

---

## 13. Checklist Implementasi UI

- [ ] Splash menentukan rute berdasarkan token
- [ ] Login menampilkan loading dan error yang jelas
- [ ] Home menampilkan maskot, bubble, progress, dan 3 jadwal teratas
- [ ] Tap maskot memanggil API dan memiliki fallback offline
- [ ] Tasks memiliki filter tanggal dan status yang berfungsi
- [ ] Form tugas memvalidasi judul dan tenggat
- [ ] Hapus tugas meminta konfirmasi
- [ ] Profile menampilkan data Google dan statistik
- [ ] Edit nama memperbarui UI tanpa restart
- [ ] Grid badge membedakan diraih/belum
- [ ] Animasi perayaan berjalan ≤ 1,5 detik
- [ ] Reduce motion dihormati
- [ ] Semua layar memiliki state loading, kosong, dan error
