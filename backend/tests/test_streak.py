from datetime import date, datetime, timedelta, timezone

from app.models import Task, utcnow


def _completed_task(db, user, when: datetime) -> Task:
    task = Task(
        user_id=user.id,
        title=f"Tugas {when.date()}",
        due_time=when,
        is_completed=True,
        completed_at=when,
    )
    db.add(task)
    db.commit()
    return task


def test_streak_increments_on_consecutive_days(client, db_session, user, auth_headers):
    today = utcnow()
    _completed_task(db_session, user, today - timedelta(days=1))
    task = Task(user_id=user.id, title="Hari ini", due_time=today, is_completed=False)
    db_session.add(task)
    db_session.commit()

    body = client.patch(f"/api/v1/tasks/{task.id}/complete", headers=auth_headers).json()
    assert body["gamification"]["current_streak"] == 2
    assert body["gamification"]["streak_increased"] is True


def test_streak_resets_after_gap(client, db_session, user, auth_headers):
    _completed_task(db_session, user, utcnow() - timedelta(days=5))
    task = Task(user_id=user.id, title="Hari ini", due_time=utcnow(), is_completed=False)
    db_session.add(task)
    db_session.commit()

    body = client.patch(f"/api/v1/tasks/{task.id}/complete", headers=auth_headers).json()
    assert body["gamification"]["current_streak"] == 1


def test_multiple_tasks_same_day_count_once(client, db_session, user, auth_headers):
    tasks = [
        Task(user_id=user.id, title=f"T{i}", due_time=utcnow(), is_completed=False)
        for i in range(2)
    ]
    db_session.add_all(tasks)
    db_session.commit()

    for task in tasks:
        body = client.patch(f"/api/v1/tasks/{task.id}/complete", headers=auth_headers).json()

    assert body["gamification"]["current_streak"] == 1


def test_uncomplete_recalculates_streak(client, db_session, user, auth_headers):
    yesterday = utcnow() - timedelta(days=1)
    _completed_task(db_session, user, yesterday)
    task = Task(user_id=user.id, title="Hari ini", due_time=utcnow(), is_completed=False)
    db_session.add(task)
    db_session.commit()

    client.patch(f"/api/v1/tasks/{task.id}/complete", headers=auth_headers)
    body = client.patch(
        f"/api/v1/tasks/{task.id}/complete", json={"is_completed": False}, headers=auth_headers
    ).json()

    # Only yesterday remains, so the streak is 1 rather than 0.
    assert body["gamification"]["current_streak"] == 1


def test_deleting_completed_task_updates_streak(client, db_session, user, auth_headers):
    task = Task(user_id=user.id, title="Satu-satunya", due_time=utcnow(), is_completed=False)
    db_session.add(task)
    db_session.commit()

    client.patch(f"/api/v1/tasks/{task.id}/complete", headers=auth_headers)
    client.delete(f"/api/v1/tasks/{task.id}", headers=auth_headers)

    profile = client.get("/api/v1/user/profile", headers=auth_headers).json()
    assert profile["current_streak"] == 0
