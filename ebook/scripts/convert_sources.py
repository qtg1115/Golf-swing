#!/usr/bin/env python3
"""Turn cached Substack sources into editable Korean manuscript Markdown.

Output goes to ebook/manuscript/<chapter-id>.md. Three placeholder markers are
emitted so nothing is ever invented:

  [[VIDEO-PUBLIC: <chapter-id> / <index> / <description>]]
      A video slot. Reader-facing URL and QR stay empty until a YouTube
      unlisted link exists for it in media/videos.yaml.
  [[PHOTO-PENDING: <chapter-id> / <index> / <note>]]
      A still referenced by the text that we do not have a file for.
  [[MANUSCRIPT-PENDING: <slug>]]
      The rest of a paywalled post, which the public teaser does not include.

Existing manuscript files are left alone unless --force is given, so hand edits
and the delivered manuscript survive a re-run.
"""
from __future__ import annotations

import argparse
import json
import re
import urllib.parse

from bs4 import BeautifulSoup, NavigableString, Tag

from paths import MANUSCRIPT_DIR, SOURCES_DIR, load_book, ordered_chapters

# Substack renders these as UI chrome, not content.
DROP_SELECTORS = [
    ".subscription-widget-wrap-editor",
    ".subscription-widget",
    ".button-wrapper",
    ".paywall-jump",
    ".image-link-expand",
    "form",
    "svg",
    "button",
    "style",
    "script",
]

# Text left over from the paywall / subscribe furniture.
NOISE_PATTERNS = [
    re.compile(r"^\s*(read more|계속 읽기|더 보기)\s*$", re.I),
    re.compile(r"^\s*(subscribe|구독)\s*$", re.I),
    re.compile(r"이 게시물은 유료 구독자", re.I),
]

# Markers the author uses for a still that is not in the post yet.
PHOTO_MARKER = re.compile(r"\[\s*사진\s*\]|\(\s*사진\s*첨부\s*\)|\[\s*사진\s*첨부\s*\]")


def original_image_url(url: str) -> str:
    """Recover the underlying S3 asset from a substackcdn /image/fetch/ wrapper."""
    if "substackcdn.com/image/fetch/" not in url:
        return url
    tail = url.split("/image/fetch/", 1)[1]
    # Strip the leading transformation segment (f_auto,q_auto,w_1456,...).
    if "/" in tail:
        tail = tail.split("/", 1)[1]
    decoded = urllib.parse.unquote(tail)
    return decoded if decoded.startswith("http") else url


def clean(soup: BeautifulSoup) -> None:
    for selector in DROP_SELECTORS:
        for node in soup.select(selector):
            node.decompose()


def inline_md(node: Tag | NavigableString) -> str:
    if isinstance(node, NavigableString):
        return re.sub(r"\s+", " ", str(node))
    if node.name in ("strong", "b"):
        inner = "".join(inline_md(c) for c in node.children).strip()
        return f"**{inner}**" if inner else ""
    if node.name in ("em", "i"):
        inner = "".join(inline_md(c) for c in node.children).strip()
        return f"*{inner}*" if inner else ""
    if node.name == "br":
        return "  \n"
    if node.name == "a":
        # Never carry a Substack link into reader-facing text; keep the words.
        return "".join(inline_md(c) for c in node.children)
    return "".join(inline_md(c) for c in node.children)


def heading_text(node: Tag) -> str:
    """Headings carry their own weight; drop inline bold from them."""
    return inline_md(node).strip().replace("**", "").strip()


# The author writes dash-prefixed run-on lines as bullets ("-임팩트 저점이 …").
DASH_BULLET = re.compile(r"^[-–·•]\s*(?=\S)")


def escape_md(text: str) -> str:
    if DASH_BULLET.match(text):
        return "- " + DASH_BULLET.sub("", text)
    return re.sub(r"^(\s*)([#>*+]|\d+\.)(\s)", r"\1\\\2\3", text)


def normalise_title(text: str) -> str:
    return re.sub(r"[\s*·—–\-:]+", "", text).lower()


class Converter:
    def __init__(self, chapter_id: str, slug: str, titles: tuple[str, ...] = ()) -> None:
        self.chapter_id = chapter_id
        self.slug = slug
        # Substack repeats the post title as the first line of the body. Drop it
        # so the chapter heading is not printed twice.
        self.skip_titles = {normalise_title(t) for t in titles if t}
        self.body_started = False
        self.video_index = 0
        self.photo_index = 0
        self.pending_photo_index = 0
        self.photos: list[dict] = []
        self.videos: list[dict] = []
        self.pending_photos: list[dict] = []
        # Nearest heading / label above the current block, used to describe a
        # video slot so the YouTube hand-off list is readable.
        self.context = ""
        self.label = ""

    def figure(self, node: Tag) -> str:
        img = node.find("img")
        if img is None:
            return ""
        src = img.get("src") or ""
        source = node.find("source")
        if not src and source is not None:
            src = (source.get("srcset") or "").split(" ")[0]
        origin = original_image_url(src)
        caption_node = node.find("figcaption")
        caption = inline_md(caption_node).strip() if caption_node else ""

        self.photo_index += 1
        stem = re.sub(r"[^a-zA-Z0-9]+", "-", origin.rsplit("/", 1)[-1]).strip("-")
        stem = re.sub(r"-(png|jpg|jpeg|webp|gif)$", "", stem, flags=re.I)[:48]
        # Every book photo is stored as an optimised JPEG regardless of the
        # source format; build_media.py flattens and resizes on download.
        filename = f"{self.chapter_id}-{self.photo_index:02d}-{stem}.jpg"

        self.photos.append(
            {
                "chapter": self.chapter_id,
                "index": self.photo_index,
                "file": filename,
                "source_url": origin,
                "caption": caption,
            }
        )
        alt = caption or f"{self.chapter_id} 사진 {self.photo_index}"
        block = [
            '<figure class="photo">',
            f'  <img src="images/photos/{filename}" alt="{alt}" />',
        ]
        if caption:
            block.append(f"  <figcaption>{caption}</figcaption>")
        block.append("</figure>")
        return "\n".join(block)

    def video(self, node: Tag) -> str:
        attrs = {}
        raw = node.get("data-attrs")
        if raw:
            try:
                attrs = json.loads(raw)
            except json.JSONDecodeError:
                attrs = {}
        self.video_index += 1
        description = self.label or self.context or "동작 시연"
        slot = {
            "id": f"{self.chapter_id}-v{self.video_index:02d}",
            "chapter": self.chapter_id,
            "index": self.video_index,
            "description": description,
            # Internal asset-matching key only. Never rendered, never linked:
            # the Substack video host is gated, so readers get a YouTube
            # unlisted URL once one exists.
            "substack_media_id": attrs.get("mediaUploadId"),
            "youtube_url": None,
        }
        self.videos.append(slot)
        return f"[[VIDEO-PUBLIC: {self.chapter_id} / {self.video_index} / {description}]]"

    def photo_marker(self, note: str) -> str:
        self.pending_photo_index += 1
        self.pending_photos.append(
            {
                "chapter": self.chapter_id,
                "index": self.pending_photo_index,
                "note": note,
            }
        )
        return f"[[PHOTO-PENDING: {self.chapter_id} / {self.pending_photo_index} / {note}]]"

    def block(self, node: Tag) -> str:
        name = node.name
        classes = node.get("class") or []

        if "native-video-embed" in classes:
            return self.video(node)
        if name == "figure" or "captioned-image-container" in classes:
            figure = node if name == "figure" else node.find("figure")
            return self.figure(figure) if figure else ""
        if name in ("h1", "h2"):
            self.context = heading_text(node)
            if not self.body_started and normalise_title(self.context) in self.skip_titles:
                return ""
            self.body_started = True
            return f"## {self.context}"
        if name == "h3":
            self.context = heading_text(node)
            return f"### {self.context}"
        if name in ("h4", "h5", "h6"):
            self.context = heading_text(node)
            return f"#### {self.context}"
        if name == "hr":
            return "---"
        if name == "blockquote":
            inner = "\n\n".join(
                filter(None, (self.block(c) for c in node.children if isinstance(c, Tag)))
            )
            if not inner:
                inner = inline_md(node).strip()
            return "\n".join(f"> {line}" if line else ">" for line in inner.splitlines())
        if name == "ul":
            return "\n".join(
                f"- {inline_md(li).strip()}" for li in node.find_all("li", recursive=False)
            )
        if name == "ol":
            return "\n".join(
                f"{i}. {inline_md(li).strip()}"
                for i, li in enumerate(node.find_all("li", recursive=False), 1)
            )
        if name == "p":
            text = inline_md(node).strip()
            if not text or any(p.search(text) for p in NOISE_PATTERNS):
                return ""
            if not self.body_started and normalise_title(text) in self.skip_titles:
                return ""
            self.body_started = True
            if PHOTO_MARKER.fullmatch(text.strip()):
                return self.photo_marker(text.strip())
            if PHOTO_MARKER.search(text):
                text = PHOTO_MARKER.sub(
                    lambda m: "\n\n" + self.photo_marker(m.group(0)) + "\n\n", text
                )
                return text.strip()
            # A short bold-only line ("**첫번째 운동**") labels what follows.
            bare = text.strip("* ").strip()
            if text.startswith("**") and text.endswith("**") and len(bare) <= 30:
                self.label = bare
            elif len(bare) > 30:
                self.label = ""
            return escape_md(text)
        if name == "div":
            return "\n\n".join(
                filter(None, (self.block(c) for c in node.children if isinstance(c, Tag)))
            )
        return ""

    def run(self, body_html: str) -> str:
        soup = BeautifulSoup(body_html or "", "lxml")
        clean(soup)
        root = soup.body or soup
        blocks = [self.block(c) for c in root.children if isinstance(c, Tag)]
        out: list[str] = []
        for block in blocks:
            block = block.strip()
            if block and block != out[-1:] and block not in ("---",) or block == "---":
                if block:
                    out.append(block)
        # Collapse repeated rules and duplicated adjacent paragraphs.
        deduped: list[str] = []
        for block in out:
            if deduped and block == deduped[-1]:
                continue
            deduped.append(block)
        while deduped and deduped[-1] == "---":
            deduped.pop()
        return "\n\n".join(deduped).strip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true", help="overwrite existing manuscript files")
    args = parser.parse_args()

    book = load_book()
    MANUSCRIPT_DIR.mkdir(parents=True, exist_ok=True)

    items = [(part, ch) for part, ch in ordered_chapters(book)]
    items += [(None, item) for item in book.get("back_matter", []) if item.get("slug")]

    photos: list[dict] = []
    videos: list[dict] = []
    pending_photos: list[dict] = []
    pending_text: list[str] = []

    for _part, chapter in items:
        if not chapter.get("slug"):
            # Part 4 comes from an unpublished draft, not from Substack.
            continue
        slug = str(chapter["slug"])
        source_path = SOURCES_DIR / f"{slug}.json"
        if not source_path.exists():
            print(f"! no cached source for {slug}; run fetch_sources.py")
            continue
        record = json.loads(source_path.read_text(encoding="utf-8"))
        converter = Converter(
            chapter["id"],
            slug,
            (chapter["title"], record.get("substack_title") or "", record.get("book_title") or ""),
        )
        body = converter.run(record["body_html"])

        lines = [f"# {chapter['title']}", ""]
        subtitle = (record.get("subtitle") or "").strip()
        if subtitle:
            lines += [f"> {subtitle}", ""]
        lines.append(body)

        if record["public_body_is_partial"]:
            pending_text.append(slug)
            lines += ["", f"[[MANUSCRIPT-PENDING: {slug}]]", ""]

        target = MANUSCRIPT_DIR / f"{chapter['id']}.md"
        if target.exists() and not args.force:
            print(f"= keep {target.name} (exists)")
        else:
            target.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
            print(
                f"+ {target.name:14s} photos={len(converter.photos)} "
                f"videos={len(converter.videos)} pending_stills={len(converter.pending_photos)}"
            )

        photos += converter.photos
        videos += converter.videos
        pending_photos += converter.pending_photos

    print(
        f"\ndetected: {len(photos)} photos, {len(videos)} video slots, "
        f"{len(pending_photos)} pending stills, {len(pending_text)} chapters awaiting full text"
    )
    (SOURCES_DIR / "_detected_media.json").write_text(
        json.dumps(
            {"photos": photos, "videos": videos, "pending_photos": pending_photos},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
