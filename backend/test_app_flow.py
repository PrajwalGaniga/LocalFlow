"""
Automated End-to-End Test Suite for LocalFlow App API & Refactors
Tests all new endpoints, services, authentication, and registration flows.
"""
import sys
import unittest
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine, SessionLocal
from app import crud, models, schemas

client = TestClient(app)


class LocalFlowAppFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Create all tables
        Base.metadata.create_all(bind=engine)
        cls.db = SessionLocal()

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_01_consumer_registration_and_lookup(self):
        phone = "9876543210"
        # 1. Register Consumer
        res = client.post(
            "/consumers/",
            json={"name": "Aarav Sharma", "phone": phone, "password": "password123"},
        )
        self.assertIn(res.status_code, [201, 409])
        
        # 2. Lookup by phone
        res_lookup = client.get(f"/consumers/by-phone/{phone}")
        self.assertEqual(res_lookup.status_code, 200)
        data = res_lookup.json()
        self.assertEqual(data["name"], "Aarav Sharma")
        self.assertEqual(data["phone"], phone)

        # 3. Login
        res_login = client.post(
            "/consumers/login",
            json={"phone": phone, "password": "password123"},
        )
        self.assertEqual(res_login.status_code, 200)

    def test_02_provider_registration_and_lookup(self):
        phone = "9888877777"
        # 1. Register Provider
        res = client.post(
            "/providers/",
            json={
                "name": "Vikram Plumber",
                "phone": phone,
                "password": "vikrampass",
                "skill": "plumber",
                "location": "koramangala",
                "rate_min": 300,
                "rate_max": 700,
            },
        )
        self.assertIn(res.status_code, [201, 409])

        # 2. Lookup by phone
        res_lookup = client.get(f"/providers/by-phone/{phone}")
        self.assertEqual(res_lookup.status_code, 200)
        data = res_lookup.json()
        self.assertEqual(data["name"], "Vikram Plumber")
        self.assertEqual(data["skill"], "plumber")

        # 3. Login
        res_login = client.post(
            "/providers/login",
            json={"phone": phone, "password": "vikrampass"},
        )
        self.assertEqual(res_login.status_code, 200)

    def test_03_notification_accept_and_decline_flow(self):
        # Register two providers for electrician in koramangala
        p1_res = client.post(
            "/providers/",
            json={
                "name": "P1 Electrician",
                "phone": "9111111111",
                "skill": "electrician",
                "location": "koramangala",
                "rate_min": 250,
                "rate_max": 500,
            },
        )
        p1_id = p1_res.json()["id"] if p1_res.status_code == 201 else client.get("/providers/by-phone/9111111111").json()["id"]

        p2_res = client.post(
            "/providers/",
            json={
                "name": "P2 Electrician",
                "phone": "9222222222",
                "skill": "electrician",
                "location": "koramangala",
                "rate_min": 250,
                "rate_max": 500,
            },
        )
        p2_id = p2_res.json()["id"] if p2_res.status_code == 201 else client.get("/providers/by-phone/9222222222").json()["id"]

        # Create service request
        req = crud.create_request(
            self.db,
            schemas.ServiceRequestCreate(
                consumer_phone="9876543210",
                skill_requested="electrician",
                location="koramangala",
                description="Ceiling fan repair",
            ),
        )

        # Notify both providers
        crud.create_notification(self.db, req.id, p1_id)
        crud.create_notification(self.db, req.id, p2_id)

        # Check P1 notifications endpoint
        notif_res = client.get(f"/providers/{p1_id}/notifications")
        self.assertEqual(notif_res.status_code, 200)
        notifs = notif_res.json()
        self.assertTrue(any(n["request_id"] == req.id for n in notifs))

        # P1 accepts the notification
        accept_res = client.post(f"/providers/{p1_id}/notifications/{req.id}/accept")
        self.assertEqual(accept_res.status_code, 200)
        accept_data = accept_res.json()
        self.assertTrue(accept_data["success"])
        self.assertEqual(accept_data["consumer_phone"], "9876543210")

        # P2 tries to accept the same job -> must get 409 Conflict
        p2_accept_res = client.post(f"/providers/{p2_id}/notifications/{req.id}/accept")
        self.assertEqual(p2_accept_res.status_code, 409)

    def test_04_consumer_requests_and_payment_flow(self):
        consumer_phone = "9876543210"
        c_res = client.get(f"/consumers/by-phone/{consumer_phone}")
        consumer_id = c_res.json()["id"]

        # Fetch consumer requests
        reqs_res = client.get(f"/consumers/{consumer_id}/requests")
        self.assertEqual(reqs_res.status_code, 200)
        requests = reqs_res.json()
        self.assertGreater(len(requests), 0)
        latest_req = requests[0]
        req_id = latest_req["id"]

        # Self-declared mark as paid
        paid_res = client.post(f"/requests/{req_id}/mark-paid")
        self.assertEqual(paid_res.status_code, 200)
        self.assertEqual(paid_res.json()["payment_status"], "paid")
        self.assertIsNotNone(paid_res.json()["paid_at"])

        # Complete request with rating
        comp_res = client.post(
            f"/requests/{req_id}/complete",
            json={"rating": 5, "rating_comment": "Super fast and clean work!"},
        )
        self.assertEqual(comp_res.status_code, 200)
        self.assertEqual(comp_res.json()["status"], "completed")
        self.assertEqual(comp_res.json()["rating"], 5)

    def test_05_fallback_html_registration_flow(self):
        # 1. Create a registration token
        link = crud.create_registration_link(self.db, "9333344444", role="provider")
        self.assertFalse(link.used)

        # 2. GET /register?token=...
        get_page = client.get(f"/register?token={link.token}")
        self.assertEqual(get_page.status_code, 200)
        self.assertIn("Join as Provider", get_page.text)
        self.assertIn("9333344444", get_page.text)

        # 3. POST /register/submit
        submit_res = client.post(
            "/register/submit",
            data={
                "token": link.token,
                "role": "provider",
                "phone": "9333344444",
                "name": "Kiran Carpenter",
                "skill": "carpenter",
                "location": "hsr layout",
                "rate_min": 350,
                "rate_max": 800,
                "password": "kiranpass",
            },
        )
        self.assertEqual(submit_res.status_code, 200)
        self.assertIn("Registered!", submit_res.text)

        # 4. Verify link is marked used
        self.db.refresh(link)
        self.assertTrue(link.used)

        # 5. Accessing the link again shows already registered
        used_page = client.get(f"/register?token={link.token}")
        self.assertEqual(used_page.status_code, 200)
        self.assertIn("Already Registered", used_page.text)

    def test_06_multi_skill_provider_registration_and_update(self):
        phone = "9777788888"
        # 1. Register first skill: electrician
        res1 = client.post(
            "/providers/",
            json={
                "name": "Arun Multi",
                "phone": phone,
                "password": "multi123password",
                "skill": "electrician",
                "location": "koramangala",
                "rate_min": 300,
                "rate_max": 600,
            },
        )
        self.assertIn(res1.status_code, [201, 409])
        prov1_id = res1.json().get("id") if res1.status_code == 201 else client.get(f"/providers/by-phone/{phone}").json()["id"]

        # 2. Register second skill with same phone: plumber
        res2 = client.post(
            "/providers/",
            json={
                "name": "Arun Multi",
                "phone": phone,
                "password": "multi123password",
                "skill": "plumber",
                "location": "koramangala",
                "rate_min": 250,
                "rate_max": 500,
            },
        )
        self.assertIn(res2.status_code, [201, 409])

        # 3. GET /providers/all-by-phone/{phone}
        all_res = client.get(f"/providers/all-by-phone/{phone}")
        self.assertEqual(all_res.status_code, 200)
        profiles = all_res.json()
        self.assertGreaterEqual(len(profiles), 2)
        skills = [p["skill"] for p in profiles]
        self.assertIn("electrician", skills)
        self.assertIn("plumber", skills)

        # 4. PATCH /providers/{id} - Update rate and availability
        patch_res = client.patch(
            f"/providers/{prov1_id}",
            json={"rate_min": 450, "rate_max": 900, "availability_status": "available_later"},
        )
        self.assertEqual(patch_res.status_code, 200)
        self.assertEqual(patch_res.json()["rate_min"], 450)
        self.assertEqual(patch_res.json()["availability_status"], "available_later")

    def test_07_provider_wallet_endpoint(self):
        # 1. Fetch wallet for provider 10
        res = client.get("/providers/10/wallet")
        self.assertEqual(res.status_code, 200)
        wallet = res.json()
        self.assertIn("total_earnings", wallet)
        self.assertIn("available_balance", wallet)
        self.assertIn("transactions", wallet)
        self.assertIsInstance(wallet["transactions"], list)

    def test_08_request_cancellation_flow(self):
        # 1. Create a request
        req_res = client.post(
            "/requests/",
            json={
                "consumer_phone": "9876543210",
                "skill_requested": "electrician",
                "location": "koramangala",
                "description": "Cancel test request",
            },
        )
        self.assertEqual(req_res.status_code, 201)
        req_id = req_res.json()["id"]

        # 2. Cancel request
        cancel_res = client.post(f"/requests/{req_id}/cancel")
        self.assertEqual(cancel_res.status_code, 200)
        self.assertTrue(cancel_res.json()["success"])
        self.assertEqual(cancel_res.json()["status"], "cancelled")

        # 3. Verify status in database
        check_res = client.get(f"/requests/{req_id}")
        self.assertEqual(check_res.json()["status"], "cancelled")


if __name__ == "__main__":
    unittest.main()
