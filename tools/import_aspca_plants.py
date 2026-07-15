#!/usr/bin/env python3
"""Build the versioned ASPCA plant catalog used by the iOS app.

The importer intentionally stores list-level factual fields and source URLs only.
It does not download ASPCA images or copy detail-page clinical prose.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup


BASE_URL = "https://www.aspca.org"
SOURCES = {
    "dog": f"{BASE_URL}/pet-care/animal-poison-control/dogs-plant-list",
    "cat": f"{BASE_URL}/pet-care/animal-poison-control/cats-plant-list",
    "horse": f"{BASE_URL}/pet-care/animal-poison-control/horse-plant-list",
}
PET_ORDER = ("cat", "dog", "horse")
DEFAULT_OUTPUT = Path("YouDuMa/Resources/Data/aspca_plants_v1.json")
DEFAULT_METADATA = Path("YouDuMa/Resources/Data/aspca_database_metadata.json")


@dataclass
class CatalogPlant:
    id: str
    name: str
    scientific_name: str
    family: str
    aliases: set[str] = field(default_factory=set)
    toxic_to: set[str] = field(default_factory=set)
    non_toxic_to: set[str] = field(default_factory=set)
    source_url: str = ""

    def apply_status(self, pet: str, status: str) -> None:
        if status == "toxic":
            if pet in self.non_toxic_to:
                raise ValueError(f"Conflicting status for {self.id}: {pet}")
            self.toxic_to.add(pet)
        else:
            if pet in self.toxic_to:
                raise ValueError(f"Conflicting status for {self.id}: {pet}")
            self.non_toxic_to.add(pet)

    def as_json(self) -> dict[str, object]:
        return {
            "id": self.id,
            "chineseName": self.name,
            "englishName": self.name,
            "scientificName": self.scientific_name,
            "family": self.family,
            "aliases": sorted(self.aliases, key=str.casefold),
            "toxicTo": [pet for pet in PET_ORDER if pet in self.toxic_to],
            "nonToxicTo": [pet for pet in PET_ORDER if pet in self.non_toxic_to],
            "toxicPrinciples": "",
            "clinicalSigns": "",
            "sourceURL": self.source_url,
        }


def clean_space(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def parse_row(row, pet: str, status: str) -> CatalogPlant:
    content = row.select_one(".field-content")
    link = content.find("a", href=True) if content else None
    if content is None or link is None:
        raise ValueError(f"Malformed {pet}/{status} plant row")

    name = clean_space(link.get_text(" ", strip=True))
    source_url = urljoin(BASE_URL, link["href"])
    slug = urlparse(source_url).path.rstrip("/").split("/")[-1]
    text = clean_space(content.get_text(" ", strip=True))

    match = re.match(
        r"^.*?\s*\((.*?)\)\s*\|\s*Scientific Names:\s*(.*?)\s*\|\s*Family:\s*(.*)$",
        text,
        flags=re.IGNORECASE,
    )
    if not match:
        raise ValueError(f"Could not parse row: {text}")

    aliases_text, scientific_name, family = (clean_space(part) for part in match.groups())
    aliases = {aliases_text} if aliases_text else set()
    aliases.discard(name)

    plant = CatalogPlant(
        id=slug,
        name=name,
        scientific_name=scientific_name,
        family=family,
        aliases=aliases,
        source_url=source_url,
    )
    plant.apply_status(pet, status)
    return plant


def parse_source(session: requests.Session, pet: str, url: str) -> list[CatalogPlant]:
    response = session.get(url, timeout=45)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")
    parsed: list[CatalogPlant] = []

    headings = {
        "toxic": f"Plants Toxic to {pet.title()}s",
        "nonToxic": f"Plants Non-Toxic to {pet.title()}s",
    }
    if pet == "horse":
        headings = {
            "toxic": "Plants Toxic to Horses",
            "nonToxic": "Plants Non-Toxic to Horses",
        }

    for status, heading_text in headings.items():
        heading = next(
            (node for node in soup.find_all("h2") if clean_space(node.get_text()) == heading_text),
            None,
        )
        if heading is None:
            raise ValueError(f"Missing heading '{heading_text}' at {url}")

        content = heading.parent.find_next_sibling("div", class_="view-content")
        if content is None:
            raise ValueError(f"Missing list for '{heading_text}' at {url}")

        for row in content.select(":scope > .views-row"):
            parsed.append(parse_row(row, pet, status))

    return parsed


def merge_plants(rows: list[CatalogPlant]) -> list[CatalogPlant]:
    merged: dict[str, CatalogPlant] = {}

    for row in rows:
        current = merged.get(row.id)
        if current is None:
            merged[row.id] = row
            continue

        if current.source_url != row.source_url:
            raise ValueError(f"Slug collision for {row.id}")
        current.aliases.update(row.aliases)
        for pet in row.toxic_to:
            current.apply_status(pet, "toxic")
        for pet in row.non_toxic_to:
            current.apply_status(pet, "nonToxic")

    return sorted(merged.values(), key=lambda plant: (plant.name.casefold(), plant.id))


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--metadata", type=Path, default=DEFAULT_METADATA)
    args = parser.parse_args()

    session = requests.Session()
    session.headers["User-Agent"] = "IsItPoisonousDataImporter/1.0 (authorized ASPCA dataset build)"

    all_rows: list[CatalogPlant] = []
    source_counts: dict[str, int] = {}
    for pet, url in SOURCES.items():
        rows = parse_source(session, pet, url)
        all_rows.extend(rows)
        source_counts[pet] = len(rows)

    plants = merge_plants(all_rows)
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    write_json(args.output, [plant.as_json() for plant in plants])
    write_json(
        args.metadata,
        {
            "schemaVersion": 1,
            "datasetVersion": "aspca-v1-2026-07-15",
            "generatedAt": generated_at,
            "plantCount": len(plants),
            "sourceRowCounts": source_counts,
            "sources": SOURCES,
            "notes": [
                "List-level factual fields only.",
                "No ASPCA images are stored.",
                "Clinical prose is maintained separately as reviewed editorial content.",
            ],
        },
    )
    print(f"Wrote {len(plants)} plants to {args.output}")
    print(f"Wrote metadata to {args.metadata}")


if __name__ == "__main__":
    main()
