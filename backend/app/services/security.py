from datetime import datetime, timedelta, timezone

import jwt
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from app.config import settings


class InvalidGoogleToken(Exception):
    pass


class EmailNotVerified(Exception):
    pass


class GoogleUserInfo:
    __slots__ = ("google_id", "email", "name", "picture_url")

    def __init__(self, google_id: str, email: str, name: str, picture_url: str | None) -> None:
        self.google_id = google_id
        self.email = email
        self.name = name
        self.picture_url = picture_url


def verify_google_token(token: str) -> GoogleUserInfo:
    if not settings.google_client_id:
        raise InvalidGoogleToken("GOOGLE_CLIENT_ID is not configured")

    try:
        payload = google_id_token.verify_oauth2_token(
            token, google_requests.Request(), settings.google_client_id
        )
    except Exception as exc:  # noqa: BLE001 - library raises many error types
        raise InvalidGoogleToken(str(exc)) from exc

    if payload.get("iss") not in ("accounts.google.com", "https://accounts.google.com"):
        raise InvalidGoogleToken("Invalid issuer")

    if not payload.get("email_verified", False):
        raise EmailNotVerified("Email not verified")

    google_id = payload.get("sub")
    email = payload.get("email")
    if not google_id or not email:
        raise InvalidGoogleToken("Token missing sub or email")

    return GoogleUserInfo(
        google_id=google_id,
        email=email,
        name=payload.get("name") or email.split("@")[0],
        picture_url=payload.get("picture"),
    )


def create_access_token(user_id: int) -> tuple[str, int]:
    expires_in = settings.jwt_expire_days * 24 * 60 * 60
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(seconds=expires_in),
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, expires_in


def decode_access_token(token: str) -> int:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.ExpiredSignatureError as exc:
        raise TokenExpired from exc
    except jwt.PyJWTError as exc:
        raise InvalidToken from exc

    subject = payload.get("sub")
    if subject is None:
        raise InvalidToken("Missing subject")
    try:
        return int(subject)
    except (TypeError, ValueError) as exc:
        raise InvalidToken("Invalid subject") from exc


class TokenExpired(Exception):
    pass


class InvalidToken(Exception):
    pass
