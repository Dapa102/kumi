from app.schemas.common import ORMModel


class DialogOut(ORMModel):
    id: int
    context: str
    text: str
