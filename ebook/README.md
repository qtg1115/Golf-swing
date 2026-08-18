# 골프 느낌의 실제 원리 — ebook build

Korean ebook production for **「골프 느낌의 실제 원리」**
(subtitle: 프로가 말하는 감각을 실제 현상으로 풀다).

| | |
|---|---|
| Title | 골프 느낌의 실제 원리 |
| Subtitle | 프로가 말하는 감각을 실제 현상으로 풀다 |
| Authors (equal billing) | 이충원 Logan Lee · 방승호 Bryan Bang · 박세인 Jason Park |
| Language | Korean only |
| Video channel | 골프느낌원리 (unlisted) |
| Outputs | `dist/golf-neukkimui-siljae-wonri.epub`, `dist/golf-neukkimui-siljae-wonri.pdf` |
| Trim size | A5 (148 × 210 mm) |

The book turns the *feel* language that tour players and teaching pros use into
actual physical phenomena — mechanics and kinesiology. It is not a foot-only
book and not a single-author book.

**Cover branding:** none. By author instruction the cover and title page carry no
company mark — no Logic Performance, no Logic Fitness. The cover is drawn art
plus real type: the title, the subtitle and the three names, and nothing else. No
channel name, no handle, no year, no seal. `verify.py` fails the build if any of
those reappear in the cover copy.

**Former working titles**, kept here only so older drafts can be matched up:
「내 발이 만드는 스윙 시간」, 「프로가 말하는 그 느낌」, 「느낌은 있는데 스윙이 안 된다」,
「그 느낌의 실체」, 「골프 느낌의 실체」. None of these are the title; the title is
「골프 느낌의 실제 원리」, which is locked.

---

## Videos — 54 playable URLs with QR codes

All **54 videos are live in the book**: each one has a QR code. The print PDF
does not print the raw URL next to 영상 보기.

The reader-facing target is the author-supplied endpoint

```
https://logicfitko.substack.com/api/v1/video/upload/{id}/src
```

which 302-redirects to a signed Mux mp4. I checked all 54 before encoding any of
them: every one answers `206 video/mp4` with no login and no cookie, and lands on
`stream.mux.com`. Each generated QR was then decoded back and compared against
the manifest — 54 of 54 match.

The EPUB and the print PDF treat the same 54 URLs differently. In the EPUB each
slot is a **button-style poster**: the clip's own first frame with a play control
on it. Tapping the poster opens the playable `src` URL. In the A5 PDF the slot
is a designed QR block — caption plus a scannable code — with no click, no
poster, and **no printed https://…/src string**. Neither format uses a photoreal
golfer as a poster, and a portrait clip stays portrait.

Worth knowing: the QR resolves to a bare mp4 file rather than a player page, so a
phone opens it in the browser's video view with no player chrome. Substack mints
a fresh Mux token per request, so the expiry inside the redirect target does not
affect the printed URL. If these are ever re-hosted on YouTube, put the watch URL
in `media/videos.yaml` and rebuild; both URL shapes are accepted.

The same clips are credited to the **골프느낌원리** channel, hosted unlisted. That name
is locked and appears on the 판권 (credits) page and here. The book is *not*
renamed — the title stays 「골프 느낌의 실제 원리」 — and the cover art carries no
channel or company mark.

**Substack post pages are still refused.** `logicfitko.substack.com/p/…` is
paid/private, so it is never linked or encoded. The split is enforced in code,
not by care: `scripts/make_qr.py` accepts only the video endpoint above (with a
full UUID) or a YouTube watch URL, and `scripts/verify.py` fails the build if any
other Substack URL reaches the EPUB or the PDF.

### Where the videos sit

| Chapter | Videos | Placement |
|---|---|---|
| 1부 · 골프를 배워도 잘 안 되는 이유 | 1 | inline |
| 3부 · 챕터 1 어드레스 — 6시 | 2 | inline |
| 3부 · 챕터 2 테이크어웨이 — 7시 | 8 | inline |
| 3부 · 챕터 3 백스윙 하프웨이 — 9시 | 8 | inline |
| 3부 · 챕터 4 탑 오브 백스윙 — 12시 | 5 | inline |
| 3부 · 챕터 5 다운스윙 전환 — 10시 | 6 | inline |
| 3부 · 챕터 6 임팩트 직전 — 8시 | 6 | inline |
| 3부 · 챕터 7 임팩트 — 다시 6시 | 5 | inline |
| 3부 · 챕터 8 팔로우스루 — 3시 | 4 | inline |
| 3부 · 챕터 9 두 번째 팔로우스루 — 1시 | 6 | inline |
| 4부 · 테크닉 챕터 1 드로우 샷 | 2 | inline |
| 4부 · 테크닉 챕터 2 페이드 샷 | 1 | inline |
| **Total** | **54** | all 54 inline at their authored positions |

Chapter 6 is the one chapter whose body is public, so its six clips are placed at
the exact paragraphs they appear in. For the other chapters the URLs and their
order are known but the paragraph each belongs to is not, because those bodies
are still paywalled. Rather than guess, those clips are grouped under a
**이 장의 영상** heading at the end of their chapter. They move inline
automatically once the full manuscript arrives carrying
`[[VIDEO-PUBLIC: …]]` markers — the build prefers a marker position and only
falls back to the chapter-end group.

Captions for the 48 grouped clips read 영상 1, 영상 2, and so on. Real captions
come from the manuscript markers, or can be written into the `description` field
in `media/videos.yaml`.

### Editing videos

`media/video-urls.yaml` is the input: chapter id → ordered list of upload ids.
`media/videos.yaml` is generated from it and must not be hand-edited except for
`description`. After a change:

```bash
python3 scripts/build_media.py && python3 scripts/make_qr.py && python3 scripts/build.py
```

---

## Artwork: everything in the book is drawn or typeset here

**No image-model artwork remains.** The 18 stock clipart headers went first, then
the author confirmed the five surviving pictures were generated too — four
teal/navy 2부 infographics and a photoreal golfer on a mountain course — and
those are deleted. `images/photos/` now holds no source photograph at all.

**Plates drawn by `scripts/make_plates.py`.** Drawn with shape maths and an
ink-simulation pass, not generated, so nothing figurative is invented and **no
lettering is baked into any of them**. Every word on those pages is set in Nanum
from `book.yaml` at build time.

| File | Where | Mark |
|---|---|---|
| `plates/cover-art.jpg` | cover, full bleed | open circle, one sweep past the join |
| `plates/part-1-footprints.jpg` | 1부 | two shoe prints inside a path that breaks up |
| `plates/part-2-grid.jpg` | 2부 | empty diagnostic grid, one cell stamped |
| `plates/part-3-clock.jpg` | 3부 | swing-clock dial, the down-and-through sweep |
| `plates/part-4-arcs.jpg` | 4부 | three ball flights off one launch point |
| `plates/fig-hi-launch.jpg` | 4부 챕터 3 | one high launch, steeply up and steeply down |
| `plates/appendix-mark.png` | 부록 | small index mark, typography otherwise |
| `cover.jpg` | EPUB cover image | the cover plate with the type drawn onto it |

**Figures typeset from `figures.yaml`.** The 2부 assessment diagrams are markup,
not pictures, rendered by `scripts/figures.py`. The Korean is set in Nanum with
the rest of the book, so it stays sharp at A5, reflows in the EPUB, is selectable
and searchable, needs no alt text, and a wording fix is a one-line edit instead of
a redraw.

| Figure id | Replaces | Now |
|---|---|---|
| `roadmap` | `p2-c1-02` 스윙 어세스먼트 로드맵 | three numbered steps; step 3 is 해당 챕터 연결, pointing forward into 3부 |
| `ball-result` | `p2-c1-03` 1단계 | five ball results, each with the segments to check |
| `stage-check` | `p2-c1-04` 2단계 | eight swing stages with one question each, stacked to fit A5 |
| `quick-map` | `p2-c1-05` 빠른 진단 맵 | eight problems, each with 먼저 점검 and 3부에서 볼 챕터 |
| `hi-launch` | `p4-c3-02` course photo | the drawn plate above |

The figure wording is the author's own: the mappings are lifted from the 최종
로드맵 표 and the 자가 평가표 in `manuscript/p2-c1.md`, so no new golf claim
entered the book. The roadmap's old subtitle 다시 읽을 챕터 and its 복습 step were
wrong for this book and are gone, which is why the captions that used to correct
them are gone too. `verify.py` fails the build if a retired file reappears on disk
or in the text, or if a figure marker does not resolve.

The printed feel is simulated rather than photographed: a shape is drawn at 3x,
blurred into a soft edge field, then thresholded against layered value noise so
the ink bites unevenly, starves in a few specks, and thins across the sheet.
Seeds are fixed, so `make plates` reproduces the same plates every time. The
palette is locked to cream stock, pine ink green and charcoal.

The cover and the four part openers print on cream, which is what lets a plate sit
on the page without showing its own edge. Text pages stay white on purpose: the
author's diagrams are white-backed, and on cream they would show a panel of their
own. The appendix mark is drawn on transparency instead of on stock, so it sits on
a white text page.

Chapter interiors carry no decoration. A chapter gets a picture only where the
author put one.

### Photo inventory

- **챕터 7 release stills** live in `media/stills.yaml`. Drop the six originals
  into `images/incoming/` as `01`…`06` (any suffix) or under the dest names in
  `images/photos/`, then `make media && make book`. They flatten onto white,
  honour EXIF rotation, apply any `rotate_cw` in the yaml (the five gym stills
  are phone portraits whose EXIF was stripped), and cap at 1600 px. A portrait
  still is printed portrait — it is not stretched to full text width. The stock
  Golf+club/ball header (byte-identical 1024² / 1,023,209 bytes) is skipped;
  Logic Fitness arch mp4s are not imported. `https://logicfitko.substack.com/p/golf`
  is this same section of 챕터 7, not a new chapter. The matching public stills
  on `/p/a90` carry EXIF orientation 6 and confirm the gym shots stand upright.
- Author iPhone stills from the Korean Substack posts live in `media/stills.yaml`
  with their public S3 URLs. `make media` fetches them into `images/incoming/`
  and flattens them (EXIF first) into `images/photos/`. Galleries share one
  `[사진]` slot. Stock 1024² Golf+club headers, teal/archer diagrams and the
  hi-launch AI graphic stay out. Slots with no original stay labelled empty.
- The compiled manuscript inventory counts **64 photos**. The rest sit inside post
  bodies that are still paywalled, so they are not fetchable yet.

No photo of a real person is ever generated or substituted. A missing still stays
a labelled empty frame.

---

## Contents and sources

Structure lives in `book.yaml`. Text is Markdown in `manuscript/` and
`front-matter/`.

- 이 책을 읽는 법 — 세 저자, 왜 느낌을 몸으로 번역하는가
- **1부. 느낌은 있는데 스윙이 안 되는 이유**
- **2부. 내 스윙의 문제를 찾는 법**
- **3부. 스윙 시계 — 느낌이 지나가는 자리** (챕터 1–10; 릴리즈 타이밍은 발바닥에서
  달라진다 is a section inside 챕터 7 임팩트 — there is no release part)
- **4부. 샷에 실리는 느낌**
- **부록. 프로와 같은 말로 말하기**

`full` means the whole body is public and typeset. `teaser` means only the public
opening is available, and the chapter carries a 본문 준비 중 notice where the rest
belongs. **No chapter body has been written, paraphrased, or padded out.**

| Chapter | Part | Source | Text | Photos | Videos |
|---|---|---|---|---|---|
| 골프 트레이닝에 대한 생각 | 1부 | `womakers` | full | 0 | 0 |
| 골프를 배워도 잘 안 되는 이유 | 1부 | `05f` | full | 1 | 0 |
| 나의 스윙 문제를 찾는 어세스먼트 로드맵 | 2부 | `434` | full | 4 typeset figures | 0 |
| 챕터 1 · 어드레스 — 6시 | 3부 | `1-6` | full | 1 | 0 |
| 챕터 2 · 테이크어웨이 — 7시 | 3부 | `chapter-2-takeaway-7` | full | 1 | 0 |
| 챕터 3 · 백스윙 하프웨이 — 9시 | 3부 | `chapter-3-9` | full | 1 | 0 |
| 챕터 4 · 탑 오브 백스윙 — 12시 | 3부 | `chapter-4-12` | full | 1 | 0 |
| 챕터 5 · 다운스윙 전환 — 10시 | 3부 | `chapter-5-10` | full | 1 | 0 |
| 챕터 6 · 임팩트 직전 — 8시 | 3부 | `chapter-6-8` | full | 1 | 6 |
| 챕터 7 · 임팩트 — 다시 6시 | 3부 | `chapter-7-6` | full | 1 | 0 |
| ↳ 릴리즈 타이밍은 발바닥에서 달라진다 (section of 챕터 7) | 3부 | unpublished draft | full | 1 | 5 pending |
| 챕터 8 · 팔로우스루 — 3시 | 3부 | `chapter-8-3` | full | 1 | 0 |
| 챕터 9 · 두 번째 팔로우스루 — 1시 | 3부 | `chapter-9-1` | full | 1 | 0 |
| 챕터 10 · 피니시 | 3부 | `chapter-10` | full | 1 | 0 |
| 테크닉 챕터 1 · 드로우 샷 | 4부 | `1` | full | 1 | 0 |
| 테크닉 챕터 2 · 페이드 샷 | 4부 | `2` | full | 1 | 0 |
| 테크닉 챕터 3 · 하이 런치 샷 | 4부 | `3` | full | 1 drawn plate | 0 |
| 테크닉 챕터 4 · 스팅어 샷 | 4부 | `4` | full | 1 | 0 |
| 테크닉 챕터 5 · 스트레이트 샷 | 4부 | `5` | full | 1 | 0 |
| 부록 · 프로와 같은 말로 말하기 | 부록 | `golf-a` | full | 1 | 0 |

4 of 19 source posts are public; 15 return a short teaser. Front matter and the
part introductions are editorial copy written for this build and need author
sign-off.

---

## Rebuild

```bash
cd ebook
make          # plates, cover, media manifests, QR, EPUB, PDF, verification
make all      # the above, plus a refetch of the sources
```

Individual steps:

| Command | Does |
|---|---|
| `python3 scripts/fetch_sources.py` | cache the source posts into `sources/` |
| `python3 scripts/convert_sources.py` | cached HTML → `manuscript/*.md` (`--force` to overwrite) |
| `python3 scripts/build_media.py` | download and optimise photos, write both manifests |
| `python3 scripts/make_qr.py` | QR PNGs for slots that have a playable URL |
| `python3 scripts/make_posters.py` | EPUB first-frame posters with a play control |
| `python3 scripts/make_plates.py` | draw the cover art and the part-opener plates |
| `python3 scripts/make_cover.py` | compose `images/cover.jpg` for the EPUB |
| `python3 scripts/build.py` | assemble the EPUB and the A5 PDF |
| `python3 scripts/verify.py` | package, image, cover/plate, and no-Substack-link checks |

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
    cover.jpg            EPUB cover: the cover plate with the type drawn on
    plates/              drawn cover art and part openers, no lettering baked in
    photos/              the author's own photos and diagrams, never redrawn
    qr/                  54 QR PNGs, one per video slot
    posters/             54 EPUB tap posters (first frame + play control)
  media/
    photos.json          photo manifest with download status
    video-urls.yaml      input: chapter id -> ordered upload ids
    videos.yaml          generated manifest: URL, QR pairing, inline flag
  templates/             common.css, print.css, epub.css, pandoc body template
  scripts/
dist/
  golf-neukkimui-siljae-wonri.epub
  golf-neukkimui-siljae-wonri.pdf
```

### Placeholder markers

Three markers keep unfinished material explicit instead of invented:

| Marker | Renders as |
|---|---|
| `[[VIDEO-PUBLIC: chapter / index / description]]` | QR + URL when the slot has one, otherwise an empty QR box + 공개 영상 주소 예정 |
| `[[PHOTO-PENDING: chapter / index / note]]` | dashed 사진 자리 frame |
| `[[MANUSCRIPT-PENDING: slug]]` | 본문 준비 중 notice |

---

## Status

| Item | State |
|---|---|
| EPUB | builds, video posters + QR + plates + cover, tappable first-frame play buttons |
| PDF | builds, **166 pages**, A5, Korean fonts render, running heads, folios |
| Photos | 6 챕터 7 stills upright; other marked frames stay empty when the post is paywalled |
| Videos | **54 of 54** — EPUB: poster button → src; print: QR, no raw URL. All inline |
| Chapter text | **complete** — all 19 chapters + the 챕터 7 release section, no pending markers |
| Front matter | draft copy, needs author sign-off |

This build is educational material. It makes no swing-fix guarantee, and the
front matter says so.
