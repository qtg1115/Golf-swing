# ⛳ Golf Swing Game (Roblox)

로블록스용 **미니 골프 게임**입니다. 파워 게이지를 모아 공을 쳐서 홀에 넣으면 점수가 올라갑니다.
코스, 공, 점수판, UI까지 **전부 코드(Luau)로** 만들어져 있어서, 별도의 모델 파일 없이
[Rojo](https://rojo.space)로 Roblox Studio에 동기화하기만 하면 바로 플레이할 수 있습니다.

> ℹ️ **중요:** Roblox Studio는 **Windows / macOS 전용**입니다. 이 프로젝트의 코드는
> 어디서나 편집·검증할 수 있지만, 실제로 게임을 실행(플레이 테스트)하려면
> 본인 PC에 Roblox Studio가 설치되어 있어야 합니다.

---

## 🎮 게임 방법

1. 마우스로 화면을 돌려(카메라) 공을 보낼 방향을 조준합니다.
2. **마우스 왼쪽 버튼**(모바일은 **화면 터치**)을 **길게 눌러** 파워를 모읍니다. 하단 게이지가 초록 → 빨강으로 차오릅니다.
3. 버튼을 **떼면** 공이 조준한 방향으로 날아갑니다.
4. 공을 홀(깃발)에 넣으면 `Holes` 점수가 +1, 그때까지의 `Strokes`(타수)는 화면에 표시된 뒤 0으로 초기화됩니다.
5. 공이 코스 밖으로 떨어지면 자동으로 티(출발점)로 돌아옵니다.

점수(`Holes`, `Strokes`)는 우측 상단 리더보드(leaderstats)에 표시됩니다.

---

## 📁 프로젝트 구조

```
roblox/golf-game/
├── default.project.json     # Rojo 프로젝트 정의 (폴더 ↔ 로블록스 서비스 매핑)
├── rokit.toml               # 툴 버전 고정 (rojo/stylua/selene)
├── stylua.toml              # 코드 포매터 설정
├── selene.toml              # 린터 설정 (Roblox 표준 라이브러리)
└── src/
    ├── shared/              # → ReplicatedStorage/GolfShared (서버·클라 공용)
    │   └── Config.luau      #    코스/공/스윙 설정값
    ├── server/              # → ServerScriptService/GolfServer
    │   ├── Main.server.luau #    코스 생성, 공 관리, 스윙 처리, 홀인 판정
    │   └── CourseBuilder.luau#    코스(잔디/벽/홀/깃발) 생성 모듈
    └── client/              # → StarterPlayer/StarterPlayerScripts/GolfClient
        └── Main.client.luau #    파워 게이지 UI, 조준, 입력 처리
```

- 파일 이름 규칙: `*.server.luau` → **Script(서버)**, `*.client.luau` → **LocalScript(클라)**, `*.luau` → **ModuleScript**.
- `ReplicatedStorage/Remotes` 아래의 `HitBall`, `Notify` **RemoteEvent**는 `default.project.json`에서 자동 생성됩니다.

---

## 🚀 Roblox Studio에서 열기

### 방법 A. 빌드된 플레이스 파일 바로 열기 (가장 빠름)

이 저장소의 코드를 받은 뒤 아래 한 줄로 `.rbxlx` 플레이스 파일을 만들 수 있습니다.

```bash
cd roblox/golf-game
rojo build default.project.json --output GolfSwingGame.rbxlx
```

생성된 `GolfSwingGame.rbxlx`를 **Roblox Studio에서 File → Open**으로 열고 ▶(Play)를 누르면 바로 플레이됩니다.
(Rojo 설치는 아래 "툴 설치" 참고)

### 방법 B. Rojo 실시간 동기화 (추천 · 코드 수정하며 개발)

1. Roblox Studio에 **Rojo 플러그인**을 설치합니다.
   - Studio 상단 **Plugins → Manage Plugins → 검색 "Rojo"** 로 설치하거나,
   - 터미널에서 `rojo plugin install` 실행.
2. 터미널에서 서버를 실행합니다.
   ```bash
   cd roblox/golf-game
   rojo serve
   ```
3. Studio에서 빈 Baseplate를 새로 만든 뒤, **Rojo 플러그인 → Connect** 를 누릅니다.
4. 이제 `src/` 의 파일을 수정하면 Studio에 **자동으로 반영**됩니다. ▶(Play)로 테스트하세요.

---

## 🧰 툴 설치

버전은 `rokit.toml`에 고정되어 있습니다. [Rokit](https://github.com/rojo-rbx/rokit)을 쓰면 한 번에 설치됩니다.

```bash
# Rokit 설치 후 (https://github.com/rojo-rbx/rokit 참고)
cd roblox/golf-game
rokit install
```

개별 설치를 원하면:

- **Rojo** — https://rojo.space/docs/v7/getting-started/installation/
- **StyLua**(포매터) — https://github.com/JohnnyMorganz/StyLua
- **selene**(린터) — https://github.com/Kampfkarren/selene

---

## ✅ 코드 검증 (Studio 없이 가능)

이 환경(Linux)에서도 아래 검사는 모두 실행할 수 있습니다.

```bash
cd roblox/golf-game
stylua --check src/     # 포맷/문법 검사
selene src/             # 정적 분석(린트, Roblox 표준 라이브러리 기준)
rojo build default.project.json --output GolfSwingGame.rbxlx   # 플레이스 빌드
```

---

## ⚙️ 밸런스 조정하기

게임 난이도/느낌은 대부분 `src/shared/Config.luau` 한 곳에서 바꿀 수 있습니다.

- `Swing.MaxPower` / `Swing.ChargeTime` — 공이 날아가는 최대 세기와 파워 차징 속도
- `Swing.LaunchAngle` — 공을 띄우는 각도
- `Hole.Radius` / `Hole.CaptureSpeed` — 홀 판정 반경과 홀인 허용 속도
- `Hole.Position` / `TeeGround` — 홀과 티의 위치(코스 길이)

값을 바꾸고 다시 `rojo serve` 또는 `rojo build` 하면 반영됩니다.
