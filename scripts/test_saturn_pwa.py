"""Non-network PWA safeguards for the public GitHub Pages distribution."""
from html.parser import HTMLParser
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tags = []

    def handle_starttag(self, tag, attrs):
        self.tags.append((tag, dict(attrs)))

class SaturnPwaTests(unittest.TestCase):
    def test_manifest_is_installable_under_repository_subpath(self):
        data = json.loads((WEB / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(data["start_url"], "./")
        self.assertEqual(data["scope"], "./")
        self.assertEqual(data["id"], "./")
        self.assertEqual(data["display"], "standalone")
        self.assertNotIn("orientation", data)
        self.assertEqual(data["lang"], "pt-BR")
        purposes = {icon["purpose"] for icon in data["icons"]}
        self.assertIn("maskable", purposes)
        self.assertIn("any", purposes)

    def test_html_has_ios_metadata_and_safe_area(self):
        html = (WEB / "index.html").read_text(encoding="utf-8")
        document = Links()
        document.feed(html)
        meta = [attributes for tag, attributes in document.tags if tag == "meta"]
        links = [attributes for tag, attributes in document.tags if tag == "link"]
        self.assertTrue(any(m.get("name") == "apple-mobile-web-app-capable"
                            and m.get("content") == "yes" for m in meta))
        self.assertTrue(any(m.get("name") == "viewport"
                            and "viewport-fit=cover" in m.get("content", "")
                            and "user-scalable=no" not in m.get("content", "")
                            for m in meta))
        self.assertTrue(any(link.get("rel") == "manifest" for link in links))
        self.assertTrue(any(link.get("rel") == "apple-touch-icon"
                            for link in links))
        self.assertIn("env(safe-area-inset-bottom)", html)
        self.assertIn("flutter-first-frame", html)
        self.assertIn("saturn-network", html)
        self.assertIn("saturn-retry", html)
        # iOS standalone black-translucent can put touch targets under
        # the home/status bar; black reserves the status-bar region.
        self.assertIn('apple-mobile-web-app-status-bar-style', html)
        self.assertIn('content="black"', html)
        self.assertNotIn('content="black-translucent"', html)

    def test_pwa_does_not_pretend_to_cache_the_whole_catalog(self):
        html = (WEB / "index.html").read_text(encoding="utf-8")
        # Cover-only cache is allowed. The app bundle, user data, and
        # catalog snapshots must never be cached/cleared by custom workers.
        self.assertIn("saturn-cover-cache-sw.js", html)
        worker = (WEB / "saturn-cover-cache-sw.js").read_text(encoding="utf-8")
        self.assertIn("url.origin !== 'https://covers.openlibrary.org'", worker)
        self.assertIn("MAX_CACHED_COVERS = 180", worker)
        self.assertNotIn("supabase.co", worker)
        self.assertNotIn("main.dart.js", worker)
        self.assertNotIn("catalog/v1", worker)
        self.assertNotIn("localStorage.clear(", html)
        self.assertNotIn("caches.delete(", html)
        self.assertNotIn("indexedDB.deleteDatabase(", html)

if __name__ == "__main__":
    unittest.main()
