#!/usr/bin/env python3
"""Render the cover PNG from book.yaml.

Deliberately plain: title, subtitle, and the three authors with equal billing.
No company branding appears on the cover by author instruction — no Logic
Performance, no Logic Fitness.
"""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

from paths import IMAGES_DIR, REPO_ROOT, load_book

WIDTH, HEIGHT = 1600, 2560
MARGIN = 150

INK = (23, 30, 26)
PAPER = (247, 246, 241)
ACCENT = (61, 106, 74)
MUTED = (108, 115, 108)

SERIF = "/usr/share/fonts/truetype/nanum/NanumMyeongjo.ttf"
SERIF_BOLD = "/usr/share/fonts/truetype/nanum/NanumMyeongjoBold.ttf"
SANS = "/usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf"
SANS_BOLD = "/usr/share/fonts/truetype/nanum/NanumBarunGothicBold.ttf"


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int) -> list[str]:
    lines: list[str] = []
    current = ""
    for word in text.split():
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=fnt) <= max_width or not current:
            current = candidate
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def centred(draw: ImageDraw.ImageDraw, y: int, text: str, fnt, fill) -> int:
    width = draw.textlength(text, font=fnt)
    draw.text(((WIDTH - width) / 2, y), text, font=fnt, fill=fill)
    ascent, descent = fnt.getmetrics()
    return y + ascent + descent


def main() -> int:
    book = load_book()
    image = Image.new("RGB", (WIDTH, HEIGHT), PAPER)
    draw = ImageDraw.Draw(image)

    # A single hairline frame keeps the cover calm without any logo.
    draw.rectangle([MARGIN - 40, MARGIN - 40, WIDTH - MARGIN + 40, HEIGHT - MARGIN + 40],
                   outline=(214, 211, 200), width=3)

    title_font = font(SERIF_BOLD, 148)
    subtitle_font = font(SANS, 52)
    author_font = font(SANS_BOLD, 60)
    credential_font = font(SANS, 40)
    label_font = font(SANS, 42)

    y = 620
    title_lines = book.get("cover_title_lines") or wrap(
        draw, book["title"], title_font, WIDTH - 2 * MARGIN
    )
    for line in title_lines:
        y = centred(draw, y, line, title_font, INK) + 24

    y += 40
    rule_half = 130
    draw.line([(WIDTH / 2 - rule_half, y), (WIDTH / 2 + rule_half, y)], fill=ACCENT, width=6)
    y += 90

    for line in wrap(draw, book["subtitle"], subtitle_font, WIDTH - 2 * MARGIN - 120):
        y = centred(draw, y, line, subtitle_font, MUTED) + 18

    # Authors sit together in one block: equal billing, no ordering emphasis.
    y = HEIGHT - MARGIN - 560
    y = centred(draw, y, "지음", label_font, MUTED) + 60
    for author in book["authors"]:
        name = f"{author['name_ko']}  ·  {author['name_en']}"
        y = centred(draw, y, name, author_font, INK) + 8
        y = centred(draw, y, author["credential"], credential_font, MUTED) + 46

    dest = IMAGES_DIR / "cover.png"
    image.save(dest, "PNG")
    print(f"wrote {dest.relative_to(REPO_ROOT)} ({WIDTH}x{HEIGHT})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
