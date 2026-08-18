"""Author stills for the 챕터 7 release section.

The six photographs sit in images/photos/ under the names in media/stills.yaml.
PHOTO-PENDING markers resolve to a figure when that file is present; otherwise
they stay a labelled empty frame. Nothing is generated or substituted.
"""
from __future__ import annotations

from pathlib import Path

import yaml
from PIL import Image, ImageOps

from paths import EBOOK_DIR, IMAGES_DIR, MEDIA_DIR, PHOTOS_DIR

STILLS_YAML = MEDIA_DIR / "stills.yaml"
INCOMING_DIR = IMAGES_DIR / "incoming"

IMAGE_SUFFIXES = (".jpg", ".jpeg", ".png", ".webp", ".JPG", ".JPEG", ".PNG", ".WEBP")


def load_stills() -> list[dict]:
    if not STILLS_YAML.exists():
        return []
    data = yaml.safe_load(STILLS_YAML.read_text(encoding="utf-8")) or {}
    return list(data.get("stills") or [])


def resolve_photo_path(filename: str) -> Path | None:
    """Find a photo by the name the manuscript uses, or the same stem."""
    if not filename:
        return None
    direct = PHOTOS_DIR / filename
    if direct.is_file():
        return direct
    stem = Path(filename).stem
    for suffix in (".jpg", ".jpeg", ".png", ".webp"):
        alt = PHOTOS_DIR / f"{stem}{suffix}"
        if alt.is_file():
            return alt
    return None


def still_for_pending(chapter: str, index: int) -> dict | None:
    for still in load_stills():
        if still.get("chapter") == chapter and still.get("index") == int(index):
            return still
    return None


def incoming_files() -> list[Path]:
    if not INCOMING_DIR.is_dir():
        return []
    files = [
        path
        for path in INCOMING_DIR.iterdir()
        if path.is_file() and path.suffix in IMAGE_SUFFIXES and not path.name.startswith(".")
    ]
    return sorted(files, key=lambda p: p.name.lower())


def upright(image: Image.Image, rotate_cw: int = 0) -> Image.Image:
    """Honour EXIF rotation, then any authored clockwise turn.

    Phone portraits often arrive as landscape pixels (EXIF 6) or with EXIF
    already stripped. ImageOps.exif_transpose stands the first case up; rotate_cw
    stands the second up. A still that is portrait after this stays portrait —
    it is never forced landscape.
    """
    image = ImageOps.exif_transpose(image) or image
    turn = int(rotate_cw or 0) % 360
    if turn:
        image = image.rotate(-turn, expand=True)
    return image


def photo_layout_class(path: Path) -> str:
    """CSS class from the pixels on disk (rotation already baked in)."""
    with Image.open(path) as image:
        return "portrait" if image.height > image.width else "landscape"
