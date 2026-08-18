#!/usr/bin/env python3
"""Compose the EPUB cover raster from the drawn plate and book.yaml.

An EPUB cover has to be a single image, so the type cannot be left to the
reader's stylesheet the way the PDF cover does it. It is still real type: the
same Nanum faces the book is set in, drawn here at cover size over the plate
from scripts/make_plates.py. Nothing is added beyond the title, the subtitle and
the three names — no company branding, no channel name, no year, no seal.

Run scripts/make_plates.py first; this reads its output.
"""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

from paths import EBOOK_DIR, IMAGES_DIR, REPO_ROOT, load_book

WIDTH, HEIGHT = 1748, 2480  # A5 at 300dpi, matching the PDF cover

INK = (38, 44, 40)
PAPER = (246, 243, 234)
PINE = (47, 92, 62)
MUTED = (108, 115, 108)
SUBTITLE = (85, 96, 90)

NANUM = "/usr/share/fonts/truetype/nanum"
SERIF_BOLD = f"{NANUM}/NanumMyeongjoBold.ttf"
SANS = f"{NANUM}/NanumBarunGothic.ttf"
SANS_BOLD = f"{NANUM}/NanumBarunGothicBold.ttf"


def centred(draw: ImageDraw.ImageDraw, y: int, text: str, font, fill, tracking: int = 0) -> int:
    """Draw one centred line, optionally letterspaced, and return the next y."""
    if tracking:
        width = sum(draw.textlength(ch, font=font) + tracking for ch in text) - tracking
        x = (WIDTH - width) / 2
        for ch in text:
            draw.text((x, y), ch, font=font, fill=fill)
            x += draw.textlength(ch, font=font) + tracking
    else:
        draw.text(((WIDTH - draw.textlength(text, font=font)) / 2, y), text, font=font, fill=fill)
    ascent, descent = font.getmetrics()
    return y + ascent + descent


def main() -> int:
    book = load_book()

    art = book.get("cover_art")
    art_path = EBOOK_DIR / art if art else None
    if art_path and art_path.exists():
        image = Image.open(art_path).convert("RGB").resize((WIDTH, HEIGHT), Image.LANCZOS)
    else:
        print("! cover art missing; falling back to plain stock")
        image = Image.new("RGB", (WIDTH, HEIGHT), PAPER)
    draw = ImageDraw.Draw(image)

    title_font = ImageFont.truetype(SERIF_BOLD, 196)
    subtitle_font = ImageFont.truetype(SANS, 58)
    author_font = ImageFont.truetype(SANS_BOLD, 68)
    author_en_font = ImageFont.truetype(SANS, 50)

    y = 300
    for line in book.get("cover_title_lines") or [book["title"]]:
        y = centred(draw, y, line, title_font, INK) + 18

    y += 74
    draw.line([(WIDTH / 2 - 82, y), (WIDTH / 2 + 82, y)], fill=PINE, width=5)
    y += 96

    centred(draw, y, book["subtitle"], subtitle_font, SUBTITLE, tracking=2)

    # Equal billing: one line of Korean names, one line of English, same weight
    # within each line and no ordering emphasis.
    y = HEIGHT - 372
    y = centred(draw, y, " · ".join(a["name_ko"] for a in book["authors"]), author_font, INK, 6)
    centred(draw, y + 26, " · ".join(a["name_en"] for a in book["authors"]), author_en_font, MUTED, 4)

    # JPEG, not PNG: the stock is grain, which PNG cannot pack.
    dest = IMAGES_DIR / "cover.jpg"
    image.save(dest, "JPEG", quality=92, optimize=True)
    print(f"wrote {dest.relative_to(REPO_ROOT)} ({WIDTH}x{HEIGHT}, {dest.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
