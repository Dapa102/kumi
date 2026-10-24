from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient


def _future(days: int = 1) -> str:
    return (datetime.now(timezone.utc) + timedelta(days=days)).isoformat().replace("+00:00", "Z")


def _create(client: TestClient, headers: dict, title: str = "Revisi Bab 3") -> dict:
    response = client.post(
        "/api/v1/tasks", json={"title": title, "due_time": _future()}, headers=headers
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_create_task_requires_auth(client):
    response = client.post("/api/v1/tasks", json={"title": "A", "due_time": _future()})
    assert response.status_code == 401
    assert response.json()["detail"]["code"] == "UNAUTHORIZED"


def test_create_task_rejects_blank_title(client, auth_headers):
    response = client.post(
        "/api/v1/tasks", json={"title": "   ", "due_time": _future()}, headers=auth_headers
    )
    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "VALIDATION_ERROR"


def test_create_task_rejects_past_due_time(client, auth_headers):
    past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat().replace("+00:00", "Z")
    response = client.post(
        "/api/v1/tasks", json={"title": "Telat", "due_time": past}, headers=auth_headers
    )
    assert response.status_code == 422
    assert "due_time" in response.json()["detail"]["fields"]


def test_create_task_success(client, auth_headers):
    body = _create(client, auth_headers)
    assert body["title"] == "Revisi Bab 3"
    assert body["is_completed"] is False
    assert body["completed_at"] is None
    assert body["due_time"].endswith("Z")


def test_list_tasks_only_returns_own_tasks(client, auth_headers, other_headers):
    _create(client, auth_headers, "Milik Rani")
    _create(client, other_headers, "Milik Dimas")

    response = client.get("/api/v1/tasks", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["title"] == "Milik Rani"


def test_list_tasks_status_filter(client, auth_headers):
    pending = _create(client, auth_headers, "Belum")
    done = _create(client, auth_headers, "Sudah")
    client.patch(f"/api/v1/tasks/{done['id']}/complete", headers=auth_headers)

    completed = client.get("/api/v1/tasks?status=completed", headers=auth_headers).json()
    assert [item["id"] for item in completed["items"]] == [done["id"]]

    still_pending = client.get("/api/v1/tasks?status=pending", headers=auth_headers).json()
    assert [item["id"] for item in still_pending["items"]] == [pending["id"]]


def test_update_task(client, auth_headers):
    task = _create(client, auth_headers)
    response = client.put(
        f"/api/v1/tasks/{task['id']}",
        json={"title": "Revisi Bab 3 dan 4", "description": "Tambah hasil uji", "due_time": _future(2)},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["title"] == "Revisi Bab 3 dan 4"


def test_delete_task(client, auth_headers):
    task = _create(client, auth_headers)
    response = client.delete(f"/api/v1/tasks/{task['id']}", headers=auth_headers)
    assert response.status_code == 204
    assert client.get(f"/api/v1/tasks/{task['id']}", headers=auth_headers).status_code == 404


def test_cannot_touch_other_users_task(client, auth_headers, other_headers):
    task = _create(client, auth_headers)

    assert client.get(f"/api/v1/tasks/{task['id']}", headers=other_headers).status_code == 404
    assert client.delete(f"/api/v1/tasks/{task['id']}", headers=other_headers).status_code == 404
    assert (
        client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=other_headers).status_code
        == 404
    )


def test_complete_toggle(client, auth_headers):
    task = _create(client, auth_headers)

    done = client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=auth_headers).json()
    assert done["is_completed"] is True
    assert done["completed_at"] is not None

    undone = client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=auth_headers).json()
    assert undone["is_completed"] is False
    assert undone["completed_at"] is None


def test_complete_is_idempotent_when_target_given(client, auth_headers):
    task = _create(client, auth_headers)
    first = client.patch(
        f"/api/v1/tasks/{task['id']}/complete", json={"is_completed": True}, headers=auth_headers
    ).json()
    second = client.patch(
        f"/api/v1/tasks/{task['id']}/complete", json={"is_completed": True}, headers=auth_headers
    ).json()
    assert first["completed_at"] == second["completed_at"]
