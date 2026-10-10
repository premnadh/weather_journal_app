import os
from datetime import datetime, timedelta, timezone
from typing import Generator

import jwt
from fastapi import (
    Cookie,
    Depends,
    FastAPI,
    HTTPException,
    Response,
    status,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, Field, field_validator
from pwdlib import PasswordHash
from sqlalchemy import (
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    create_engine,
    inspect,
    text,
)
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    Session,
    mapped_column,
    sessionmaker,
)


# --------------------------------------------------
# Configuration
# --------------------------------------------------

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./weather_journal.db",
)

JWT_SECRET_KEY = os.getenv(
    "JWT_SECRET_KEY",
    "local-development-only-change-this-secret",
)

JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_MINUTES = 30

SESSION_COOKIE_NAME = "weather_journal_session"
SESSION_COOKIE_SECURE = (
    os.getenv("COOKIE_SECURE", "false").lower() == "true"
)
SESSION_COOKIE_SAMESITE = "lax"


engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
    if DATABASE_URL.startswith("sqlite")
    else {},
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
)

password_hash = PasswordHash.recommended()
bearer_scheme = HTTPBearer(auto_error=False)


# --------------------------------------------------
# Database models
# --------------------------------------------------

class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )
    email: Mapped[str] = mapped_column(
        String(254),
        unique=True,
        index=True,
        nullable=False,
    )
    hashed_password: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class JournalEntry(Base):
    __tablename__ = "journal_entries"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )
    title: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
    )
    content: Mapped[str] = mapped_column(
        Text,
        default="",
        nullable=False,
    )
    mood: Mapped[str] = mapped_column(
        String(40),
        default="neutral",
        nullable=False,
    )
    weather: Mapped[str] = mapped_column(
        String(80),
        default="",
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
        index=True,
    )


# Create new tables and migrate existing databases.
Base.metadata.create_all(bind=engine)

if "user_id" not in {
    column["name"]
    for column in inspect(engine).get_columns("journal_entries")
}:
    with engine.begin() as connection:
        connection.execute(
            text(
                "ALTER TABLE journal_entries "
                "ADD COLUMN user_id INTEGER"
            )
        )

with engine.begin() as connection:
    connection.execute(
        text(
            "CREATE INDEX IF NOT EXISTS ix_journal_entries_user_id "
            "ON journal_entries (user_id)"
        )
    )


# --------------------------------------------------
# FastAPI application
# --------------------------------------------------

app = FastAPI(
    title="Weather Journal API",
    description="A REST API for personal journal entries and weather notes.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --------------------------------------------------
# Request and response schemas
# --------------------------------------------------

class UserCreate(BaseModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        value = value.strip().lower()

        if (
            value.count("@") != 1
            or " " in value
            or "." not in value.rsplit("@", 1)[-1]
        ):
            raise ValueError("Enter a valid email address")

        return value


class UserLogin(BaseModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    created_at: datetime


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class EntryCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    content: str = Field(default="", max_length=10000)
    mood: str = Field(default="neutral", max_length=40)
    weather: str = Field(default="", max_length=80)


class EntryUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    content: str | None = Field(default=None, max_length=10000)
    mood: str | None = Field(default=None, max_length=40)
    weather: str | None = Field(default=None, max_length=80)


class EntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    content: str
    mood: str
    weather: str
    created_at: datetime


# --------------------------------------------------
# Database dependency
# --------------------------------------------------

def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# --------------------------------------------------
# Authentication helpers
# --------------------------------------------------

def create_access_token(user_id: int) -> str:
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_MINUTES
    )

    return jwt.encode(
        {
            "sub": str(user_id),
            "exp": expires_at,
        },
        JWT_SECRET_KEY,
        algorithm=JWT_ALGORITHM,
    )


def set_session_cookie(response: Response, token: str) -> None:
    response.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=token,
        httponly=True,
        secure=SESSION_COOKIE_SECURE,
        samesite=SESSION_COOKIE_SAMESITE,
        max_age=ACCESS_TOKEN_MINUTES * 60,
        path="/",
    )


def clear_session_cookie(response: Response) -> None:
    response.delete_cookie(
        key=SESSION_COOKIE_NAME,
        path="/",
        httponly=True,
        secure=SESSION_COOKIE_SECURE,
        samesite=SESSION_COOKIE_SAMESITE,
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        bearer_scheme
    ),
    session_cookie: str | None = Cookie(
        default=None,
        alias=SESSION_COOKIE_NAME,
    ),
    db: Session = Depends(get_db),
) -> User:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or missing authentication token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # Prefer a Bearer token when supplied; otherwise use the cookie.
    token = (
        credentials.credentials
        if credentials is not None
        else session_cookie
    )

    if not token:
        raise unauthorized

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET_KEY,
            algorithms=[JWT_ALGORITHM],
        )

        subject = payload.get("sub")

        if not isinstance(subject, str):
            raise unauthorized

        user_id = int(subject)

    except (jwt.InvalidTokenError, ValueError, TypeError):
        raise unauthorized from None

    user = db.get(User, user_id)

    if user is None:
        raise unauthorized

    return user


def get_owned_entry(
    entry_id: int,
    user: User,
    db: Session,
) -> JournalEntry:
    entry = (
        db.query(JournalEntry)
        .filter(
            JournalEntry.id == entry_id,
            JournalEntry.user_id == user.id,
        )
        .first()
    )

    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found",
        )

    return entry


# --------------------------------------------------
# Health
# --------------------------------------------------

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "weather-journal-api",
    }


# --------------------------------------------------
# Registration
# --------------------------------------------------

@app.post(
    "/api/auth/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_user(
    details: UserCreate,
    db: Session = Depends(get_db),
):
    existing_user = (
        db.query(User)
        .filter(User.email == details.email)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    user = User(
        email=details.email,
        hashed_password=password_hash.hash(details.password),
    )

    db.add(user)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        ) from None

    db.refresh(user)
    return user


# --------------------------------------------------
# Login
# --------------------------------------------------

@app.post("/api/auth/login", response_model=TokenResponse)
def login_user(
    details: UserLogin,
    response: Response,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(User.email == details.email)
        .first()
    )

    if user is None or not password_hash.verify(
        details.password,
        user.hashed_password,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token(user.id)

    # Establish the browser session.
    set_session_cookie(response, token)

    # Preserve compatibility with existing Bearer-token clients.
    return TokenResponse(
        access_token=token,
        user=user,
    )


# --------------------------------------------------
# Logout
# --------------------------------------------------

@app.post("/api/auth/logout")
def logout_user(response: Response):
    clear_session_cookie(response)

    return {"message": "Logged out successfully"}


# --------------------------------------------------
# Current user / session restoration
# --------------------------------------------------

@app.get("/api/auth/me", response_model=UserResponse)
def read_current_user(
    user: User = Depends(get_current_user),
):
    return user


# --------------------------------------------------
# Journal CRUD
# --------------------------------------------------

@app.get(
    "/api/entries",
    response_model=list[EntryResponse],
)
def list_entries(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(JournalEntry)
        .filter(JournalEntry.user_id == user.id)
        .order_by(JournalEntry.id.desc())
        .all()
    )


@app.post(
    "/api/entries",
    response_model=EntryResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_entry(
    entry: EntryCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    new_entry = JournalEntry(
        **entry.model_dump(),
        user_id=user.id,
    )

    db.add(new_entry)
    db.commit()
    db.refresh(new_entry)

    return new_entry


@app.get(
    "/api/entries/{entry_id}",
    response_model=EntryResponse,
)
def read_entry(
    entry_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_owned_entry(entry_id, user, db)


@app.patch(
    "/api/entries/{entry_id}",
    response_model=EntryResponse,
)
def update_entry(
    entry_id: int,
    updates: EntryUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    entry = get_owned_entry(entry_id, user, db)

    for field, value in updates.model_dump(
        exclude_unset=True
    ).items():
        if value is not None:
            setattr(entry, field, value)

    db.commit()
    db.refresh(entry)

    return entry


@app.delete(
    "/api/entries/{entry_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_entry(
    entry_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    entry = get_owned_entry(entry_id, user, db)

    db.delete(entry)
    db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)