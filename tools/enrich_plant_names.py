#!/usr/bin/env python3
"""Enrich the versioned plant catalog with Chinese and pinyin search names."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests
from deep_translator import GoogleTranslator
from opencc import OpenCC
from pypinyin import Style, lazy_pinyin


DEFAULT_CATALOG = Path("YouDuMa/Resources/Data/aspca_plants_v1.json")
DEFAULT_METADATA = Path("YouDuMa/Resources/Data/aspca_database_metadata.json")
DEFAULT_OVERRIDES = Path("tools/chinese_name_overrides.json")
WIKIDATA_ENDPOINT = "https://query.wikidata.org/sparql"
GBIF_MATCH_ENDPOINT = "https://api.gbif.org/v1/species/match"
USER_AGENT = "IsItPoisonous/1.0 (https://github.com/MingyiLiuProject/Is-it-poisonous)"
PET_DATA_FIELDS = {
    "id",
    "chineseName",
    "englishName",
    "scientificName",
    "family",
    "aliases",
    "toxicTo",
    "nonToxicTo",
    "toxicPrinciples",
    "clinicalSigns",
    "sourceURL",
}


def normalize_scientific_name(value: str) -> str:
    value = value.replace("\u00a0", " ").strip()
    value = re.sub(r"\s+(spp\.?|sp\.?|species)$", "", value, flags=re.IGNORECASE)
    value = re.sub(r"\s+cv\.?\s+.*$", "", value, flags=re.IGNORECASE)
    value = re.sub(r"\s+'[^']+'$", "", value)
    return re.sub(r"\s+", " ", value).strip()


def contains_han(value: str) -> bool:
    return bool(re.search(r"[\u3400-\u9fff]", value))


def split_chinese_names(value: str) -> list[str]:
    parts = re.split(r"[、,，;/；]|\s+\(|\)", value)
    return [
        part.strip()
        for part in parts
        if contains_han(part) and 1 < len(part.strip()) <= 18
    ]


def query_wikidata_labels(names: set[str]) -> dict[str, str]:
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    labels: dict[str, str] = {}
    ordered = sorted(name for name in names if name)

    for start in range(0, len(ordered), 60):
        batch = ordered[start : start + 60]
        values = " ".join(json.dumps(name, ensure_ascii=False) for name in batch)
        query = f"""
        SELECT ?taxonName ?taxonLabel WHERE {{
          VALUES ?taxonName {{ {values} }}
          ?taxon wdt:P225 ?taxonName.
          SERVICE wikibase:label {{
            bd:serviceParam wikibase:language "zh-hans,zh,en".
          }}
        }}
        """
        response = session.get(
            WIKIDATA_ENDPOINT,
            params={"query": query, "format": "json"},
            timeout=90,
        )
        response.raise_for_status()
        for result in response.json()["results"]["bindings"]:
            label = result.get("taxonLabel", {})
            if label.get("xml:lang", "").startswith("zh"):
                labels[result["taxonName"]["value"]] = label["value"]
        time.sleep(0.15)

    return labels


def fetch_gbif_record(scientific_name: str) -> tuple[str, dict[str, Any]]:
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    try:
        match = session.get(
            GBIF_MATCH_ENDPOINT,
            params={"name": scientific_name, "kingdom": "Plantae"},
            timeout=45,
        ).json()
        usage_key = match.get("usageKey") or match.get("taxonKey")
        vernaculars: list[dict[str, Any]] = []
        if usage_key:
            response = session.get(
                f"https://api.gbif.org/v1/species/{usage_key}/vernacularNames",
                params={"limit": 100},
                timeout=45,
            )
            if response.ok:
                vernaculars = response.json().get("results", [])
        return scientific_name, {
            "acceptedName": match.get("canonicalName") or match.get("scientificName"),
            "confidence": match.get("confidence") or 0,
            "matchType": match.get("matchType") or "",
            "rank": match.get("rank") or "",
            "vernaculars": vernaculars,
        }
    except (requests.RequestException, ValueError):
        return scientific_name, {
            "acceptedName": None,
            "confidence": 0,
            "matchType": "",
            "rank": "",
            "vernaculars": [],
        }


def fetch_gbif_records(names: set[str]) -> dict[str, dict[str, Any]]:
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        return dict(executor.map(fetch_gbif_record, sorted(name for name in names if name)))


def gbif_chinese_names(record: dict[str, Any], converter: OpenCC) -> list[str]:
    candidates: list[tuple[bool, str]] = []
    for item in record.get("vernaculars", []):
        language = str(item.get("language", "")).lower()
        raw_name = item.get("vernacularName", "")
        if language not in {"zho", "zh", "chinese"} or not contains_han(raw_name):
            continue
        for name in split_chinese_names(converter.convert(raw_name)):
            candidates.append((bool(item.get("preferred")), name))

    return list(
        dict.fromkeys(
            name
            for _, name in sorted(
                candidates,
                key=lambda item: (not item[0], len(item[1]), item[1]),
            )
        )
    )


def translate_missing_names(english_names: list[str]) -> dict[str, str]:
    translator = GoogleTranslator(source="en", target="zh-CN")
    translated: dict[str, str] = {}
    unique_names = list(dict.fromkeys(english_names))

    for start in range(0, len(unique_names), 30):
        batch = unique_names[start : start + 30]
        try:
            results = translator.translate_batch(batch)
        except Exception:
            results = [translator.translate(name) for name in batch]
        for english_name, chinese_name in zip(batch, results):
            translated[english_name] = chinese_name.strip()
        time.sleep(0.25)

    return translated


def pinyin_terms(names: list[str]) -> list[str]:
    terms: list[str] = []
    for name in names:
        syllables = lazy_pinyin(name, style=Style.NORMAL, errors="ignore")
        if not syllables:
            continue
        terms.extend(
            [
                " ".join(syllables).lower(),
                "".join(syllables).lower(),
                "".join(syllable[0] for syllable in syllables if syllable).lower(),
            ]
        )
    return list(dict.fromkeys(term for term in terms if term))


def is_safe_accepted_name(record: dict[str, Any]) -> bool:
    return (
        bool(record.get("acceptedName"))
        and record.get("confidence", 0) >= 80
        and record.get("rank") not in {"KINGDOM", "PHYLUM", "CLASS", "ORDER"}
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--metadata", type=Path, default=DEFAULT_METADATA)
    parser.add_argument("--overrides", type=Path, default=DEFAULT_OVERRIDES)
    args = parser.parse_args()

    plants = json.loads(args.catalog.read_text(encoding="utf-8"))
    overrides = json.loads(args.overrides.read_text(encoding="utf-8"))
    converter = OpenCC("t2s")

    normalized_names = {
        normalize_scientific_name(plant["scientificName"]) for plant in plants
    }
    gbif = fetch_gbif_records(normalized_names)
    accepted_names = {
        record["acceptedName"]
        for record in gbif.values()
        if is_safe_accepted_name(record)
    }
    wikidata = query_wikidata_labels(normalized_names | accepted_names)

    unresolved_english_names: list[str] = []
    preliminary: list[dict[str, Any]] = []
    for plant in plants:
        source_name = normalize_scientific_name(plant["scientificName"])
        record = gbif.get(source_name, {})
        accepted_name = record.get("acceptedName") if is_safe_accepted_name(record) else None
        override = overrides.get(source_name) or overrides.get(f"id:{plant['id']}")
        vernacular_names = gbif_chinese_names(record, converter)

        if override:
            chinese_name = override["name"]
            chinese_aliases = override.get("aliases", [])
            source = "reviewed"
            needs_review = False
        elif source_name in wikidata:
            chinese_name = converter.convert(wikidata[source_name])
            chinese_aliases = vernacular_names
            source = "wikidata"
            needs_review = False
        elif vernacular_names:
            chinese_name = vernacular_names[0]
            chinese_aliases = vernacular_names[1:]
            source = "gbif"
            needs_review = False
        elif accepted_name in wikidata:
            chinese_name = converter.convert(wikidata[accepted_name])
            chinese_aliases = []
            source = "wikidataAcceptedTaxon"
            needs_review = record.get("matchType") != "EXACT"
        else:
            chinese_name = ""
            chinese_aliases = []
            source = "translatedFallback"
            needs_review = True
            unresolved_english_names.append(plant["englishName"])

        preliminary.append(
            {
                "plant": plant,
                "acceptedScientificName": (
                    (override or {}).get("acceptedScientificName")
                    or accepted_name
                    or plant["scientificName"].strip()
                    or "ASPCA 未提供学名"
                ),
                "chineseName": chinese_name,
                "chineseAliases": chinese_aliases,
                "nameSource": source,
                "nameNeedsReview": (
                    needs_review
                    or (
                        not plant["scientificName"].strip()
                        and not (override or {}).get("acceptedScientificName")
                    )
                ),
            }
        )

    translations = translate_missing_names(unresolved_english_names)
    enriched: list[dict[str, Any]] = []
    for item in preliminary:
        plant = item.pop("plant")
        if not item["chineseName"]:
            translated_name = translations.get(plant["englishName"], "").strip()
            item["chineseName"] = (
                translated_name
                if contains_han(translated_name)
                else f"待核对译名（{plant['englishName']}）"
            )

        chinese_names = list(
            dict.fromkeys([item["chineseName"]] + item["chineseAliases"])
        )
        item["chineseAliases"] = [
            name for name in chinese_names[1:] if name != item["chineseName"]
        ]
        item["pinyin"] = pinyin_terms(chinese_names)

        output = {key: value for key, value in plant.items() if key in PET_DATA_FIELDS}
        output.update(item)
        enriched.append(output)

    assert len(enriched) == len(plants)
    assert all(contains_han(plant["chineseName"]) for plant in enriched)
    assert all(plant["acceptedScientificName"] for plant in enriched)
    assert all(plant["pinyin"] for plant in enriched)

    args.catalog.write_text(
        json.dumps(enriched, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    counts: dict[str, int] = {}
    for plant in enriched:
        counts[plant["nameSource"]] = counts.get(plant["nameSource"], 0) + 1

    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    metadata.update(
        {
            "schemaVersion": 2,
            "datasetVersion": f"aspca-v2-multilingual-{datetime.now(timezone.utc):%Y-%m-%d}",
            "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "nameEnrichment": {
                "chineseNameCount": len(enriched),
                "professionalNameCount": len(enriched),
                "pinyinCount": len(enriched),
                "needsReviewCount": sum(
                    plant["nameNeedsReview"] for plant in enriched
                ),
                "sourceCounts": counts,
                "sources": {
                    "wikidata": "https://www.wikidata.org/",
                    "gbif": "https://www.gbif.org/",
                },
            },
        }
    )
    review_note = (
        "Automatically matched or translated names remain explicitly marked "
        "for professional review."
    )
    if review_note not in metadata["notes"]:
        metadata["notes"].append(review_note)
    args.metadata.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Enriched {len(enriched)} plants: {counts}")


if __name__ == "__main__":
    main()
