# bytepath-ex

Upstream release `v0.0.0` (master @ a327ex/BYTEPATH `51ee308`).

## v0.2.0 — Display options (windowed / fullscreen / scale) — 2026-07-22

Window options UI: pick between windowed, fullscreen and borderless
desktop modes, drag the window edge to resize, or pick a monitor on
multi-display setups. Choices are persisted on every change so the
game comes up the same way next launch.

### Added
- `rooms/Options.lua`: new options screen, reachable from the
  console's `options` command. Up / down to pick a row, left / right
  (or on-screen buttons) to change, enter / click to go back.
- `main.lua`:
  - `applyDisplayMode()` — single entry point that interprets
    `(display_mode, window_scale, display)` and calls
    `love.window.setMode()` accordingly. Calls `save()` on every
    change so the choice is persisted immediately.
  - `love.resize()` — in windowed mode, the handler figures out the
    new `window_scale` from the live window size and saves.
  - `clampWindowScale()` and `display_mode_list` helpers.
- `globals.lua`: `display_mode` and `window_scale` defaults
  (windowed, 2x). The legacy `fullscreen` boolean is kept as a
  save-compatibility alias.

### Changed
- `objects/ConsoleInputLine.lua`: `options` is now a recognized
  command and is dispatched to `gotoRoom('Options')`.
- `rooms/Console.lua`: the main keyboard menu now has seven entries
  (added `options`). The intro text mentions the new command.
- First-run experience now boots into a windowed 960x540 window
  (was desktop fullscreen).

## v0.1.0 — LÖVE 11.5 port — 2026-07-22

First runnable build on LÖVE 11.5 (Mysterious Mysteries, brew cask).

### Added
- `main.lua`: `getLetterboxOffset()` and `drawGameCanvas()` helpers to
  project the 480x270 game frame onto the configured window.
- `libraries/boipushy/Input.lua`: `Input.keyboard_keys` whitelist
  gating `love.keyboard.isDown()`.

### Changed
- `resources/shaders/*.frag` (8 files): legacy LÖVE 0.10.2 GLSL
  rewritten as modern GLSL 3.00 ES (`extern` → `uniform`,
  `Image` → `sampler2D`).
- `conf.lua`: `fsaa` → `msaa`, `vsync` boolean → 1, `fullscreentype`
  "exclusive" → "desktop", `loveVersion` 0.10.2 → 11.5, dropped the
  removed `srgb` flag.
- `main.lua`: Steamworks require replaced with `Steam = nil` (no
  `libsteam_api.dylib` on macOS). Custom `love.run` disabled in
  favour of the LÖVE 11.5 default loop. `gotoRoom('Console')` is
  called immediately instead of via `timer:after(0.5, …)`.
- `libraries/sound.lua`: `setLooping(opts.loop == true)` to satisfy
  the strict 11.5 type check. `Source:isStopped()` is gone, fall back
  to `isPlaying()`.
- `rooms/Stage.lua`, `rooms/Console.lua`: every `setColor` call uses
  0..1 floats; the final `draw(canvas, 0, 0, 0, sx, sy)` goes through
  `drawGameCanvas(canvas)`.
- `README.md`: 한국어 기본, 원본 스크린샷 GIF 2개 (gameplay, RGB
  shift / glitch) `docs/images/`에 첨부.

### Known issues
- Visual effects (RGB shift, glitch, distort) are using the new
  modern GLSL ports; minor differences in scanline / fuzz look vs
  the 0.10.2 release are expected.
- Save data is local-only (no Steam cloud).
- `Steam` 업적 해제는 stub 처리되어 있으므로 게임 진행에는 영향이 없습니다.
