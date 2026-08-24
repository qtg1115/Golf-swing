#!/usr/bin/env python3
"""Re-paragraph the manuscript so it reads as book prose, not column staccato.

The source columns put every sentence on its own line with a blank line between,
which prints as machine-like staccato. This groups consecutive prose sentences
into paragraphs. It moves no sentence, drops no sentence, and edits no wording —
only the blank lines between sentences change.

Boundaries that are never crossed: headings, blockquotes, figures, media markers,
list items, bold-only labels, and hard line breaks.
"""
from __future__ import annotations

import argparse
import re
import sys

from paths import MANUSCRIPT_DIR

# A paragraph that is structure, not prose. The dash forms are deliberately loose:
# the author writes bullets both as "- item" and, often, as "-item".
STRUCTURAL = re.compile(
    r'^(#{1,6} |>|<|\[\[|---|\d+[.)]\s?|[-*]\s?\S|\*\*.*\*\*$|\*[^*]+\*$)'
)

# A turn in the argument. Worth its own paragraph once one is already running.
TURN = ('하지만', '그러나', '반대로', '즉', '결국', '따라서', '그래서', '만약',
        '오히려', '물론', '여기서', '그렇다면', '이제', '다만')

# Short declaratives that land better alone.
PUNCH_MAX = 22
# Keep paragraphs from becoming walls.
PARA_MAX = 190


def is_structural(block: str) -> bool:
    return bool(STRUCTURAL.match(block.strip())) or '  \n' in block or '\n' in block.strip()


def starts_turn(s: str) -> bool:
    return s.lstrip().startswith(TURN)


def group(run: list[str]) -> list[str]:
    """Group a run of one-sentence blocks into paragraphs."""
    out: list[str] = []
    cur: list[str] = []

    def flush():
        if cur:
            out.append(' '.join(cur))
            cur.clear()

    for i, s in enumerate(run):
        last = i == len(run) - 1
        length = sum(len(x) for x in cur) + len(s)

        # A turn opens a new paragraph once the current one has substance.
        if cur and starts_turn(s) and len(cur) >= 2:
            flush()
            cur.append(s)
            continue

        # Would overflow: close first.
        if cur and length > PARA_MAX:
            flush()
            cur.append(s)
            continue

        cur.append(s)

        # A short closing line stands alone for emphasis.
        if last and len(s) <= PUNCH_MAX and len(cur) > 1:
            cur.pop()
            flush()
            out.append(s)
            return out

        if len(cur) >= 4:
            flush()

    flush()
    return out


def process(text: str) -> tuple[str, int, int]:
    blocks = text.split('\n\n')
    result: list[str] = []
    run: list[str] = []
    merged = 0

    def close_run():
        nonlocal merged
        if not run:
            return
        grouped = group(run)
        merged += len(run) - len(grouped)
        result.extend(grouped)
        run.clear()

    for raw in blocks:
        b = raw.strip()
        if not b:
            continue
        if is_structural(b):
            close_run()
            result.append(b)
        else:
            run.append(b)
    close_run()
    return '\n\n'.join(result) + '\n', len(blocks), merged


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', nargs='*', help='manuscript stems (default: all)')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    targets = (
        [MANUSCRIPT_DIR / f'{n}.md' for n in args.files]
        if args.files
        else sorted(MANUSCRIPT_DIR.glob('*.md'))
    )

    total_before = total_merged = 0
    for path in targets:
        if not path.exists():
            print(f'! missing {path.name}', file=sys.stderr)
            continue
        original = path.read_text(encoding='utf-8')
        new, before, merged = process(original)
        total_before += before
        total_merged += merged
        after = before - merged
        print(f'{path.name:16} {before:4} blocks -> {after:4}  ({merged} merges)')
        if not args.dry_run and new != original:
            path.write_text(new, encoding='utf-8')

    print(f'\ntotal blocks {total_before} -> {total_before - total_merged}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
