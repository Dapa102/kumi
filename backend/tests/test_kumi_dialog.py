from datetime import datetime, timedelta, timezone

from app.models import KumiDialog


def _future(days: int = 1) -> str:
    return (datetime.now(timezone.utc) + timedelta(days=days)).isoformat().replace("+00:00", "Z")


def test_dialog_requires_auth(client):
    assert client.get("/api/v1/kumi/dialog").status_code == 401


def test_dialog_returns_matching_context(client, db_session, auth_headers):
    db_session.add_all(
        [
            KumiDialog(context="morning", text="Pagi!"),
            KumiDialog(context="night", text="Malam!"),
        ]
    )
    db_session.commit()

    response = client.get("/api/v1/kumi/dialog?context=morning", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["context"] == "morning"


def test_dialog_excludes_id_when_alternatives_exist(client, db_session, auth_headers):
    first = KumiDialog(context="idle", text="Satu")
    second = KumiDialog(context="idle", text="Dua")
    db_session.add_all([first, second])
    db_session.commit()

    response = client.get(
        f"/api/v1/kumi/dialog?context=idle&exclude_id={first.id}", headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["id"] == second.id


def test_dialog_unknown_context(client, auth_headers):
    response = client.get("/api/v1/kumi/dialog?context=evening", headers=auth_headers)
    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "VALIDATION_ERROR"


def test_dialog_empty_context_returns_404(client, auth_headers):
    response = client.get("/api/v1/kumi/dialog?context=morning", headers=auth_headers)
    assert response.status_code == 404
    assert response.json()["detail"]["code"] == "NOT_FOUND"


def test_dialog_defaults_to_time_based_context(client, db_session, auth_headers):
    for context in ("morning", "afternoon", "night"):
        db_session.add(KumiDialog(context=context, text=f"{context} text"))
    db_session.commit()

    response = client.get("/api/v1/kumi/dialog", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["context"] in {"morning", "afternoon", "night"}
