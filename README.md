# bytepath-ex

BYTEPATH (a327ex, MIT) — LÖVE 11.5 port and improvement branch.

The upstream release was built against LÖVE 0.10.2 and no longer
boots on a modern `brew install --cask love` install. This fork
applies the minimum set of changes needed to make the game run
under LÖVE 11.5 (Mysterious Mysteries, 2024-era stable) on macOS,
without changing the gameplay.

## Run

```bash
brew install --cask love
xattr -dr com.apple.quarantine /Applications/love.app   # Gatekeeper bypass
cd bytepath-ex
love .
```

The game window opens at 1280x720, the 480x270 game frame is
letterboxed inside it. Type `start` on the console screen to begin.

## What changed vs upstream

Four commits on top of the a327ex master HEAD:

| Commit | Area | Reason |
| --- | --- | --- |
| `shaders:` | `resources/shaders/*.frag` | LÖVE 11.5 dropped the legacy GLSL front matter (`extern Image`, `Image` parameter type). Without the port the shaders fail to compile silently and the screen saturates to white. |
| `core:` | `main.lua`, `conf.lua`, `libraries/sound.lua` | API migrations: `setLooping` strict boolean, `isStopped` removed (use `isPlaying`), `love.run` default loop, `conf.lua` fsaa→msaa / vsync=1 / fullscreentype="desktop", Steamworks shimmed to `nil`. |
| `boipushy/Input:` | `libraries/boipushy/Input.lua` | LÖVE 11.5's `love.keyboard.isDown` raises "Invalid key constant" for gamepad virtual names (`dpup`, `l1`, ...). Add a keyboard-only whitelist before calling it. |
| `rooms:` | `rooms/Stage.lua`, `rooms/Console.lua` | All `setColor` calls normalized from 0..255 to 0..1, final canvas draw routed through `drawGameCanvas()` for letterboxing. |

## License

Original code © a327ex, MIT. Port changes in this fork are MIT as well.
