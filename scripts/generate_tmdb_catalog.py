#!/usr/bin/env python3
"""Build limited, attributable SATURN discovery snapshots from TMDB.

Requires a TMDB v4 Read Access Token in TMDB_READ_TOKEN. No key is put in
Flutter, Git, public JSON or Actions logs. Use with TMDB's terms/licensing.

The public files are daily snapshots, NOT a complete or real-time database.
Avoid making an unavailable title look available: only BR flatrate results
and actual /watch/providers rows can mark service availability.
"""
from __future__ import annotations

import datetime as dt
import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://api.themoviedb.org/3"
NOW = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
TOKEN = os.environ.get("TMDB_READ_TOKEN", "").strip()
OUT = pathlib.Path(os.environ.get("SATURN_CATALOG_OUTPUT", "catalog_out"))
MAX_PAGES = max(1, min(65, int(os.environ.get("SATURN_CATALOG_PAGES", "25"))))
MAX_DETAILS = max(0, min(1200, int(os.environ.get("SATURN_WATCH_LOOKUPS", "500"))))
MAX_TRAILERS = max(0, min(800, int(os.environ.get("SATURN_TRAILER_LOOKUPS", "360"))))
MAX_PANORAMA_LOOKUPS = max(0, min(900,
    int(os.environ.get("SATURN_PANORAMA_LOOKUPS", "350"))))
# IMDb IDs are verified from TMDB external_ids (not guessed from names).
MAX_IMDB_LOOKUPS = max(0, min(500,
    int(os.environ.get("SATURN_IMDB_LOOKUPS", "250"))))
# Public snapshots must not redistribute licensed scores without approval.
OMDB_PUBLICATION_ALLOWED = os.environ.get("SATURN_CRITIC_PUBLICATION_ALLOWED") == "true"
OMDB_API_KEY = (os.environ.get("SATURN_OMDB_API_KEY", "").strip()
                if OMDB_PUBLICATION_ALLOWED else "")
MAX_CRITIC_LOOKUPS = max(0, min(250, int(os.environ.get("SATURN_CRITIC_LOOKUPS", "90"))))
if not TOKEN:
    sys.exit("TMDB_READ_TOKEN ausente: catálogo não publicado.")

TITLES: dict[str, dict] = {}
SEEN_PROVIDER: dict[str, set[str]] = {}
TOTAL_CALLS = 0


def get(path: str, params: dict | None = None) -> dict:
    global TOTAL_CALLS
    url = BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers={
        "Authorization": "Bearer " + TOKEN,
        "Accept": "application/json",
        "User-Agent": "SATURN-private-catalog/0.5",
    })
    for attempt in range(5):
        try:
            with urllib.request.urlopen(request, timeout=18) as response:
                payload = json.load(response)
            TOTAL_CALLS += 1
            time.sleep(0.15)
            if not isinstance(payload, dict):
                raise ValueError("Resposta inesperada TMDB.")
            return payload
        except urllib.error.HTTPError as error:
            if error.code in (401, 403):
                raise RuntimeError("Chave TMDB inválida/sem permissão.") from error
            if error.code not in (429, 500, 502, 503, 504) or attempt == 4:
                raise
            delay = min(30, 2 ** attempt + 1)
            print("TMDB temporarily unavailable, retrying", file=sys.stderr)
            time.sleep(delay)
        except (TimeoutError, urllib.error.URLError):
            if attempt == 4:
                raise
            time.sleep(min(15, 2 ** attempt))
    raise RuntimeError("API TMDB indisponível.")


def year(raw: str) -> int:
    match = re.match(r"^\d{4}", str(raw or ""))
    return int(match.group(0)) if match else 0


def kind_for(media: str, record: dict) -> str:
    if media == "movie":
        return "Filme"
    genres = record.get("genre_ids") or []
    language = (record.get("original_language") or "").lower()
    countries = record.get("origin_country") or []
    if language == "ja" and 16 in genres:
        return "Anime"
    if language in {"ko", "zh", "th"} or (
        language == "ja" and 16 not in genres
    ) or any(c in {"KR", "CN", "TW", "TH"} for c in countries):
        return "Dorama"
    return "Série"


def save_result(media: str, record: dict) -> str | None:
    if record.get("adult") is True:
        return None
    tid = record.get("id")
    title = (record.get("title") or record.get("name") or "").strip()
    if not isinstance(tid, int) or not title:
        return None
    ident = f"tmdb:{media}:{tid}"
    kind = kind_for(media, record)
    raw = TITLES.get(ident)
    if raw:
        raw["popularity"] = max(
            raw.get("popularity", 0.0),
            float(record.get("popularity") or 0),
        )
        # A later discovery list may contain artwork missing in the first hit.
        backdrop = record.get("backdrop_path") or ""
        if isinstance(backdrop, str) and re.fullmatch(r"/[a-zA-Z0-9_./-]+", backdrop) and not raw.get("backdropUrl"):
            raw["backdropUrl"] = "https://image.tmdb.org/t/p/w1280" + backdrop
        return ident
    poster = record.get("poster_path") or ""
    if poster and not re.fullmatch(r"/[a-zA-Z0-9_./-]+", poster):
        poster = ""
    backdrop = record.get("backdrop_path") or ""
    if not isinstance(backdrop, str) or not re.fullmatch(r"/[a-zA-Z0-9_./-]+", backdrop):
        backdrop = ""
    description = (record.get("overview") or "").strip()
    TITLES[ident] = {
        "id": ident,
        "title": title,
        "originalTitle": (record.get("original_title") or
                          record.get("original_name") or title).strip(),
        "imdbId": record.get("imdb_id")
            if isinstance(record.get("imdb_id"), str) and
            re.fullmatch(r"tt[0-9]{7,10}", record["imdb_id"])
            else "",
        "kind": kind,
        "description": description[:1400],
        "year": year(record.get("release_date") or
                     record.get("first_air_date")),
        "posterUrl": ("https://image.tmdb.org/t/p/w500" + poster) if poster else "",
        "backdropUrl": ("https://image.tmdb.org/t/p/w1280" + backdrop) if backdrop else "",
        "creator": "",
        "provider": "TMDB",
        "detailUrl": f"https://www.themoviedb.org/{media}/{tid}",
        "popularity": round(float(record.get("popularity") or 0), 3),
        "genreIds": [int(g) for g in (record.get("genre_ids") or []) if isinstance(g, int)],
        "tmdbVoteAverage": round(float(record.get("vote_average") or 0.0), 2),
        "tmdbVoteCount": int(record.get("vote_count") or 0),
        "streamingProviders": {},
        "watchProviders": [],
        "watchUrl": "",
        "trailerYoutubeId": "",
        "trailerYoutubeIds": [],
        "originalLanguage": (record.get("original_language") or "").lower(),
        "externalRatings": {},
        "ratingsUpdatedAt": "",
        "availabilityChecked": False,
    }
    return ident


def crawl_discover(media: str, label: str, params: dict, page_count: int,
                   provider_name: str | None = None) -> None:
    loaded = 0
    for p in range(1, page_count + 1):
        response = get("/discover/" + media, {
            "language": "pt-BR",
            "include_adult": "false",
            "page": p,
            "sort_by": "popularity.desc",
            **params,
        })
        rows = response.get("results") or []
        if not isinstance(rows, list) or not rows:
            break
        for row in rows:
            if not isinstance(row, dict):
                continue
            identity = save_result(media, row)
            if identity:
                loaded += 1
                if provider_name:
                    SEEN_PROVIDER.setdefault(identity, set()).add(provider_name)
        if p >= int(response.get("total_pages", 1)):
            break
    print(f"{label}: {loaded} results")


def provider_ids(media: str) -> dict[str, int]:
    response = get("/watch/providers/" + media, {
        "language": "pt-BR", "watch_region": "BR",
    })
    found: dict[str, int] = {}
    # We only accept standalone subscription products, never channel add-ons.
    names = {
        "netflix": {"netflix"},
        "primeVideo": {"amazon prime video", "prime video"},
        "crunchyroll": {"crunchyroll"},
    }
    for record in response.get("results", []):
        if not isinstance(record, dict):
            continue
        name = str(record.get("provider_name") or "").casefold().strip()
        for service, aliases in names.items():
            if name in aliases and isinstance(record.get("provider_id"), int):
                found[service] = record["provider_id"]
    return found


def enrich_single(ident: str, provider_map: dict[str, dict[str, int]]) -> None:
    _, media, sid = ident.split(":")
    response = get(f"/{media}/{sid}/watch/providers")
    data = response.get("results")
    region = data.get("BR") if isinstance(data, dict) else None
    item = TITLES[ident]
    item["availabilityChecked"] = True
    item["streamingProviders"] = {}
    item["watchProviders"] = []
    if not isinstance(region, dict):
        return
    url = region.get("link")
    if isinstance(url, str) and url.startswith(
        "https://www.themoviedb.org/"
    ):
        item["watchUrl"] = url
    offers = region.get("flatrate") or []
    ids = {
        key: value for key, value in provider_map.get(media, {}).items()
    }
    for offer in offers:
        if not isinstance(offer, dict):
            continue
        pid = offer.get("provider_id")
        pname = str(offer.get("provider_name") or "").strip()
        if pname and pname not in item["watchProviders"]:
            item["watchProviders"].append(pname)
        for service, known_id in ids.items():
            if pid == known_id:
                item["streamingProviders"][service] = pname


def best_panorama(payload: dict) -> str:
    """Use verified widescreen TMDB stills, never posters or fuzzy titles."""
    choices = []
    for image in payload.get("backdrops") or []:
        if not isinstance(image, dict):
            continue
        path = image.get("file_path")
        width = image.get("width")
        height = image.get("height")
        ratio = image.get("aspect_ratio")
        if (not isinstance(path, str) or ".." in path or
            not re.fullmatch(r"/[a-zA-Z0-9_./-]+[.](?:jpg|jpeg|png|webp)", path) or
            not isinstance(width, int) or width < 1280 or
            not isinstance(height, int) or height < 640 or
            not isinstance(ratio, (float, int)) or
            not 1.5 <= float(ratio) <= 2.5):
            continue
        votes = image.get("vote_average") or 0
        count = image.get("vote_count") or 0
        # Natural, text-free scenery is preferred to artwork with language.
        language = image.get("iso_639_1")
        score = ((1 if language is None else 0),
                 float(votes), int(count), width)
        choices.append((score, path))
    if not choices:
        return ""
    choices.sort(reverse=True)
    return "https://image.tmdb.org/t/p/w1280" + choices[0][1]


def trailer_youtube_ids(payload: dict, original_language: str = "") -> list[str]:
    """Rank real TMDB-linked YouTube videos; prefer original speech.

    Keep up to four different IDs so an unavailable/restricted embed can
    switch to another official candidate without guessing or scraping.
    """
    candidates = []
    for row in payload.get("results") or []:
        if not isinstance(row, dict):
            continue
        key = row.get("key")
        if (row.get("site") != "YouTube" or
            row.get("type") not in ("Trailer", "Teaser") or
            not isinstance(key, str) or
            not re.fullmatch(r"[A-Za-z0-9_-]{11}", key)):
            continue
        language = str(row.get("iso_639_1") or "").lower()
        country = str(row.get("iso_3166_1") or "").upper()
        original = original_language.lower()
        score = (
            int(row.get("type") == "Trailer") * 1000
            + int(bool(original) and language == original) * 330
            + int(row.get("official") is True) * 110
            + (50 if language == "pt" else 30 if language == "en" else 0)
            + (9 if country == "BR" else 0)
        )
        candidates.append((score, key))
    candidates.sort(reverse=True)
    result = []
    for _, key in candidates:
        if key not in result:
            result.append(key)
        if len(result) >= 4:
            break
    return result


def trailer_youtube_id(payload: dict) -> str:
    """Compatibility helper used by old fixtures and snapshot consumers."""
    return next(iter(trailer_youtube_ids(payload)), "")


def parse_omdb_ratings(payload: dict) -> dict[str, str]:
    """Expose only values explicitly supplied, validated and attributed."""
    if not isinstance(payload, dict) or payload.get("Response") != "True":
        return {}
    known = {
        "Internet Movie Database": ("imdb", re.compile(r"^(10(?:\.0)?|[0-9](?:\.[0-9])?)/10$")),
        "Rotten Tomatoes": ("rottenTomatoes", re.compile(r"^(100|[0-9]{1,2})%$")),
        "Metacritic": ("metacritic", re.compile(r"^(100|[0-9]{1,2})/100$")),
    }
    result = {}
    for rating in payload.get("Ratings") or []:
        if not isinstance(rating, dict):
            continue
        info = known.get(rating.get("Source"))
        value = rating.get("Value")
        if info is not None and isinstance(value, str) and info[1].fullmatch(value):
            result[info[0]] = value
    return result


def verified_critic_scores(ident: str) -> dict[str, str]:
    if not OMDB_API_KEY:
        return {}
    _, media, sid = ident.split(":")
    raw = get(f"/{media}/{sid}/external_ids")
    imdb_id = raw.get("imdb_id")
    if not isinstance(imdb_id, str) or not re.fullmatch(r"tt[0-9]{7,10}", imdb_id):
        return {}
    # OMDb's API is used privately; never print or persist its API key.
    url = "https://www.omdbapi.com/?" + urllib.parse.urlencode({
        "apikey": OMDB_API_KEY, "i": imdb_id, "r": "json",
    })
    request = urllib.request.Request(url, headers={
        "Accept": "application/json",
        "User-Agent": "SATURN-personal-ratings/0.7",
    })
    with urllib.request.urlopen(request, timeout=12) as response:
        payload = json.load(response)
    time.sleep(0.13)
    return parse_omdb_ratings(payload)


def build() -> None:
    provider_map = {
        "movie": provider_ids("movie"),
        "tv": provider_ids("tv"),
    }
    # Explore by popularity and original language; discovery is not a full
    # mirror of TMDB, and filters may overlap (IDs are deduplicated).
    crawl_discover("movie", "popular movies", {},
                   MAX_PAGES)
    crawl_discover("movie", "high-rated movies",
                   {"sort_by": "vote_average.desc", "vote_count.gte": 400},
                   min(MAX_PAGES, 20))
    crawl_discover("tv", "popular series", {}, MAX_PAGES)
    crawl_discover("tv", "high-rated series",
                   {"vote_count.gte": 100, "sort_by": "vote_average.desc"},
                   min(MAX_PAGES, 20))
    for language in ["ko", "ja", "zh", "th"]:
        crawl_discover(
            "tv", f"dramas-{language}", {"with_original_language": language},
            min(MAX_PAGES, 20),
        )
    crawl_discover(
        "tv", "anime-JP",
        {"with_original_language": "ja", "with_genres": 16},
        min(MAX_PAGES, 30),
    )
    for media in ["movie", "tv"]:
        for service, provider_id in provider_map[media].items():
            crawl_discover(
                media, f"{service}-{media}-Brazil-subscription", {
                    "with_watch_providers": str(provider_id),
                    "watch_region": "BR",
                    "with_watch_monetization_types": "flatrate",
                }, MAX_PAGES, provider_name=service,
            )

    # Provider-filtered discovery is already a grounded BR subscription signal.
    # Detailed watch-provider queries improve precise availability and
    # enumerate other streaming services, capped to protect API quotas.
    for ident, services in SEEN_PROVIDER.items():
        for service in sorted(services):
            TITLES[ident]["streamingProviders"][service] = {
                "netflix": "Netflix",
                "crunchyroll": "Crunchyroll",
                "primeVideo": "Prime Video",
            }[service]
    prioritized = sorted(
        TITLES,
        key=lambda ident: (bool(SEEN_PROVIDER.get(ident)),
                           TITLES[ident]["popularity"]),
        reverse=True,
    )
    for i, ident in enumerate(prioritized[:MAX_DETAILS]):
        try:
            enrich_single(ident, provider_map)
        except Exception as exc:
            # Retain the provider-filter signal; do not forge a URL.
            print(f"Warning: unable to enrich {ident}: {type(exc).__name__}",
                  file=sys.stderr)
        if (i + 1) % 100 == 0:
            print(f"Watch provider details: {i + 1}")

    verified_imdb_count = 0
    for ident in prioritized[:MAX_IMDB_LOOKUPS]:
        if TITLES[ident].get("imdbId"):
            continue
        try:
            _, media, sid = ident.split(":")
            external = get(f"/{media}/{sid}/external_ids")
            imdb_id = external.get("imdb_id")
            if isinstance(imdb_id, str) and re.fullmatch(
                r"tt[0-9]{7,10}", imdb_id):
                TITLES[ident]["imdbId"] = imdb_id
                verified_imdb_count += 1
        except Exception as exc:
            print(f"IMDb ID unavailable for {ident}: {type(exc).__name__}",
                  file=sys.stderr)
    print(f"Verified extra IMDb identifiers: {verified_imdb_count}")

    missing_artwork = [ident for ident in prioritized
                       if not TITLES[ident]["backdropUrl"]]
    rescued = 0
    for ident in missing_artwork[:MAX_PANORAMA_LOOKUPS]:
        try:
            _, media, sid = ident.split(":")
            images = get(f"/{media}/{sid}/images", {
                "include_image_language": "pt,en,null",
            })
            panorama = best_panorama(images)
            if panorama:
                TITLES[ident]["backdropUrl"] = panorama
                rescued += 1
        except Exception as exc:
            print(f"Backdrop lookup failed for {ident}: {type(exc).__name__}",
                  file=sys.stderr)
    print(f"Extra authentic panoramas: {rescued} of "
          f"{min(len(missing_artwork), MAX_PANORAMA_LOOKUPS)} lookups")

    for ident in prioritized[:MAX_TRAILERS]:
        try:
            _, media, sid = ident.split(":")
            original = str(TITLES[ident].get("originalLanguage") or "")
            local = {
                "ja": "ja-JP", "ko": "ko-KR", "zh": "zh-CN",
                "es": "es-ES", "fr": "fr-FR", "de": "de-DE",
                "hi": "hi-IN", "en": "en-US", "pt": "pt-BR",
            }.get(original, "")
            languages = ",".join(dict.fromkeys([
                x for x in [local, "en-US", "pt-BR", "null"] if x
            ]))
            payload = get(f"/{media}/{sid}/videos", {
                "language": "en-US",
                "include_video_language": languages,
            })
            alternatives = trailer_youtube_ids(payload, original)
            TITLES[ident]["trailerYoutubeIds"] = alternatives
            TITLES[ident]["trailerYoutubeId"] = (
                alternatives[0] if alternatives else "")
        except Exception as exc:
            print(f"Trailer not available for {ident}: {type(exc).__name__}",
                  file=sys.stderr)

    if OMDB_API_KEY:
        count = 0
        for ident in prioritized[:MAX_CRITIC_LOOKUPS]:
            try:
                ratings = verified_critic_scores(ident)
                if ratings:
                    TITLES[ident]["externalRatings"] = ratings
                    TITLES[ident]["ratingsUpdatedAt"] = NOW
                    count += 1
            except Exception as error:
                # Never print URL/exception text containing API secrets.
                print(f"Critic ratings unavailable for {ident}: {type(error).__name__}",
                      file=sys.stderr)
        print(f"Found externally attributed critic scores for {count} titles")
    else:
        print("OMDb key not configured: no IMDb/Rotten/Metacritic scores generated.")

    groups = {"movies": [], "series": [], "dramas": [], "anime": []}
    for item in TITLES.values():
        category = {
            "Filme": "movies", "Série": "series",
            "Dorama": "dramas", "Anime": "anime",
        }[item["kind"]]
        groups[category].append(item)
    OUT.mkdir(parents=True, exist_ok=True)
    stats = {}
    for name, rows in groups.items():
        rows.sort(key=lambda row: row["popularity"], reverse=True)
        stats[name] = len(rows)
        with (OUT / f"{name}.json").open("w", encoding="utf-8") as handle:
            json.dump({
                "schema": 1,
                "source": "TMDB / JustWatch",
                "country": "BR",
                "generatedAt": NOW,
                "results": rows,
            }, handle, ensure_ascii=False, separators=(",", ":"))
    with (OUT / "manifest.json").open("w", encoding="utf-8") as handle:
        json.dump({
            "schema": 1,
            "source": "TMDB / JustWatch",
            "country": "BR",
            "generatedAt": NOW,
            "counts": stats,
            "panoramas": {
                "available": sum(bool(x["backdropUrl"]) for x in TITLES.values()),
                "enhanced": rescued,
            },
        }, handle, ensure_ascii=False, separators=(",", ":"))
    print(json.dumps({
        "source": "TMDB / JustWatch", "counts": stats,
        "requests": TOTAL_CALLS, "checked": min(MAX_DETAILS, len(prioritized)),
        "trailerLookups": min(MAX_TRAILERS, len(prioritized)),
    }))


if __name__ == "__main__":
    build()
