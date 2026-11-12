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

    def test_original_audio_first_and_verified_alternatives(self):
        sample = {"results": [
            {"site": "YouTube", "type": "Trailer",
             "official": True, "iso_639_1": "pt", "key": "123456789ab"},
            {"site": "YouTube", "type": "Trailer",
             "official": True, "iso_639_1": "ja", "key": "abcdefghijk"},
            {"site": "YouTube", "type": "Trailer",
             "official": True, "iso_639_1": "en", "key": "123456789ac"},
            {"site": "YouTube", "type": "Teaser",
             "iso_639_1": "ja", "key": "123456789ad"},
            {"site": "YouTube", "type": "Trailer",
             "iso_639_1": "ja", "key": "abcdefghijk"},
            {"site": "Vimeo", "type": "Trailer",
             "iso_639_1": "ja", "key": "123456789ae"},
        ]}
        ids = MODULE.trailer_youtube_ids(sample, "ja")
        self.assertEqual(ids, [
            "abcdefghijk", "123456789ab", "123456789ac",
            "123456789ad"])
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(MODULE.trailer_youtube_ids(
            {"results": [{"site": "YouTube", "type": "Trailer",
                "key": "bad id"}]}, "ja"), [])

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

    def test_enriches_only_real_panoramas_for_the_correct_tmdb_id(self):
        images = {"backdrops": [
            {"file_path": "/wrong-portrait.jpg", "width": 700,
             "height": 1200, "aspect_ratio": 0.58},
            {"file_path": "/low-resolution.jpg", "width": 800,
             "height": 450, "aspect_ratio": 1.77},
            {"file_path": "/cinematic.jpg", "width": 1920,
             "height": 1080, "aspect_ratio": 1.777,
             "iso_639_1": None, "vote_average": 7.9,
             "vote_count": 30},
        ]}
        self.assertEqual(MODULE.best_panorama(images),
            "https://image.tmdb.org/t/p/w1280/cinematic.jpg")
        self.assertEqual(MODULE.best_panorama({"backdrops": [
            {"file_path": "/portrait.jpg", "width": 620,
             "height": 900, "aspect_ratio": .7},
        ]}), "")
        self.assertEqual(MODULE.best_panorama({"backdrops": [
            {"file_path": "/../escape.jpg", "width": 1920,
             "height": 1080, "aspect_ratio": 1.77},
        ]}), "")

    def test_imdb_ids_come_only_from_verified_tmdb_metadata(self):
        record = {
            "id": 110, "title": "Original", "imdb_id": "tt12345678",
            "release_date": "2025-01-01",
        }
        MODULE.save_result("movie", record)
        self.assertEqual(MODULE.TITLES["tmdb:movie:110"]["imdbId"],
                         "tt12345678")
        MODULE.save_result("movie", {
            **record, "id": 111, "imdb_id": "unverified"
        })
        self.assertEqual(MODULE.TITLES["tmdb:movie:111"]["imdbId"], "")

    def test_verifies_localized_aliases_duration_and_tv_seasons(self):
        MODULE.save_result("movie", {
            "id": 900, "title": "O Filme", "original_title": "The Movie",
        })
        MODULE.save_result("tv", {
            "id": 901, "name": "Ela Era Bonita",
            "original_name": "그녀는 예뻤다", "genre_ids": [18],
            "original_language": "ko",
        })

        def fake_get(path, params=None):
            self.assertEqual(params["language"], "pt-BR")
            if path == "/movie/900":
                return {
                    "runtime": 117,
                    "alternative_titles": {
                        "titles": [{"title": "The Movie"}],
                    },
                    "translations": {"translations": []},
                }
            if path == "/tv/901":
                return {
                    "number_of_seasons": 1,
                    "alternative_titles": {
                        "results": [{"title": "She Was Pretty"}],
                    },
                    "translations": {"translations": [
                        {"iso_639_1": "en", "data": {
                            "name": "She Was Pretty",
                        }},
                    ]},
                }
            raise AssertionError(path)

        with mock.patch.object(MODULE, "get", fake_get):
            MODULE.enrich_title_metadata("tmdb:movie:900")
            MODULE.enrich_title_metadata("tmdb:tv:901")

        movie = MODULE.TITLES["tmdb:movie:900"]
        drama = MODULE.TITLES["tmdb:tv:901"]
        self.assertEqual(movie["runtimeMinutes"], 117)
        self.assertIsNone(movie["seasonCount"])
        self.assertEqual(drama["seasonCount"], 1)
        self.assertIsNone(drama["runtimeMinutes"])
        self.assertIn("She Was Pretty", drama["aliases"])
        self.assertEqual(drama["aliases"].count("She Was Pretty"), 1)

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
                 mock.patch.object(MODULE, "MAX_METADATA_LOOKUPS", 0), \
                 mock.patch.object(MODULE, "MAX_TRAILERS", 0), \
                 mock.patch.object(MODULE, "MAX_PANORAMA_LOOKUPS", 0), \
                 mock.patch.object(MODULE, "MAX_IMDB_LOOKUPS", 0):
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
