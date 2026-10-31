# Finish the TV shows (the Shorts Theater) — the agent brief (owner #89; spec §5.12, §14.12)

You are finishing EasyCraft's **TV shows**: the Shorts Theater a short walk from the spawn in every home world (Godot
4.7.2, typed GDScript; Android, the browser, later iPhone). The owner: "finish tv shows feature". Today the channel list
is a bundled sample with placeholder video ids (phones say "Coming soon"), the Android player is a WebView plugin
(`addons/easycraft_webview`, checked only with one public film on the emulator) and the browser has no player. Work
autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec §5.12 and §14.12 (the Theater: curated channels, YouTube's official
   embedded player, never an endless feed, made-for-kids), the Theater's code (`core/theater/*`, `entities/theater/*`,
   `ui/theater*` or where TheaterPanel lives, `data/theater/sample_channels.json`), the web page (`web/shell.html`,
   `core/platform/web_glue.gd`: the only place the game talks to the page's JavaScript), the server's storage and RPCs
   (`server/modules/`, `server/README.md`), and the world game plan (`docs/superpowers/plans/2026-09-29-world-game-plan.md`:
   the game is educational).

## What to build
- **Real channels of real, kind, educational videos**: EasyCraft TV first, then Space, Science, Nature and animals, How
  things are made, Music, Art, History; each video embeddable on YouTube and made for kids (or a space agency's public
  films), found and checked by you (the video's page: its title, its channel, embedding allowed), 6-12 a channel, the
  real 11-character ids. No personal channels of living children, no ads-heavy channels, nothing scary.
- **The list on the server**: the Nakama module keeps the channel list in storage (read by everyone, written only with
  the server's admin key: an RPC the owner can call with a JSON file, and a script in `tools/`), the game reads it at
  start and keeps the last one (the bundled list is the fallback); bump the module version from the one on your base.
- **A player in the browser**: the page shows YouTube's official embedded player over the game (an `<iframe>` with the
  privacy-enhanced domain `youtube-nocookie.com`, made-for-kids settings, controls, a big CLOSE), opened by the game
  through `WebGlue` (no text from the list reaches the page as code: ids checked by `TheaterChannels`), closed by CLOSE or
  walking out; the game holds its sound while a video plays.
- **Android**: the WebView plugin plays the same list (check its build steps in DEVELOPMENT.md; the lead checks on the
  emulator); iPhone comes on the Mac (M6): leave the same interface.
- The Theater's panel: channels as big picture tabs, videos as cards with their titles, NEXT and BACK, and "made for
  kids" only.

## Allocation and rules
- New or changed files: the Theater's code, `web/shell.html` (one player block), `core/platform/web_glue.gd` (two
  calls), the server module (storage + RPC + tests), `tools/theater_list.*`, tests `tests/**/test_theater*.gd`, notes
  `docs/devlog/parts/tv-shows.md`. Never touch the core loop's agents' files (earn/invite, missions, flight), the School
  units, the worlds.
- TDD; `--import` and grep Parse Error; single tests; server `npm --prefix server/modules test`; the FULL suite once at
  the end. Never open the editor or an emulator; never touch adb; never deploy. Never merge or push. Never run more
  agents. A `test_nakama_account_key.gd` failure can come from other agents sharing the local Nakama: rerun it alone.

## Finish
Notes (rulings, the channel list with each video's source page, the privacy settings, what the lead must deploy and
check on the emulator and live); spec §5.12 "As built"; `docs/DEVELOPMENT.md`; `server/README.md`. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, the module version,
what a child sees, the tests' results, what the lead must look at.
