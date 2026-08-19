# Golf-swing

Publishing repo for the Korean golf ebook **「골프 느낌의 실제 원리」**
(프로가 말하는 감각을 실제 현상으로 풀다) by 이충원 Logan Lee · 방승호 Bryan Bang ·
박세인 Jason Park.

- Source, images, manifests and build scripts: [`ebook/`](ebook/README.md)
- Built files: `dist/golf-neukkimui-siljae-wonri.epub`, `dist/golf-neukkimui-siljae-wonri.pdf` (188pp A5)

To rebuild:

```bash
cd ebook && make
```

All 54 videos carry a QR code and a tappable first-frame poster (EPUB and PDF),
each verified reachable without a login, and are credited to the 골프느낌원리
channel (unlisted). See [`ebook/README.md`](ebook/README.md) for the inventory
and current status.
