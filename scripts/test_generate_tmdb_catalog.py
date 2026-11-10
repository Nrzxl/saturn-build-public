import importlib.util
import json
import os
import pathlib
import tempfile
import unittest
from unittest import mock

os.environ.setdefault("TMDB_READ_TOKEN", "UNIT_TEST_ONLY")

FILE = pathlib.Path(__file__).with_name("generate_tmdb_catalog.py")
SPEC = importlib.util.spec_from_file_location("saturn_generator", FILE)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class CatalogGenerationTests(unittest.TestCase):
    def setUp(self):
        MODULE.TITLES.clear()
        MODULE.SEEN_PROVIDER.clear()
        MODULE.TOTAL_CALLS = 0

    def test_omdb_critic_ratings_only_when_verified(self):
        parsed = MODULE.parse_omdb_ratings({
            "Response": "True",
            "Ratings": [
                {"Source": "Internet Movie Database", "Value": "8.2/10"},
                {"Source": "Rotten Tomatoes", "Value": "91%"},
                {"Source": "Metacritic", "Value": "75/100"},
                {"Source": "Unknown", "Value": "100/100"},
                {"Source": "Rotten Tomatoes", "Value": "N/A"},
            ],
        })
        self.assertEqual(parsed, {
            "imdb": "8.2/10",
            "rottenTomatoes": "91%",
            "metacritic": "75/100",
        })
        self.assertEqual(MODULE.parse_omdb_ratings({
            "Response": "False", "Ratings": [
                {"Source": "Rotten Tomatoes", "Value": "100%"},
            ],
        }), {})

    def test_classifies_anime_doramas_and_films(self):
        self.assertEqual(MODULE.kind_for("movie", {}), "Filme")
        self.assertEqual(MODULE.kind_for("tv", {
            "original_language": "ja", "genre_ids": [16],
        }), "Anime")
        self.assertEqual(MODULE.kind_for("tv", {
            "original_language": "ko", "genre_ids": [18],
        }), "Dorama")
        self.assertEqual(MODULE.kind_for("tv", {
            "original_language": "en", "genre_ids": [18],
        }), "Série")

    def test_prefers_verified_portuguese_official_youtube_trailer(self):
        sample = {"results": [
            {"site": "YouTube", "type": "Teaser",
             "official": True, "key": "Abcdefghijk"},
            {"site": "YouTube", "type": "Trailer",
             "official": True, "iso_639_1": "en", "key": "123456789ab"},
            {"site": "YouTube", "type": "Trailer",
             "official": True, "iso_639_1": "pt",
             "iso_3166_1": "BR", "key": "abcdefghijk"},
            {"site": "Other", "type": "Trailer",
             "official": True, "key": "zyxwvutsrqp"},
        ]}
        self.assertEqual(
            MODULE.trailer_youtube_id(sample), "abcdefghijk")
        self.assertEqual(
            MODULE.trailer_youtube_id({"results": [
                {"site": "YouTube", "type": "Trailer",
                 "key": "not-valid"},
            ]}), "")

    def test_no_adult_titles_and_no_duplicate_ids(self):
        record = {
            "id": 100, "title": "Filme Real", "poster_path": "/poster.jpg",
            "backdrop_path": "/cinema.jpg",
            "popularity": 42, "overview": "Uma história",
        }
        self.assertEqual(MODULE.save_result("movie", record), "tmdb:movie:100")
        self.assertIsNone(MODULE.save_result("movie", {**record, "adult": True}))
        self.assertEqual(MODULE.save_result("movie", record), "tmdb:movie:100")
        self.assertEqual(len(MODULE.TITLES), 1)
        self.assertEqual(MODULE.TITLES["tmdb:movie:100"]["backdropUrl"],
                         "https://image.tmdb.org/t/p/w1280/cinema.jpg")

    def test_uses_brazilian_subscription_only_not_rental(self):
        def fake_get(path, params=None):
            if path.startswith("/watch/providers/"):
                if path.endswith("/movie"):
                    return {"results": [
                        {"provider_name": "Netflix", "provider_id": 8},
                        {"provider_name": "Amazon Prime Video", "provider_id": 119},
                        {"provider_name": "Crunchyroll Amazon Channel", "provider_id": 900},
                    ]}
                return {"results": [
                    {"provider_name": "Crunchyroll", "provider_id": 283},
                ]}
            if path == "/movie/100/watch/providers":
                return {"results": {
                    "BR": {
                        "link": "https://www.themoviedb.org/movie/100/watch?locale=BR",
                        "flatrate": [
                            {"provider_id": 8, "provider_name": "Netflix"},
                        ],
                        "rent": [
                            {"provider_id": 119,
                             "provider_name": "Amazon Prime Video"},
                        ],
                    },
                    "US": {
                        "flatrate": [
                            {"provider_id": 119, "provider_name": "Amazon Prime Video"},
                        ],
                    },
                }}
            if path.startswith("/discover/"):
                if path.endswith("/movie"):
                    return {
                        "results": [{
                            "id": 100, "title": "Filme Real",
                            "popularity": 42, "poster_path": "/poster.jpg",
                            "release_date": "2025-04-01",
                        }],
                        "total_pages": 1,
                    }
                return {"results": [], "total_pages": 0}
            raise AssertionError(path)

        with tempfile.TemporaryDirectory() as folder:
            with mock.patch.object(MODULE, "get", fake_get), \
                 mock.patch.object(MODULE, "OUT", pathlib.Path(folder)), \
                 mock.patch.object(MODULE, "MAX_PAGES", 1), \
                 mock.patch.object(MODULE, "MAX_DETAILS", 1), \
                 mock.patch.object(MODULE, "MAX_TRAILERS", 0):
                MODULE.build()
                data = json.loads(
                    (pathlib.Path(folder) / "movies.json").read_text(
                        encoding="utf-8")
                )
            self.assertEqual(data["country"], "BR")
            self.assertEqual(len(data["results"]), 1)
            item = data["results"][0]
            self.assertEqual(item["streamingProviders"], {"netflix": "Netflix"})
            self.assertEqual(item["watchProviders"], ["Netflix"])
            self.assertTrue(item["availabilityChecked"])
            self.assertIn("/movie/100/watch", item["watchUrl"])
            self.assertNotIn("Amazon Prime Video", item["watchProviders"])


if __name__ == "__main__":
    unittest.main()
