# Kumi — Arsitektur Sistem & Panduan Deployment

**Versi:** 1.0
**Bergantung pada:** `docs/01-brd-prd.md`
**Stack:** Flutter · FastAPI · MariaDB · Docker Compose · Nginx · Let's Encrypt

---

## 1. Prinsip Arsitektur

1. **Client-server dengan batas yang jelas.** Flutter hanya berbicara dengan REST API. Tidak ada akses langsung ke basis data dari klien.
2. **Backend stateless.** Semua state sesi disimpan di klien sebagai JWT. API dapat di-restart tanpa kehilangan sesi.
3. **Satu pintu masuk.** Hanya Nginx yang terbuka ke publik (port 80/443). Container API dan MariaDB berada di jaringan internal Docker.
4. **Konfigurasi lewat environment.** Tidak ada secret di dalam image atau repositori.
5. **MVP sesederhana mungkin.** Tidak ada message broker, cache layer, atau orkestrator cluster. Satu VPS, dua container inti.

---

## 2. High-Level Architecture

### 2.1 Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                        Perangkat Pengguna                     │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Flutter App (Android / iOS)                           │  │
│  │  ├─ UI (Home, Tasks, Profile)                          │  │
│  │  ├─ State & Repository                                │  │
│  │  ├─ Secure Storage (JWT)                              │  │
│  │  └─ Local Notifications (dijadwalkan di perangkat)     │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────┬──────────────────────────────────┘
                            │ HTTPS  (443)
                            │ JSON / REST  ·  Authorization: Bearer <JWT>
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                        VPS Publik                             │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Nginx (host)                                          │  │
│  │  ├─ TLS termination (Let's Encrypt)                    │  │
│  │  ├─ 80 → 301 redirect ke 443                           │  │
│  │  └─ reverse proxy /api/* → api:8000                    │  │
│  └───────────────────────────┬────────────────────────────┘  │
│                              │ docker network (internal)     │
│                              ▼                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Container: api  (FastAPI + Uvicorn)                   │  │
│  │  ├─ routers/  auth · user · tasks · kumi               │  │
│  │  ├─ services/ google verify · jwt · streak · badge     │  │
│  │  ├─ models/   SQLAlchemy                               │  │
│  │  └─ schemas/  Pydantic                                 │  │
│  └───────────────────────────┬────────────────────────────┘  │
│                              │ mysql://  (3306, internal)    │
│                              ▼                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Container: db  (MariaDB 11)                           │  │
│  │  └─ volume: mariadb_data (persisten)                   │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Layanan eksternal: Google Identity (verifikasi token) │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Alur komunikasi

1. **Flutter → Nginx.** Aplikasi mengirim permintaan HTTPS ke `https://api.<domain>/api/v1/...`. Nginx mengakhiri TLS.
2. **Nginx → FastAPI.** Nginx meneruskan permintaan ke container `api` melalui jaringan Docker internal (`api:8000`). Header `Host`, `X-Real-IP`, dan `X-Forwarded-Proto` diteruskan.
3. **FastAPI → MariaDB.** FastAPI memakai SQLAlchemy dengan driver PyMySQL ke `db:3306`. Kredensial berasal dari environment.
4. **FastAPI → Google.** Hanya pada endpoint auth: ID Token diverifikasi ke endpoint sertifikat publik Google (`google-auth` memvalidasi signature, `aud`, `iss`, dan `exp`).
5. **Respons kembali** melalui jalur yang sama sebagai JSON.

### 2.3 Komponen & tanggung jawab

| Komponen | Tanggung jawab | Tidak bertanggung jawab atas |
|---|---|---|
| Flutter app | UI, state, penyimpanan JWT, penjadwalan notifikasi lokal | Otorisasi, perhitungan streak |
| Nginx | TLS, routing, kompresi, rate limit dasar | Logika bisnis |
| FastAPI | Autentikasi, otorisasi, validasi, logika bisnis, akses data | Rendering UI, penjadwalan notifikasi |
| MariaDB | Persistensi relasional, constraint, indeks | Logika aplikasi |
| Google Identity | Penerbitan identitas | Otorisasi resource Kumi |

---

## 3. Alur Autentikasi Google Sign-In

### 3.1 Alur ringkas

```
Flutter dapat ID Token → Kirim ke FastAPI → FastAPI verifikasi ke Google Server → FastAPI kembalikan JWT lokal
```

### 3.2 Sequence diagram

```
Flutter                 Google Identity           FastAPI                  MariaDB
   │                          │                      │                       │
   │ 1. Sign in (native)      │                      │                       │
   ├─────────────────────────>│                      │                       │
   │ 2. ID Token (JWT)        │                      │                       │
   │<─────────────────────────┤                      │                       │
   │                          │                      │                       │
   │ 3. POST /api/v1/auth/google {id_token}          │                       │
   ├────────────────────────────────────────────────>│                       │
   │                          │ 4. Verifikasi token  │                       │
   │                          │<─────────────────────┤                       │
   │                          │ 5. Payload (sub,email,name,picture)           │
   │                          ├─────────────────────>│                       │
   │                          │                      │ 6. UPSERT user by google_id
   │                          │                      ├──────────────────────>│
   │                          │                      │ 7. user record        │
   │                          │                      │<──────────────────────┤
   │                          │                      │ 8. Terbitkan JWT lokal │
   │ 9. 200 {access_token, user}                     │                       │
   │<────────────────────────────────────────────────┤                       │
   │ 10. Simpan JWT di secure storage                │                       │
   │                                                  │                       │
   │ 11. GET /api/v1/tasks  Authorization: Bearer …   │                       │
   ├────────────────────────────────────────────────>│ 12. Validasi JWT      │
   │                                                  ├──────────────────────>│
   │ 13. 200 [tasks]                                  │                       │
   │<────────────────────────────────────────────────┤                       │
```

### 3.3 Aturan verifikasi

| Pemeriksaan | Aturan |
|---|---|
| Signature | Divalidasi terhadap sertifikat publik Google |
| `aud` | Harus sama dengan `GOOGLE_CLIENT_ID` backend |
| `iss` | `accounts.google.com` atau `https://accounts.google.com` |
| `exp` | Belum kedaluwarsa |
| `email_verified` | Harus `true` |

### 3.4 Token lokal

- Algoritma: HS256 dengan `JWT_SECRET`.
- Klaim: `sub` (user id), `iat`, `exp`.
- Umur: 7 hari (MVP). Tidak ada refresh token; sesi berakhir memaksa login ulang.
- Transport: header `Authorization: Bearer <token>`.

### 3.5 Konfigurasi Google Cloud Console

1. Buat project di Google Cloud Console.
2. Aktifkan **Google Identity** / OAuth consent screen (External, mode testing).
3. Buat **OAuth 2.0 Client ID** tipe **Android** dan/atau **iOS** sesuai target. Untuk Android, daftarkan package name (`com.example.kumi`) dan SHA-1 fingerprint debug/release.
4. Buat juga **Web application** client ID untuk dipakai sebagai `serverClientId` pada `google_sign_in` (diperlukan agar ID Token berisi audience yang dapat diverifikasi backend).
5. Salin client ID Web ke `GOOGLE_CLIENT_ID` di `.env` backend dan ke konfigurasi Flutter.

---

## 4. Struktur Repositori

```
kumi/
├── lib/                     # aplikasi Flutter
│   ├── core/                # config, http client, storage, theme
│   ├── features/            # auth, home, tasks, profile
│   └── main.dart
├── test/                    # widget/unit test Flutter
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── deps.py
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── routers/
│   │   └── services/
│   ├── tests/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
├── deploy/
│   ├── docker-compose.yml
│   └── nginx/kumi.conf
├── docs/
└── README.md
```

---

## 5. Konfigurasi Docker

### 5.1 `backend/Dockerfile`

```dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
```

Catatan: `--proxy-headers` diperlukan agar FastAPI membaca `X-Forwarded-Proto` dari Nginx (skema URL pada dokumentasi OpenAPI).

### 5.2 `deploy/docker-compose.yml`

```yaml
services:
  db:
    image: mariadb:11.4
    container_name: kumi-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: ${MARIADB_ROOT_PASSWORD}
      MARIADB_DATABASE: ${MARIADB_DATABASE}
      MARIADB_USER: ${MARIADB_USER}
      MARIADB_PASSWORD: ${MARIADB_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 10
    networks:
      - kumi-net

  api:
    build:
      context: ../backend
    container_name: kumi-api
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: mysql+pymysql://${MARIADB_USER}:${MARIADB_PASSWORD}@db:3306/${MARIADB_DATABASE}
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRE_DAYS: ${JWT_EXPIRE_DAYS:-7}
      GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID}
      CORS_ORIGINS: ${CORS_ORIGINS:-*}
      TZ: Asia/Jakarta
    ports:
      - "127.0.0.1:8000:8000"
    networks:
      - kumi-net

volumes:
  mariadb_data:

networks:
  kumi-net:
    driver: bridge
```

**Catatan penting:**

- Port API di-bind ke `127.0.0.1` saja. Nginx di host yang meneruskan lalu lintas. Container tidak terekspos langsung ke internet.
- MariaDB tidak mempublikasikan port ke host sama sekali.
- `depends_on` dengan `condition: service_healthy` mencegah API start sebelum DB siap.

### 5.3 Environment variables

File `deploy/.env` (tidak di-commit):

| Variabel | Wajib | Contoh | Keterangan |
|---|---|---|---|
| `MARIADB_ROOT_PASSWORD` | Ya | `ubah-ini` | Hanya untuk administrasi container |
| `MARIADB_DATABASE` | Ya | `kumi` | Nama basis data |
| `MARIADB_USER` | Ya | `kumi_app` | User aplikasi (bukan root) |
| `MARIADB_PASSWORD` | Ya | `ubah-ini` | Kata sandi user aplikasi |
| `JWT_SECRET` | Ya | 64 karakter acak | `openssl rand -hex 32` |
| `JWT_EXPIRE_DAYS` | Tidak | `7` | Umur token |
| `GOOGLE_CLIENT_ID` | Ya | `123-abc.apps.googleusercontent.com` | Audience yang divalidasi |
| `CORS_ORIGINS` | Tidak | `*` atau daftar origin | Lihat §6.3 |
| `TZ` | Tidak | `Asia/Jakarta` | Zona waktu log |

Contoh `deploy/.env.example`:

```dotenv
MARIADB_ROOT_PASSWORD=change-me-root
MARIADB_DATABASE=kumi
MARIADB_USER=kumi_app
MARIADB_PASSWORD=change-me-app
JWT_SECRET=change-me-64-hex
JWT_EXPIRE_DAYS=7
GOOGLE_CLIENT_ID=000000000000-xxxxxxxx.apps.googleusercontent.com
CORS_ORIGINS=*
TZ=Asia/Jakarta
```

### 5.4 Perintah operasional

```bash
# build dan jalankan
cd deploy && docker compose up -d --build

# lihat log
docker compose logs -f api

# cek status
docker compose ps

# migrasi/seed (dijalankan sekali)
docker compose exec api python -m app.seed

# backup basis data
docker compose exec db mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" > backup.sql
```

---

## 6. Strategi Deployment VPS

### 6.1 Prasyarat

- VPS Ubuntu 22.04/24.04, minimal 1 vCPU / 1 GB RAM (2 GB disarankan).
- Domain dengan record `A` untuk `api.<domain>` mengarah ke IP VPS.
- Akses SSH dengan user non-root bersudo.

### 6.2 Langkah deployment

**Langkah 1 — Hardening dasar server.**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx docker.io docker-compose-v2 git ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

**Langkah 2 — Ambil kode dan siapkan environment.**

```bash
sudo mkdir -p /opt/kumi && sudo chown "$USER":"$USER" /opt/kumi
git clone <repo-url> /opt/kumi
cd /opt/kumi/deploy
cp .env.example .env
nano .env   # isi seluruh nilai; JWT_SECRET hasil `openssl rand -hex 32`
chmod 600 .env
```

**Langkah 3 — Jalankan container.**

```bash
docker compose up -d --build
curl -s http://127.0.0.1:8000/health
```

**Langkah 4 — Konfigurasi Nginx.**

`/etc/nginx/sites-available/kumi`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name api.example.com;

    # Let's Encrypt HTTP-01 challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.example.com;

    ssl_certificate     /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # batas ukuran body request
    client_max_body_size 1m;

    # rate limit dasar untuk endpoint auth
    location /api/v1/auth/ {
        limit_req zone=auth burst=5 nodelay;
        proxy_pass http://127.0.0.1:8000;
        include /etc/nginx/proxy_params;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
```

Tambahkan zone pada blok `http` di `/etc/nginx/nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;
```

Aktifkan situs dan uji konfigurasi:

```bash
sudo ln -s /etc/nginx/sites-available/kumi /etc/nginx/sites-enabled/kumi
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

**Langkah 5 — Terbitkan sertifikat SSL.**

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.example.com --redirect -m admin@example.com --agree-tos
```

Perpanjangan otomatis sudah dipasang oleh paket Debian/Ubuntu melalui timer systemd. Verifikasi:

```bash
sudo certbot renew --dry-run
sudo systemctl list-timers | grep certbot
```

**Langkah 6 — Verifikasi publik.**

```bash
curl -i https://api.example.com/health
curl -i https://api.example.com/docs   # opsional: nonaktifkan di produksi
```

### 6.3 Penanganan CORS

Flutter mobile **tidak** menerapkan kebijakan same-origin seperti browser, sehingga CORS tidak diperlukan untuk build Android/iOS. CORS tetap wajib bila:

- aplikasi dijalankan sebagai **Flutter Web**, atau
- dokumentasi `/docs` diakses dari browser pada origin berbeda.

Konfigurasi FastAPI:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,   # ["*"] untuk demo, daftar eksplisit untuk produksi
    allow_credentials=False,               # JWT dikirim via header, bukan cookie
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)
```

Aturan:

| Lingkungan | `allow_origins` |
|---|---|
| Pengembangan lokal | `["*"]` |
| Produksi dengan Flutter Web | Daftar origin eksplisit, mis. `["https://app.example.com"]` |
| Produksi mobile-only | Daftar kosong atau origin dokumentasi |

`allow_credentials` harus `false` selama token dikirim lewat header `Authorization`. Kombinasi `allow_origins=["*"]` dengan `allow_credentials=True` ditolak browser dan harus dihindari.

### 6.4 Hardening tambahan

- Nonaktifkan `/docs` dan `/redoc` di produksi (`docs_url=None`) atau lindungi dengan autentikasi.
- Jalankan container sebagai user non-root di Dockerfile produksi.
- Batasi akses SSH dengan key-only (`PasswordAuthentication no`).
- Pasang `fail2ban` untuk SSH.
- Backup harian: `mariadb-dump` ke direktori terpisah + rotasi 7 hari (cron).
- Pantau disk dan memori: `docker stats`, logrotate untuk log container.
- Gunakan `restart: unless-stopped` agar container pulih setelah reboot.

### 6.5 Checklist go-live

- [ ] `GET /health` mengembalikan `{"status":"ok"}` melalui HTTPS
- [ ] Sertifikat valid dan perpanjangan otomatis teruji (`--dry-run`)
- [ ] Port 8000 dan 3306 tidak terbuka ke publik (`sudo ss -tlnp`)
- [ ] `.env` berisi secret kuat dan permission `600`
- [ ] `JWT_SECRET` bukan nilai contoh
- [ ] Login Google berhasil dari perangkat fisik terhadap API produksi
- [ ] CORS sesuai kebutuhan (mobile-only atau daftar origin eksplisit)
- [ ] Backup basis data terjadwal dan pernah diuji restore
- [ ] Log tidak memuat token, ID Token, atau data pribadi

### 6.6 Rollback

```bash
cd /opt/kumi
git checkout <commit-sebelumnya>
cd deploy
docker compose up -d --build
```

Karena skema MVP dikelola dengan migrasi yang aditif, rollback kode tidak memerlukan rollback basis data. Bila migrasi destruktif diperlukan, backup harus dibuat lebih dulu dan prosedur rollback didokumentasikan pada PR terkait.

---

## 7. Alur Data Ringkas per Fitur

| Fitur | Alur |
|---|---|
| Login | Flutter → Google → ID Token → API → verifikasi → JWT |
| Lihat tugas | Flutter → API (JWT) → MariaDB → JSON |
| Tambah tugas | Flutter → API → validasi → MariaDB → JSON → jadwalkan notifikasi lokal |
| Selesai tugas | Flutter → API → update status → hitung streak → cek badge → JSON → animasi maskot |
| Dialog maskot | Flutter (konteks) → API → pilih dialog acak sesuai konteks → JSON |
| Notifikasi | Sepenuhnya di perangkat; tidak ada push server |

---

## 8. Keputusan Arsitektur (ADR Ringkas)

| # | Keputusan | Alternatif | Alasan |
|---|---|---|---|
| 1 | JWT lokal setelah verifikasi Google | Sesi server-side | Stateless, sederhana, cocok untuk satu layanan |
| 2 | Nginx di host, bukan container | Nginx sebagai container | Lebih sedikit lapisan; Certbot mudah; sesuai skala MVP |
| 3 | Notifikasi lokal, bukan push | FCM | Menghindari dependensi layanan push dan konfigurasi tambahan |
| 4 | Dialog berbasis aturan (tabel) | LLM | Sesuai batasan out-of-scope; hasil deterministik dan murah |
| 5 | SQLAlchemy + PyMySQL | Async driver | Sederhana; beban MVP tidak menuntut async DB |
| 6 | Port API hanya di localhost | Publikasi langsung | Mengurangi permukaan serangan; TLS terpusat di Nginx |
