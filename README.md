# EasyCraft

A 3D sandbox and survival game for children, with its own magic: living buddies, Size Magic, stamps and Mirror,
worlds and universes to visit, and learning built into play (a child never has to read to play or learn). Built with
[Godot 4.7](https://godotengine.org/) (typed GDScript) and [Voxel Tools](https://github.com/Zylann/godot_voxel), for
Android phones, the Meta Quest 3 and the web, with an online server on [Nakama](https://heroiclabs.com/nakama/).

**Play it in a browser:** https://giorgipirveli.github.io/easycraft/

**Download it** for an Android phone or tablet, or for a Meta Quest 3:
https://github.com/giorgipirveli/easycraft/releases/latest (the apps update themselves to the newest game at each start).

## Where things are

| What | Where |
|---|---|
| How to build, test and run it (the toolchain, the commands, the architecture, the known gotchas) | [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) |
| The design spec | [`docs/superpowers/specs/2026-09-23-realm-hoppers-design.md`](docs/superpowers/specs/2026-09-23-realm-hoppers-design.md) |
| Learning as play, and the deep learning games | [`docs/design/learning-is-play.md`](docs/design/learning-is-play.md), [`docs/design/future-lessons.md`](docs/design/future-lessons.md), [`docs/design/games/`](docs/design/games/) |
| The development log | [`docs/devlog/`](docs/devlog/) |
| The online server (Nakama modules and deployment) | [`server/`](server/) |
| Asset credits | [`assets/CREDITS.md`](assets/CREDITS.md) |

Tests: `tests/run_tests.sh` (GUT, headless).

## Rights

**Copyright © 2026 the EasyCraft authors. All rights reserved.** This source code is published so it can be read. No
license is granted to copy, modify, distribute or use it, in whole or in part, without written permission.

Third-party parts keep their own licenses, in their folders: Voxel Tools (`addons/zylann.voxel/LICENSE.md`), GUT
(`addons/gut/LICENSE.md`), the Nakama Godot client (`addons/com.heroiclabs.nakama/LICENSE`), the Godot OpenXR vendors
plugin (`addons/godotopenxrvendors/*/LICENSE*`), the godot-mcp editor plugin (`addons/godot_mcp/LICENSE`, MIT), and the
sounds and pictures listed in `assets/CREDITS.md` (CC0).
