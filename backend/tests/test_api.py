from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_create_list_update_and_delete_entry():
    payload = {
        "title": "Rainy afternoon",
        "content": "Worked on my portfolio project.",
        "mood": "focused",
        "weather": "Rainy",
    }

    created = client.post("/api/entries", json=payload)
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
    )
    assert updated.status_code == 200
    assert updated.json()["title"] == "Productive rainy afternoon"

    deleted = client.delete(f"/api/entries/{entry_id}")
    assert deleted.status_code == 204

    missing = client.get(f"/api/entries/{entry_id}")
    assert missing.status_code == 404


def test_rejects_empty_title():
    response = client.post(
        "/api/entries",
        json={"title": "", "content": "This should fail"},
    )
    assert response.status_code == 422
