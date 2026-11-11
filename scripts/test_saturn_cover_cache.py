from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class TestSATURNCoverCache(unittest.TestCase):
    def test_public_artwork_cache_is_limited_to_known_image_endpoints(self):
        text = (ROOT / 'web' / 'saturn-cover-cache-sw.js').read_text()
        self.assertIn("url.origin === 'https://covers.openlibrary.org'", text)
        self.assertIn("CINEMATIC_HOSTS", text)
        self.assertIn("image.tmdb.org", text)
        self.assertIn("static.tvmaze.com", text)
        self.assertIn("s4.anilist.co", text)
        self.assertIn("const SATURN_CINEMATIC_ART", text)
        self.assertIn("MAX_CACHED_ART = 220", text)
        self.assertIn("event.request.mode === 'no-cors'", text)
        self.assertIn("!CINEMATIC_HOSTS.has(url.hostname)", text)
        self.assertIn("url.searchParams.has('api_key')", text)
        self.assertIn("event.request.method !== 'GET'", text)
        self.assertIn("MAX_CACHED_COVERS = 180", text)
        self.assertIn("response.clone()", text)
        self.assertNotIn("supabase.co", text)

    def test_registered_without_intercepting_flutter_update(self):
        html = (ROOT / 'web' / 'index.html').read_text()
        self.assertIn("saturn-cover-cache-sw.js", html)
        self.assertIn("flutter_bootstrap.js", html)

if __name__ == '__main__':
    unittest.main()
