# Build 「골프 느낌의 실제 원리」.
#
#   make            fetch nothing, rebuild the book from what is in the repo
#   make all        full pipeline including a Substack refetch
#   make videos     regenerate QR codes after adding YouTube URLs to media/videos.yaml
#
# Requires: pandoc, python3 with weasyprint / pillow / qrcode / pyyaml /
# beautifulsoup4, and a Korean font (Nanum or Noto CJK KR).

PY := python3
S  := scripts

.PHONY: book all fetch convert media videos posters plates cover verify clean

book: plates cover media videos posters
	$(PY) $(S)/build.py
	$(PY) $(S)/verify.py

all: fetch convert book

fetch:
	$(PY) $(S)/fetch_sources.py

convert:
	$(PY) $(S)/convert_sources.py

media:
	$(PY) $(S)/build_media.py

# QR codes are written only for slots that already carry a playable URL.
videos:
	$(PY) $(S)/make_qr.py

# EPUB tap targets: first-frame poster + play control, linking the src URL.
posters: videos
	$(PY) $(S)/make_posters.py

# Cover art and part-opener plates. Drawn, not generated: no lettering is baked
# into them, so every word on those pages comes from book.yaml.
plates:
	$(PY) $(S)/make_plates.py

cover: plates
	$(PY) $(S)/make_cover.py

verify:
	$(PY) $(S)/verify.py

clean:
	rm -rf .build
