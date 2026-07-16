#!/usr/bin/env python3
"""Add openly licensed Wikimedia Commons plant photos to the catalog."""

from __future__ import annotations

import argparse
import concurrent.futures
import html
import json
import re
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

import requests
from bs4 import BeautifulSoup


DEFAULT_CATALOG = Path("YouDuMa/Resources/Data/aspca_plants_v1.json")
DEFAULT_METADATA = Path("YouDuMa/Resources/Data/aspca_database_metadata.json")
DEFAULT_OVERRIDES = Path("tools/plant_image_query_overrides.json")
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
WIKIDATA_ENDPOINT = "https://query.wikidata.org/sparql"
USER_AGENT = "IsItPoisonous/1.0 (https://github.com/MingyiLiuProject/Is-it-poisonous)"
ALLOWED_LICENSE_PREFIXES = (
    "CC0",
    "CC BY",
    "CC-BY",
    "Public domain",
    "Public Domain",
    "PDM",
)
PHOTO_REJECTION_TERMS = (
    "drawing",
    "illustration",
    "herbarium",
    "specimen",
    "distribution map",
    "range map",
    "botanical plate",
    "stamp",
    "painting",
    "poster",
)
METADATA_FILTER = "|".join(
    [
        "Artist",
        "Credit",
        "ImageDescription",
        "LicenseShortName",
        "LicenseUrl",
    ]
)


def clean_html(value: str) -> str:
    unescaped = html.unescape(value or "")
    if "<" not in unescaped:
        return re.sub(r"\s+", " ", unescaped).strip()
    text = BeautifulSoup(unescaped, "html.parser").get_text(" ")
    return re.sub(r"\s+", " ", text).strip()


def commons_title_from_url(value: str) -> str:
    filename = unquote(urlparse(value).path.rsplit("/", 1)[-1])
    return f"File:{filename.replace('_', ' ')}"


def accepted_names(plants: list[dict[str, Any]]) -> set[str]:
    return {
        plant["acceptedScientificName"].strip()
        for plant in plants
        if plant["acceptedScientificName"].strip()
        and not plant["acceptedScientificName"].startswith("ASPCA ")
    }


def query_wikidata_images(names: set[str]) -> dict[str, list[str]]:
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    images: dict[str, list[str]] = {}
    ordered = sorted(names)

    for start in range(0, len(ordered), 60):
        batch = ordered[start : start + 60]
        values = " ".join(json.dumps(name, ensure_ascii=False) for name in batch)
        query = f"""
        SELECT ?taxonName ?image WHERE {{
          VALUES ?taxonName {{ {values} }}
          ?taxon wdt:P225 ?taxonName;
                 wdt:P18 ?image.
        }}
        """
        response = session.get(
            WIKIDATA_ENDPOINT,
            params={"query": query, "format": "json"},
            timeout=90,
        )
        response.raise_for_status()
        for result in response.json()["results"]["bindings"]:
            name = result["taxonName"]["value"]
            title = commons_title_from_url(result["image"]["value"])
            images.setdefault(name, [])
            if title not in images[name]:
                images[name].append(title)
        time.sleep(0.1)

    return images


def metadata_value(metadata: dict[str, Any], key: str) -> str:
    return clean_html(str(metadata.get(key, {}).get("value", "")))


def is_allowed_license(license_name: str) -> bool:
    return any(license_name.startswith(prefix) for prefix in ALLOWED_LICENSE_PREFIXES)


def get_with_retry(
    session: requests.Session,
    url: str,
    *,
    params: dict[str, Any],
    timeout: int = 90,
) -> requests.Response:
    for attempt in range(6):
        response = session.get(url, params=params, timeout=timeout)
        if response.status_code != 429:
            response.raise_for_status()
            return response
        retry_after = int(response.headers.get("Retry-After", "0") or 0)
        time.sleep(max(retry_after, 2 ** (attempt + 1)))
    response.raise_for_status()
    return response


def parse_image(page: dict[str, Any], match_type: str) -> dict[str, Any] | None:
    image_info = (page.get("imageinfo") or [{}])[0]
    metadata = image_info.get("extmetadata", {})
    license_name = metadata_value(metadata, "LicenseShortName")
    if not is_allowed_license(license_name):
        return None
    if not image_info.get("thumburl") or not image_info.get("descriptionurl"):
        return None
    if image_info.get("mime") != "image/jpeg":
        return None

    title = page.get("title", "")
    normalized_title = title.casefold()
    if any(term in normalized_title for term in PHOTO_REJECTION_TERMS):
        return None

    author = metadata_value(metadata, "Artist") or image_info.get("user", "")
    if not author:
        return None

    return {
        "thumbnailURL": image_info["thumburl"],
        "pageURL": image_info["descriptionurl"],
        "fileTitle": title.removeprefix("File:"),
        "author": author,
        "license": license_name,
        "licenseURL": metadata_value(metadata, "LicenseUrl"),
        "description": metadata_value(metadata, "ImageDescription"),
        "source": "Wikimedia Commons",
        "matchType": match_type,
        "needsReview": match_type != "wikidataTaxonImage",
    }


def fetch_titles(titles: list[str], match_type: str) -> list[dict[str, Any]]:
    if not titles:
        return []
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    candidates: list[dict[str, Any]] = []

    for start in range(0, len(titles), 40):
        response = get_with_retry(
            session,
            COMMONS_API,
            params={
                "action": "query",
                "format": "json",
                "formatversion": 2,
                "prop": "imageinfo",
                "titles": "|".join(titles[start : start + 40]),
                "iiprop": "url|size|mime|mediatype|user|extmetadata",
                "iiurlwidth": 500,
                "iiextmetadatalanguage": "en",
                "iiextmetadatafilter": METADATA_FILTER,
            },
        )
        for page in response.json().get("query", {}).get("pages", []):
            image = parse_image(page, match_type)
            if image:
                candidates.append(image)
    return candidates


def search_commons(
    name: str,
    match_type: str = "commonsScientificNameSearch",
) -> tuple[str, dict[str, Any] | None]:
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    try:
        response = get_with_retry(
            session,
            COMMONS_API,
            params={
                "action": "query",
                "format": "json",
                "formatversion": 2,
                "generator": "search",
                "gsrsearch": (
                    f'"{name}" filetype:bitmap'
                    if match_type == "commonsScientificNameSearch"
                    else f'"{name}" plant filetype:bitmap'
                ),
                "gsrnamespace": 6,
                "gsrlimit": 8,
                "prop": "imageinfo",
                "iiprop": "url|size|mime|mediatype|user|extmetadata",
                "iiurlwidth": 500,
                "iiextmetadatalanguage": "en",
                "iiextmetadatafilter": METADATA_FILTER,
            },
        )
        pages = response.json().get("query", {}).get("pages", [])
        candidates = [
            image
            for page in pages
            if (image := parse_image(page, match_type))
        ]
        if not candidates:
            return name, None

        normalized_name = re.sub(r"[^a-z0-9]", "", name.casefold())

        def score(image: dict[str, Any]) -> tuple[int, str]:
            normalized_title = re.sub(
                r"[^a-z0-9]",
                "",
                image["fileTitle"].casefold(),
            )
            exact_name_bonus = 100 if normalized_name in normalized_title else 0
            cc0_bonus = 10 if image["license"].startswith("CC0") else 0
            return exact_name_bonus + cc0_bonus, image["fileTitle"]

        return name, max(candidates, key=score)
    except (requests.RequestException, ValueError):
        return name, None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--metadata", type=Path, default=DEFAULT_METADATA)
    parser.add_argument("--overrides", type=Path, default=DEFAULT_OVERRIDES)
    args = parser.parse_args()

    plants = json.loads(args.catalog.read_text(encoding="utf-8"))
    overrides = json.loads(args.overrides.read_text(encoding="utf-8"))
    names = accepted_names(plants)
    wikidata_titles = query_wikidata_images(names)

    title_images = {
        image["fileTitle"].casefold(): image
        for image in fetch_titles(
            sorted({title for titles in wikidata_titles.values() for title in titles}),
            "wikidataTaxonImage",
        )
    }
    exact_images: dict[str, dict[str, Any]] = {}
    for name, titles in wikidata_titles.items():
        candidates = [
            title_images[title.removeprefix("File:").casefold()]
            for title in titles
            if title.removeprefix("File:").casefold() in title_images
        ]
        if candidates:
            exact_images[name] = candidates[0]

    missing_names = names - exact_images.keys()
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        fallback_images = dict(executor.map(search_commons, sorted(missing_names)))

    missing_common_names = {
        plant["englishName"]
        for plant in plants
        if not (
            exact_images.get(plant["acceptedScientificName"].strip())
            or fallback_images.get(plant["acceptedScientificName"].strip())
        )
    }
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        common_name_images = dict(
            executor.map(
                lambda name: search_commons(name, "commonsCommonNameSearch"),
                sorted(missing_common_names),
            )
        )

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        override_images = dict(
            executor.map(
                lambda name: search_commons(name, "manualQueryOverride"),
                sorted(set(overrides.values())),
            )
        )

    enriched: list[dict[str, Any]] = []
    for plant in plants:
        name = plant["acceptedScientificName"].strip()
        image = (
            exact_images.get(name)
            or fallback_images.get(name)
            or common_name_images.get(plant["englishName"])
            or override_images.get(overrides.get(plant["id"], ""))
        )
        output = dict(plant)
        output["image"] = image
        enriched.append(output)

    args.catalog.write_text(
        json.dumps(enriched, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    source_counts = Counter(
        plant["image"]["matchType"]
        for plant in enriched
        if plant["image"] is not None
    )
    image_count = sum(plant["image"] is not None for plant in enriched)
    review_count = sum(
        bool(plant["image"] and plant["image"]["needsReview"])
        for plant in enriched
    )
    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    metadata.update(
        {
            "schemaVersion": 3,
            "datasetVersion": f"aspca-v3-images-{datetime.now(timezone.utc):%Y-%m-%d}",
            "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "imageEnrichment": {
                "imageCount": image_count,
                "missingImageCount": len(enriched) - image_count,
                "needsReviewCount": review_count,
                "sourceCounts": dict(source_counts),
                "source": "https://commons.wikimedia.org/",
                "thumbnailWidth": 500,
                "licensePolicy": "CC0, Public Domain, CC BY, and CC BY-SA",
            },
        }
    )
    image_note = (
        "Plant images are loaded from Wikimedia Commons and retain author, "
        "license, and source-page attribution."
    )
    if image_note not in metadata["notes"]:
        metadata["notes"].append(image_note)
    args.metadata.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    print(
        f"Images for {image_count}/{len(enriched)} plants; "
        f"{review_count} search matches need review; sources={dict(source_counts)}"
    )


if __name__ == "__main__":
    main()
