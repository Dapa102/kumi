# Kumi

Aplikasi *daily companion* untuk manajemen tugas mahasiswa dan pekerja muda.
Aplikasi Flutter (`lib/`) dengan backend FastAPI (`backend/`), database MySQL/MariaDB,
dan deployment Docker Compose (`deploy/`).

## Prasyarat

- Flutter 3.47+ / Dart 3.13+
- Python 3.12+
- Docker & Docker Compose (opsional, untuk deployment)

## Menjalankan aplikasi Flutter

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
```

`API_BASE_URL` default `http://10.0.2.2:8000` (emulator Android).
`GOOGLE_CLIENT_ID` wajib diisi agar login Google berfungsi; jangan menyimpan nilai
sensitif di dalam `lib/`.

Perintah kualitas kode:

```bash
dart format .
flutter analyze
flutter test
```

## Menjalankan backend secara lokal

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
cp .env.example .env   # wajib; isi JWT_SECRET hasil `openssl rand -hex 32`
uvicorn app.main:app --reload
```

`JWT_SECRET` wajib diisi minimal 32 karakter — API menolak start jika kosong.
Achievement dan dialog awal di-seed otomatis saat startup (`AUTO_SEED=true`, idempotent).

Tes dan lint backend:

```bash
cd backend
pytest -q
ruff check .
ruff format .
```

## Deployment (Docker Compose)

```bash
cd deploy
cp .env.example .env   # isi seluruh nilai; JWT_SECRET hasil `openssl rand -hex 32`
docker compose up -d --build
docker compose logs -f api
docker compose down
```

Compose menolak start jika `JWT_SECRET` atau password MariaDB belum diisi.
Jangan pernah meng-commit `deploy/.env` atau nilai secret apa pun.

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [`docs/BRD.md`](docs/BRD.md) | Business Requirements Document (BRD) |
| [`docs/PRD.md`](docs/PRD.md) | Product Requirements Document (PRD) |
| [`docs/02-architecture-deployment.md`](docs/02-architecture-deployment.md) | Arsitektur & deployment |
| [`docs/03-database-erd.md`](docs/03-database-erd.md) | Skema & ERD |
| [`docs/04-api-contract.md`](docs/04-api-contract.md) | Kontrak API |
| [`docs/05-ui-ux-wireframe.md`](docs/05-ui-ux-wireframe.md) | Wireframe & flow |
| [`docs/06-repo-guidelines.md`](docs/06-repo-guidelines.md) | Aturan repositori |

## Kontribusi

Ikuti [`docs/06-repo-guidelines.md`](docs/06-repo-guidelines.md): branch
`feature/*`/`fix/*` dari `development`, Conventional Commits, dan PR dengan CI hijau.
