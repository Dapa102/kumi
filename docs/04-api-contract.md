# Kumi — API Contract & Specification

**Versi:** 1.0
**Base URL (produksi):** `https://api.example.com`
**Base URL (lokal):** `http://127.0.0.1:8000`
**Prefix:** `/api/v1`
**Format:** JSON (`Content-Type: application/json`)
**Autentikasi:** Bearer JWT pada header `Authorization`

---

## 1. Konvensi Umum

### 1.1 Header standar

| Header | Arah | Wajib | Keterangan |
|---|---|---|---|
| `Content-Type: application/json` | Request | Ya (kecuali GET) | Format body |
| `Accept: application/json` | Request | Tidak | Format respons |
| `Authorization: Bearer <jwt>` | Request | Ya pada endpoint terproteksi | Token lokal dari `/auth/google` |
| `X-Timezone-Offset` | Request | Tidak | Offset zona waktu klien dalam menit dari UTC (mis. `420` untuk WIB). Dipakai untuk batas hari lokal, `completed_today`, dan streak. Default `0` |
| `X-Request-ID` | Request | Tidak | ID korelasi untuk log |
| `Content-Type: application/json` | Response | Ya | Semua respons JSON |

### 1.2 Format error

Semua error memakai bentuk yang sama:

```json
{
  "detail": {
    "code": "VALIDATION_ERROR",
    "message": "Judul tugas wajib diisi.",
    "fields": {
      "title": "Field required"
    }
  }
}
```

- `detail.code` — kode mesin, stabil, dapat dipakai klien untuk percabangan.
- `detail.message` — pesan untuk manusia (Bahasa Indonesia).
- `detail.fields` — opsional, peta nama field ke pesan (hanya untuk validasi).

### 1.3 Tabel kode error

| HTTP | `code` | Kapan |
|---|---|---|
| 400 | `BAD_REQUEST` | Permintaan tidak dapat diproses (parameter tidak masuk akal) |
| 401 | `INVALID_GOOGLE_TOKEN` | ID Token Google gagal diverifikasi |
| 401 | `TOKEN_EXPIRED` | JWT lokal kedaluwarsa |
| 401 | `UNAUTHORIZED` | Header Authorization hilang/tidak valid |
| 403 | `FORBIDDEN` | Resource bukan milik pengguna (dipakai terbatas; umumnya 404) |
| 404 | `NOT_FOUND` | Resource tidak ada atau bukan milik pengguna |
| 422 | `VALIDATION_ERROR` | Body/parameter gagal validasi Pydantic |
| 429 | `RATE_LIMITED` | Melebihi batas permintaan |
| 500 | `INTERNAL_ERROR` | Kesalahan tak terduga |

### 1.4 Format waktu

- Semua timestamp: ISO 8601 UTC dengan sufiks `Z`, contoh `2026-10-19T09:30:00Z`.
- Tanggal (tanpa waktu): `YYYY-MM-DD`.
- Klien mengirim `X-Timezone-Offset` (menit dari UTC) agar backend menghitung hari kalender lokal. Tanpa header, backend memakai offset default server.

### 1.5 Paginasi

Endpoint daftar memakai query `limit` dan `offset` (bukan cursor) pada MVP.

| Parameter | Default | Maksimum |
|---|---|---|
| `limit` | 50 | 100 |
| `offset` | 0 | — |

Respons daftar selalu memuat `items` dan `total`:

```json
{
  "items": [],
  "total": 0
}
```

### 1.6 Otorisasi

Semua resource di-scope per pengguna. Backend mengambil `user_id` dari klaim `sub` JWT dan **selalu** menambahkan filter `user_id = current_user.id`. Resource milik pengguna lain menghasilkan `404`, bukan `403`, agar keberadaannya tidak bocor.

---

## 2. Ringkasan Endpoint

| # | Method | Path | Auth | Deskripsi |
|---|---|---|---|---|
| 1 | POST | `/api/v1/auth/google` | No | Tukar ID Token Google dengan JWT lokal |
| 2 | GET | `/api/v1/user/profile` | Yes | Ambil profil + statistik |
| 3 | PUT | `/api/v1/user/profile` | Yes | Ubah nama tampilan |
| 4 | GET | `/api/v1/tasks` | Yes | Daftar tugas (filter tanggal/status) |
| 5 | POST | `/api/v1/tasks` | Yes | Buat tugas |
| 6 | GET | `/api/v1/tasks/{id}` | Yes | Detail satu tugas |
| 7 | PUT | `/api/v1/tasks/{id}` | Yes | Ubah tugas |
| 8 | DELETE | `/api/v1/tasks/{id}` | Yes | Hapus tugas |
| 9 | PATCH | `/api/v1/tasks/{id}/complete` | Yes | Toggle status selesai |
| 10 | GET | `/api/v1/kumi/dialog` | Yes | Dialog maskot sesuai konteks |
| 11 | GET | `/api/v1/achievements` | Yes | Daftar badge + status diraih |
| 12 | GET | `/health` | No | Health check (API + DB) |

---

## 3. Spesifikasi Endpoint

## 3.1 POST `/api/v1/auth/google`

Menukar ID Token Google dengan JWT lokal. Membuat pengguna baru bila belum ada.

| Item | Nilai |
|---|---|
| **Auth Required** | No |
| **Rate limit** | 10 permintaan/menit per IP (Nginx) |

**Request header**

```
Content-Type: application/json
```

**Request body**

```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|---|---|
| `id_token` | string | Ya | ID Token JWT dari Google, panjang 100–4096 |

**Response sukses — `200 OK`**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 604800,
  "is_new_user": true,
  "user": {
    "id": 1,
    "email": "rani@example.com",
    "name": "Rani Putri",
    "picture_url": "https://lh3.googleusercontent.com/a/...",
    "current_streak": 0,
    "created_at": "2026-10-19T02:15:00Z"
  }
}
```

| Field | Keterangan |
|---|---|
| `access_token` | JWT lokal (HS256) |
| `token_type` | Selalu `bearer` |
| `expires_in` | Umur token dalam detik |
| `is_new_user` | `true` bila baris `users` baru dibuat (dipakai klien untuk onboarding) |
| `user` | Profil ringkas |

**Error responses**

| Status | `code` | Kondisi | Body |
|---|---|---|---|
| 401 | `INVALID_GOOGLE_TOKEN` | Signature/audience/issuer/exp tidak valid | `{"detail":{"code":"INVALID_GOOGLE_TOKEN","message":"Token Google tidak valid."}}` |
| 401 | `EMAIL_NOT_VERIFIED` | `email_verified` bernilai `false` | `{"detail":{"code":"EMAIL_NOT_VERIFIED","message":"Email Google belum terverifikasi."}}` |
| 422 | `VALIDATION_ERROR` | `id_token` kosong | `{"detail":{"code":"VALIDATION_ERROR","message":"Data tidak valid.","fields":{"id_token":"Field required"}}}` |
| 429 | `RATE_LIMITED` | Melebihi batas | `{"detail":{"code":"RATE_LIMITED","message":"Terlalu banyak percobaan. Coba lagi nanti."}}` |

**Perilaku**

1. Verifikasi ID Token ke Google (signature, `aud` = `GOOGLE_CLIENT_ID`, `iss`, `exp`).
2. `UPSERT` pengguna berdasarkan `google_id`.
3. Perbarui `email` dan `picture_url` bila berubah; **jangan** timpa `name` bila pengguna pernah mengeditnya.
4. Terbitkan JWT dengan klaim `sub`, `iat`, `exp`.

---

## 3.2 GET `/api/v1/user/profile`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Request header**

```
Authorization: Bearer <jwt>
```

**Request body** — tidak ada

**Response sukses — `200 OK`**

```json
{
  "id": 1,
  "email": "rani@example.com",
  "name": "Rani Putri",
  "picture_url": "https://lh3.googleusercontent.com/a/...",
  "current_streak": 4,
  "last_completed_date": "2026-10-19",
  "stats": {
    "total_tasks": 24,
    "completed_tasks": 18,
    "completed_today": 2,
    "completion_rate": 0.75
  },
  "created_at": "2026-10-01T03:00:00Z"
}
```

| Field | Keterangan |
|---|---|
| `current_streak` | Hari berturut-turut dengan ≥ 1 tugas selesai |
| `stats.total_tasks` | Seluruh tugas pengguna |
| `stats.completed_tasks` | Tugas dengan `is_completed = 1` |
| `stats.completed_today` | Tugas selesai pada tanggal UTC hari ini |
| `stats.completion_rate` | `completed_tasks / total_tasks`, 0 bila total 0 |

**Error responses**

| Status | `code` | Body |
|---|---|---|
| 401 | `UNAUTHORIZED` | `{"detail":{"code":"UNAUTHORIZED","message":"Autentikasi diperlukan."}}` |
| 401 | `TOKEN_EXPIRED` | `{"detail":{"code":"TOKEN_EXPIRED","message":"Sesi berakhir, silakan masuk kembali."}}` |
| 500 | `INTERNAL_ERROR` | `{"detail":{"code":"INTERNAL_ERROR","message":"Terjadi kesalahan pada server."}}` |

---

## 3.3 PUT `/api/v1/user/profile`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Request header**

```
Authorization: Bearer <jwt>
Content-Type: application/json
```

**Request body**

```json
{
  "name": "Rani P."
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|---|---|
| `name` | string | Ya | 1–100 karakter setelah `trim`; tidak boleh hanya spasi |

**Response sukses — `200 OK`**

```json
{
  "id": 1,
  "email": "rani@example.com",
  "name": "Rani P.",
  "picture_url": "https://lh3.googleusercontent.com/a/...",
  "current_streak": 4,
  "last_completed_date": "2026-10-19",
  "created_at": "2026-10-01T03:00:00Z"
}
```

**Error responses**

| Status | `code` | Kondisi | Body |
|---|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid | `{"detail":{"code":"UNAUTHORIZED","message":"Autentikasi diperlukan."}}` |
| 422 | `VALIDATION_ERROR` | Nama kosong/terlalu panjang | `{"detail":{"code":"VALIDATION_ERROR","message":"Data tidak valid.","fields":{"name":"Nama harus 1-100 karakter"}}}` |

**Perilaku:** hanya `name` yang dapat diubah. `email`, `picture_url`, dan `google_id` tidak dapat diubah lewat endpoint ini.

---

## 3.4 GET `/api/v1/tasks`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Request header**

```
Authorization: Bearer <jwt>
```

**Query parameters**

| Parameter | Tipe | Wajib | Default | Keterangan |
|---|---|---|---|---|
| `date` | `YYYY-MM-DD` | Tidak | — | Filter tugas dengan `due_time` pada tanggal tersebut (UTC) |
| `status` | `all` \| `pending` \| `completed` | Tidak | `all` | Filter status |
| `limit` | integer | Tidak | 50 | 1–100 |
| `offset` | integer | Tidak | 0 | ≥ 0 |

**Contoh:** `GET /api/v1/tasks?date=2026-10-19&status=pending&limit=20`

**Response sukses — `200 OK`**

```json
{
  "items": [
    {
      "id": 42,
      "title": "Revisi Bab 3",
      "description": "Perbaiki metodologi dan tabel 3.2",
      "due_time": "2026-10-19T15:00:00Z",
      "is_completed": false,
      "completed_at": null,
      "created_at": "2026-10-18T08:12:00Z",
      "updated_at": "2026-10-18T08:12:00Z"
    },
    {
      "id": 41,
      "title": "Kuis Pemrograman Mobile",
      "description": null,
      "due_time": "2026-10-19T09:00:00Z",
      "is_completed": true,
      "completed_at": "2026-10-19T08:40:00Z",
      "created_at": "2026-10-17T11:00:00Z",
      "updated_at": "2026-10-19T08:40:00Z"
    }
  ],
  "total": 2
}
```

**Error responses**

| Status | `code` | Kondisi |
|---|---|---|
| 400 | `BAD_REQUEST` | Format `date` tidak valid |
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid |
| 422 | `VALIDATION_ERROR` | `limit`/`offset` di luar rentang |

**Perilaku:** hasil selalu terurut `due_time ASC`, lalu `id ASC` sebagai tie-breaker agar paginasi stabil.

---

## 3.5 POST `/api/v1/tasks`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Request header**

```
Authorization: Bearer <jwt>
Content-Type: application/json
```

**Request body**

```json
{
  "title": "Revisi Bab 3",
  "description": "Perbaiki metodologi dan tabel 3.2",
  "due_time": "2026-10-19T15:00:00Z"
}
```

| Field | Tipe | Wajib | Aturan |
|---|---|---|---|
| `title` | string | Ya | 1–150 karakter setelah `trim` |
| `description` | string \| null | Tidak | Maksimum 1000 karakter |
| `due_time` | string (ISO 8601) | Ya | Harus di masa depan |

**Response sukses — `201 Created`**

```json
{
  "id": 43,
  "title": "Revisi Bab 3",
  "description": "Perbaiki metodologi dan tabel 3.2",
  "due_time": "2026-10-19T15:00:00Z",
  "is_completed": false,
  "completed_at": null,
  "created_at": "2026-10-19T02:30:00Z",
  "updated_at": "2026-10-19T02:30:00Z"
}
```

Header respons: `Location: /api/v1/tasks/43`

**Error responses**

| Status | `code` | Kondisi | Body |
|---|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid | `{"detail":{"code":"UNAUTHORIZED","message":"Autentikasi diperlukan."}}` |
| 422 | `VALIDATION_ERROR` | Field gagal validasi | `{"detail":{"code":"VALIDATION_ERROR","message":"Data tidak valid.","fields":{"title":"Judul wajib diisi","due_time":"Tenggat harus di masa depan"}}}` |

**Perilaku:** tugas baru selalu `is_completed = false`, `completed_at = null`.

---

## 3.6 GET `/api/v1/tasks/{id}`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Path parameter:** `id` — integer > 0

**Response sukses — `200 OK`**

```json
{
  "id": 43,
  "title": "Revisi Bab 3",
  "description": "Perbaiki metodologi dan tabel 3.2",
  "due_time": "2026-10-19T15:00:00Z",
  "is_completed": false,
  "completed_at": null,
  "created_at": "2026-10-19T02:30:00Z",
  "updated_at": "2026-10-19T02:30:00Z"
}
```

**Error responses**

| Status | `code` | Kondisi | Body |
|---|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid | `{"detail":{"code":"UNAUTHORIZED","message":"Autentikasi diperlukan."}}` |
| 404 | `NOT_FOUND` | Tidak ada atau bukan milik pengguna | `{"detail":{"code":"NOT_FOUND","message":"Tugas tidak ditemukan."}}` |

---

## 3.7 PUT `/api/v1/tasks/{id}`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Request body**

```json
{
  "title": "Revisi Bab 3 dan Bab 4",
  "description": "Tambahkan pembahasan hasil uji",
  "due_time": "2026-10-20T15:00:00Z"
}
```

Semua field wajib (penggantian penuh). Gunakan `PATCH` untuk perubahan parsial di masa depan bila diperlukan.

**Response sukses — `200 OK`**

```json
{
  "id": 43,
  "title": "Revisi Bab 3 dan Bab 4",
  "description": "Tambahkan pembahasan hasil uji",
  "due_time": "2026-10-20T15:00:00Z",
  "is_completed": false,
  "completed_at": null,
  "created_at": "2026-10-19T02:30:00Z",
  "updated_at": "2026-10-19T03:05:00Z"
}
```

**Error responses**

| Status | `code` | Kondisi |
|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid |
| 404 | `NOT_FOUND` | Tidak ada atau bukan milik pengguna |
| 422 | `VALIDATION_ERROR` | Field gagal validasi |

**Perilaku:** endpoint ini tidak mengubah `is_completed`/`completed_at`; status hanya berubah melalui `PATCH /complete`.

---

## 3.8 DELETE `/api/v1/tasks/{id}`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Response sukses — `204 No Content`** (tanpa body)

**Error responses**

| Status | `code` | Kondisi |
|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid |
| 404 | `NOT_FOUND` | Tidak ada atau bukan milik pengguna |

**Perilaku:** hard delete pada MVP. Klien wajib membatalkan notifikasi lokal terkait setelah menerima `204`.

---

## 3.9 PATCH `/api/v1/tasks/{id}/complete`

Toggle status selesai. Idempoten terhadap status akhir.

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Request body** (opsional)

```json
{
  "is_completed": true
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `is_completed` | boolean | Tidak | Bila dihilangkan, status dibalik (toggle) |

**Response sukses — `200 OK`**

```json
{
  "id": 43,
  "title": "Revisi Bab 3",
  "description": "Perbaiki metodologi dan tabel 3.2",
  "due_time": "2026-10-19T15:00:00Z",
  "is_completed": true,
  "completed_at": "2026-10-19T03:10:00Z",
  "created_at": "2026-10-19T02:30:00Z",
  "updated_at": "2026-10-19T03:10:00Z",
  "gamification": {
    "current_streak": 5,
    "streak_increased": true,
    "new_achievements": [
      {
        "code": "task_10",
        "name": "Produktif",
        "description": "Selesaikan 10 tugas",
        "icon": "badge_ten",
        "earned_at": "2026-10-19T03:10:00Z"
      }
    ]
  }
}
```

**Error responses**

| Status | `code` | Kondisi |
|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid |
| 404 | `NOT_FOUND` | Tidak ada atau bukan milik pengguna |

**Perilaku**

1. Bila `is_completed` menjadi `true`: set `completed_at = now()` (UTC).
2. Bila menjadi `false`: set `completed_at = NULL`; streak dihitung ulang dari data, tidak boleh berkurang salah akibat toggle berulang.
3. Setelah perubahan, evaluasi streak dan badge, kembalikan ringkasan pada `gamification`.
4. Toggle berulang pada hari yang sama tidak menambah streak lebih dari satu.

---

## 3.10 GET `/api/v1/kumi/dialog`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Query parameters**

| Parameter | Tipe | Wajib | Default | Keterangan |
|---|---|---|---|---|
| `context` | `morning` \| `afternoon` \| `night` \| `task_done` \| `idle` | Tidak | diturunkan dari jam server | Konteks dialog |
| `exclude_id` | integer | Tidak | — | Hindari pengulangan dialog yang baru saja tampil |

**Contoh:** `GET /api/v1/kumi/dialog?context=morning&exclude_id=3`

**Response sukses — `200 OK`**

```json
{
  "id": 1,
  "context": "morning",
  "text": "Selamat pagi! Hari ini kita mulai pelan-pelan, ya."
}
```

**Error responses**

| Status | `code` | Kondisi | Body |
|---|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid | `{"detail":{"code":"UNAUTHORIZED","message":"Autentikasi diperlukan."}}` |
| 422 | `VALIDATION_ERROR` | `context` tidak dikenal | `{"detail":{"code":"VALIDATION_ERROR","message":"Data tidak valid.","fields":{"context":"Nilai harus salah satu dari: morning, afternoon, night, task_done, idle"}}}` |
| 404 | `NOT_FOUND` | Tidak ada dialog aktif untuk konteks | `{"detail":{"code":"NOT_FOUND","message":"Dialog tidak tersedia."}}` |

**Perilaku:** memilih satu baris acak dari `kumi_dialogs` dengan `context` dan `is_active = 1`. Bila `exclude_id` diberikan dan masih ada kandidat lain, baris tersebut dihindari. Klien menyimpan fallback lokal untuk kasus `404`/jaringan gagal.

---

## 3.11 GET `/api/v1/achievements`

| Item | Nilai |
|---|---|
| **Auth Required** | Yes |

**Response sukses — `200 OK`**

```json
{
  "items": [
    {
      "id": 1,
      "code": "first_steps",
      "name": "Langkah Pertama",
      "description": "Selesaikan tugas pertamamu",
      "icon": "badge_first",
      "earned": true,
      "earned_at": "2026-10-01T05:00:00Z"
    },
    {
      "id": 2,
      "code": "task_10",
      "name": "Produktif",
      "description": "Selesaikan 10 tugas",
      "icon": "badge_ten",
      "earned": false,
      "earned_at": null
    }
  ],
  "total": 6
}
```

**Error responses**

| Status | `code` | Kondisi |
|---|---|---|
| 401 | `UNAUTHORIZED` | Token tidak ada/invalid |

---

## 3.12 GET `/health`

| Item | Nilai |
|---|---|
| **Auth Required** | No |
| **Tujuan** | Health check untuk Docker dan monitoring |

**Response sukses — `200 OK`**

```json
{
  "status": "ok",
  "database": "ok",
  "version": "1.0.0",
  "time": "2026-10-19T03:15:00Z"
}
```

**Response gagal — `503 Service Unavailable`**

```json
{
  "status": "degraded",
  "database": "error",
  "version": "1.0.0",
  "time": "2026-10-19T03:15:00Z"
}
```

---

## 4. Pemetaan Model (Pydantic)

### 4.1 Skema utama

```python
class UserPublic(BaseModel):
    id: int
    email: EmailStr
    name: str
    picture_url: str | None
    current_streak: int
    created_at: datetime

class TaskOut(BaseModel):
    id: int
    title: str
    description: str | None
    due_time: datetime
    is_completed: bool
    completed_at: datetime | None
    created_at: datetime
    updated_at: datetime

class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=150)
    description: str | None = Field(default=None, max_length=1000)
    due_time: datetime

class TaskUpdate(BaseModel):
    title: str = Field(min_length=1, max_length=150)
    description: str | None = Field(default=None, max_length=1000)
    due_time: datetime

class TaskComplete(BaseModel):
    is_completed: bool | None = None
```

### 4.2 Aturan validasi tambahan

| Aturan | Implementasi |
|---|---|
| `title` tidak hanya spasi | `field_validator` melakukan `strip()` lalu cek kosong |
| `due_time` di masa depan (create & update) | `field_validator` membandingkan dengan `datetime.now(timezone.utc)`; update tetap mengizinkan tenggat lampau hanya untuk tugas yang sudah selesai |
| `name` tidak hanya spasi | Sama seperti `title` |

---

## 5. Kontrak Klien Flutter

| Kebutuhan | Implementasi |
|---|---|
| Menyimpan JWT | `flutter_secure_storage` |
| Menambahkan header | Interceptor `Authorization: Bearer <token>` dan `X-Timezone-Offset` (dari offset zona waktu perangkat) |
| Menangani 401 | Hapus token, arahkan ke Login, tampilkan pesan sesi berakhir |
| Menangani error jaringan | Tampilkan pesan + tombol "Coba lagi"; jangan crash |
| Format tanggal | Parse ISO 8601 UTC, konversi ke `toLocal()` |
| Timeout | 15 detik per permintaan |

### 5.1 Pemetaan error ke UI

| `code` | Pesan UI |
|---|---|
| `UNAUTHORIZED` / `TOKEN_EXPIRED` | "Sesi berakhir, silakan masuk kembali." |
| `INVALID_GOOGLE_TOKEN` | "Gagal masuk. Coba lagi." |
| `VALIDATION_ERROR` | Tampilkan `detail.fields` pada form |
| `NOT_FOUND` | "Data tidak ditemukan." |
| `RATE_LIMITED` | "Terlalu banyak percobaan. Tunggu sebentar." |
| Lainnya / jaringan | "Terjadi kesalahan. Coba lagi." |

---

## 6. Contoh Alur End-to-End

```
1. POST /api/v1/auth/google        → 200 {access_token, user}
2. GET  /api/v1/user/profile       → 200 {profile, stats}
3. GET  /api/v1/tasks?date=...     → 200 {items, total}
4. POST /api/v1/tasks              → 201 {task}
5. PATCH /api/v1/tasks/43/complete → 200 {task, gamification}
6. GET  /api/v1/kumi/dialog?context=task_done → 200 {dialog}
7. GET  /api/v1/achievements       → 200 {items, total}
8. DELETE /api/v1/tasks/43         → 204
```

---

## 7. Catatan Keamanan API

- ID Token Google **tidak** disimpan di server; hanya dipakai saat verifikasi.
- JWT lokal tidak boleh dicatat pada log (redaksi header `Authorization`).
- Semua query wajib menyertakan filter `user_id` dari token, bukan dari body/query.
- Endpoint auth dibatasi rate limit untuk mencegah *token stuffing*.
- `/docs` dan `/redoc` dinonaktifkan di produksi.
- Pesan error tidak boleh membocorkan detail internal (stack trace, SQL).
