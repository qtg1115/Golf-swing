# 스쿨 시뮬레이터

로블록스 스튜디오에서 바로 열고 이어서 작업할 수 있는 **학교 생활 시뮬레이터**입니다.

이 저장소의 `.luau` 파일은 로블록스 게임이 됩니다. 스튜디오로 불러온 뒤 Play를 누르면 캠퍼스, 시간표, 수업, 급식, 매점, 퀘스트가 동작합니다.

## 스튜디오로 불러오는 방법

가장 쉬운 방법은 **Rojo**입니다. 코드는 이 폴더에 두고, 로블록스 스튜디오는 그 코드를 실시간으로 받아 실행합니다.

### 1) 한 번만 준비

1. [로블록스 스튜디오](https://create.roblox.com/docs/studio/setup)를 설치합니다.
2. 스튜디오에서 **Toolbox → Plugins**로 이동해 **Rojo** 플러그인을 설치합니다.  
   또는 [Rojo 릴리즈](https://github.com/rojo-rbx/rojo/releases)에서 `Rojo.rbxm`을 받아 `Plugins` 폴더에 넣습니다.
3. 컴퓨터에 Rojo CLI를 설치합니다.

```bash
# Windows (PowerShell)
irm https://raw.githubusercontent.com/rojo-rbx/rojo/master/scripts/install.ps1 | iex
```

macOS / Linux는 [Rojo 설치 문서](https://rojo.space/docs/v7/getting-started/installation/)를 따릅니다.

### 2) 이 프로젝트를 스튜디오에 연결

터미널에서 이 저장소 폴더로 들어간 뒤:

```bash
rojo serve
```

그다음 로블록스 스튜디오에서

1. **File → New** 로 빈 플레이스를 만듭니다.
2. 플러그인 **Rojo → Connect** 를 누릅니다.
3. `localhost:34872` 에 연결합니다.

Explorer에 `ReplicatedStorage/Shared`, `ServerScriptService/Server`, `StarterPlayer/StarterPlayerScripts/Client`가 보이면 성공입니다.

4. **Play** 를 누르면 학교가 생성되고 게임이 시작됩니다.

이후에는 이 폴더의 코드를 수정하면 스튜디오에 바로 반영됩니다. 맵 모양, 수업 시간, 상점 가격, UI 문구를 여기서 바꾼 뒤 스튜디오에서 테스트하면 됩니다.

### 3) 파일로 바로 열기

저장소에 이미 `SchoolSimulator.rbxlx` 가 있습니다. 이 파일을 로블록스 스튜디오에서 **File → Open from File** 으로 열면 됩니다.

코드를 고친 뒤에는 다시 빌드하세요.

```bash
rojo build -o SchoolSimulator.rbxlx
```

## 게임에서 할 수 있는 것

- 시간표에 맞춰 교실에 앉아 **수업 듣기**
- 점심시간에 **급식실**에서 에너지 회복
- **운동장**에서 놀기, NPC와 인사하기
- **매점**에서 간식/교복/참고서 구매
- 오늘 할 일을 끝내고 보상 받기
- 성적, 인기, 코인, 레벨 성장

조작은 로블록스 기본 이동 + 각 오브젝트 앞의 **근접 버튼(E)** 입니다.

## 코드를 어디서 고치나

| 하고 싶은 일 | 파일 |
| --- | --- |
| 교시 길이, 과목, 상점, 퀘스트 | `src/shared/Config.luau` |
| 학교 건물/교실/운동장 배치 | `src/server/SchoolBuilder.luau` |
| 수업, 급식, 구매, 퀘스트 규칙 | `src/server/GameService.luau` |
| 시간표 진행 | `src/server/ScheduleService.luau` |
| NPC 이름과 이동 | `src/server/NPCService.luau` |
| 화면 UI | `src/client/Hud.luau` |

스튜디오에서 파트나 GUI를 직접 만들어도 됩니다. 다만 Rojo가 동기화하는 폴더(`Shared`, `Server`, `Client`) 안의 스크립트를 스튜디오에서 직접 고치면, 다음 동기화 때 이 저장소 코드로 덮어쓰일 수 있습니다. 스크립트는 이 폴더에서 수정하는 편이 안전합니다.

## 스튜디오에서 퍼블리시

1. 스튜디오에서 Play로 확인합니다.
2. **File → Publish to Roblox**
3. 새 게임을 만들거나 기존 게임에 덮어씁니다.
4. Game Settings에서 게임 이름, 아이콘, 권한을 정합니다.

데이터 저장(DataStore)을 쓰려면 Game Settings → Security에서 **Enable Studio Access to API Services** 를 켜세요. 꺼져 있어도 스튜디오 테스트는 되고, 재접속 시 진행 상황만 초기화됩니다.
