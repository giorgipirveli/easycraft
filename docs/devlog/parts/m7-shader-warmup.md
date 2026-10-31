# M7: the shader warm-up (the browser's freezes are shader compiles)

The owner (2026-09-28): "from time to time when playing it freezes" (the browser version on phones). The lead measured
it on the emulator's Chrome: a fresh page's first world load froze for 5.4 s, 5.3 s and 11.5 s (at the spawn), 1.3 s
later; the same world loaded again in the same session had no frame over 60 ms. The page's JS CPU profile of that first
load (38 s): `getProgramParameter` 18.7 s (49 %: WebGL waiting for shader programs to link), `getParameter` 6.4 s
(17 %), `getShaderParameter` 1.4 s; the game's wasm a few %. The realistic pictures landing (a style switch) froze
949 ms. The lead's quiet baseline (07:55, the live build with the game-logic fixes, a fresh page, BLOCKY, Sandbox
CONTINUE): 5.4 s, 5.1 s, 10.8 s at the spawn, 1.2 s at +24 s; the same as before those fixes. A worker agent (branch `worktree-agent-a893dedb18ab1c1dd`, from `lead-merge` 5f49f37, `545f674` merged in)
measured what compiles where in headless Chrome and built a warm-up behind the HTML loading page. No editor, emulator
or adb: the lead checks on the emulator.

## The tool: `tools/web_shader_probe.py`

It serves a web export itself (a free port, the COOP/COEP headers), opens it in headless Chrome (its own profile and
DevTools port) and injects, before the page's scripts (`Page.addScriptToEvaluateOnNewDocument`), wrappers around
WebGL2's `shaderSource`, `attachShader`, `compileShader`, `getShaderParameter`, `linkProgram`, `getProgramParameter`,
`getParameter` and `requestAnimationFrame`: every link is recorded with its phase, its wait (the link call plus the
`LINK_STATUS` query, where the page blocks), and a signature (the kind of Godot shader, the `#define` lines of its
vertex and fragment source, the material's uniform block); every frame's duration and the shader time inside it. The
game plays the phases itself: the page adds `window.__probeArgs` to the engine's args (the served `index.html` is
patched), so the game gets `-- --shader-probe=<phases>` and `scenes/main.gd` adds `tools/shader_probe_steps.gd`, which
prints `PROBE phase=<name>` at each start; the page's phase is `boot` until `MENU ready`, then `menu`. Usage and
options: DEVELOPMENT.md §7 "Shader compiles in a browser". Headless Chrome draws with SwiftShader (software GL): a link
takes 5-15 ms there against 100-500 ms on a phone, so **the count of programs per phase is the measure**, and their
share of the long frames.

## What compiles where (before)

Headless Chrome 1280x720, desktop graphics (medium), one export measured with `--no-warmup` (the game's
`--no-shader-warmup`: the same build without the warm-up). Programs linked per phase:

| phase | programs | long frames (>100 ms) | their time | shader share |
|---|---:|---:|---:|---:|
| boot (to `MENU ready`) | 20 | 0 | 0 | |
| menu (12 s) | 33 | 3 | 742 ms | 46 % |
| new world (Sandbox, seed 20260923, to the spawn + 10 s) | **71** | 5 | 9765 ms | 14 % (7.5 s is the scene switch) |
| play (walk, jump, place/break, 12 animals, water and under it, night with lanterns, a cave) | 24 | 3 | 608 ms | 54 % |
| creatures (every animal, monster and boss, bot friends, at night) | 9 | 2 | 561 ms | 22 % |
| the Moon (fly up, land) | 11 | 2 | 647 ms | 18 % |
| REALISTIC (the switch in SETTINGS) | 25 | 3 | 906 ms | 52 % |
| end (BLOCKY again, SAVE AND QUIT) | 13 | 2 | 351 ms | 30 % |
| CONTINUE (a reload: boot 20, menu 33, then) | **79** | 6 | 9285 ms | 7 % |
| a REALISTIC child: its pictures landing mid-play | **27** | 4 | 1123 ms | 51 % |

153 programs after the menu in one session, 79 again on every CONTINUE. Why so many (the engine's GLES3 code,
`drivers/gles3/shader_gles3.h`, 4.7.2):
- **Every new material shader compiles 4 programs at once** the first time anything with it is bound
  (`_initialize_version`: colour, colour instanced, depth, depth instanced, all at the default specialization), none of
  which a real draw uses; then **one program per specialization** actually drawn: the pass (colour, depth prepass,
  shadow), and the lights and environment (`DISABLE_LIGHT_OMNI` unless a lantern lights it, `USE_DEPTH_FOG`,
  `USE_RADIANCE_MAP`, `APPLY_TONEMAPPING` unless glow or a 3D scale below 1 moves tonemapping to a later pass, the sun's
  shadows), instanced or not. In the new world's 71, 48 were those unused defaults.
- **A StandardMaterial3D's shader is freed when no material with its settings is left**, so after a REALISTIC visit
  every BLOCKY block shader compiled again ("end": 13; the lead's 949 ms at the landing is the other direction).
- The materials themselves are few: the census below found 34 ways the game draws besides the blocks (most of the 52
  scripts that make materials share a handful of settings), and the blocks 4 shaders a style for 18 pages.
- **`getParameter`** (the lead's 17 %): the probe sees one `getParameter(SCISSOR_TEST)` and one
  `getParameter(DRAW_FRAMEBUFFER_BINDING)` per frame (3485 each in the first visit above); the first took 10.8 s in all
  (~3 ms a frame) in SwiftShader, the second 13 ms. It is a synchronous round trip to Chrome's GPU process, i.e. where the main thread
  waits for the GPU to finish the previous frame: GPU-bound frame time, not shaders. Not changed here (it is in the
  engine's web frame code); a phone GPU that is busy drawing shows up there.

## The design

- **Where:** the menu. `Menu._ready` ends with `_warm_then_announce()`: where `ShaderWarmup.wanted` (the OpenGL
  renderer: every browser, and an Android phone or desktop that fell back to OpenGL; `PlatformRules.warms_shaders`),
  once a run, `ShaderWarmup.start(menu, backdrop world)`, and `MENU ready` is printed when it finishes. The page's
  loading screen stays until that line (its CSS animation runs on the compositor; the tips and the bar's timers run
  between frames).
- **How it draws, where nobody sees it:** a SubViewport with a world of its own (128x128, always updating) holds a camera,
  a copy of the backdrop's environment (fog, sky, ambient light) and of its sun (with its shadows), an omni light, and
  the game view's 3D scale, MSAA and screen AA (the 3D scale decides whether tonemapping is in the scene shaders: below
  1, LOW on phones, it is in a later pass). Each draw is shown twice for one frame: by the omni light (lanterns, the
  cave lantern, torches: another specialization for every material) and out of its reach; two draws a frame (a browser
  waits for every new program in that frame: short frames keep the page's timers going and Chrome's "page unresponsive"
  away). Behind the loading page the game view draws no 3D meanwhile (`quiet_main_view`): SwiftShader spent most of a
  warm-up frame on the menu's backdrop; a phone would too.
- **What:** `BlockLibrary.warmup_materials(style)`: every page's opaque, cut-out and glow materials and the water, as
  keeper twins set up in that style (the pixel page stands in before the realistic pictures are in: the same shader);
  kept, so both styles stay compiled whichever the blocks show. Then **the census**, `data/shader_warmup.json`: every
  way the game draws (a material by what makes its shader: `ShaderWarmup.describe` = the class, the bool/int settings
  that differ from a new one, a ShaderMaterial's shader file; instanced or not; casting a shadow or not; skinned, with
  the scene of the character; a Label3D's and Sprite3D's settings), written by playing a session on the desktop with the
  browser's renderer settings (`--rendering-method gl_compatibility`: the same `albedo_texture_force_srgb`) and walking
  the whole tree every second (hidden nodes too: the break ring, the highlights; not SubViewports with their own world).
  34 draws, each with the styles and phases it was seen in and where (`at`). One draw per shader in the warm-up.
- **Styles:** BLOCKY always; REALISTIC too when it is the child's saved style (its pass turns on glow and the panorama
  sky in the little world, and draws everything again: glow changes every material's variant). A child who picks
  REALISTIC later gets it warmed at that tap (`ShaderWarmup.watch_style`, on `Game.settings_applied`), in the look of the
  world on screen, not when its pictures land in the middle of play.
- **New content comes along:** a new block page by itself (`BlockLibrary.warmup_materials` walks the registered pages;
  test); anything else through the census: `test_shader_warmup_sources.gd` fails for a script that makes a material, a
  3D label or sprite, particles or a shader and is not listed (with how it is warmed), and checks that the game's own
  material makers (Fx, the break ring, the portal swirl, the game ring, the blaster's mark, the golem's glow, the avatar
  parts, the animals) are in the census. Re-run the census after adding content (DEVELOPMENT.md §7).

## After

The same export, measured with the warm-up (programs per phase; before in brackets):

| phase | programs | long frames | their time | shader share |
|---|---:|---:|---:|---:|
| boot (to `MENU ready`, the warm-up in it) | 212 (20) | 16 | 5235 ms | 69 % |
| menu | 2 (33) | 0 | 0 | |
| new world | **0** (71) | 3 | 7976 ms | 0 % (the scene switch, 7.6 s) |
| play | 1 (24) | 1 | 158 ms | 0 % |
| creatures | 0 (9) | 1 | 345 ms | 0 % |
| the Moon | 0 (11) | 2 | 430 ms | 0 % |
| REALISTIC (picked in SETTINGS: warmed at that tap) | 45 (25) | 4 | 1576 ms | 61 % |
| end | 0 (13) | 0 | 0 | |
| CONTINUE after a reload | **1** (79) | 4 | 8324 ms | 0 % (the scene switch, 7.8 s) |
| a REALISTIC child: its pictures landing mid-play | **0** (27) | 2 | 255 ms | 0 % |

The 2 in the menu and the 1 in play were the particles' material drawn instanced (the title's sparkle, the sprinkles and
butterflies): the warm-up's one-frame MultiMesh was culled (its box is only worked out as it is drawn); fixed with a
custom box, see "Checked after the fix" below. The REALISTIC tap compiles more than the switch did before (45 against
25: everything in its glow, not only what was on screen), then nothing later.

**Time to `MENU ready`** (from PLAY on the page to the line; headless Chrome): first visit 5.5 s before, 15.6 s after;
a reload 4.4 s before, 13.4 s after; a REALISTIC child 5.6 s before, 18.5 s after (both styles: 257 programs). The
warm-up compiles in one go what the first world load, the first minutes of play and the rarer sights compiled one by
one (212 programs before the menu against 53; 153 after it went to 3). On a phone the link time dominates: at the
emulator's ~200 ms a program the page would show its loading screen about 30 s longer on a first visit, and the first
world load would lose its 5-12 s freezes; the lead measures it there. Chrome keeps compiled programs in its GPU cache
across visits, so a returning visit's warm-up should be shorter than the first.

## Checked after the fix (instanced draws)

The next export (`9007e33`, the full suite running on the PC meanwhile), phases new, play, creatures and a reload with
CONTINUE: boot 215 programs, **menu 0, new world 0, play 0, creatures 0, end 0; CONTINUE 0**. No long frame after the
menu had any shader time in it (new world: 3 long frames, all the scene switch; play 3, 387 ms; creatures 2, 452 ms).
`MENU ready` 16.0 s after PLAY (12.6 s on the reload) under that load.

## Tests

`tests/unit/test_platform_rules.gd` (`warms_shaders`), `tests/unit/test_shader_warmup.gd` (describe/build/key, every
block page in both styles and later pages, keepers, the census walk, `wanted`, the styles), `test_shader_warmup_sources.gd`
(the census parses and builds, holds the game's own material makers, every material-making script is listed),
`tests/integration/test_shader_warmup_stage.gd` (the little world lit like the game, one draw per shader lit and unlit,
instanced/labels/sprites/skinned, the REALISTIC pass in its own world only, it finishes, frees its world, keeps the
materials, gives up after its time, gives the game view's 3D back), `test_shader_warmup_menu.gd` (a browser's menu
announces after the warm-up, the app and desktop at once, once a run, both styles for a REALISTIC child, REALISTIC at
the tap). Full suite: 6397 passed, none failed.

## Rulings

(Rulings 2 and 3 are replaced by the rework's, below.)

1. **The OpenGL renderer only** (every browser; an Android phone or desktop without Vulkan). The Android app and the
   desktop use Vulkan (the Mobile renderer), which compiles its pipelines when a material is loaded, in the background:
   nothing changes there (the menu announces at once; `test_the_android_app_and_the_desktop_announce_at_once`). Cost if
   wrong: an old phone on the OpenGL fallback shows the menu a few seconds after it appears (its warm-up runs under the
   visible menu; nothing of it shows, the menu's own frames are slow meanwhile).
2. **Everything before the menu, not only the first world.** The rare sights (monsters, bosses, the Moon, the other
   universes' effects) are few shaders (the census: 34 draws in all) and are exactly the "from time to time" freezes.
   Cost if wrong: the loading page stays longer than needed on a first visit (the numbers above); trimming is one filter
   on the census's `phases`.
3. **REALISTIC only for a REALISTIC child at boot; at the tap for one who picks it later.** It doubles the warm-up (every
   material again under glow). Cost if wrong: a child who switches in SETTINGS waits there for as long as the switch
   used to freeze plus the rest of REALISTIC's shaders (1.6 s here, some seconds on a phone), once a run.
4. **The census is data, made by playing** (`data/shader_warmup.json`, like the atlases our tools make), not a
   hand-written list: the game's materials are made in 52 scripts with many small differences. Cost if wrong: content
   added without re-running the census compiles on its first sight as before (the sources test catches a new script,
   not a new setting in an old one).
5. **A lantern for every draw** (one more specialization each). The game has lanterns at night, the cave lantern on
   the player, buddies' and pets' lights: anything can be lit. Cost if wrong: about one program per draw more than
   needed.
6. **Kept materials** (`ShaderWarmup.kept()`, the block twins): about a hundred small resources for the whole run, so
   their shaders are never freed and compiled again.

## Left open

- **Fewer shaders would cut the cost itself:** Godot compiles 4 unused programs for every new material shader (48 of
  the new world's 71). The census shows 34 ways of drawing, many of them near-duplicates (a plain colour material with
  and without `metallic_specular`, unshaded vertex colours with and without sRGB, labels with different settings);
  consolidating them in the game's material makers would shorten the warm-up by roughly 5 programs per shader removed.
- What the census does not play compiles on first sight: a friend's ghost race and bottles, a showcase visit, the
  photo filters (2D), Build Rewind's and the avatar editor's own little worlds (other lights and sky). Canvas
  (2D) shader materials are not warmed (the HUD's lines are).
- The per-frame `getParameter(SCISSOR_TEST)` GPU sync is the engine's; not touched.
- The lead: time to `MENU ready` and the first world load on the emulator's Chrome, before (`--no-shader-warmup` is a
  developer arg of the same build) and after.

# The rework: shown, spread, ordered (2026-09-28, second agent)

The lead on the emulator's Chrome (quiet PC): the warm-up held the loading page 44 s ("WARMUP blocky: 72 draws in
43631 ms", `MENU ready` 51 s after PLAY, the same after a reload: no program cache in the emulator's GPU path); the
first world load afterwards had long frames of 4.0 s (the scene switch), 0.3 and 0.2 s, and stood after 2.2 s. Off
(`b1cdf43`) until it shows its progress and spreads its work. This agent: branch `worktree-agent-ada1c6430da943609`
(from `lead-merge` `9187c8b`), headless Chrome only (no editor, emulator or adb).

## What the measurements showed

- **Programs per draw, at ~0.22 s each on the emulator** (43.6 s for the old warm-up's ~195): a draw-by-draw log
  (`--shader-warmup-log`, then one draw a frame; each program to the draw whose frame linked it) gives 5-7 programs for
  a draw with a new shader (Godot's 4 unused defaults and its pass), 1 for one that shares a shader (another shadow or
  instancing setting, a lantern). About 1.1-1.5 s a new shader on a phone, and it cannot be split: the 4 defaults
  come with its first bind.
- **The spawn's 10.8 s freeze was mostly the Sandbox's own prewarms.** Of a new world's 71 programs (no warm-up), 41
  were the tiny draws in front of the camera at `player.spawned` (the game ring and star, the portal swirl, the desert
  window, the blasters' bubble and mark, the break ring and pop, the thought bubble, Fx): made for Vulkan (~100 ms
  each), on WebGL all of them in the spawn's frames. What the world itself put on screen was 30.
- **The census's `phases` said where a draw was in the tree, not where it was drawn** (hidden nodes count: the mirror
  wall, the night sky, the game ring are in every first world and drawn much later). It now records `shown` too.
- Without a warm-up the menu compiles 33 programs in its first seconds (it stutters ~7 s on a phone after `MENU ready`).

## The design

- **Before `MENU ready`, only what the menu shows** (`ShaderWarmup.tier` FIRST: the census saw it on screen in the
  `menu` phase): the 4 block shaders (water, opaque, cut-out, glow) and the title diorama, plus the little world's own
  (its sky, the copy shaders). 59 programs before the menu against 20 without a warm-up (215 with the old one). The
  page shows it: `WebGlue.warmup_progress` → `window.easycraftWarmup(fraction)` → "Getting your world ready… N %" and
  the bar (the engine's start is its first 10 %); the bar's stripes now move by a transform, on the compositor, so they
  keep moving through a long frame, like the drifting blocks, the splash's bob and the sparkles. The game's view draws
  no 3D from `start()` on (the menu's first frame used to compile its backdrop's shaders in one go, with no progress).
- **Right after it, what a first world shows** (WORLD: shown within 48 m of the camera in `new`; the player's own
  feedback on blocks: the target highlight, the break ring, the place pop; the blocks by a lantern: a returning child's
  world has lanterns and torches). It draws on the idle menu and behind the loading card, and **the loading card waits
  for it** (`LoadingCard.HOLD_GROUP`, at most `HOLD_MAX` 30 s) with the game's view drawing no 3D under it (the card
  covers the screen), so nothing a first world shows is compiled in the world. The log line
  `WARMUP world blocky: <draws> draws in <ms> ms` says when it is done.
- **Then SOON** (shown in `play`, or in the first world hidden until used: the night sky, thought bubbles, secrets, the
  blasters, the game ring), **the lanterns on the rest, LATER** (monsters and bosses, the Moon, portals, other
  universes' effects, bot badges).
- **Where and how fast after the menu** (`later_may_run`): on the main menu when nobody touched anything for 1.5 s, or
  behind a loading card; never in play. Each frame draws as many as fit a 150 ms budget at the last draws' cost
  (`next_count`, timed to `RenderingServer.frame_post_draw`: at least one, at most twice the last, at most 8; a phone
  draws one a frame), then as long again without drawing (`rest_after`, at most 2 s), except while a loading card only
  waits for it (the child already stands in the world: every frame).
- **The prewarms go through `ShaderWarmup.at_spawn`**, skipped where a warm-up ran this run (`covers_prewarms`): their
  shaders are in the census (the census draws them once in a `prewarm` phase, so the desert window, which only a
  prewarm draws in a census session, stays in it).
- **Styles:** a REALISTIC child's first part and world part are REALISTIC (what the census's `realistic` phase showed
  counts as its first world), BLOCKY follows in the rest (a device whose realistic pictures are still on their way).
  REALISTIC picked later joins the running warm-up's rest right after the world part (`add_style`), or starts a warm-up
  with no first part (`first_part = false`).
- **On in every browser again** (`PlatformRules.shader_warmup = true`; the lead's ruling test became
  `test_the_shader_warm_up_is_on_in_every_browser_since_its_rework`).

## Measured (headless Chrome, SwiftShader, 1280x720, desktop graphics)

Programs linked per phase; *sight* = compiled by the game's own first sight (what the child meets), *warm* = in the
warm-up's own frames (the probe now tells them apart: the game prints its draws, `tools/web_shader_probe.py` always
passes `--shader-warmup-log`). One export (`325f4fa`, the census of this session), the same build each time: before =
`--no-warmup`; the rework = `--warmup` (the rule was still off in that export; on since `1463ec7`, same logic).

| phase | before (no warm-up) | old warm-up (all before the menu) | rework, 12 s on the menu | rework, a tap after 2 s |
|---|---:|---:|---:|---:|
| before `MENU ready` | 20 | 215 | 59 (31 warm) | 59 (31 warm) |
| PLAY → `MENU ready` (headless) | 6.1 s | 15.6 s (19.8 one draw a frame) | 9.5 s | 10.2 s |
| menu: sight / warm | 33 / 0 | 0 / 0 | 0 / 66 | 0 / 12 |
| new world: sight / warm | 71 / 0 | 0 / 0 | **0** / 90 | **0** / 141 |
| play (walk, build, animals, water, night, lanterns, a cave) | 12 | 0 | 0 | 0 |
| creatures (every animal, monster, boss, bots, at night) | 19 | 0 | 0 | 2 |
| the Moon | 23 | 0 | 0 | 0 (1 warm, its loading card) |
| a reload: before `MENU ready` / menu / CONTINUE (sight) | 20 / 33 / **81** | 215 / 0 / 0 | 59 / 0 / **0** | 59 / 0 / **0** |

The worst frames in SwiftShader: the menu's own frames ≤ 29 ms and a warm-up frame on the menu ≤ 423 ms (a phone: one
draw, ~1.1-1.5 s); play ≤ 160 ms with no shader in it; the scene switch 7-9 s headless (4.0 s on the emulator, not
shaders). The page, 12 s run: "Starting the game… 10 %" at PLAY, "Getting your world ready… 14 %" at 7.5 s, 29, 43,
57, 71, 100 % by 9.3 s, `MENU ready` at 9.5 s. The whole warm-up ended 38 s after its start with 12 s on the menu
and the world loads' cards (14.7 s of it frames that drew); with a tap after 2 s it ended at the next menu (the rest
waits in play). (The log line's "worst after the menu" counts a scene switch that shares a frame with a draw: 8.2 s
there; the probe's per-frame numbers above are the ones to read.)

A REALISTIC child, a tap after 2 s (the export before `1463ec7`): `MENU ready` 11.8 s (72 before it); new world 1
first sight, play 2; its realistic look once the pictures landed (the probe's `realistic` phase: a dog, Pip, a bot) 13:
its realistic avatar and a bot's realistic body were LATER then; they are in its world part now (`1463ec7`).

## What to expect on the emulator (the lead measures)

At ~0.22 s a program:
- **`MENU ready` about 15-17 s after PLAY** (6-8 s without, 51 s with the old warm-up): +39 programs ≈ +8.6 s, the bar
  moving from 10 % to 100 % a step a draw (about one a second), the tips and the CSS animations going. The same on a
  reload (no program cache there); a real phone's Chrome may keep programs between visits.
- **The menu, idle:** one warm-up frame (~1.1-1.5 s) then as long without; nothing for 1.5 s after a touch. Its world
  part (~50 programs, ~11 s of drawing) is done after ~20-25 s on an idle menu.
- **A child who taps at once:** the loading card stays until the world part is drawn: ~11 s of drawing behind it, at
  half the time while the world loads and every frame once the child stands in it; frames of ~1.1-1.5 s behind the
  card. Then **no compile in the world** (before: long frames of 5.4, 5.1, 10.8 and 1.2 s).
- **In play:** nothing for what the first world and the first minutes show; what the rest has not reached yet
  (monsters, bosses, the Moon, portals) compiles on first sight as before, ~1 s each, until the child spends time on a
  menu or a loading card.

## Rulings (the rework)

1. **Before the menu only what the menu shows.** A menu-and-world first part was ~22 draws, ~100 programs: `MENU ready`
   ~28 s on the emulator, over the lead's 15-20 s. Cost if wrong: a child who taps at once waits for the world part on
   the loading card instead of the loading page (the same seconds; the page's animation is smoother).
2. **The loading card waits for the world part (at most 30 s), with the game's view drawing no 3D under it.** Cost if
   wrong: a quick child's first world comes ~10-15 s later than without a warm-up (the card's hint moving about once
   a second meanwhile), and a Survivor child stands in a world they cannot see for that long (the card takes the
   taps). In exchange nothing a first world shows compiles in it. Undo: `LoadingCard.HOLD_MAX = 0.0`.
3. **The rest only on an idle menu and behind loading cards, at most half the time, never in play.** Cost if wrong: a
   child who never waits on a menu meets the rare sights' compiles (~1 s each, monsters at the first night, the Moon)
   as before; the menu's orbit moves in steps while it is idle.
4. **The Sandbox's prewarms are left to the warm-up where one ran.** Cost if wrong: a prewarmed thing the rest has not
   reached compiles on its first real sight (the game ring, a portal, the blasters: SOON/LATER; the break ring and the
   pop are in the world part).
5. **FIRST / WORLD / SOON / LATER from the census** (`shown` within 48 m of the camera, sampled every 0.5 s, and one
   hand list: the player's feedback scripts, hidden until the first look at a block). Cost if wrong: a draw the census
   did not see near a first world's spawn (a returning child's own builds: a bot friend's badge, a portal) compiles on
   its first sight until the rest reaches it. Re-run the census after content changes (DEVELOPMENT.md §7).
6. **A REALISTIC child: REALISTIC first, BLOCKY after the menu.** Cost if wrong: on a device whose realistic pictures
   are still downloading, the menu and the first world show BLOCKY with first-sight compiles.
7. **REALISTIC picked later joins the rest** (no longer warmed at the tap, which ran every REALISTIC draw at 2 a frame:
   ~40 s of 1 FPS on the emulator). Cost if wrong: the switch compiles what is on screen at that moment (~25 programs,
   a few seconds on a phone); the rest follows on the next menu or loading card.
8. **On in every browser.** Cost if wrong (the emulator says otherwise): `PlatformRules.shader_warmup = false` turns it
   all off (the prewarms come back with it: `covers_prewarms` is false without a warm-up).

## Tests (the rework)

`tests/unit/test_shader_warmup.gd` (`next_count`, `later_may_run`, `rest_after`, `tier`, `plan`, `visible_keys`,
`at_spawn`/`covers_prewarms`, no script hooks a prewarm to `spawned` directly, the developer args),
`tests/unit/test_web_glue.gd` (the page's progress script), `tests/unit/test_platform_rules.gd` (on in every browser),
`tests/integration/test_shader_warmup_spread.gd` (the first part, the order, the progress, the budget, the view, the
card's hold and the quiet view under it, max_seconds, a style added later), `test_shader_warmup_menu.gd` (MENU ready
after the first part, the rest under the root on an idle menu, never in play, behind a loading card, a tap holds it,
the styles), `test_loading_card.gd` (it waits for a holder, never longer than `hold_max`), `test_shader_warmup_stage.gd`.
GUT's `wait_for_signal` on a warm-up hung a test file (its signal watcher records every `node_drawn` with its node):
the menu tests poll `RUNNING` instead.

## Left open (the rework)

- Warming during play at calm moments (standing still, a full-screen panel open) would finish the rest sooner for a
  child who never waits on a menu; not done (the lead's rule: no frame over 60 ms in play).
- The engine's 4 unused default programs per shader, and near-duplicate materials (three Label3D settings are 3
  shaders, ~18 programs): consolidating them shortens every part.
- While the engine starts (before the first progress), the bar stands at 10 % with "Starting the game…" (a long first
  frame; the CSS animations run on).

## Measured on the emulator (the lead, 2026-09-29 04:00-04:55)

`tools/web_emu_flow.py` (the child's taps; the warm-up's own lines), each build served on port 8060 in turn:

| Emulator (Pixel 8 AVD, Chrome, landscape), same steps | Before (live `…1790639824`) | The rework (`308f6d7`) |
|---|---|---|
| MENU ready after PLAY | 8.2-8.5 s | 14.6-16.3 s |
| A new player taps straight through (name, look, style) into SANDBOX | a 5.1 s frame, then **11.2 s frozen** at the spawn | worst frame 1.3 s (5 over 60 ms, 3.3 s in all) |
| A new player waits 40 s on the menu first | 3.7 s, then **11.0 s frozen** | worst 1.2 s (2.6 s in all) |
| A returning child: PLAY, SANDBOX, CONTINUE at once | 4.9 s, then **11.3 s frozen** | worst 1.3 s (about 1.2 s frames for 9 s behind the loading card) |
| The idle menu | two 1.4 s frames | about 1.2 s frames every 2.4 s while the warm-up runs (world part ~33 s, the rest ~75 s) |

The 11 s frame is the first world's frame compiling its ~70 programs at once (it coincides with "TUTORIAL playground …
ms to find", which only counts until the main thread takes the worker's answer). Time to a smooth world is about the
same (~30 s for a returning child); the difference is a frozen screen that looks like a crash (#64) against a loading
page with progress and short hitches. **Ruling: merged** (`308f6d7`). Cost if wrong: the menu 7 s later and a hitchy
idle menu; `PlatformRules.shader_warmup = false` turns it all off. The world part took ~33 s on the idle menu here, not
the ~11 s the notes expected (one draw, then as long without).

## The lead's change (2026-09-29 05:40): the menu does not wait for its own draws (`ShaderWarmup.menu_first = false`)

The first part (the menu's own draws before `MENU ready`) held the loading page ~7.5 s on the emulator, while the menu
compiles the same shaders in ~3.5 s of its own first frames (behind the loading page, until the warm-up's first frame
says it is ready). Off: the menu's draws join the first world's part (a loading card still waits for it). The same
emulator, the same taps (`tools/web_emu_flow.py`):

| | before the rework | the rework (menu first) | menu_first off (live) |
|---|---|---|---|
| MENU ready after PLAY, a new player / a returning one | 8.5 / 8.2 s | 16.1 / 16.3 s | **11.9 / 10.8 s** |
| A new player taps straight through into SANDBOX | 5.1 s + **11.2 s frozen** | worst 1.3 s | worst 2.5 s (behind the loading card) |
| A returning child: PLAY, SANDBOX, CONTINUE | 4.9 s + **11.3 s frozen** | worst 1.3 s, ~9 s of hitches | worst 2.5 s, ~13 s behind the card |
| PLAY to a smooth world, a returning child | ~29 s | ~32 s | **~27 s** |

The first-part design stays in the code and its tests (they switch `menu_first` on).
