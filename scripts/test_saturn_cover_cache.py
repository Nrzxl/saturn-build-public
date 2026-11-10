from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class TestSATURNCoverCache(unittest.TestCase):
    def test_only_book_image_requests_are_cached(self):
        text = (ROOT / 'web' / 'saturn-cover-cache-sw.js').read_text()
        self.assertIn("url.origin !== 'https://covers.openlibrary.org'", text)
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
