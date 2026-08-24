"""Shared paths and small helpers for the ebook build scripts."""
from __future__ import annotations

from pathlib import Path

import yaml

EBOOK_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = EBOOK_DIR.parent

BOOK_YAML = EBOOK_DIR / "book.yaml"
SOURCES_DIR = EBOOK_DIR / "sources"
MANUSCRIPT_DIR = EBOOK_DIR / "manuscript"
FRONT_MATTER_DIR = EBOOK_DIR / "front-matter"
IMAGES_DIR = EBOOK_DIR / "images"
PHOTOS_DIR = IMAGES_DIR / "photos"
QR_DIR = IMAGES_DIR / "qr"
POSTERS_DIR = IMAGES_DIR / "posters"
MEDIA_DIR = EBOOK_DIR / "media"
TEMPLATES_DIR = EBOOK_DIR / "templates"
BUILD_DIR = EBOOK_DIR / ".build"
DIST_DIR = REPO_ROOT / "dist"

VIDEOS_YAML = MEDIA_DIR / "videos.yaml"
VIDEO_URLS_YAML = MEDIA_DIR / "video-urls.yaml"
PHOTOS_JSON = MEDIA_DIR / "photos.json"


def load_book() -> dict:
    return yaml.safe_load(BOOK_YAML.read_text(encoding="utf-8"))


def load_videos() -> dict:
    if not VIDEOS_YAML.exists():
        return {"videos": []}
    return yaml.safe_load(VIDEOS_YAML.read_text(encoding="utf-8")) or {"videos": []}


def ordered_chapters(book: dict):
    """Yield (part, chapter) pairs in reading order."""
    for part in book["parts"]:
        for chapter in part["chapters"]:
            yield part, chapter
