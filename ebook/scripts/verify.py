#!/usr/bin/env python3
"""Check the built EPUB and PDF before they go out.

The important check is the third one: no Substack URL may appear anywhere a
reader could act on it, because those posts are paid/private. Video links and
QR codes are only ever YouTube unlisted URLs.
"""
from __future__ import annotations

import re
import sys
import zipfile

from paths import DIST_DIR, MANUSCRIPT_DIR, QR_DIR, REPO_ROOT, load_book, load_videos

SUBSTACK = re.compile(r"(https?://[\w.-]*substack(?:cdn)?\.com[^\s\"'<>)\]]*)", re.I)
IMG_SRC = re.compile(rb'src="([^"]+\.(?:jpe?g|png))"')
VIDEO_MARKER = re.compile(r"\[\[VIDEO-PUBLIC:")


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.notes: list[str] = []

    def check(self, ok: bool, label: str, detail: str = "") -> None:
        if ok:
            print(f"  ok    {label}")
        else:
            print(f"  FAIL  {label}{': ' + detail if detail else ''}")
            self.failures.append(label)

    def note(self, text: str) -> None:
        print(f"  note  {text}")
        self.notes.append(text)


def check_outputs(book: dict, report: Report) -> tuple[zipfile.ZipFile | None, bytes]:
    epub_path = DIST_DIR / f'{book["basename"]}.epub'
    pdf_path = DIST_DIR / f'{book["basename"]}.pdf'
    report.check(epub_path.exists(), f"EPUB exists ({epub_path.name})")
    report.check(pdf_path.exists(), f"PDF exists ({pdf_path.name})")
    if not (epub_path.exists() and pdf_path.exists()):
        return None, b""
    return zipfile.ZipFile(epub_path), pdf_path.read_bytes()


def check_epub(epub: zipfile.ZipFile, book: dict, report: Report) -> None:
    names = epub.namelist()
    report.check(names[0] == "mimetype", "mimetype is the first zip entry")
    report.check(
        epub.read("mimetype") == b"application/epub+zip", "mimetype content is application/epub+zip"
    )

    opf = next((n for n in names if n.endswith(".opf")), None)
    report.check(opf is not None, "package document present")
    if opf:
        meta = epub.read(opf).decode("utf-8", "replace")
        report.check(book["title"] in meta, "title in EPUB metadata")
        for author in book["authors"]:
            report.check(
                author["name_ko"] in meta, f'author {author["name_ko"]} in EPUB metadata'
            )
        report.check('xml:lang="ko"' in meta or ">ko<" in meta, "language is ko")

    nav = next((n for n in names if n.endswith("nav.xhtml")), None)
    report.check(nav is not None, "navigation document present")
    if nav:
        nav_text = epub.read(nav).decode("utf-8", "replace")
        for part in book["parts"]:
            report.check(part["title"] in nav_text, f'part {part["number"]} in navigation')

    # Every referenced image must be inside the package.
    packaged = {n.split("/")[-1] for n in names}
    missing: list[str] = []
    for name in names:
        if not name.endswith(".xhtml"):
            continue
        for src in IMG_SRC.findall(epub.read(name)):
            filename = src.decode().split("/")[-1]
            if filename not in packaged:
                missing.append(f"{name} -> {filename}")
    report.check(not missing, "all referenced images are packaged", "; ".join(missing[:3]))

    images = [n for n in names if re.search(r"\.(jpe?g|png)$", n, re.I)]
    report.note(f"{len(images)} image file(s) packaged")


def check_no_substack(epub: zipfile.ZipFile, pdf_bytes: bytes, report: Report) -> None:
    hits: list[str] = []
    for name in epub.namelist():
        if not re.search(r"\.(xhtml|html|css|opf|ncx)$", name):
            continue
        text = epub.read(name).decode("utf-8", "replace")
        for match in SUBSTACK.findall(text):
            hits.append(f"EPUB {name}: {match}")
    report.check(not hits, "no Substack URL in the EPUB", "; ".join(hits[:3]))

    # PDF content streams are compressed, so decompress before scanning.
    pdf_hits: list[str] = []
    for stream in re.findall(rb"stream\r?\n(.*?)endstream", pdf_bytes, re.S):
        import zlib

        try:
            text = zlib.decompress(stream).decode("latin-1", "replace")
        except zlib.error:
            text = stream.decode("latin-1", "replace")
        if "substack" in text.lower():
            pdf_hits.append(text[max(0, text.lower().find("substack") - 40) :][:120])
    report.check(not pdf_hits, "no Substack URL in the PDF", "; ".join(pdf_hits[:2]))


def check_videos(report: Report) -> None:
    slots = load_videos().get("videos") or []
    marker_count = sum(
        len(VIDEO_MARKER.findall(path.read_text(encoding="utf-8")))
        for path in MANUSCRIPT_DIR.glob("*.md")
    )
    report.check(
        marker_count == len(slots),
        "every manuscript video marker has a manifest slot",
        f"{marker_count} markers vs {len(slots)} slots",
    )

    bad = [s["id"] for s in slots if (s.get("youtube_url") or "") and "substack" in s["youtube_url"]]
    report.check(not bad, "no Substack URL in the video manifest", ", ".join(bad))

    with_url = [s for s in slots if s.get("youtube_url")]
    for slot in with_url:
        report.check(
            (QR_DIR / f'{slot["id"]}.png').exists(),
            f'QR present for {slot["id"]}',
        )
    orphan_qrs = [
        p.name for p in QR_DIR.glob("*.png") if p.stem not in {s["id"] for s in with_url}
    ]
    report.check(not orphan_qrs, "no QR without a manifest URL", ", ".join(orphan_qrs))
    report.note(
        f"{len(slots)} video slot(s): {len(with_url)} with a YouTube URL, "
        f"{len(slots) - len(with_url)} awaiting upload"
    )


def main() -> int:
    book = load_book()
    report = Report()

    print("outputs")
    epub, pdf_bytes = check_outputs(book, report)
    if epub is None:
        print("\nbuild the book first: python3 scripts/build.py")
        return 1

    print("epub package")
    check_epub(epub, book, report)

    print("reader-facing links")
    check_no_substack(epub, pdf_bytes, report)

    print("video slots")
    check_videos(report)

    print()
    if report.failures:
        print(f"{len(report.failures)} check(s) failed")
        return 1
    print("all checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
