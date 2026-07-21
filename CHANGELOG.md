# bytepath-ex

Upstream release `v0.0.0` (master @ a327ex/BYTEPATH `51ee308`).

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

### Known issues
- Visual effects (RGB shift, glitch, distort) are using the new
  modern GLSL ports; minor differences in scanline / fuzz look vs
  the 0.10.2 release are expected.
- Save data is local-only (no Steam cloud).
