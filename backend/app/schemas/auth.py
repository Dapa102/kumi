from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMModel, UtcDateTime


class GoogleAuthRequest(BaseModel):
    id_token: str = Field(min_length=20, max_length=4096)


class UserPublic(ORMModel):
    id: int
    email: EmailStr
    name: str
    picture_url: str | None = None
    current_streak: int
    created_at: UtcDateTime


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    is_new_user: bool
    user: UserPublic
