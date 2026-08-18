# Build 「골프 느낌의 실체」.
#
#   make            fetch nothing, rebuild the book from what is in the repo
#   make all        full pipeline including a Substack refetch
#   make videos     regenerate QR codes after adding YouTube URLs to media/videos.yaml
#
# Requires: pandoc, python3 with weasyprint / pillow / qrcode / pyyaml /
# beautifulsoup4, and a Korean font (Nanum or Noto CJK KR).

PY := python3
S  := scripts

.PHONY: book all fetch convert media videos cover verify clean

book: cover media videos
	$(PY) $(S)/build.py
	$(PY) $(S)/verify.py

all: fetch convert book

fetch:
	$(PY) $(S)/fetch_sources.py

convert:
	$(PY) $(S)/convert_sources.py

media:
	$(PY) $(S)/build_media.py

# QR codes are written only for slots that already carry a YouTube unlisted URL.
videos:
	$(PY) $(S)/make_qr.py

cover:
	$(PY) $(S)/make_cover.py

verify:
	$(PY) $(S)/verify.py

clean:
	rm -rf .build
