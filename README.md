# bytepath-ex

> a327ex의 [BYTEPATH](https://github.com/a327ex/BYTEPATH) (MIT) — LÖVE 11.5 포트 + 개선 브랜치

BYTEPATH는 빌드 이론을 깊게 파는 리플레이형 아케이드 슈터입니다. 거대한 스킬 트리, 다양한 클래스와 함선을 조합해 자신만의 빌드를 만들고, 점점 어려워지는 적의 물결을 헤쳐나가야 합니다. 본 저장소는 원작 게임플레이를 그대로 유지하면서 LÖVE 11.5에서 실행되도록 만든 포크입니다.

<p align="center">
<img src="docs/images/gameplay.gif" alt="BYTEPATH gameplay" width="720">
</p>

<p align="center">
<img src="docs/images/effects.gif" alt="BYTEPATH RGB shift / glitch effects" width="720">
</p>

* **[Steam (원작)](https://store.steampowered.com/app/760330/BYTEPATH/)**
* **[튜토리얼 (a327ex 블로그)](https://github.com/a327ex/blog/issues/30)**

---

## 실행 방법

### macOS (가장 간단)

```bash
brew install --cask love
xattr -dr com.apple.quarantine /Applications/love.app   # Gatekeeper 우회
cd bytepath-ex
love .
```

`love .` 만 입력하면 1280x720 윈도우가 열리고, 480x270 게임 화면이 letterbox로 매핑되어 표시됩니다. 콘솔 화면에 `start`를 입력하고 Enter를 누르면 시뮬레이션이 시작됩니다.

### macOS .app 번들 (실행 파일)

[Releases 페이지](https://github.com/sigco3111/bytepath-ex/releases)에서 `bytepath-ex-macos-X.Y.Z.zip`을 받아 압축을 풀고, `bytepath-ex.app`을 더블클릭하세요. brew로 love를 따로 설치할 필요가 없습니다. 게이트키퍼 경고가 뜨면 우클릭 → 열기로 실행하거나, 다음 명령으로 격리를 해제합니다:

```bash
xattr -dr com.apple.quarantine /Applications/bytepath-ex.app
```

### Windows / Linux

소스에서 직접 실행하려면 [LÖVE 11.5](https://love2d.org/)를 설치한 뒤 프로젝트 디렉터리에서:

* **Windows**: `love.exe .`
* **Linux**: `love .` (대부분 배포판 패키지로 제공)

---

## 원본과의 차이점 (v0.2.1)

원작은 LÖVE 0.10.2 시대를 기준으로 빌드됐기 때문에, brew/공식 설치본으로 받는 최신 LÖVE 11.5에서는 부팅조차 되지 않습니다. 본 포크는 게임플레이를 1도 건드리지 않고 11.5에서 실행되도록 하는 데 집중했습니다.

현재 안정 버전은 **v0.2.1**입니다. upstream HEAD `a327ex/BYTEPATH@51ee308`을 기반으로 LÖVE 11.5 호환, 화면 모드 설정, UI 및 뷰포트 수정이 적용되어 있습니다.

| 커밋 | 영역 | 이유 |
| --- | --- | --- |
| `shaders: port legacy LÖVE 0.10.2 GLSL to modern 3.00 ES` | `resources/shaders/*.frag` | LÖVE 11.5는 더 이상 legacy GLSL 프론트매터(`extern Image`, `Image` 파라미터 타입)를 인식하지 못합니다. 변환하지 않으면 셰이더가 silent하게 컴파일 실패하면서 화면이 흰색으로 saturate됩니다. |
| `core: migrate from LÖVE 0.10.2 to 11.5 API` | `main.lua`, `conf.lua`, `libraries/sound.lua` | `setLooping`이 strict boolean, `Source:isStopped()` 제거, 커스텀 `love.run`이 LÖVE 11.5의 `love.handlers` 변경과 충돌, `conf.lua`의 `fsaa` → `msaa` / `vsync = true` → `1` / `fullscreentype = "desktop"` 등. |
| `boipushy/Input: gate love.keyboard.isDown on known keyboard keys` | `libraries/boipushy/Input.lua` | LÖVE 11.5의 `love.keyboard.isDown`은 게임패드 가상 키(`dpup` 등)나 알 수 없는 키를 받으면 `Invalid key constant` 에러를 던집니다. 화이트리스트로 막았습니다. |
| `rooms: normalize colors to 0..1 and route through drawGameCanvas` | `rooms/Stage.lua`, `rooms/Console.lua` | 셰이더 파이프라인은 0..1 RGBA를 기대하지만 원본은 0..255 정수를 사용했습니다. 모든 `setColor`를 0..1로 정규화하고, 최종 캔버스 출력을 `drawGameCanvas()`로 letterbox 처리했습니다. |
| `options: v0.2.0 display mode window/fullscreen/desktop` | `rooms/Options.lua`, `main.lua` | `Options` 룸 신설, `display_mode` / `window_scale` / `display` 토글, `love.window.setMode()` 동적 처리, `love.resize` 자동 window_scale 감지. |
| `ui: v0.2.1 fix shader-free UI for Classes/Passive, rebuild main menu` | `rooms/Classes.lua`, `rooms/SkillTree.lua`, `objects/Node.lua`, `objects/Line.lua`, `rooms/Console.lua` | 4-pass 셰이더 파이프라인을 우회하여 셰이더 깨진 Class/Passive 룸을 복구, GUI 메뉴 재작성, 모듈 잔상 제거. |
| `options: scanlines on/off toggle` | `rooms/Options.lua`, `main.lua` | distort 셰이더의 `scanlines` uniform + glitch/rgb_shift/displace 셰이더 패스 모두 동시 off 토글. |
| `escape/esc to leave Options + paused overlay after shader passes` | `rooms/Options.lua`, `objects/Paused.lua`, `rooms/Stage.lua` | esc 키로 옵션 화면 종료, 일시정지 시 셰이더 패스 후 dim 오버레이 + RESUME/MENU 버튼. |
| `module ghosting cleanup on Console destroy` | `rooms/Console.lua` | 모듈 진입 후 복귀 시 잔상 라인 정리, 비활성 모듈 draw 가드. |

### 미해결 / 알려진 이슈

* 시각 효과(RGB shift, glitch, distort)는 modern GLSL로 재기반된 셰이더로 그려지며, 미세한 스캔라인 / fuzz 표현 차이는 원본 대비 있을 수 있습니다.
* Steam 클라우드 저장은 비활성화되어 있습니다 (macOS에서 Steam SDK 부재). `transient_save`, `permanent_save`는 로컬에만 저장됩니다.
* `Steam` 업적 해제는 stub 처리되어 있으므로 게임 진행에는 영향이 없습니다.

---

## 디렉터리 구조

```
.
├── main.lua              -- 부트스트랩, love 콜백, 방 전환
├── conf.lua              -- LÖVE 윈도우 / 모듈 설정
├── globals.lua           -- 색상 팔레트, 게임 상수
├── utils.lua             -- random(), 클래스 유틸
├── GameObject.lua        -- 게임 오브젝트 베이스
├── objects/              -- Player, Enemy, Bullet, Item, ...
├── rooms/                -- Console(첫 화면), Stage(전투), ScoreScreen, Paused, SkillTree, ...
├── libraries/            -- classic, hump, moses, mlib, bitser, HC, boipushy, ...
├── resources/            -- fonts/, graphics/, sounds/, shaders/
└── docs/images/          -- README에 사용된 스크린샷
```

---

## 빌드 방법 (macOS)

현재 저장소에는 자동 패키징 스크립트가 포함되어 있지 않습니다. 아래 명령으로 `.love`와 `.app` 번들을 수동 생성할 수 있습니다.

```bash
# 수동 빌드 예시
zip -qr /tmp/bytepath-ex.love . -x "*.DS_Store" -x ".git/*"
cp -R /Applications/love.app ./bytepath-ex.app
cp /tmp/bytepath-ex.love ./bytepath-ex.app/Contents/Resources/game.love
# Info.plist의 CFBundleName / CFBundleIdentifier 만 교체
ditto -c -k --sequesterRsrc --keepParent bytepath-ex.app bytepath-ex-macos-0.2.1.zip
```

---

## 라이선스

원작 코드는 a327ex, MIT 라이선스. 본 포크의 추가/변경 사항도 동일하게 MIT. 모든 자산(폰트, 사운드, 그래픽)은 각자의 라이선스를 따르며, 게임 내 크레딧에서 출처를 확인할 수 있습니다.
