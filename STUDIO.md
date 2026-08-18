# 로블록스 스튜디오에서 이 파일 쓰는 법

이 저장소는 **우리학교 대모험** 게임입니다. 전학생이 불리를 피하거나 맞서며 레벨과 아이템으로 학교생활을 하는 스토리 게임이고, 스튜디오로 불러와 Play 하면 됩니다.

```
이 폴더의 코드  →  Rojo가 스튜디오로 전송  →  스튜디오에서 Play / 맵 수정 / 퍼블리시
```

Rojo는 두 개가 필요합니다.

- **플러그인**: 스튜디오 안에 설치하는 버튼
- **서버(CLI)**: 컴퓨터에서 `rojo serve` 를 실행하는 프로그램

지금은 플러그인만 설치하면 됩니다.

## Rojo 플러그인 설치 (가장 쉬운 방법)

1. [로블록스 스튜디오](https://create.roblox.com)를 켭니다. 로그인되어 있어야 합니다.
2. 브라우저에서 이 페이지를 엽니다.  
   https://create.roblox.com/store/asset/13916111004/Rojo
3. **Get Plugin** 또는 **Install** 을 누릅니다.
4. 스튜디오가 열려 있으면 설치 확인 창이 뜹니다. **설치**를 누릅니다.
5. 스튜디오 상단 탭에서 **PLUGINS**(플러그인) 을 엽니다.
6. **Rojo** 아이콘이 보이면 설치가 끝난 것입니다.

### 스튜디오 안에서 찾을 때

1. 스튜디오를 엽니다.
2. 왼쪽 또는 상단의 **Toolbox**(도구 상자)를 엽니다.
3. **Marketplace** / **Creator Store** 에서 검색창에 `Rojo` 를 입력합니다.
4. 만든 사람이 `LPGhatguy` 또는 Rojo 공식으로 보이는 플러그인을 선택합니다.
5. **Install** 을 누릅니다.
6. 상단 **PLUGINS** 탭에 Rojo가 생기면 성공입니다.

### 설치가 안 보일 때

- 스튜디오를 완전히 종료했다가 다시 켭니다.
- 상단 **PLUGINS** 탭이 없으면 빈 플레이스를 하나 연 뒤 다시 봅니다. 홈 화면에서는 탭이 숨겨질 수 있습니다.
- Toolbox 검색이 안 되면 위 Creator Store 링크로 설치하세요.

## 플러그인을 수동으로 넣는 방법

인터넷 스토어가 안 될 때만 쓰면 됩니다.

1. https://github.com/rojo-rbx/rojo/releases 에서 최신 버전의 `Rojo.rbxm` 을 받습니다.
2. 파일을 아래 폴더에 넣습니다.

- Windows: `%LOCALAPPDATA%\Roblox\Plugins`
- macOS: `~/Documents/Roblox/Plugins`

Windows에서 폴더 여는 방법:

1. `Win + R` 을 누릅니다.
2. `%LOCALAPPDATA%\Roblox\Plugins` 를 붙여넣고 Enter.
3. 받은 `Rojo.rbxm` 을 그 폴더에 복사합니다.
4. 스튜디오를 다시 켭니다.

## 설치 후 연결

플러그인만으로는 코드가 자동으로 들어오지 않습니다. 컴퓨터에서 Rojo 서버도 켜야 합니다.

1. 이 프로젝트 폴더에서 터미널을 엽니다.
2. `rojo serve` 를 실행합니다.
3. 스튜디오 **PLUGINS → Rojo** 를 누릅니다.
4. **Connect** 를 누릅니다. 주소는 보통 `localhost:34872` 입니다.

Explorer에 `ReplicatedStorage/Shared`, `ServerScriptService/Server` 가 보이면 연결된 것입니다. 그다음 **Play** 를 누르면 학교가 생성됩니다.

Rojo CLI가 아직 없다면 [설치 문서](https://rojo.space/docs/v7/getting-started/installation/)를 보거나, 우선 `SchoolSimulator.rbxlx` 를 **File → Open from File** 로 열어도 게임을 바로 테스트할 수 있습니다.

## 스튜디오에서 HTTP 403 이 뜰 때

`We could not open the place [...]. HTTP 403` 은 클라우드에 있는 게임을 열 권한이 없다는 뜻입니다. 이 저장소 코드가 깨진 것이 아닙니다.

1. **Close** 를 누릅니다. Retry 를 여러 번 누르지 마세요.
2. 홈 화면의 **School simulator** 최근 항목은 다시 누르지 마세요. 그 카드는 로블록스 클라우드 플레이스이고, 지금 권한이 막혀 있습니다.
3. 대신 이렇게 엽니다.
   - 위쪽 메뉴 **File → New** 로 빈 플레이스를 만들거나
   - **File → Open from File** 로 이 저장소의 `SchoolSimulator.rbxlx` 를 엽니다.
4. 클라우드 게임을 꼭 열어야 하면 스튜디오에서 로그아웃한 뒤 같은 계정으로 다시 로그인합니다.
5. VPN을 켜 두었다면 끄고 다시 시도합니다.

빈 플레이스나 `.rbxlx` 가 열리면 **PLUGINS** 탭에서 Rojo를 설치하고 연결하면 됩니다.

## 주의

- 스크립트는 가급적 이 저장소의 `src/` 에서 수정하세요.
- 스튜디오에서 건물, 파트, 이펙트를 추가하는 것은 괜찮습니다.
- 게임을 다른 사람에게 보여주려면 스튜디오에서 **Publish to Roblox** 하면 됩니다.
