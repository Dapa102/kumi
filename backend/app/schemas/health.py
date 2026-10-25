from pydantic import BaseModel

from app.schemas.common import UtcDateTime


class HealthOut(BaseModel):
    status: str
    database: str
    version: str
    time: UtcDateTime
