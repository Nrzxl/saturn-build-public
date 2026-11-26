"""Regression: public movie discovery never depends on the private APK repo.

All inputs are generated public TMDB metadata, not accounts, reviews or tokens.
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "web" / "catalog" / "v1"
CATEGORIES = ("movies", "series", "dramas", "anime")


class PublicCatalogPublicationTest(unittest.TestCase):
    def test_public_snapshot_is_complete_and_consistent(self):
        manifest = json.loads((CATALOG / "manifest.json").read_text("utf-8"))
        self.assertEqual(manifest["schema"], 1)
        self.assertEqual(manifest["country"], "BR")
        self.assertEqual(set(manifest["counts"]), set(CATEGORIES))
        generated = manifest["generatedAt"]
        for name in CATEGORIES:
            with self.subTest(name=name):
                document = json.loads((CATALOG / f"{name}.json").read_text("utf-8"))
                self.assertEqual(document["schema"], 1)
                self.assertEqual(document["country"], "BR")
                self.assertEqual(document["generatedAt"], generated)
                results = document["results"]
                self.assertEqual(len(results), manifest["counts"][name])
                self.assertGreater(len(results), 100)
                self.assertEqual(len(set(r["id"] for r in results)), len(results))
                self.assertTrue(all(r["id"].startswith("tmdb:") for r in results))
                self.assertTrue(all(isinstance(r["title"], str) for r in results))

    def test_supporting_metadata_is_public_and_read_only(self):
        technical = json.loads((CATALOG / "technical.json").read_text("utf-8"))
        self.assertEqual((technical["schema"], technical["country"]), (1, "BR"))
        self.assertGreater(len(technical["values"]), 1000)
        backdrops = json.loads(
            (CATALOG / "backdrops-fallback.json").read_text("utf-8")
        )
        self.assertEqual(backdrops["schema"], 1)
        self.assertEqual(backdrops["country"], "BR")

    def test_client_uses_pages_not_the_private_downloads_repository(self):
        runtime = (ROOT / "lib" / "tmdb_catalog_data.dart").read_text("utf-8")
        tech = (ROOT / "lib" / "saturn_technical_metadata.dart").read_text("utf-8")
        self.assertIn("nrzxl.github.io/saturn-build-public/catalog/v1", runtime)
        self.assertIn("nrzxl.github.io/saturn-build-public/catalog/v1", tech)
        self.assertIn(
            "raw.githubusercontent.com/Nrzxl/saturn-build-public/main/web/catalog/v1",
            runtime,
        )
        self.assertNotIn("Nrzxl/saturn-downloads", runtime + tech)

    def test_no_private_fields_in_published_catalog(self):
        private_keys = {"user_id", "email", "review", "notes", "password",
                        "access_token", "refresh_token", "service_role", "api_key"}
        for name in CATEGORIES:
            with self.subTest(name=name):
                document = json.loads((CATALOG / f"{name}.json").read_text("utf-8"))
                for row in document["results"]:
                    self.assertFalse(set(row) & private_keys)
                    self.assertFalse(re.search(
                        r"sb_secret_|github_pat_|ghp_[A-Za-z0-9]|service_role",
                        json.dumps(row),
                        re.I,
                    ))


if __name__ == "__main__":
    unittest.main()
