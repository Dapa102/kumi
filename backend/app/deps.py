from datetime import date, datetime, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.services.security import InvalidToken, TokenExpired, decode_access_token

bearer_scheme = HTTPBearer(auto_error=False)


def _unauthorized(code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"code": code, "message": message},
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("UNAUTHORIZED", "Autentikasi diperlukan.")

    try:
        user_id = decode_access_token(credentials.credentials)
    except TokenExpired:
        raise _unauthorized("TOKEN_EXPIRED", "Sesi berakhir, silakan masuk kembali.")
    except InvalidToken:
        raise _unauthorized("UNAUTHORIZED", "Autentikasi diperlukan.")

    user = db.get(User, user_id)
    if user is None:
        raise _unauthorized("UNAUTHORIZED", "Autentikasi diperlukan.")
    return user


def utc_today() -> date:
    return datetime.now(timezone.utc).date()
