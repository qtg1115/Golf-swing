#!/usr/bin/env python3
"""Check the built EPUB and PDF before they go out.

The link check is the important one. A reader-facing URL must be something a
reader can actually open:

  * allowed — the author-verified Substack video endpoint
    /api/v1/video/upload/{id}/src, which redirects to a signed Mux mp4 with no
    login, and any YouTube watch URL
  * refused — every other Substack URL, above all a /p/ post page, because those
    are paid or private

The check fails the build on a refused URL in the EPUB, in the PDF, or in the
video manifest.
"""
from __future__ import annotations

import re
import sys
import zipfile

from paths import DIST_DIR, MANUSCRIPT_DIR, QR_DIR, REPO_ROOT, load_book, load_videos

SUBSTACK = re.compile(r"(https?://[\w.-]*substack(?:cdn)?\.com[^\s\"'<>)\]]*)", re.I)
ALLOWED_SUBSTACK = re.compile(
    r"^https://[\w-]+\.substack\.com/api/v1/video/upload/"
    r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/src$",
    re.I,
)
IMG_SRC = re.compile(rb'src="([^"]+\.(?:jpe?g|png))"')
VIDEO_MARKER = re.compile(r"\[\[VIDEO-PUBLIC:\s*([^/\]]+?)\s*/\s*(\d+)\s*/")


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
    allowed = 0
    for name in epub.namelist():
        if not re.search(r"\.(xhtml|html|css|opf|ncx)$", name):
            continue
        text = epub.read(name).decode("utf-8", "replace")
        for match in SUBSTACK.findall(text):
            if ALLOWED_SUBSTACK.match(match):
                allowed += 1
            else:
                hits.append(f"EPUB {name}: {match}")
    report.check(not hits, "no gated Substack URL in the EPUB", "; ".join(hits[:3]))
    report.note(f"{allowed} playable video URL(s) in the EPUB text")

    # PDF text is inside compressed content streams, and long URLs get split
    # across show-text operators, so reassemble the visible glyphs per stream.
    import zlib

    pdf_hits: list[str] = []
    for stream in re.findall(rb"stream\r?\n(.*?)endstream", pdf_bytes, re.S):
        try:
            raw = zlib.decompress(stream).decode("latin-1", "replace")
        except zlib.error:
            continue
        if "substack" not in raw.lower():
            continue
        joined = "".join(re.findall(r"\((.*?)\)\s*Tj", raw, re.S)).replace("\\", "")
        for match in SUBSTACK.findall(joined):
            if not ALLOWED_SUBSTACK.match(match):
                pdf_hits.append(match)
    report.check(not pdf_hits, "no gated Substack URL in the PDF", "; ".join(pdf_hits[:2]))


def check_videos(report: Report) -> None:
    slots = load_videos().get("videos") or []
    slot_ids = {s["id"] for s in slots}

    # Markers fix a slot's position in the text; a slot without one is laid out at
    # the end of its chapter. So markers must be a subset of the slots, and every
    # marker must resolve to a real slot.
    unknown: list[str] = []
    marker_count = 0
    for path in MANUSCRIPT_DIR.glob("*.md"):
        for chapter, index in VIDEO_MARKER.findall(path.read_text(encoding="utf-8")):
            marker_count += 1
            slot_id = f"{chapter}-v{int(index):02d}"
            if slot_id not in slot_ids:
                unknown.append(f"{path.name}: {slot_id}")
    report.check(
        not unknown,
        "every manuscript video marker resolves to a manifest slot",
        "; ".join(unknown[:3]),
    )
    report.note(f"{marker_count} of {len(slots)} slot(s) positioned by a manuscript marker")

    from make_qr import validate

    bad = []
    for slot in slots:
        url = (slot.get("video_url") or "").strip()
        if url and validate(url) is not None:
            bad.append(f'{slot["id"]}: {validate(url)}')
    report.check(not bad, "every manifest URL is an openable target", "; ".join(bad[:3]))

    with_url = [s for s in slots if s.get("video_url")]
    missing_qr = [s["id"] for s in with_url if not (QR_DIR / f'{s["id"]}.png').exists()]
    report.check(not missing_qr, "every slot with a URL has a QR", ", ".join(missing_qr[:5]))

    orphan_qrs = [
        p.name for p in QR_DIR.glob("*.png") if p.stem not in {s["id"] for s in with_url}
    ]
    report.check(not orphan_qrs, "no QR without a manifest URL", ", ".join(orphan_qrs))
    report.note(
        f"{len(slots)} video slot(s): {len(with_url)} with a playable URL, "
        f"{len(slots) - len(with_url)} without"
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
