from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_api():
    res_health = client.get("/health")
    print(f"GET /health -> status: {res_health.status_code}, data: {res_health.json()}")
    assert res_health.status_code == 200

    res_root = client.get("/")
    print(f"GET / -> status: {res_root.status_code}, data: {res_root.json()}")
    assert res_root.status_code == 200

    res_providers = client.get("/providers/")
    print(f"GET /providers/ -> status: {res_providers.status_code}, total providers: {len(res_providers.json())}")
    assert res_providers.status_code == 200

    res_requests = client.get("/requests/")
    print(f"GET /requests/ -> status: {res_requests.status_code}, total requests: {len(res_requests.json())}")
    assert res_requests.status_code == 200

    print("\n[OK] All FastAPI API endpoints responded correctly!")


if __name__ == "__main__":
    test_api()
