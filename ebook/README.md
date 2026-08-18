# 골프 느낌의 실체 — ebook build

Korean ebook production for **「골프 느낌의 실체」**
(subtitle: 프로가 말하는 감각을 실제 현상으로 풀다).

| | |
|---|---|
| Title | 골프 느낌의 실체 |
| Subtitle | 프로가 말하는 감각을 실제 현상으로 풀다 |
| Authors (equal billing) | 이충원 Logan Lee · 방승호 Bryan Bang · 박세인 Jason Park |
| Language | Korean only |
| Channel name (video hosting) | 골프 느낌의 실체 |
| Outputs | `dist/golf-neukkimui-silche.epub`, `dist/golf-neukkimui-silche.pdf` |
| Trim size | A5 (148 × 210 mm) |

The book turns the *feel* language that tour players and teaching pros use into
actual physical phenomena — mechanics and kinesiology. It is not a foot-only
book and not a single-author book.

**Cover branding:** none. By author instruction the cover and title page carry no
company mark — no Logic Performance, no Logic Fitness.

**Former working titles**, kept here only so older drafts can be matched up:
「내 발이 만드는 스윙 시간」, 「프로가 말하는 그 느낌」, 「느낌은 있는데 스윙이 안 된다」,
「그 느낌의 실체」. None of these are the title; the title is 「골프 느낌의 실체」.

---

## Video hosting — what still needs a public URL

**Every ebook video is to be hosted as YouTube UNLISTED on the golf channel
(골프 느낌의 실체). QR generation waits for those URLs.**

**54 videos are pending YouTube unlisted upload.** That is the count in the
compiled manuscript inventory. No QR code has been generated, because no public
URL exists yet.

Substack is never used as the reader-facing target. Readers cannot open
`logicfitko.substack.com` links — most of those posts are paid or private — so
none of the following are encoded anywhere in the EPUB or PDF, and the build
refuses to encode them:

- `https://logicfitko.substack.com/p/…`
- `https://logicfitko.substack.com/api/v1/video/upload/…/src`
- any other Substack-gated URL

`scripts/verify.py` scans the finished EPUB and the decompressed PDF streams for
`substack` and fails the build if a match appears. `scripts/make_qr.py` rejects
any URL that is not an `https` YouTube watch URL.

### Video slots laid out in the current build

Six slots are laid out in the manuscript so far, all in one chapter. They are the
only clips visible in the public source; the rest sit inside posts whose body is
not public yet (see the chapter table below).

| Slot | Part / chapter | Description in the text | Public URL |
|---|---|---|---|
| `p3-c6-v01` | 3부 · 챕터 6 임팩트 직전 — 8시 | 2. 벤 호건의 느낌을 몸으로 하는 방법 | pending |
| `p3-c6-v02` | 3부 · 챕터 6 임팩트 직전 — 8시 | 2. 벤 호건의 느낌을 몸으로 하는 방법 | pending |
| `p3-c6-v03` | 3부 · 챕터 6 임팩트 직전 — 8시 | 2. 벤 호건의 느낌을 몸으로 하는 방법 | pending |
| `p3-c6-v04` | 3부 · 챕터 6 임팩트 직전 — 8시 | 첫번째 운동 | pending |
| `p3-c6-v05` | 3부 · 챕터 6 임팩트 직전 — 8시 | 두번째 운동 | pending |
| `p3-c6-v06` | 3부 · 챕터 6 임팩트 직전 — 8시 | 세번째 운동 | pending |

Remaining slots by chapter cannot be listed yet: the clips live inside the 15
chapters whose body text is still paywalled. They appear in this table as soon as
the full manuscript lands and `scripts/convert_sources.py` runs against it.

### How a video slot renders today

Caption, an empty dashed QR box, and the label 공개 영상 주소 예정. Nothing is
invented and no URL is shown:

```
┌──────┐  영상 보기
│  QR  │  첫번째 운동
└──────┘  공개 영상 주소 예정
          p3-c6-v04
```

### Filling in a URL

1. Upload the clip to the 골프 느낌의 실체 channel as **unlisted**.
2. Put the watch URL in `media/videos.yaml` under the matching slot:

```yaml
  - id: p3-c6-v04
    chapter: p3-c6
    index: 4
    description: "첫번째 운동"
    substack_media_id: 814630e9-d484-4bdb-983d-32329e0de058
    youtube_url: https://www.youtube.com/watch?v=XXXXXXXXXXX
```

3. `make videos && make book`

The QR appears in the box, the label becomes the URL in plain text for anyone who
cannot scan, and `verify.py` confirms the QR exists.

`substack_media_id` is an internal asset-matching key so the original clip can be
found for upload. It is never rendered, never linked, and never encoded.

---

## Photo inventory

- **23 photos embedded** — downloaded from the source CDN into `images/photos/`,
  flattened onto white, capped at 1600 px on the long edge, stored as JPEG q92.
  Images are embedded locally; nothing hotlinks a gated host.
- **1 photo slot pending a file.** The both-feet swing photo for the release
  section. Drop the file at exactly `images/photos/01-swing-both-feet.png` and
  rerun `make book` — the build picks it up and replaces the placeholder frame
  automatically. Until then it renders as a dashed 사진 자리 box.
- The compiled manuscript inventory counts **64 photos**. The 41 not yet here are
  inside the paywalled post bodies, along with the 6 stills the author flagged as
  missing (5 `[사진]` markers in the release draft, 1 `(사진첨부)` in CHAPTER 9).
  Those become `[[PHOTO-PENDING: …]]` slots when the full manuscript is converted.

No photo of a real person is ever generated or substituted. A missing still stays
a labelled empty frame.

---

## Contents and sources

Structure lives in `book.yaml`. Text is Markdown in `manuscript/` and
`front-matter/`.

- 이 책을 읽는 법 — 세 저자, 왜 느낌을 몸으로 번역하는가
- **1부. 느낌은 있는데 스윙이 안 되는 이유**
- **2부. 내 스윙의 문제를 찾는 법**
- **3부. 스윙 시계 — 느낌이 지나가는 자리** (챕터 1–10; the release/foot material is a
  section of 챕터 7 임팩트, not a part of its own)
- **4부. 샷에 실리는 느낌**
- **부록. 프로와 같은 말로 말하기**

`full` means the whole body is public and typeset. `teaser` means only the public
opening is available, and the chapter carries a 본문 준비 중 notice where the rest
belongs. **No chapter body has been written, paraphrased, or padded out.**

| Chapter | Part | Source | Text | Photos | Videos |
|---|---|---|---|---|---|
| 골프 트레이닝에 대한 생각 | 1부 | `womakers` | full | 0 | 0 |
| 골프를 배워도 잘 안되는 이유 | 1부 | `05f` | teaser | 1 | 0 |
| 나의 스윙 문제를 찾는 어세스먼트 로드맵 | 2부 | `434` | full | 5 | 0 |
| 챕터 1 · 어드레스 — 6시 | 3부 | `1-6` | teaser | 1 | 0 |
| 챕터 2 · 테이크어웨이 — 7시 | 3부 | `chapter-2-takeaway-7` | teaser | 1 | 0 |
| 챕터 3 · 백스윙 하프웨이 — 9시 | 3부 | `chapter-3-9` | teaser | 1 | 0 |
| 챕터 4 · 탑 오브 백스윙 — 12시 | 3부 | `chapter-4-12` | teaser | 1 | 0 |
| 챕터 5 · 다운스윙 전환 — 10시 | 3부 | `chapter-5-10` | teaser | 1 | 0 |
| 챕터 6 · 임팩트 직전 — 8시 | 3부 | `chapter-6-8` | full | 1 | 6 |
| 챕터 7 · 임팩트 — 다시 6시 | 3부 | `chapter-7-6` | teaser | 1 | 0 |
| ↳ 릴리즈 타이밍은 발바닥에서 달라진다 | 3부 | unpublished draft | pending | 1 pending | 0 |
| 챕터 8 · 팔로우스루 — 3시 | 3부 | `chapter-8-3` | teaser | 1 | 0 |
| 챕터 9 · 두 번째 팔로우스루 — 1시 | 3부 | `chapter-9-1` | teaser | 1 | 0 |
| 챕터 10 · 피니시 | 3부 | `chapter-10` | full | 1 | 0 |
| 테크닉 챕터 1 · 드로우 샷 | 4부 | `1` | teaser | 1 | 0 |
| 테크닉 챕터 2 · 페이드 샷 | 4부 | `2` | teaser | 1 | 0 |
| 테크닉 챕터 3 · 하이 런치 샷 | 4부 | `3` | teaser | 2 | 0 |
| 테크닉 챕터 4 · 스팅어 샷 | 4부 | `4` | teaser | 1 | 0 |
| 테크닉 챕터 5 · 스트레이트 샷 | 4부 | `5` | teaser | 1 | 0 |
| 부록 · 프로와 같은 말로 말하기 | 부록 | `golf-a` | teaser | 1 | 0 |

4 of 19 source posts are public; 15 return a short teaser. Front matter and the
part introductions are editorial copy written for this build and need author
sign-off.

---

## Rebuild

```bash
cd ebook
make          # cover, media manifests, QR, EPUB, PDF, verification
make all      # the above, plus a refetch of the sources
```

Individual steps:

| Command | Does |
|---|---|
| `python3 scripts/fetch_sources.py` | cache the source posts into `sources/` |
| `python3 scripts/convert_sources.py` | cached HTML → `manuscript/*.md` (`--force` to overwrite) |
| `python3 scripts/build_media.py` | download and optimise photos, write both manifests |
| `python3 scripts/make_qr.py` | QR PNGs for slots that have a YouTube URL |
| `python3 scripts/make_cover.py` | render `images/cover.png` |
| `python3 scripts/build.py` | assemble the EPUB and the A5 PDF |
| `python3 scripts/verify.py` | package, image, and no-Substack-link checks |

`convert_sources.py` will not overwrite an existing manuscript file unless
`--force` is passed, so hand edits and the delivered manuscript survive a re-run.

### Dependencies

```bash
sudo apt-get install -y pandoc fonts-noto-cjk fonts-nanum poppler-utils
pip3 install weasyprint qrcode pillow beautifulsoup4 lxml pyyaml
```

Korean text is set in NanumMyeongjo with NanumBarunGothic headings, and both
fonts are confirmed to render in the PDF.

---

## Layout

```
ebook/
  book.yaml              structure, title, authors, part and chapter order
  Makefile
  front-matter/          이 책을 읽는 법 + part introductions
  manuscript/            one Markdown file per chapter
  sources/               cached source payloads (build provenance)
  images/
    cover.png
    photos/              embedded photos, JPEG q92, ≤1600 px
    qr/                  QR PNGs — empty until YouTube URLs exist
  media/
    photos.json          photo manifest with download status
    videos.yaml          video manifest, youtube_url: null until uploaded
  templates/             common.css, print.css, epub.css, pandoc body template
  scripts/
dist/
  golf-neukkimui-silche.epub
  golf-neukkimui-silche.pdf
```

### Placeholder markers

Three markers keep unfinished material explicit instead of invented:

| Marker | Renders as |
|---|---|
| `[[VIDEO-PUBLIC: chapter / index / description]]` | caption + empty QR box + 공개 영상 주소 예정 |
| `[[PHOTO-PENDING: chapter / index / note]]` | dashed 사진 자리 frame |
| `[[MANUSCRIPT-PENDING: slug]]` | 본문 준비 중 notice |

---

## Status

| Item | State |
|---|---|
| EPUB | builds, 24 images packaged, Korean metadata, hierarchical navigation |
| PDF | builds, A5, Korean fonts render, running heads, folios, contents with page numbers |
| Photos | 23 embedded, 1 awaiting a file, 41 more expected with the full manuscript |
| Videos | **54 pending YouTube unlisted upload; 0 QR codes generated** |
| Chapter text | 4 chapters complete, 15 awaiting full manuscript, 1 release draft pending |
| Front matter | draft copy, needs author sign-off |

This build is educational material. It makes no swing-fix guarantee, and the
front matter says so.
