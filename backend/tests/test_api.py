
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def register_user():
    email = f"{uuid4().hex}@example.com"
    password = "Secure-test-password-123"

    response = client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )
    assert response.status_code == 201

    login = client.post(
        "/api/auth/login",
        json={"email": email, "password": password},
    )
    assert login.status_code == 200

    token = login.json()["access_token"]
    return email, {"Authorization": f"Bearer {token}"}


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
    assert login.json()["token_type"] == "bearer"

    invalid_login = client.post(
        "/api/auth/login",
        json={"email": email, "password": "wrong-password"},
    )
    assert invalid_login.status_code == 401


def test_journal_requires_authentication():
    response = client.get(
        "/api/entries",
        headers={"Cookie": ""},
    )

    assert response.status_code == 401

def test_create_list_update_and_delete_entry():
    _, headers = register_user()
    payload = {
        "title": "Rainy afternoon",
        "content": "Worked on my portfolio project.",
        "mood": "focused",
        "weather": "Rainy",
    }

    created = client.post("/api/entries", json=payload, headers=headers)
    assert created.status_code == 201

    entry = created.json()
    entry_id = entry["id"]
    assert entry["title"] == payload["title"]

    listed = client.get("/api/entries", headers=headers)
    assert listed.status_code == 200
    assert any(item["id"] == entry_id for item in listed.json())

    updated = client.patch(
        f"/api/entries/{entry_id}",
        json={"title": "Productive rainy afternoon"},
        headers=headers,
    )
    assert updated.status_code == 200
    assert updated.json()["title"] == "Productive rainy afternoon"

    deleted = client.delete(f"/api/entries/{entry_id}", headers=headers)
    assert deleted.status_code == 204

    missing = client.get(f"/api/entries/{entry_id}", headers=headers)
    assert missing.status_code == 404


def test_users_cannot_access_each_others_entries():
    _, owner_headers = register_user()
    _, other_headers = register_user()

    created = client.post(
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

    other_entries = client.get("/api/entries", headers=other_headers)
    assert other_entries.status_code == 200
    assert all(item["id"] != entry_id for item in other_entries.json())

    response = client.get(
        f"/api/entries/{entry_id}",
        headers=other_headers,
    )
    assert response.status_code == 404

    response = client.patch(
        f"/api/entries/{entry_id}",
        json={"title": "Unauthorized edit"},
        headers=other_headers,
    )
    assert response.status_code == 404

    response = client.delete(
        f"/api/entries/{entry_id}",
        headers=other_headers,
    )
    assert response.status_code == 404


def test_rejects_empty_title():
    _, headers = register_user()

    response = client.post(
        "/api/entries",
        json={"title": "", "content": "This should fail"},
        headers=headers,
    )
    assert response.status_code == 422
