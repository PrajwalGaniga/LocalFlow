"""
Automated End-to-End Test Suite for LocalFlow App API & Refactors
Tests all endpoints, services, locations, browse, direct request, and registration flows.
"""
import unittest
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine, SessionLocal
from app import crud, models, schemas
from app.utils.time import now_ist

client = TestClient(app)


class LocalFlowAppFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Create all tables and seed locations
        Base.metadata.create_all(bind=engine)
        cls.db = SessionLocal()
        # Find Koramangala location ID
        koramangala = cls.db.query(models.ServiceLocation).filter(models.ServiceLocation.area_name == "Koramangala").first()
        cls.koramangala_id = koramangala.id if koramangala else 1

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_00_locations_endpoints(self):
        # 1. GET /locations/
        res = client.get("/locations/")
        self.assertEqual(res.status_code, 200)
        locs = res.json()
        self.assertGreaterEqual(len(locs), 32)

        # 2. GET /locations/districts
        res_d = client.get("/locations/districts")
        self.assertEqual(res_d.status_code, 200)
        districts = res_d.json()
        self.assertIn("Bengaluru Urban", districts)
        self.assertIn("Dakshina Kannada", districts)
        self.assertIn("Udupi", districts)
        self.assertIn("Mysuru", districts)

        # 3. GET /locations/by-district/{district}
        res_blr = client.get("/locations/by-district/Bengaluru Urban")
        self.assertEqual(res_blr.status_code, 200)
        areas = [l["area_name"] for l in res_blr.json()]
        self.assertIn("Koramangala", areas)
        self.assertIn("Whitefield", areas)

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
                "location_id": self.koramangala_id,
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

    def test_03_notification_accept_with_consumer_name(self):
        # Register provider for electrician in koramangala
        p1_res = client.post(
            "/providers/",
            json={
                "name": "P1 Electrician",
                "phone": "9111111111",
                "skill": "electrician",
                "location_id": self.koramangala_id,
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
                "location_id": self.koramangala_id,
                "rate_min": 250,
                "rate_max": 500,
            },
        )
        p2_id = p2_res.json()["id"] if p2_res.status_code == 201 else client.get("/providers/by-phone/9222222222").json()["id"]

        # Ensure consumer exists
        client.post("/consumers/", json={"name": "Priya Sharma", "phone": "9876543210"})

        # Create service request
        req = crud.create_request(
            self.db,
            schemas.ServiceRequestCreate(
                consumer_phone="9876543210",
                skill_requested="electrician",
                location_id=self.koramangala_id,
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

        # P1 accepts the notification -> verify consumer_name is returned
        accept_res = client.post(f"/providers/{p1_id}/notifications/{req.id}/accept")
        self.assertEqual(accept_res.status_code, 200)
        accept_data = accept_res.json()
        self.assertTrue(accept_data["success"])
        self.assertEqual(accept_data["consumer_phone"], "9876543210")
        self.assertEqual(accept_data["consumer_name"], "Aarav Sharma")

        # P2 tries to accept the same job -> must get 409 Conflict
        p2_accept_res = client.post(f"/providers/{p2_id}/notifications/{req.id}/accept")
        self.assertEqual(p2_accept_res.status_code, 409)

    def test_04_direct_request_to_preferred_provider(self):
        # Create a direct request targeting P1 Electrician only
        p1 = client.get("/providers/by-phone/9111111111").json()
        p1_id = p1["id"]

        req_res = client.post(
            "/requests/",
            json={
                "consumer_phone": "9876543210",
                "skill_requested": "electrician",
                "location_id": self.koramangala_id,
                "description": "Direct request for P1",
                "preferred_provider_id": p1_id,
            },
        )
        self.assertEqual(req_res.status_code, 201)
        req_data = req_res.json()
        req_id = req_data["id"]
        self.assertEqual(req_data["preferred_provider_id"], p1_id)

        # Verify only 1 notification was created (for P1)
        notifs = crud.get_request_notifications(self.db, req_id)
        self.assertEqual(len(notifs), 1)
        self.assertEqual(notifs[0].provider_id, p1_id)

    def test_05_browse_providers_endpoint(self):
        res = client.get(f"/providers/?skill=electrician&location_id={self.koramangala_id}")
        self.assertEqual(res.status_code, 200)
        pros = res.json()
        self.assertIsInstance(pros, list)
        self.assertGreater(len(pros), 0)
        for p in pros:
            self.assertEqual(p["skill"].lower(), "electrician")

    def test_06_consumer_requests_and_payment_flow(self):
        consumer_phone = "9876543210"
        p1 = client.get("/providers/by-phone/9111111111").json()
        p1_id = p1["id"]

        # Create a fresh request
        req_res = client.post(
            "/requests/",
            json={
                "consumer_phone": consumer_phone,
                "skill_requested": "electrician",
                "location_id": self.koramangala_id,
                "description": "Payment flow test request",
            },
        )
        self.assertEqual(req_res.status_code, 201)
        req_id = req_res.json()["id"]

        # Provider accepts request so status becomes 'matched'
        client.post(f"/providers/{p1_id}/notifications/{req_id}/accept")

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

    def test_07_provider_wallet_and_profile_patch(self):
        p1 = client.get("/providers/by-phone/9111111111").json()
        p1_id = p1["id"]

        # Patch rate
        patch_res = client.patch(f"/providers/{p1_id}", json={"rate_min": 350, "rate_max": 750})
        self.assertEqual(patch_res.status_code, 200)
        self.assertEqual(patch_res.json()["rate_min"], 350)

        # Fetch wallet
        res = client.get(f"/providers/{p1_id}/wallet")
        self.assertEqual(res.status_code, 200)
        wallet = res.json()
        self.assertIn("total_earnings", wallet)
        self.assertIn("available_balance", wallet)

    def test_08_request_cancellation_flow(self):
        # 1. Create a request
        req_res = client.post(
            "/requests/",
            json={
                "consumer_phone": "9876543210",
                "skill_requested": "electrician",
                "location_id": self.koramangala_id,
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
