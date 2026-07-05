from fastapi.testclient import TestClient

from shortener.main import app

client = TestClient(app)


def test_shorten_and_redirect():
    resp = client.post("/shorten", json={"url": "https://example.com"})
    assert resp.status_code == 200
    code = resp.json()["code"]

    redirect_resp = client.get(f"/{code}", follow_redirects=False)
    assert redirect_resp.status_code == 301
    assert redirect_resp.headers["location"] == "https://example.com/"


def test_redirect_not_found():
    resp = client.get("/doesnotexist", follow_redirects=False)
    assert resp.status_code == 404


def test_shorten_invalid_url():
    resp = client.post("/shorten", json={"url": "not-a-url"})
    assert resp.status_code == 422