#!/usr/bin/env python3
"""Cache the Substack source posts listed in book.yaml.

Writes one JSON file per chapter into ebook/sources/. Paid posts return only a
public teaser; the teaser is stored as-is and flagged, never padded out.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request

from paths import BOOK_YAML, SOURCES_DIR, load_book

UA = "Mozilla/5.0 (compatible; LogicPerformance-ebook-build/1.0)"
ARCHIVE = "https://logicfitko.substack.com/api/v1/posts?limit=50&offset={offset}"
POST_URL = "https://logicfitko.substack.com/p/{slug}"
PRELOADS = re.compile(r'window\._preloads\s*=\s*JSON\.parse\((".*?")\)\s*</script>', re.S)


def http_get(url: str, tries: int = 4) -> str:
    delay = 4
    for attempt in range(1, tries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read().decode("utf-8", "replace")
        except (urllib.error.URLError, TimeoutError) as exc:
            if attempt == tries:
                raise
            print(f"  retry {attempt}/{tries} after {exc}", file=sys.stderr)
            time.sleep(delay)
            delay *= 2
    raise AssertionError("unreachable")


def fetch_archive() -> dict[str, dict]:
    posts: dict[str, dict] = {}
    offset = 0
    while True:
        batch = json.loads(http_get(ARCHIVE.format(offset=offset)))
        if not batch:
            break
        for post in batch:
            posts.setdefault(post["slug"], post)
        if len(batch) < 50:
            break
        offset += 50
    return posts


def fetch_post(slug: str) -> dict:
    html = http_get(POST_URL.format(slug=slug))
    match = PRELOADS.search(html)
    if not match:
        raise RuntimeError(f"no _preloads payload on /p/{slug}")
    return json.loads(json.loads(match.group(1)))["post"]


def plain_text(body_html: str) -> str:
    text = re.sub(r"<(script|style)\b.*?</\1>", " ", body_html, flags=re.S | re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def chapter_slugs(book: dict) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    for part in book["parts"]:
        for chapter in part["chapters"]:
            if chapter.get("slug"):
                out.append((str(chapter["slug"]), chapter["title"]))
    for item in book.get("back_matter", []):
        if item.get("slug"):
            out.append((str(item["slug"]), item["title"]))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="report on the existing cache without contacting Substack",
    )
    args = parser.parse_args()

    book = load_book()
    wanted = chapter_slugs(book)
    SOURCES_DIR.mkdir(parents=True, exist_ok=True)

    if args.offline:
        for slug, title in wanted:
            path = SOURCES_DIR / f"{slug}.json"
            state = "cached" if path.exists() else "MISSING"
            print(f"{slug:24s} {state:8s} {title}")
        return 0

    print(f"structure: {BOOK_YAML}")
    archive = fetch_archive()
    print(f"archive: {len(archive)} posts listed")

    rows = []
    for slug, title in wanted:
        meta = archive.get(slug, {})
        post = fetch_post(slug)
        text = plain_text(post.get("body_html") or "")
        audience = post.get("audience") or meta.get("audience") or "unknown"
        wordcount = meta.get("wordcount") or post.get("wordcount") or 0
        # A paid post hands back a short teaser instead of the body. Treat any
        # non-public post as partial so the build can label it honestly.
        partial = audience != "everyone"
        record = {
            "slug": slug,
            "book_title": title,
            "substack_title": post.get("title"),
            "subtitle": post.get("subtitle"),
            "audience": audience,
            "post_date": post.get("post_date"),
            "wordcount_full": wordcount,
            "public_text_chars": len(text),
            "public_body_is_partial": partial,
            "body_html": post.get("body_html") or "",
            "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        (SOURCES_DIR / f"{slug}.json").write_text(
            json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        rows.append(record)
        flag = "TEASER ONLY" if partial else "full"
        print(f"{slug:24s} {audience:11s} {len(text):6d} chars  {flag}")
        time.sleep(0.4)

    partial = [r["slug"] for r in rows if r["public_body_is_partial"]]
    print(f"\n{len(rows)} sources cached, {len(partial)} paywalled: {', '.join(partial)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
