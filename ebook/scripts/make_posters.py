#!/usr/bin/env python3
"""Build EPUB video posters: a real first-frame preview with a play control.

Each slot's playable src URL is followed to Mux, one frame is pulled, and a
button-style play mark is drawn on it. The reader taps that image to open the
same src URL. Print does not use these posters.

Nothing figurative is invented: the pixels are the author's own clip. If a
frame cannot be pulled, a large designed play-control card is used instead of
the tiny ink mark.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from paths import POSTERS_DIR, REPO_ROOT, load_videos

UA = "Mozilla/5.0 (compatible; LogicPerformance-ebook-build/1.0)"
POSTER_MAX_EDGE = 960
JPEG_QUALITY = 86

# Fallback card — cream stock, pine play control. No person.
PAPER = (246, 243, 234)
PINE = (47, 92, 62)
INK = (38, 44, 40)


def resolve_src(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=45) as resp:
        return resp.geturl()


def extract_frame(media_url: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-ss",
        "0.8",
        "-i",
        media_url,
        "-frames:v",
        "1",
        "-update",
        "1",
        str(dest),
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"  ! ffmpeg {dest.name}: {exc}", file=sys.stderr)
        return False
    if result.returncode != 0 or not dest.is_file() or dest.stat().st_size < 2000:
        err = (result.stderr or "").strip().splitlines()[-1:] 
        print(f"  ! frame {dest.name}: {err or result.returncode}", file=sys.stderr)
        return False
    return True


def play_overlay(image: Image.Image) -> Image.Image:
    """Draw a tappable play control on the frame. Portrait stays portrait."""
    image = image.convert("RGB")
    if max(image.size) > POSTER_MAX_EDGE:
        scale = POSTER_MAX_EDGE / max(image.size)
        image = image.resize(
            (round(image.width * scale), round(image.height * scale)), Image.LANCZOS
        )
    w, h = image.size
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    # Soft dim so the control reads on light gym floors.
    draw.rectangle((0, 0, w, h), fill=(20, 24, 22, 55))
    r = max(36, min(w, h) * 0.16)
    cx, cy = w / 2, h / 2
    box = (cx - r, cy - r, cx + r, cy + r)
    draw.ellipse(box, fill=(246, 243, 234, 220), outline=PINE + (255,), width=max(3, int(r * 0.08)))
    # Play triangle pointing right, optically centred.
    tri = [
        (cx - r * 0.22, cy - r * 0.38),
        (cx - r * 0.22, cy + r * 0.38),
        (cx + r * 0.42, cy),
    ]
    draw.polygon(tri, fill=PINE + (255,))
    overlay = overlay.filter(ImageFilter.SMOOTH)
    return Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")


def fallback_card(dest: Path) -> None:
    """Large button-style play control when a frame cannot be pulled."""
    # 3:4 so a missing frame still reads as a tap target, not a 26mm ink mark.
    w, h = 720, 960
    image = Image.new("RGB", (w, h), PAPER)
    dest.parent.mkdir(parents=True, exist_ok=True)
    play_overlay(image).save(dest, "JPEG", quality=JPEG_QUALITY, optimize=True)


def write_poster(frame: Path, dest: Path) -> None:
    with Image.open(frame) as image:
        play_overlay(image).save(dest, "JPEG", quality=JPEG_QUALITY, optimize=True, progressive=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true", help="rebuild posters that already exist")
    args = parser.parse_args()

    POSTERS_DIR.mkdir(parents=True, exist_ok=True)
    slots = [s for s in (load_videos().get("videos") or []) if s.get("video_url")]
    written = skipped = failed = 0

    with tempfile.TemporaryDirectory(prefix="golf-posters-") as tmp:
        tmp_dir = Path(tmp)
        for slot in slots:
            dest = POSTERS_DIR / f'{slot["id"]}.jpg'
            if dest.exists() and dest.stat().st_size > 8000 and not args.force:
                skipped += 1
                continue
            url = slot["video_url"].strip()
            try:
                media = resolve_src(url)
            except Exception as exc:
                print(f"  ! resolve {slot['id']}: {exc}", file=sys.stderr)
                fallback_card(dest)
                failed += 1
                continue
            frame = tmp_dir / f'{slot["id"]}.jpg'
            if extract_frame(media, frame):
                write_poster(frame, dest)
                written += 1
                print(f"  poster {dest.relative_to(REPO_ROOT)}")
            else:
                fallback_card(dest)
                failed += 1
                print(f"  fallback {dest.relative_to(REPO_ROOT)}")

    print(f"posters: {written} written  {skipped} kept  {failed} fallback  {len(slots)} slots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
