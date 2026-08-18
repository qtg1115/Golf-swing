#!/usr/bin/env python3
"""Generate QR PNGs for video slots that have a playable URL.

A QR is written only for a slot whose video_url is set in media/videos.yaml.
Anything else is left without a QR so the build renders an empty placeholder box
labelled "공개 영상 주소 예정".

Only URLs a reader can actually open are accepted. Two shapes pass:

  * the author-verified Substack video endpoint,
    https://logicfitko.substack.com/api/v1/video/upload/{id}/src, which
    redirects to a signed Mux mp4 and needs no login
  * a YouTube watch URL, for anything re-hosted later

A Substack POST page is still rejected: those are paid/private, so a reader
scanning that QR would hit a paywall.
"""
from __future__ import annotations

import re
import sys
from urllib.parse import urlparse

import qrcode
from qrcode.constants import ERROR_CORRECT_M

from paths import QR_DIR, REPO_ROOT, load_videos

YOUTUBE_HOSTS = {"youtube.com", "www.youtube.com", "youtu.be", "m.youtube.com"}
YOUTUBE_WATCH = re.compile(
    r"^https://(?:(?:www\.|m\.)?youtube\.com/(?:watch\?v=|live/|shorts/)[\w-]{6,}"
    r"|youtu\.be/[\w-]{6,})",
)

SUBSTACK_VIDEO = re.compile(
    r"^https://[\w-]+\.substack\.com/api/v1/video/upload/"
    r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/src$"
)


def validate(url: str) -> str | None:
    """Return an error message, or None when the URL is an acceptable target."""
    parsed = urlparse(url)
    if parsed.scheme != "https":
        return "must be https"
    host = (parsed.netloc or "").lower()

    if "substack.com" in host:
        if SUBSTACK_VIDEO.match(url):
            return None
        return (
            "the only allowed Substack path is /api/v1/video/upload/{id}/src; "
            "post pages are paywalled and must not be encoded"
        )

    if host in YOUTUBE_HOSTS:
        if YOUTUBE_WATCH.match(url):
            return None
        return "not a recognisable YouTube watch URL"

    return f"host {host!r} is not an allowed video host"


def render(url: str, dest) -> None:
    qr = qrcode.QRCode(version=None, error_correction=ERROR_CORRECT_M, box_size=10, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    qr.make_image(fill_color="black", back_color="white").save(dest)


def main() -> int:
    QR_DIR.mkdir(parents=True, exist_ok=True)
    slots = load_videos().get("videos") or []

    written = pending = 0
    errors: list[str] = []
    keep: set[str] = set()

    for slot in slots:
        url = (slot.get("video_url") or "").strip()
        if not url:
            pending += 1
            continue
        problem = validate(url)
        if problem:
            errors.append(f"{slot['id']}: {problem} ({url})")
            continue
        dest = QR_DIR / f"{slot['id']}.png"
        render(url, dest)
        keep.add(dest.name)
        written += 1

    # Drop QRs whose slot lost its URL, so a stale code never ships.
    for stale in sorted(QR_DIR.glob("*.png")):
        if stale.name not in keep:
            stale.unlink()
            print(f"- removed stale {stale.relative_to(REPO_ROOT)}")

    print(f"{written} QR code(s) written to {QR_DIR.relative_to(REPO_ROOT)}")
    print(f"{pending} slot(s) still without a playable URL")
    if errors:
        print("\nrejected:", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
