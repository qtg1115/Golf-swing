#!/usr/bin/env python3
"""Build the photo/video manifests and download the photos.

Photos are pulled from the Substack CDN into ebook/images/photos/ so the EPUB and
PDF embed local files and never hotlink a gated host.

Videos get a manifest entry only. There is deliberately no reader-facing URL and
no QR code until a YouTube unlisted link exists: the Substack video host is
paid/private, so encoding it would hand readers a link they cannot open.
Existing youtube_url values in media/videos.yaml are always preserved.
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
import time
import urllib.error
import urllib.request

from PIL import Image

from paths import (
    MANUSCRIPT_DIR,
    MEDIA_DIR,
    PHOTOS_DIR,
    PHOTOS_JSON,
    REPO_ROOT,
    SOURCES_DIR,
    VIDEOS_YAML,
    load_videos,
)

UA = "Mozilla/5.0 (compatible; LogicPerformance-ebook-build/1.0)"

VIDEO_MARKER = re.compile(r"\[\[VIDEO-PUBLIC:\s*([^/\]]+?)\s*/\s*(\d+)\s*/\s*([^\]]*?)\s*\]\]")
PHOTO_PENDING_MARKER = re.compile(r"\[\[PHOTO-PENDING:\s*([^/\]]+?)\s*/\s*(\d+)\s*/\s*([^\]]*?)\s*\]\]")
FIGURE_SRC = re.compile(r'<img[^>]+src="images/photos/([^"]+)"')

VIDEOS_HEADER = """\
# Video manifest for 「내 발이 만드는 스윙 시간」
#
# POLICY (author instruction):
#   * Every ebook video is hosted as YouTube UNLISTED on the golf channel.
#   * Reader-facing links and QR codes use that YouTube watch URL and nothing else.
#   * Substack URLs are never used as a reader-facing target and never encoded
#     into a QR code, because those posts are paid/private.
#   * Until youtube_url is filled in, the build renders an empty QR box with the
#     label "공개 영상 주소 예정". No URL is invented.
#
# substack_media_id is an INTERNAL asset-matching key only. It exists so the
# original clip can be located for upload. It is never rendered or linked.
#
# To publish a video: set youtube_url to the full watch URL, e.g.
#   youtube_url: https://www.youtube.com/watch?v=XXXXXXXXXXX
# then re-run scripts/make_qr.py and scripts/build.py.
"""


# A5 at ~350 dpi needs roughly 1600 px on the long edge; anything more is weight
# the EPUB and PDF do not use.
MAX_EDGE = 1600
JPEG_QUALITY = 92


def optimise(data: bytes, dest) -> None:
    """Flatten onto white, cap the long edge, and store as a progressive JPEG."""
    with Image.open(io.BytesIO(data)) as image:
        if image.mode in ("RGBA", "LA", "P"):
            image = image.convert("RGBA")
            flattened = Image.new("RGB", image.size, (255, 255, 255))
            flattened.paste(image, mask=image.split()[-1])
            image = flattened
        else:
            image = image.convert("RGB")
        if max(image.size) > MAX_EDGE:
            scale = MAX_EDGE / max(image.size)
            image = image.resize(
                (round(image.width * scale), round(image.height * scale)), Image.LANCZOS
            )
        image.save(dest, "JPEG", quality=JPEG_QUALITY, optimize=True, progressive=True)


def download(url: str, dest, tries: int = 3) -> bool:
    delay = 3
    for attempt in range(1, tries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = resp.read()
            if not data:
                raise RuntimeError("empty response")
            optimise(data, dest)
            return True
        except (urllib.error.URLError, TimeoutError, RuntimeError) as exc:
            if attempt == tries:
                print(f"  ! failed {url}: {exc}", file=sys.stderr)
                return False
            time.sleep(delay)
            delay *= 2
    return False


def scan_manuscript() -> tuple[list[dict], list[dict], set[str]]:
    """Read the manuscript for video slots, pending stills, and figure filenames."""
    videos: list[dict] = []
    pending: list[dict] = []
    figures: set[str] = set()
    for path in sorted(MANUSCRIPT_DIR.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        for chapter, index, description in VIDEO_MARKER.findall(text):
            videos.append(
                {
                    "id": f"{chapter}-v{int(index):02d}",
                    "chapter": chapter,
                    "index": int(index),
                    "description": description,
                    "manuscript": path.name,
                }
            )
        for chapter, index, note in PHOTO_PENDING_MARKER.findall(text):
            pending.append({"chapter": chapter, "index": int(index), "note": note})
        figures.update(FIGURE_SRC.findall(text))
    return videos, pending, figures


def merge_videos(found: list[dict]) -> dict:
    existing = {v["id"]: v for v in load_videos().get("videos") or []}
    merged = []
    for slot in sorted(found, key=lambda v: (v["chapter"], v["index"])):
        prior = existing.get(slot["id"], {})
        merged.append(
            {
                "id": slot["id"],
                "chapter": slot["chapter"],
                "index": slot["index"],
                "description": prior.get("description") or slot["description"],
                "substack_media_id": prior.get("substack_media_id"),
                # Filled in by hand once the clip is uploaded as YouTube unlisted.
                "youtube_url": prior.get("youtube_url"),
            }
        )
    # Carry over any hand-added slots that the manuscript does not yet reference.
    known = {v["id"] for v in merged}
    for slot_id, slot in sorted(existing.items()):
        if slot_id not in known:
            slot.setdefault("youtube_url", None)
            merged.append(slot)
    return {"videos": merged}


def attach_substack_ids(manifest: dict) -> None:
    detected_path = SOURCES_DIR / "_detected_media.json"
    if not detected_path.exists():
        return
    detected = json.loads(detected_path.read_text(encoding="utf-8"))
    by_id = {v["id"]: v for v in detected.get("videos", [])}
    for slot in manifest["videos"]:
        if not slot.get("substack_media_id"):
            match = by_id.get(slot["id"])
            if match:
                slot["substack_media_id"] = match.get("substack_media_id")


def dump_videos(manifest: dict) -> None:
    lines = [VIDEOS_HEADER, "videos:"]
    for slot in manifest["videos"]:
        lines.append(f"  - id: {slot['id']}")
        lines.append(f"    chapter: {slot['chapter']}")
        lines.append(f"    index: {slot['index']}")
        description = (slot.get("description") or "").replace('"', "'")
        lines.append(f'    description: "{description}"')
        media_id = slot.get("substack_media_id")
        lines.append(f"    substack_media_id: {media_id or 'null'}")
        url = slot.get("youtube_url")
        lines.append(f"    youtube_url: {url or 'null'}")
        lines.append("")
    VIDEOS_YAML.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-download", action="store_true", help="manifests only")
    parser.add_argument("--redownload", action="store_true", help="refetch existing photos")
    args = parser.parse_args()

    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    PHOTOS_DIR.mkdir(parents=True, exist_ok=True)

    detected_path = SOURCES_DIR / "_detected_media.json"
    detected = (
        json.loads(detected_path.read_text(encoding="utf-8"))
        if detected_path.exists()
        else {"photos": []}
    )

    videos, pending_stills, figures = scan_manuscript()

    # Photos: everything the manuscript references, with a source URL when known.
    by_file = {p["file"]: p for p in detected.get("photos", [])}
    photos = []
    for filename in sorted(figures):
        record = by_file.get(filename, {})
        photos.append(
            {
                "file": filename,
                "chapter": record.get("chapter") or filename.split("-")[0],
                "caption": record.get("caption", ""),
                "source_url": record.get("source_url"),
            }
        )

    downloaded = missing = skipped = 0
    for photo in photos:
        dest = PHOTOS_DIR / photo["file"]
        if dest.exists() and not args.redownload:
            photo["status"] = "present"
            skipped += 1
            continue
        if args.skip_download or not photo["source_url"]:
            photo["status"] = "missing"
            missing += 1
            continue
        if download(photo["source_url"], dest):
            photo["status"] = "downloaded"
            downloaded += 1
        else:
            photo["status"] = "missing"
            missing += 1

    PHOTOS_JSON.write_text(
        json.dumps(
            {
                "photos": photos,
                "pending_stills": pending_stills,
                "expected_total_from_manuscript_inventory": 64,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    manifest = merge_videos(videos)
    attach_substack_ids(manifest)
    dump_videos(manifest)

    with_url = sum(1 for v in manifest["videos"] if v.get("youtube_url"))
    print(f"photos:  {len(photos)} referenced  {downloaded} downloaded  {skipped} already present  {missing} missing")
    print(f"videos:  {len(manifest['videos'])} slots  {with_url} with a YouTube URL  {len(manifest['videos']) - with_url} awaiting upload")
    print(f"pending stills: {len(pending_stills)}")
    print(f"wrote {PHOTOS_JSON.relative_to(REPO_ROOT)}")
    print(f"wrote {VIDEOS_YAML.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
