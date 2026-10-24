from datetime import datetime, timedelta, timezone


def _future(days: int = 1) -> str:
    return (datetime.now(timezone.utc) + timedelta(days=days)).isoformat().replace("+00:00", "Z")


def _create(client, headers, title="Tugas"):
    return client.post(
        "/api/v1/tasks", json={"title": title, "due_time": _future()}, headers=headers
    ).json()


def test_first_steps_awarded_once(client, auth_headers, seed_achievements):
    for _ in range(2):
        task = _create(client, auth_headers)
        client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=auth_headers)

    badges = client.get("/api/v1/achievements", headers=auth_headers).json()["items"]
    earned = [b for b in badges if b["code"] == "first_steps" and b["earned"]]
    assert len(earned) == 1


def test_new_achievement_returned_on_completion(client, auth_headers, seed_achievements):
    task = _create(client, auth_headers)
    body = client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=auth_headers).json()

    codes = [item["code"] for item in body["gamification"]["new_achievements"]]
    assert codes == ["first_steps"]


def test_task_10_awarded_after_ten_completions(client, auth_headers, seed_achievements):
    for _ in range(10):
        task = _create(client, auth_headers)
        client.patch(f"/api/v1/tasks/{task['id']}/complete", headers=auth_headers)

    badges = client.get("/api/v1/achievements", headers=auth_headers).json()["items"]
    earned_codes = {b["code"] for b in badges if b["earned"]}
    assert {"first_steps", "task_10"} <= earned_codes


def test_achievement_list_includes_unearned(client, auth_headers, seed_achievements):
    body = client.get("/api/v1/achievements", headers=auth_headers).json()
    assert body["total"] == 3
    assert all(item["earned"] is False for item in body["items"])
