import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app
from app.models import Achievement, User
from app.services.security import create_access_token


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(engine)


@pytest.fixture()
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def user(db_session):
    record = User(
        google_id="google-1",
        email="rani@example.com",
        name="Rani Putri",
        picture_url="https://example.com/a.png",
    )
    db_session.add(record)
    db_session.commit()
    db_session.refresh(record)
    return record


@pytest.fixture()
def auth_headers(user):
    token, _ = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def other_user(db_session):
    record = User(google_id="google-2", email="dimas@example.com", name="Dimas")
    db_session.add(record)
    db_session.commit()
    db_session.refresh(record)
    return record


@pytest.fixture()
def other_headers(other_user):
    token, _ = create_access_token(other_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def seed_achievements(db_session):
    rows = [
        Achievement(
            code="first_steps",
            name="Langkah Pertama",
            description="Selesaikan tugas pertamamu",
            icon="badge_first",
            criteria_type="total_completed",
            criteria_value=1,
        ),
        Achievement(
            code="task_10",
            name="Produktif",
            description="Selesaikan 10 tugas",
            icon="badge_ten",
            criteria_type="total_completed",
            criteria_value=10,
        ),
        Achievement(
            code="streak_3",
            name="Tiga Hari",
            description="Streak 3 hari berturut-turut",
            icon="badge_fire3",
            criteria_type="streak",
            criteria_value=3,
        ),
    ]
    db_session.add_all(rows)
    db_session.commit()
    return rows
