
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def register_user(test_client=client):
    email = f"{uuid4().hex}@example.com"
    password = "Secure-test-password-123"

    response = test_client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )
    assert response.status_code == 201

    login = test_client.post(
        "/api/auth/login",
        json={"email": email, "password": password},
    )
    assert login.status_code == 200

    csrf_token = test_client.cookies.get("weather_journal_csrf")
    assert csrf_token

    headers = {"X-CSRF-Token": csrf_token}
    return email, headers


def test_health_endpoint():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_register_and_login():
    email = f"{uuid4().hex}@example.com"
    password = "Secure-test-password-123"

    registered = client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )
    assert registered.status_code == 201
    assert registered.json()["email"] == email
    assert "hashed_password" not in registered.json()

    duplicate = client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )
    assert duplicate.status_code == 409

    login = client.post(
        "/api/auth/login",
        json={"email": email, "password": password},
    )
    assert login.status_code == 200
    assert login.json()["email"] == email
    assert "access_token" not in login.json()
    assert "token_type" not in login.json()
    assert "weather_journal_session" in login.cookies
    assert "weather_journal_csrf" in login.cookies

    invalid_login = client.post(
        "/api/auth/login",
        json={"email": email, "password": "wrong-password"},
    )
    assert invalid_login.status_code == 401


def test_journal_requires_authentication():
    with TestClient(app) as unauthenticated_client:
        response = unauthenticated_client.get("/api/entries")

    assert response.status_code == 401


def test_create_list_update_and_delete_entry():
    _, headers = register_user()

    payload = {
        "title": "Rainy afternoon",
        "content": "Worked on my portfolio project.",
        "mood": "focused",
        "weather": "Rainy",
    }

    created = client.post(
        "/api/entries",
        json=payload,
        headers=headers,
    )
    assert created.status_code == 201

    entry = created.json()
    entry_id = entry["id"]
    assert entry["title"] == payload["title"]

    listed = client.get("/api/entries")
    assert listed.status_code == 200
    assert any(item["id"] == entry_id for item in listed.json())

    updated = client.patch(
        f"/api/entries/{entry_id}",
        json={"title": "Productive rainy afternoon"},
        headers=headers,
    )
    assert updated.status_code == 200
    assert updated.json()["title"] == "Productive rainy afternoon"

    deleted = client.delete(
        f"/api/entries/{entry_id}",
        headers=headers,
    )
    assert deleted.status_code == 204

    missing = client.get(f"/api/entries/{entry_id}")
    assert missing.status_code == 404


def test_users_cannot_access_each_others_entries():
    with (
        TestClient(app) as owner_client,
        TestClient(app) as other_client,
    ):
        owner_email, owner_headers = register_user(owner_client)
        other_email, other_headers = register_user(other_client)

        assert owner_email != other_email

        created = owner_client.post(
            "/api/entries",
            json={
                "title": "Private note",
                "content": "This belongs to the first user.",
                "mood": "neutral",
                "weather": "Cloudy",
            },
            headers=owner_headers,
        )
        assert created.status_code == 201
        entry_id = created.json()["id"]

        owner_entries = owner_client.get("/api/entries")
        assert owner_entries.status_code == 200
        assert any(
            item["id"] == entry_id
            for item in owner_entries.json()
        )

        other_entries = other_client.get("/api/entries")
        assert other_entries.status_code == 200
        assert all(
            item["id"] != entry_id
            for item in other_entries.json()
        )

        forbidden = other_client.get(f"/api/entries/{entry_id}")
        assert forbidden.status_code in (403, 404)


def test_rejects_empty_title():
    _, headers = register_user()

    response = client.post(
        "/api/entries",
        json={
            "title": "",
            "content": "This should fail",
        },
        headers=headers,
    )

    assert response.status_code == 422

def test_authenticated_write_without_csrf_token_is_rejected():
    with TestClient(app) as test_client:
        register_user(test_client)

        # The session cookie remains present, but the request
        # deliberately omits the X-CSRF-Token header.
        response = test_client.post(
            "/api/entries",
            json={
                "title": "CSRF protection test",
                "content": "This request should be rejected.",
                "mood": "neutral",
                "weather": "Cloudy",
            },
        )

        assert "weather_journal_session" in test_client.cookies
        assert response.status_code == 403
