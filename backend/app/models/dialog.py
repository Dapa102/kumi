from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import DIALOG_CONTEXTS, Base, BigIntPK, utcnow


class KumiDialog(Base):
    __tablename__ = "kumi_dialogs"

    id: Mapped[int] = mapped_column(BigIntPK, primary_key=True, autoincrement=True)
    context: Mapped[str] = mapped_column(
        Enum(*DIALOG_CONTEXTS, name="dialog_context"), nullable=False, index=True
    )
    text: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=utcnow)
