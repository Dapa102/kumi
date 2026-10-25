# Kumi — Aturan Repositori & Panduan Pengembangan

**Versi:** 1.0
**Berlaku untuk:** seluruh kontributor repositori Kumi

---

## 1. Prinsip Kolaborasi

1. **`main` selalu dapat dijalankan.** Tidak ada commit yang membuat build gagal.
2. **Perubahan kecil, PR kecil.** Satu PR menyelesaikan satu masalah.
3. **Secret tidak pernah masuk Git.** Tidak ada pengecualian.
4. **Kode dibaca lebih sering daripada ditulis.** Utamakan kejelasan.
5. **Setiap perbaikan bug disertai bukti.** Tes atau langkah reproduksi.

---

## 2. Strategi Percabangan

### 2.1 Struktur branch

| Branch | Peran | Aturan |
|---|---|---|
| `main` | Produksi, selalu stabil | Hanya menerima merge dari `development` atau `hotfix/*` |
| `development` | Integrasi fitur | Menerima merge dari `feature/*` dan `fix/*` |
| `feature/<scope>-<deskripsi>` | Fitur baru | Bercabang dari `development` |
| `fix/<scope>-<deskripsi>` | Perbaikan bug non-darurat | Bercabang dari `development` |
| `hotfix/<deskripsi>` | Perbaikan darurat produksi | Bercabang dari `main`, merge ke `main` **dan** `development` |
| `docs/<deskripsi>` | Dokumentasi saja | Bercabang dari `development` |

### 2.2 Penamaan branch

Format: `<tipe>/<scope>-<deskripsi-singkat>`

| Contoh | Keterangan |
|---|---|
| `feature/auth-google-signin` | Login Google |
| `feature/tasks-crud` | CRUD tugas |
| `feature/kumi-mascot-dialog` | Micro-interaction |
| `fix/tasks-streak-double-count` | Perbaikan streak |
| `docs/api-contract` | Dokumentasi |
| `hotfix/login-500` | Darurat |

Aturan: huruf kecil, kata dipisah tanda hubung, maksimum 5 kata, tanpa spasi/karakter khusus.

### 2.3 Alur kerja

```bash
git checkout development
git pull origin development
git checkout -b feature/tasks-crud
# ... kerja ...
git add -A
git commit -m "feat(tasks): add create and list endpoints"
git push -u origin feature/tasks-crud
```

Buka Pull Request ke `development`. Setelah review dan CI hijau, merge dengan **squash merge** agar riwayat `development` tetap linier.

### 2.4 Aturan merge

| Ke | Dari | Metode |
|---|---|---|
| `development` | `feature/*`, `fix/*`, `docs/*` | Squash merge |
| `main` | `development` | Merge commit (menandai rilis) |
| `main` | `hotfix/*` | Squash merge, lalu cherry-pick ke `development` |

Setelah merge, hapus branch sumber (kecuali `hotfix` sampai cherry-pick selesai).

### 2.5 Konvensi commit

Mengikuti Conventional Commits:

```
<tipe>(<scope>): <deskripsi singkat>

[body opsional: alasan perubahan]

[footer opsional: refs #12]
```

| Tipe | Penggunaan |
|---|---|
| `feat` | Fitur baru |
| `fix` | Perbaikan bug |
| `docs` | Dokumentasi |
| `refactor` | Perubahan struktur tanpa mengubah perilaku |
| `test` | Menambah/memperbaiki tes |
| `chore` | Build, dependensi, konfigurasi |
| `style` | Formatting tanpa perubahan logika |

Contoh:

```
feat(auth): exchange Google ID token for local JWT
fix(tasks): prevent double streak increment on same day
docs(deploy): add certbot renewal verification step
```

Aturan: subjek ≤ 72 karakter, imperatif, tanpa titik di akhir.

### 2.6 Versioning & tag

- Rilis ditandai tag `v<major>.<minor>.<patch>` pada `main`.
- MVP: `v1.0.0`.

---

## 3. Manajemen Keamanan & Secret

### 3.1 Aturan utama

> **Tidak ada secret di repositori.** Tidak di kode, tidak di test, tidak di dokumentasi, tidak di commit message, tidak di screenshot.

### 3.2 File yang wajib di-ignore

`.gitignore` root harus memuat:

```gitignore
# Environment
.env
.env.*
!.env.example
**/.env
**/.env.*
!**/.env.example

# Python
__pycache__/
*.py[cod]
.venv/
venv/
.pytest_cache/
.coverage
htmlcov/

# Flutter/Dart
.dart_tool/
build/
*.iml
.idea/

# OS
.DS_Store

# Logs & backup
*.log
*.sql.gz
backup*.sql
```

Verifikasi sebelum commit:

```bash
git status --short
git check-ignore -v deploy/.env
```

### 3.3 Daftar secret & penanganan

| Secret | Lokasi | Rotasi |
|---|---|---|
| `JWT_SECRET` | `deploy/.env` | Bila mencurigakan; mencabut semua sesi |
| `MARIADB_ROOT_PASSWORD` | `deploy/.env` | Tahunan |
| `MARIADB_PASSWORD` | `deploy/.env` | Tahunan |
| `GOOGLE_CLIENT_ID` | `deploy/.env` + konfigurasi Flutter | Bukan rahasia, tetapi tetap dikelola lewat konfigurasi |
| Keystore Android (`.jks`) | Di luar repo | Jangan pernah commit |

### 3.4 Bila secret terlanjur ter-commit

1. **Segera rotasi** secret tersebut (anggap sudah bocor).
2. Hapus dari riwayat dengan `git filter-repo` (bukan `git rm` biasa).
3. Force-push dan minta semua kontributor clone ulang.
4. Catat insiden secara singkat di PR/issue terkait (tanpa menulis nilai secret).

Perintah rotasi `JWT_SECRET`:

```bash
openssl rand -hex 32
```

Lalu perbarui `deploy/.env`, jalankan `docker compose up -d api`. Semua token lama otomatis tidak valid.

### 3.5 Konfigurasi Flutter

Jangan menaruh nilai sensitif di `lib/`. `GOOGLE_CLIENT_ID` bukan rahasia, tetapi tetap dikelola lewat:

```bash
flutter run --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
```

atau file `--dart-define-from-file=env.json` yang di-ignore.

### 3.6 Praktik aman tambahan

- Aktifkan **secret scanning** dan **push protection** di GitHub.
- Wajibkan review minimal 1 orang untuk PR ke `main`.
- Aktifkan branch protection: tidak bisa push langsung ke `main`/`development`.
- Jangan menempelkan token asli pada issue, PR, atau chat. Gunakan placeholder.
- Log backend tidak boleh memuat header `Authorization` atau ID Token.

---

## 4. Standar Kode

### 4.1 Dart / Flutter

**Penamaan:**

| Entitas | Gaya | Contoh |
|---|---|---|
| File | `snake_case.dart` | `task_card.dart`, `auth_repository.dart` |
| Class / Enum | `UpperCamelCase` | `TaskCard`, `AuthState` |
| Variabel / method | `lowerCamelCase` | `dueTime`, `fetchTasks()` |
| Konstanta | `lowerCamelCase` | `defaultPadding` |
| Private | awalan `_` | `_isLoading` |

**Struktur:**

```
lib/
├── core/
│   ├── config/          # base url, flavor
│   ├── network/         # dio client, interceptors
│   ├── storage/         # secure storage wrapper
│   └── theme/           # tokens, text styles
├── features/
│   ├── auth/
│   │   ├── data/        # repository, api
│   │   ├── domain/      # model
│   │   └── presentation/ # screen, widget, controller
│   ├── home/
│   ├── tasks/
│   └── profile/
└── main.dart
```

**Aturan:**

- Satu widget publik per file; widget privat boleh menyertai.
- `const` digunakan bila memungkinkan (`prefer_const_constructors`).
- Tidak ada `print()`; gunakan `debugPrint` atau logger.
- Tidak ada logika bisnis di `build()`.
- State management: satu pilihan untuk seluruh proyek (`provider` atau `riverpod`), tidak dicampur.
- Analisis wajib bersih: `flutter analyze` tanpa warning.
- Format: `dart format .` sebelum commit.

**Contoh gaya:**

```dart
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(task.title),
        subtitle: Text(formatDue(task.dueTime)),
      ),
    );
  }
}
```

### 4.2 Python / FastAPI

**Penamaan:**

| Entitas | Gaya | Contoh |
|---|---|---|
| File/modul | `snake_case.py` | `task_service.py` |
| Class | `UpperCamelCase` | `TaskService` |
| Fungsi/variabel | `snake_case` | `get_current_user`, `due_time` |
| Konstanta | `UPPER_SNAKE_CASE` | `MAX_TITLE_LENGTH` |
| Private | awalan `_` | `_build_query()` |

**Struktur:**

```
backend/app/
├── main.py          # app factory, middleware, router include
├── config.py        # Settings (pydantic-settings)
├── database.py      # engine, SessionLocal, Base
├── deps.py          # get_db, get_current_user
├── models/          # SQLAlchemy models
├── schemas/         # Pydantic schemas
├── routers/         # endpoint per domain
└── services/        # logika bisnis (auth, streak, achievement)
```

**Aturan:**

- Type hint wajib pada signature fungsi publik.
- Router hanya menangani HTTP (parse, panggil service, bentuk respons). Logika bisnis di `services/`.
- Akses DB lewat dependency `get_db`, bukan session global.
- Query selalu difilter `user_id` dari token.
- Tidak ada `SELECT *`; sebutkan kolom via ORM.
- Error memakai `HTTPException` dengan bentuk `detail` sesuai kontrak API.
- Format & lint: `ruff format .` dan `ruff check .`; tipe: `mypy app` (opsional untuk MVP tetapi dianjurkan).

**Contoh gaya:**

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.task import TaskCreate, TaskOut
from app.services import task_service

router = APIRouter(prefix="/api/v1/tasks", tags=["tasks"])


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_task(
    payload: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    return task_service.create_task(db, current_user.id, payload)
```

### 4.3 Konfigurasi lint

`analysis_options.yaml` (Flutter) minimal memuat `include: package:flutter_lints/flutter.yaml` dan aturan tambahan:

```yaml
linter:
  rules:
    prefer_const_constructors: true
    always_declare_return_types: true
    avoid_print: true
```

`backend/pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]
```

---

## 5. Pengujian Otomatis

### 5.1 Piramida pengujian MVP

| Lapisan | Alat | Cakupan target |
|---|---|---|
| Unit (backend) | `pytest` | Service: streak, achievement, auth |
| API (backend) | `pytest` + `TestClient` | Semua endpoint dengan DB SQLite in-memory |
| Widget (Flutter) | `flutter_test` | Widget kunci: TaskCard, validasi form |
| Manual | Checklist PRD | Alur end-to-end di perangkat |

### 5.2 Setup pytest

`backend/requirements-dev.txt`:

```text
pytest==8.3.3
httpx==0.27.2
```

`backend/tests/conftest.py`:

```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base
from app.deps import get_db
from app.main import app


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(engine)


@pytest.fixture()
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
```

`backend/tests/test_tasks.py`:

```python
def test_create_task_requires_auth(client):
    response = client.post("/api/v1/tasks", json={"title": "A", "due_time": "2030-01-01T00:00:00Z"})
    assert response.status_code == 401


def test_create_task_rejects_empty_title(client, auth_headers):
    response = client.post(
        "/api/v1/tasks",
        json={"title": "   ", "due_time": "2030-01-01T00:00:00Z"},
        headers=auth_headers,
    )
    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "VALIDATION_ERROR"


def test_create_task_success(client, auth_headers):
    response = client.post(
        "/api/v1/tasks",
        json={"title": "Revisi Bab 3", "due_time": "2030-01-01T00:00:00Z"},
        headers=auth_headers,
    )
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Revisi Bab 3"
    assert body["is_completed"] is False
    assert body["completed_at"] is None
```

`backend/tests/test_streak.py`:

```python
from datetime import date, timedelta


def test_streak_increments_on_consecutive_days(complete_task, user):
    complete_task(user, day=date(2026, 10, 18))
    complete_task(user, day=date(2026, 10, 19))
    assert user.current_streak == 2


def test_streak_resets_after_gap(complete_task, user):
    complete_task(user, day=date(2026, 10, 15))
    complete_task(user, day=date(2026, 10, 19))
    assert user.current_streak == 1


def test_multiple_tasks_same_day_count_once(complete_task, user):
    complete_task(user, day=date(2026, 10, 19))
    complete_task(user, day=date(2026, 10, 19))
    assert user.current_streak == 1
```

`backend/tests/test_achievements.py`:

```python
def test_first_steps_awarded_once(client, auth_headers, seed_achievements):
    for _ in range(2):
        task = client.post(
            "/api/v1/tasks",
            json={"title": "T", "due_time": "2030-01-01T00:00:00Z"},
            headers=auth_headers,
        ).json()
        client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=auth_headers)

    badges = client.get("/api/v1/achievements", headers=auth_headers).json()["items"]
    earned = [b for b in badges if b["code"] == "first_steps" and b["earned"]]
    assert len(earned) == 1
```

### 5.3 Menjalankan tes

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pytest -q
```

Target MVP: seluruh tes lulus dan mencakup minimal:

- Auth: token tidak valid → 401
- Tasks: create, list filter, update, delete, complete
- Isolasi data: pengguna A tidak dapat mengakses tugas pengguna B
- Streak: berturut-turut, putus, duplikat hari yang sama
- Achievement: diberikan sekali, tidak duplikat

### 5.4 Tes Flutter

```bash
flutter test
flutter analyze
```

Contoh widget test:

```dart
testWidgets('TaskCard shows strikethrough when completed', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TaskCard(
          task: Task(id: 1, title: 'Belajar', isCompleted: true, dueTime: DateTime.now()),
          onToggle: () {},
        ),
      ),
    ),
  );

  final text = tester.widget<Text>(find.text('Belajar'));
  expect(text.style?.decoration, TextDecoration.lineThrough);
});
```

### 5.5 CI (GitHub Actions)

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main, development]
  push:
    branches: [main, development]

jobs:
  backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: ruff check .
      - run: pytest -q

  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test
```

Aturan: PR tidak boleh di-merge bila CI merah.

---

## 6. Template Pull Request

`.github/pull_request_template.md`:

```markdown
## Ringkasan
<!-- Apa yang berubah dan mengapa -->

## Jenis perubahan
- [ ] feat
- [ ] fix
- [ ] docs
- [ ] refactor
- [ ] test
- [ ] chore

## Cara menguji
1.
2.

## Checklist
- [ ] `flutter analyze` bersih
- [ ] `pytest` lulus
- [ ] Tidak ada secret baru di diff
- [ ] Dokumentasi diperbarui bila kontrak API berubah
- [ ] Diuji di perangkat/emulator
```

---

## 7. Review Checklist

| Area | Yang diperiksa |
|---|---|
| Keamanan | Tidak ada secret, token tidak di-log, query terfilter `user_id` |
| Kontrak API | Perubahan endpoint disertai pembaruan `docs/04-api-contract.md` |
| Basis data | Perubahan skema disertai pembaruan `docs/03-database-erd.md` |
| Error handling | Kasus gagal jaringan dan 401 ditangani |
| UI | State loading, kosong, dan error tersedia |
| Tes | Logika baru memiliki tes atau alasan eksplisit mengapa tidak |
| Gaya | Mengikuti konvensi penamaan dan struktur folder |

---

## 8. Dokumentasi

| Dokumen | Isi | Pembaruan wajib saat |
|---|---|---|
| `docs/BRD.md` | BRD | Lingkup bisnis atau acceptance criteria berubah |
| `docs/PRD.md` | PRD | Lingkup produk atau acceptance criteria berubah |
| `docs/02-architecture-deployment.md` | Arsitektur & deploy | Topologi, container, atau langkah deploy berubah |
| `docs/03-database-erd.md` | Skema & ERD | Migrasi/kolom/indeks berubah |
| `docs/04-api-contract.md` | Kontrak API | Endpoint, field, atau status code berubah |
| `docs/05-ui-ux-wireframe.md` | Wireframe & flow | Layar atau interaksi berubah |
| `docs/06-repo-guidelines.md` | Aturan repo | Proses atau standar berubah |
| `README.md` | Cara menjalankan | Perintah setup berubah |

Aturan: **kode dan dokumen berubah dalam PR yang sama.** PR yang mengubah kontrak tanpa memperbarui dokumentasi ditolak.

---

## 9. Definition of Done (PR)

1. Kode berjalan lokal dan sesuai acceptance criteria terkait.
2. `flutter analyze` dan `pytest` lulus.
3. Tidak ada secret pada diff (`git diff --cached` diperiksa).
4. Dokumentasi terkait diperbarui.
5. Minimal satu reviewer menyetujui.
6. CI hijau.
7. Branch sumber dihapus setelah merge.

---

## 10. Quick Reference

```bash
# Flutter
flutter pub get
flutter run
flutter analyze
flutter test
dart format .

# Backend lokal
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
uvicorn app.main:app --reload
pytest -q

# Docker
cd deploy
cp .env.example .env
docker compose up -d --build
docker compose logs -f api
docker compose down

# Git
git checkout -b feature/<scope>-<deskripsi>
git commit -m "feat(<scope>): <deskripsi>"
git push -u origin HEAD
```
