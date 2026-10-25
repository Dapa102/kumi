from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import AuthResponse, GoogleAuthRequest, UserPublic
from app.services.security import (
    EmailNotVerified,
    InvalidGoogleToken,
    create_access_token,
    verify_google_token,
)

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/google", response_model=AuthResponse)
def google_login(payload: GoogleAuthRequest, db: Session = Depends(get_db)) -> AuthResponse:
    try:
        info = verify_google_token(payload.id_token)
    except EmailNotVerified as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "code": "EMAIL_NOT_VERIFIED",
                "message": "Email Google belum terverifikasi.",
            },
        ) from exc
    except InvalidGoogleToken as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_GOOGLE_TOKEN", "message": "Token Google tidak valid."},
        ) from exc

    user = db.scalar(select(User).where(User.google_id == info.google_id))
    is_new_user = user is None

    if user is None:
        user = User(
            google_id=info.google_id,
            email=info.email,
            name=info.name,
            picture_url=info.picture_url,
        )
        db.add(user)
    else:
        # Keep the name the user may have edited; refresh contact data from Google.
        user.email = info.email
        user.picture_url = info.picture_url

    db.commit()
    db.refresh(user)

    token, expires_in = create_access_token(user.id)
    return AuthResponse(
        access_token=token,
        expires_in=expires_in,
        is_new_user=is_new_user,
        user=UserPublic.model_validate(user),
    )
