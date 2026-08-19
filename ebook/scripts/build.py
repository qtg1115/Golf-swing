#!/usr/bin/env python3
"""Assemble the manuscript into dist/*.epub and dist/*.pdf.

The build reads ebook/book.yaml for structure, ebook/manuscript/*.md for text,
and ebook/media/videos.yaml for video slots. Three placeholder markers in the
manuscript are expanded into styled blocks:

  [[VIDEO-PUBLIC: chapter / index / description]]
  [[PHOTO-PENDING: chapter / index / note]]
  [[MANUSCRIPT-PENDING: slug]]

A video slot renders a caption, an empty QR box, and the label
"공개 영상 주소 예정" until media/videos.yaml carries a YouTube unlisted URL for
it. Substack URLs are never rendered or encoded: those posts are paid/private.
"""
from __future__ import annotations

import argparse
import html
import re
import shutil
import subprocess
import sys

from figures import load_figures, render as render_figure, wrap_terms
from paths import (
    BUILD_DIR,
    DIST_DIR,
    EBOOK_DIR,
    FRONT_MATTER_DIR,
    IMAGES_DIR,
    MANUSCRIPT_DIR,
    PHOTOS_DIR,
    POSTERS_DIR,
    QR_DIR,
    REPO_ROOT,
    TEMPLATES_DIR,
    load_book,
    load_videos,
)
from stills import photo_layout_class, resolve_photo_path, stills_for_pending

FIGURE_MARKER = re.compile(r"\[\[FIGURE:\s*([a-z0-9-]+)\s*\]\](?!\])")
VIDEO_MARKER = re.compile(r"\[\[VIDEO-PUBLIC:\s*([^/\]]+?)\s*/\s*(\d+)\s*/\s*(.*?)\s*\]\](?!\])")
PHOTO_PENDING = re.compile(r"\[\[PHOTO-PENDING:\s*([^/\]]+?)\s*/\s*(\d+)\s*/\s*(.*?)\s*\]\](?!\])")
TEXT_PENDING = re.compile(r"\[\[MANUSCRIPT-PENDING:\s*(.*?)\s*\]\](?!\])")
FIGURE_BLOCK = re.compile(
    r'<figure class="photo">\s*<img src="images/photos/([^"]+)"[^>]*/?>\s*'
    r'(?:<figcaption>(.*?)</figcaption>\s*)?</figure>',
    re.S,
)
ATX_HEADING = re.compile(r"^(#{1,6})(\s+)", re.M)

# The manuscript marks media inline with the author's own shorthand on its own
# line. Anchored so it never matches the note inside a [[PHOTO-PENDING: … ]].
BARE_PHOTO = re.compile(r"^\[\s*사진\s*\]$", re.M)
BARE_VIDEO = re.compile(r"^\[\s*영상\s*\]$", re.M)
FIGURE_SRC = re.compile(r'<img[^>]+src="images/photos/([^"]+)"')

PENDING_VIDEO_LABEL = "공개 영상 주소 예정"

# Assessment figures are typeset, not drawn, so they load once per build.
FIGURES = load_figures()

# ---------------------------------------------------------------------------
# print line breaking
# ---------------------------------------------------------------------------

TAG_SPLIT = re.compile(r"(<[^>]*>)")
HANGUL_WORD = re.compile(r"[가-힣]{2,10}")
STRIP_TAGS = re.compile(r"<[^>]*>")

# A short line immediately before a figure — 첫번째 운동, 아래 사진을 보자 — is a
# lead-in for it, whether or not it was written as a heading.
LEAD_IN_FIGURE = re.compile(
    r"(<(h[2-6]|p)(?:\s[^>]*)?>(?:(?!</\2>).)*?</\2>)\s*"
    r"(<figure\b(?:(?!</figure>).)*?</figure>)",
    re.S,
)
LEAD_IN_MAX_CHARS = 40


def group_lead_in_with_figure(body: str) -> str:
    """Bind a short lead-in to the figure it introduces.

    Video slots and photos are unbreakable blocks, so when one did not fit in the
    space left, it moved to the next page and left its lead-in stranded as the
    last line of the previous one. The pair becomes one unbreakable group. Only
    short lead-ins qualify, so a full paragraph is never dragged along.
    """

    def wrap(match: re.Match) -> str:
        lead, _, figure = match.groups()
        if len(STRIP_TAGS.sub("", lead).strip()) > LEAD_IN_MAX_CHARS:
            return match.group(0)
        return f'<div class="keep-with-figure">{lead}\n{figure}</div>'

    return LEAD_IN_FIGURE.sub(wrap, body)


def keep_korean_words_whole(body: str) -> str:
    """Stop Korean words breaking mid-syllable in the PDF.

    `word-break: keep-all` in the stylesheet covers the EPUB, whose reading
    systems implement it, but WeasyPrint does not: the property appears nowhere
    in its source, so Hangul breaks between any two syllables and 백스윙 prints
    as 백/스윙. The `.term` spans catch the tokens the author named; this catches
    every other Korean word by wrapping each one in a nowrap span. No invisible
    joiner characters are inserted, so the text stays searchable and copyable,
    and anything inside a tag — every href included — is left alone.
    """
    pieces = []
    for piece in TAG_SPLIT.split(body):
        if piece.startswith("<"):
            pieces.append(piece)
        else:
            pieces.append(HANGUL_WORD.sub(lambda m: f'<span class="nb">{m.group()}</span>', piece))
    return "".join(pieces)


class Stats:
    def __init__(self) -> None:
        self.videos_with_url = 0
        self.videos_pending = 0
        self.photos_embedded = 0
        self.photos_pending = 0
        self.chapters_pending_text = 0
        self.videos_appended = 0
        self.photos_auto_placed = 0
        self.figures_typeset = 0
        # Slot ids already laid out, so a chapter appendix does not repeat them.
        self.placed: set[str] = set()


def slot_lookup() -> dict[str, dict]:
    return {v["id"]: v for v in load_videos().get("videos") or []}


def demote(markdown: str, levels: int = 1) -> str:
    """Push every ATX heading down N levels so chapters nest under parts."""
    return ATX_HEADING.sub(lambda m: "#" * min(6, len(m.group(1)) + levels) + m.group(2), markdown)


PLAY_MARK = "images/plates/play-mark.png"


def poster_href(slot_id: str) -> str | None:
    poster = POSTERS_DIR / f"{slot_id}.jpg"
    if poster.is_file():
        return f"images/posters/{slot_id}.jpg"
    if (EBOOK_DIR / PLAY_MARK).exists():
        return PLAY_MARK
    return None


def video_block(
    chapter: str,
    index: int,
    description: str,
    slots: dict,
    stats: Stats,
    fmt: str = "print",
) -> str:
    slot_id = f"{chapter}-v{int(index):02d}"
    slot = slots.get(slot_id, {})
    caption = slot.get("description") or description or f"영상 {int(index)}"
    url = (slot.get("video_url") or "").strip()
    qr_path = QR_DIR / f"{slot_id}.png"
    stats.placed.add(slot_id)

    poster = ""
    if url and qr_path.exists():
        stats.videos_with_url += 1
        qr = f'<div class="video-qr"><img src="images/qr/{slot_id}.png" alt="영상 QR 코드" /></div>'
        label = "영상 보기"
        # EPUB and print both get a button-style first-frame poster. The href
        # is the playable src (WeasyPrint makes it a clickable PDF annotation).
        # The src string is never printed under 영상 보기.
        src = poster_href(slot_id)
        if src:
            layout = ""
            poster_file = POSTERS_DIR / f"{slot_id}.jpg"
            if poster_file.is_file():
                layout = f" {photo_layout_class(poster_file)}"
            poster = (
                f'<a class="video-poster{layout}" href="{html.escape(url, quote=True)}">'
                f'<img src="{src}" alt="영상 재생 — {html.escape(caption)}" />'
                "</a>\n"
            )
    else:
        stats.videos_pending += 1
        qr = '<div class="video-qr empty"></div>'
        label = "영상 보기"

    # Raw HTML is emitted flush left: an indented line inside a markdown raw
    # block would be read back as an indented code block.
    return (
        f'<figure class="video-slot video-{fmt}">\n'
        '<div class="video-row">\n'
        f"{poster}"
        f"{qr}\n"
        '<div class="video-body">\n'
        f'<p class="video-label">{label}</p>\n'
        f'<p class="video-caption">{html.escape(caption)}</p>\n'
        f'<p class="video-slot-id">{slot_id}</p>\n'
        "</div>\n"
        "</div>\n"
        "</figure>"
    )


def chapter_video_appendix(
    chapter_id: str, slots: dict, placed: set[str], stats: Stats, fmt: str = "print"
) -> str:
    """Lay out a chapter's videos that no manuscript marker has positioned yet.

    The URLs and their order within a chapter are known, but the exact paragraph
    each clip belongs to is only known where the post body is public. Rather than
    guess a position, the remaining clips are collected at the end of the chapter
    and move inline as soon as the full manuscript supplies markers.
    """
    pending = [
        slot
        for slot_id, slot in sorted(slots.items(), key=lambda kv: kv[1].get("index") or 0)
        if slot.get("chapter") == chapter_id and slot_id not in placed
    ]
    if not pending:
        return ""
    blocks = [
        '<div class="video-appendix">',
        '<p class="video-appendix-title">이 장의 영상</p>',
        "</div>",
    ]
    for slot in pending:
        stats.videos_appended += 1
        blocks.append(
            video_block(
                chapter_id, slot["index"], slot.get("description", ""), slots, stats, fmt
            )
        )
    return "\n\n".join(blocks)


# A note that only repeats "사진" adds nothing to the printed frame.
GENERIC_PHOTO_NOTE = re.compile(r"^[\[\(]?\s*사진\s*(?:첨부)?\s*[\]\)]?$")


def photo_pending_block(
    note: str, stats: Stats, chapter: str | None = None, index: int | None = None
) -> str:
    if chapter and index is not None:
        matches = stills_for_pending(chapter, int(index))
        figures = []
        for i, still in enumerate(matches):
            path = resolve_photo_path(still["dest"])
            if path:
                caption = still.get("caption") or "" if i == 0 else ""
                figures.append(figure_block(path.name, caption, stats))
        if figures:
            if len(figures) == 1:
                return figures[0]
            return (
                f'<div class="photo-gallery gallery-{len(figures)}">\n'
                + "\n".join(figures)
                + "\n</div>"
            )
    stats.photos_pending += 1
    note = (note or "").strip()
    if not note or GENERIC_PHOTO_NOTE.match(note):
        detail = ""
    else:
        detail = f" — {html.escape(note)}"
    return (
        '<div class="photo-pending">\n'
        f"<p>사진 자리{detail}</p>\n"
        "<p>원본 사진 준비 중</p>\n"
        "</div>"
    )


def text_pending_block(stats: Stats) -> str:
    stats.chapters_pending_text += 1
    return (
        '<div class="notice">\n'
        '<span class="notice-title">본문 준비 중</span>\n'
        "<p>이 장의 본문은 원고 확정 후 이 자리에 실립니다.</p>\n"
        "<p>현재 판에는 저자가 공개한 도입부까지만 수록되어 있습니다.</p>\n"
        "</div>"
    )


def figure_block(filename: str, caption: str, stats: Stats) -> str:
    path = resolve_photo_path(filename)
    if path is None:
        stats.photos_pending += 1
        detail = html.escape(caption) if caption else html.escape(filename)
        return (
            '<div class="photo-pending">\n'
            f"<p>사진 자리 — {detail}</p>\n"
            f"<p>파일 준비 중: images/photos/{html.escape(filename)}</p>\n"
            "</div>"
        )
    stats.photos_embedded += 1
    alt = html.escape(caption) or "본문 사진"
    layout = photo_layout_class(path)
    parts = [
        f'<figure class="photo {layout}">',
        f'<img class="{layout}" src="images/photos/{path.name}" alt="{alt}" />',
    ]
    if caption:
        parts.append(f"<figcaption>{caption}</figcaption>")
    parts.append("</figure>")
    return "\n".join(parts)


def chapter_photo_files(chapter_id: str, already_used: set[str]) -> list[str]:
    """Photos downloaded for this chapter, in source order, still unreferenced.

    Filenames are '<chapter>-<nn>-<stem>.jpg', so sorting gives the order the
    images appear in the source post.
    """
    return [
        path.name
        for path in sorted(PHOTOS_DIR.glob(f"{chapter_id}-[0-9][0-9]-*"))
        if path.name not in already_used
    ]


def expand_bare_markers(
    markdown: str, chapter_id: str, slots: dict, stats: Stats, fmt: str = "print"
) -> str:
    """Turn the author's [사진] / [영상] shorthand into real blocks.

    The nth [영상] in a chapter takes the nth video slot for that chapter, which is
    what moves the supplied videos inline instead of grouping them at chapter end.
    The nth [사진] takes the nth downloaded photo for the chapter; once those run
    out the rest render as labelled pending frames. Nothing is invented.
    """
    available = chapter_photo_files(chapter_id, set(FIGURE_SRC.findall(markdown)))
    chapter_slots = sorted(
        (slot for slot in slots.values() if slot.get("chapter") == chapter_id),
        key=lambda slot: slot.get("index") or 0,
    )
    counters = {"photo": 0, "video": 0}

    def photo(_match: re.Match) -> str:
        counters["photo"] += 1
        position = counters["photo"]
        if position <= len(available):
            stats.photos_auto_placed += 1
            return figure_block(available[position - 1], "", stats)
        return photo_pending_block("사진", stats)

    def video(_match: re.Match) -> str:
        counters["video"] += 1
        position = counters["video"]
        if position <= len(chapter_slots):
            slot = chapter_slots[position - 1]
            return video_block(
                chapter_id, slot["index"], slot.get("description", ""), slots, stats, fmt
            )
        # More markers than supplied videos: leave an honest empty slot.
        stats.videos_pending += 1
        return (
            '<figure class="video-slot">\n'
            '<div class="video-row">\n'
            '<div class="video-qr empty"></div>\n'
            '<div class="video-body">\n'
            '<p class="video-label">영상 보기</p>\n'
            f'<p class="video-caption">영상 {position}</p>\n'
            f'<p class="video-url pending">{PENDING_VIDEO_LABEL}</p>\n'
            "</div>\n"
            "</div>\n"
            "</figure>"
        )

    markdown = BARE_VIDEO.sub(video, markdown)
    return BARE_PHOTO.sub(photo, markdown)


def diagram_block(figure_id: str, stats: Stats) -> str:
    """A typeset assessment figure, or a loud gap if the id is unknown."""
    markup = render_figure(figure_id, FIGURES)
    if not markup:
        print(f"! unknown figure id: {figure_id}", file=sys.stderr)
        return f'<div class="photo-pending">\n<p>그림 자리 — {html.escape(figure_id)}</p>\n</div>'
    stats.figures_typeset += 1
    return markup


def expand(
    markdown: str,
    slots: dict,
    stats: Stats,
    chapter_id: str | None = None,
    fmt: str = "print",
) -> str:
    markdown = FIGURE_MARKER.sub(lambda m: diagram_block(m.group(1), stats), markdown)
    markdown = FIGURE_BLOCK.sub(
        lambda m: figure_block(m.group(1), (m.group(2) or "").strip(), stats), markdown
    )
    markdown = VIDEO_MARKER.sub(
        lambda m: video_block(m.group(1), int(m.group(2)), m.group(3), slots, stats, fmt),
        markdown,
    )
    markdown = PHOTO_PENDING.sub(
        lambda m: photo_pending_block(m.group(3), stats, m.group(1), int(m.group(2))),
        markdown,
    )
    markdown = TEXT_PENDING.sub(lambda m: text_pending_block(stats), markdown)
    if chapter_id:
        markdown = expand_bare_markers(markdown, chapter_id, slots, stats, fmt)
    return markdown


def strip_first_heading(markdown: str) -> tuple[str, str]:
    """Split a leading '# Title' off a manuscript file."""
    lines = markdown.splitlines()
    title = ""
    start = 0
    for i, line in enumerate(lines):
        if line.strip():
            if line.startswith("# "):
                title = line[2:].strip()
                start = i + 1
            break
    return title, "\n".join(lines[start:]).strip()


def plate_block(item: dict) -> str:
    """The drawn plate for a part opener or the appendix.

    Plates carry no lettering, so the alt text has to describe the mark itself.
    """
    plate = item.get("plate")
    if not plate or not (EBOOK_DIR / plate).exists():
        return ""
    size = f' {item["plate_size"]}' if item.get("plate_size") else ""
    alt = html.escape(item.get("plate_alt") or "")
    # One raw block, flush left and with no blank line inside it, so pandoc
    # passes it through whole instead of reparsing the image as a paragraph.
    return (
        f'<div class="part-plate{size}">\n'
        f'<img src="{plate}" alt="{alt}" />\n'
        "</div>"
    )


def title_page(book: dict) -> str:
    authors = "\n".join(
        '<p class="author">'
        f'<span class="author-name">{a["name_ko"]} · {a["name_en"]}</span>'
        f'<span class="author-credential">{a["credential"]}</span></p>'
        for a in book["authors"]
    )
    return (
        '<div class="title-page">\n'
        f'<h1 class="book-title">{book["title"]}</h1>\n'
        f'<p class="book-subtitle">{book["subtitle"]}</p>\n'
        '<hr class="title-rule" />\n'
        '<div class="byline">\n'
        '<p class="byline-label">지음</p>\n'
        f"{authors}\n"
        "</div>\n"
        "</div>\n"
    )


def colophon(book: dict, stats: Stats) -> str:
    authors = " · ".join(f'{a["name_ko"]} ({a["name_en"]})' for a in book["authors"])
    channel = book.get("video_channel")
    total_videos = stats.videos_with_url + stats.videos_pending
    rows = [
        f"<dt>제목</dt><dd>{book['title']}</dd>",
        f"<dt>부제</dt><dd>{book['subtitle']}</dd>",
        f"<dt>지음</dt><dd>{authors}</dd>",
    ]
    if channel:
        rows.append(f"<dt>영상 채널</dt><dd>{channel} (비공개 링크)</dd>")
    rows.append(f"<dt>저작권</dt><dd>{book['rights']}</dd>")

    notes = [
        "이 책은 교육 자료입니다. 특정한 결과를 보장하지 않으며, "
        "통증이나 부상이 있는 경우 전문가와 상의한 뒤 적용하기를 권합니다."
    ]
    if channel and total_videos:
        notes.append(
            f"본문의 영상 {total_videos}편은 전자책에서 미리보기를 눌러, "
            f"인쇄본에서는 QR 코드로 바로 볼 수 있으며, "
            f"{channel} 채널에 비공개(unlisted)로도 함께 올라갑니다."
        )
    if stats.videos_pending:
        notes.append(
            f"아직 주소가 확정되지 않은 영상 자리 {stats.videos_pending}곳은 "
            "주소가 정해지면 QR 코드와 함께 채워진 판으로 갱신됩니다."
        )
    body = "\n".join(rows)
    paragraphs = "\n".join(f"<p>{note}</p>" for note in notes)
    return (
        '<div class="colophon">\n'
        "<h1>판권</h1>\n"
        f"<dl>\n{body}\n</dl>\n"
        f"{paragraphs}\n"
        "</div>\n"
    )


def read(path) -> str:
    return path.read_text(encoding="utf-8").strip()


def wrap_terms_outside_tags(text: str) -> str:
    """Keep 다운스윙 / 테이크어웨이 / … unsplit, without touching attributes."""
    parts = re.split(r"(<[^>]+>)", text)
    out: list[str] = []
    inside_term = False
    for part in parts:
        if part.startswith('<span class="term"'):
            inside_term = True
            out.append(part)
        elif inside_term and part == "</span>":
            inside_term = False
            out.append(part)
        elif part.startswith("<") or inside_term:
            out.append(part)
        else:
            out.append(wrap_terms(part))
    return "".join(out)


def assemble(book: dict, stats: Stats, fmt: str = "print") -> str:
    slots = slot_lookup()
    out: list[str] = [title_page(book)]

    for item in book.get("front_matter", []):
        if item["kind"] == "title-page":
            continue
        if item["kind"] == "markdown":
            body = read(FRONT_MATTER_DIR.parent / item["file"])
            title, rest = strip_first_heading(body)
            title = title or item["title"]
            # Demote so the contents list stops at part and chapter level.
            rest = expand(demote(rest), slots, stats, fmt=fmt)
            out.append(f'# {title} {{#{item["id"]} .front-section}}\n\n{rest}\n')

    for part in book["parts"]:
        intro = ""
        if part.get("intro"):
            intro_path = EBOOK_DIR / part["intro"]
            if intro_path.exists():
                intro = read(intro_path)
        opener = [f'# 파트 {part["number"]} · {part["title"]} {{#{part["id"]} .part-title}}\n']
        plate = plate_block(part)
        if plate:
            opener.append(f"{plate}\n")
        if intro:
            # Left as plain markdown rather than wrapped in a div: the reader runs
            # with markdown_in_html_blocks disabled so that injected captions are
            # not re-parsed as markdown.
            opener.append(f"{intro}\n")
        out.append("\n".join(opener))

        for chapter in part["chapters"]:
            path = (
                EBOOK_DIR / chapter["file"]
                if chapter.get("file")
                else MANUSCRIPT_DIR / f'{chapter["id"]}.md'
            )
            if not path.exists():
                print(f"! missing manuscript {path.relative_to(REPO_ROOT)}", file=sys.stderr)
                continue
            title, body = strip_first_heading(read(path))
            title = title or chapter["title"]
            body = expand(demote(body), slots, stats, chapter["id"], fmt)
            # A merged section sits inside its chapter as a sibling of the
            # chapter's own headings.
            for section in chapter.get("sections", []):
                section_path = EBOOK_DIR / section["file"]
                if not section_path.exists():
                    print(f"! missing section {section['file']}", file=sys.stderr)
                    continue
                section_title, section_body = strip_first_heading(read(section_path))
                section_body = expand(
                    demote(section_body, 2), slots, stats, section["id"], fmt
                )
                body += (
                    f'\n\n### {section_title or section["title"]} '
                    f'{{#{section["id"]}}}\n\n{section_body}\n'
                )
            for still in chapter.get("pending_stills", []):
                body += "\n\n" + photo_pending_block(still.get("note", ""), stats)
            appendix = chapter_video_appendix(
                chapter["id"], slots, stats.placed, stats, fmt
            )
            if appendix:
                body += f"\n\n{appendix}\n"
            out.append(f'## {title} {{#{chapter["id"]} .chapter}}\n\n{body}\n')

    for item in book.get("back_matter", []):
        if item["kind"] == "chapter":
            path = MANUSCRIPT_DIR / f'{item["id"]}.md'
            if not path.exists():
                continue
            title, body = strip_first_heading(read(path))
            body = expand(demote(body), slots, stats, item["id"], fmt)
            plate = plate_block(item)
            opening = f"{plate}\n\n" if plate else ""
            out.append(
                f'# {title or item["title"]} {{#{item["id"]} .front-section}}\n\n{opening}{body}\n'
            )
        elif item["kind"] == "colophon":
            out.append(colophon(book, stats))

    return wrap_terms_outside_tags("\n\n".join(out))


def metadata_yaml(book: dict) -> str:
    authors = "\n".join(f'  - {a["name_ko"]} ({a["name_en"]})' for a in book["authors"])
    return (
        "---\n"
        f'title: "{book["title"]}"\n'
        f'subtitle: "{book["subtitle"]}"\n'
        "author:\n"
        f"{authors}\n"
        f'lang: {book["language"]}\n'
        f'rights: "{book["rights"]}"\n'
        f'identifier: {book["identifier"]}\n'
        "---\n"
    )


def run(cmd: list[str], cwd=None) -> None:
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(" ".join(str(c) for c in cmd), file=sys.stderr)
        print(result.stdout, file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        raise SystemExit(f"command failed: {cmd[0]}")
    if result.stderr.strip():
        for line in result.stderr.strip().splitlines():
            print(f"  pandoc: {line}")


def build_epub(book: dict, source, stats: Stats) -> None:
    dest = DIST_DIR / f'{book["basename"]}.epub'
    css = BUILD_DIR / "epub-combined.css"
    css.write_text(
        read(TEMPLATES_DIR / "common.css") + "\n\n" + read(TEMPLATES_DIR / "epub.css") + "\n",
        encoding="utf-8",
    )
    run(
        [
            "pandoc",
            str(source),
            "-f",
            "markdown+raw_html+native_divs-markdown_in_html_blocks",
            "-t",
            "epub3",
            "--toc",
            "--toc-depth=2",
            "--split-level=1",
            "--section-divs",
            # pandoc ships a broken ko translation table, so name the TOC here.
            "--metadata=toc-title:차례",
            f"--css={css}",
            f'--epub-cover-image={IMAGES_DIR / "cover.jpg"}',
            f'--metadata-file={BUILD_DIR / "metadata.yaml"}',
            f"--resource-path={EBOOK_DIR}",
            "-o",
            str(dest),
        ],
        cwd=EBOOK_DIR,
    )
    print(f"epub: {dest.relative_to(REPO_ROOT)} ({dest.stat().st_size // 1024} KB)")


def pdf_cover_html(book: dict) -> str:
    """The printed cover: drawn plate underneath, every word set in Nanum here.

    Nothing else goes on it — no company mark, no channel name, no year — so the
    only strings emitted are the title, the subtitle and the three names.
    """
    lines = "".join(f"{line}<br/>" for line in (book.get("cover_title_lines") or [book["title"]]))
    art = book.get("cover_art")
    style = f" style=\"background-image: url('{art}')\"" if art else ""
    ko = " · ".join(a["name_ko"] for a in book["authors"])
    en = " · ".join(a["name_en"] for a in book["authors"])
    return (
        f'<div class="pdf-cover"{style}>\n'
        '  <div class="cover-head">\n'
        f'    <p class="cover-title">{lines}</p>\n'
        '    <hr class="cover-rule" />\n'
        f'    <p class="cover-subtitle">{book["subtitle"]}</p>\n'
        "  </div>\n"
        '  <div class="cover-authors">\n'
        f'    <p class="cover-author-ko">{ko}</p>\n'
        f'    <p class="cover-author-en">{en}</p>\n'
        "  </div>\n"
        "</div>\n"
    )


def build_pdf(book: dict, source, stats: Stats) -> None:
    from weasyprint import HTML

    fragment = BUILD_DIR / "print-body.html"
    run(
        [
            "pandoc",
            str(source),
            "-f",
            "markdown+raw_html+native_divs-markdown_in_html_blocks",
            "-t",
            "html5",
            "--section-divs",
            "--toc",
            "--toc-depth=2",
            f'--template={TEMPLATES_DIR / "pandoc-body.html"}',
            "-o",
            str(fragment),
        ],
        cwd=EBOOK_DIR,
    )
    rendered = fragment.read_text(encoding="utf-8")
    toc_html, _, body_html = rendered.partition("<!--/TOC-->")
    toc_html = toc_html.replace("<!--TOC-->", "").strip()

    # Print-only: bind short lead-ins to their figure, then hold every Korean
    # word together — not just the flagged tokens.
    body_html = keep_korean_words_whole(group_lead_in_with_figure(body_html))
    toc_html = keep_korean_words_whole(toc_html)

    document = (
        "<!DOCTYPE html>\n"
        f'<html lang="{book["language"]}">\n<head>\n<meta charset="utf-8" />\n'
        f'<title>{book["title"]}</title>\n'
        f'<link rel="stylesheet" href="{(TEMPLATES_DIR / "common.css").as_uri()}" />\n'
        f'<link rel="stylesheet" href="{(TEMPLATES_DIR / "print.css").as_uri()}" />\n'
        "</head>\n<body>\n"
        + pdf_cover_html(book)
        + '<section class="toc-section" id="toc">\n<h1>차례</h1>\n'
        + toc_html
        + "\n</section>\n"
        + body_html
        + "\n</body>\n</html>\n"
    )
    page = BUILD_DIR / "print.html"
    page.write_text(document, encoding="utf-8")

    dest = DIST_DIR / f'{book["basename"]}.pdf'
    HTML(filename=str(page), base_url=str(EBOOK_DIR) + "/").write_pdf(str(dest))
    print(f"pdf:  {dest.relative_to(REPO_ROOT)} ({dest.stat().st_size // 1024} KB)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--epub-only", action="store_true")
    parser.add_argument("--pdf-only", action="store_true")
    args = parser.parse_args()

    book = load_book()
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    BUILD_DIR.mkdir(parents=True)
    DIST_DIR.mkdir(parents=True, exist_ok=True)

    stats = Stats()
    body = assemble(book, stats, fmt="epub")
    source = BUILD_DIR / "book.md"
    source.write_text(metadata_yaml(book) + "\n" + body + "\n", encoding="utf-8")
    (BUILD_DIR / "metadata.yaml").write_text(metadata_yaml(book), encoding="utf-8")

    if not args.pdf_only:
        build_epub(book, source, stats)
    if not args.epub_only:
        # Reset per-render counters so the report is not doubled.
        pdf_stats = Stats()
        pdf_body = assemble(book, pdf_stats, fmt="print")
        source.write_text(metadata_yaml(book) + "\n" + pdf_body + "\n", encoding="utf-8")
        build_pdf(book, source, pdf_stats)
        stats = pdf_stats

    print(
        f"\nphotos embedded: {stats.photos_embedded}   photo slots pending: {stats.photos_pending}\n"
        f"video slots laid out: {stats.videos_with_url + stats.videos_pending}   "
        f"with QR + URL: {stats.videos_with_url}   still placeholder: {stats.videos_pending}\n"
        f"  of those, {stats.videos_appended} collected at chapter end "
        f"(no marker position in the manuscript yet)\n"
        f"photos auto-placed from a [사진] marker: {stats.photos_auto_placed}\n"
        f"figures typeset from figures.yaml: {stats.figures_typeset}\n"
        f"chapters awaiting full text: {stats.chapters_pending_text}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
