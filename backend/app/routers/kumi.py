import random
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import DIALOG_CONTEXTS, KumiDialog, User
from app.schemas import DialogOut

router = APIRouter(prefix="/api/v1/kumi", tags=["kumi"])


def _context_from_hour(hour: int) -> str:
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 18:
        return "afternoon"
    return "night"


@router.get("/dialog", response_model=DialogOut)
def get_dialog(
    context: str | None = Query(default=None),
    exclude_id: int | None = Query(default=None, ge=1),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DialogOut:
    del current_user  # auth is required, dialog content is not user specific

    if context is None:
        context = _context_from_hour(datetime.now(UTC).hour)

    if context not in DIALOG_CONTEXTS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "VALIDATION_ERROR",
                "message": "Data tidak valid.",
                "fields": {"context": "Nilai harus salah satu dari: " + ", ".join(DIALOG_CONTEXTS)},
            },
        )

    candidates = db.scalars(
        select(KumiDialog).where(KumiDialog.context == context, KumiDialog.is_active.is_(True))
    ).all()

    if not candidates:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "NOT_FOUND", "message": "Dialog tidak tersedia."},
        )

    if exclude_id is not None and len(candidates) > 1:
        candidates = [dialog for dialog in candidates if dialog.id != exclude_id]

    return DialogOut.model_validate(random.choice(candidates))
