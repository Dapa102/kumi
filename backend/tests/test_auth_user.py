from datetime import UTC, datetime, timedelta

from app.services.security import create_access_token, decode_access_token


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["database"] == "ok"


def test_profile_returns_stats(client, auth_headers):
    response = client.get("/api/v1/user/profile", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["email"] == "rani@example.com"
    assert body["stats"]["total_tasks"] == 0
    assert body["stats"]["completion_rate"] == 0.0


def test_update_profile_name(client, auth_headers):
    response = client.put(
        "/api/v1/user/profile", json={"name": "  Rani P.  "}, headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Rani P."


def test_update_profile_rejects_blank_name(client, auth_headers):
    response = client.put("/api/v1/user/profile", json={"name": "   "}, headers=auth_headers)
    assert response.status_code == 422
    assert "name" in response.json()["detail"]["fields"]


def test_profile_requires_token(client):
    assert client.get("/api/v1/user/profile").status_code == 401


def test_profile_rejects_bad_token(client):
    response = client.get("/api/v1/user/profile", headers={"Authorization": "Bearer not-a-token"})
    assert response.status_code == 401
    assert response.json()["detail"]["code"] == "UNAUTHORIZED"


def test_profile_rejects_expired_token(client, user):
    import jwt

    from app.config import settings

    expired = jwt.encode(
        {
            "sub": str(user.id),
            "iat": datetime.now(UTC) - timedelta(hours=1),
            "exp": datetime(2020, 1, 1, tzinfo=UTC),
        },
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )
    response = client.get("/api/v1/user/profile", headers={"Authorization": f"Bearer {expired}"})
    assert response.status_code == 401
    assert response.json()["detail"]["code"] == "TOKEN_EXPIRED"


def test_token_roundtrip(user):
    token, expires_in = create_access_token(user.id)
    assert expires_in > 0
    assert decode_access_token(token) == user.id


def test_google_login_rejects_invalid_token(client):
    response = client.post("/api/v1/auth/google", json={"id_token": "x" * 40})
    assert response.status_code == 401
    assert response.json()["detail"]["code"] == "INVALID_GOOGLE_TOKEN"
