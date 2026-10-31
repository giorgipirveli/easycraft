# The best visuals (2026-10-01, the visuals agent)

The brief: `docs/superpowers/plans/2026-10-01-visuals-brief.md` (the owner's goal: "create amazing and best visuals";
#94 "game improvement"). Branch `worktree-agent-a119c3edbdf81ef70`, from `lead-merge` `7cc3c439`. No editor, emulator or
adb: pictures from a real window on this PC (Intel UHD iGPU, 1600 x 720, the emulator's 20:9), in **both renderers**:
`gl_compatibility` (the web, the emulator, a phone without Vulkan) and `mobile` (Vulkan: a phone). The PC's load was
6-18 through the day (another app is built here): the bench compares **GPU time**, not wall time.

## The tool

`tools/look_shots.gd` (DEVELOPMENT.md §4 "The look"): a NEW Sandbox world of seed 12345 per universe, fixed views in
both styles (Green Meadows: noon, morning, sunset and night from 20 m over the spawn, the ground at eye level, the sea's
shore, a cave; the Moon, Mars, Venus, Saturn's rings and the Wonders: noon, sunset, night over the landing; `--menu` the
title screen), each measured (`LOOK_BENCH`: wall, GPU and render-CPU time, draws, primitives) and photographed.
`--env=` tries Environment settings, `--no-shadows` / `--no-lantern` take one cost alone. The pictures of this work are
in the scratchpad of the session (not committed); the committed before/after sheets are
`docs/devlog/parts/visuals/opengl-meadows.jpg`, `opengl-worlds.jpg`, `vulkan-meadows.jpg`, `vulkan-worlds.jpg`.

## What the "before" pictures showed

- **OpenGL (the web, the emulator): neon grass, near-black leaves, a dark REALISTIC world, a black REALISTIC night.**
  Every colour picture was decoded twice there: Godot 4.7's OpenGL decodes a `source_color` picture itself, and the
  M1b fix (2026-09-23, "the atlas was washed out on the emulator") forced a second decode (`albedo_texture_force_srgb`,
  a `to_linear` in the water, planet and skin shaders). Measured, the sunlit grass's red/green: this PC's OpenGL 0.23,
  the lead's emulator shot of the app (2026-09-25) 0.25, the web build in the emulator's Chrome (2026-09-27) 0.27,
  Vulkan 0.43, the tile itself 0.47. An unshaded quad of the grass tile: 89,192,51 without the forced decode (the tile
  is 90,193,53), 23,136,4 with it, on both renderers. So the web and the emulator never showed the colours the phones
  (Vulkan) showed.
- **Every view from a height: the fogged far hills stood as a pale wall over a dark blue band** (the painted sky's lower
  half, ground_bottom 0.36,0.5,0.7, showed beyond the streamed land; at sunset a pink wall over a purple band; on the
  sea a coloured line along the horizon).
- **REALISTIC's photo sky at sunset was a dim noon** (its energy only), at night nearly black on OpenGL and grey on
  Vulkan.
- **Blocky water was a flat pale tile** (roughness 1, no glint); on OpenGL once the colours were right, a milky cyan
  over the sand.
- **The title diorama hid behind the menu's panels** (only the buddy's head under the wordmark showed; so since M5).
- Mornings and evenings had the day's white light until the last minutes of dawn and dusk.

## The changes (each measured; commits on the branch)

| Change | Where | Cost (this PC's iGPU, 1600 x 720) |
|---|---|---|
| **Every picture decoded once** (no `force_srgb` anywhere; the census's materials follow) | `fb4c1c15`; `tests/unit/test_look_colours.gd` | none (one `pow` less a pixel on OpenGL) |
| **The far land melts into the sky:** the haze and the sky under the horizon are the horizon's colour (`DayCycle.sky_meets_fog`, every world's own sky and space's too) | `ebaf826d`, `f535000f`; `test_look.gd`, `test_look_sky.gd` | none |
| **Hazy blue far hills:** the fog starts at 0.45 of the view (was 0.7), the day's horizon and haze a light blue (0.6, 0.78, 0.98) | `ebaf826d` | none |
| **A golden low sun** (under a height of 0.5 the sunlight turns toward 1.0, 0.8, 0.56) | `ebaf826d` | none |
| **The photo sky at dusk and night** takes the fog's colour (`fog_sky_affect` 0.45 at sunset, 0.65 at night) | `ebaf826d` | none (a uniform the sky shader reads) |
| **ACES tonemapping at exposure 0.75** (was Filmic 1.0): the painted colours at noon (at 1.0 a flat orange tile, painted 230,115,51, came out 255,175,104; Mars's red ground pale yellow on OpenGL) | `ebaf826d`, `f535000f` | none |
| **Moonlight 0.55** (was 0.4) so the night stays moonlit under the lower exposure | `600caa30` | none |
| **Blocky water:** deeper blue across, the sun's glint (roughness 0.35), a texel-sized shimmer (not on LOW) | `73dde6aa` | a few ALU a water pixel: within noise (8.6 → 8.0-8.3 ms in the water view) |
| **Leaves, flowers and wheat sway** (a vertex sway, `world/look/sway.gdshader`), **on HIGH only** | `13a72053`, `78e1a4ac`; `test_look_sway.gd` | see "The sway" |
| **A world's own sunlight** (a descriptor's `sun_light`: Mars 0.7, Venus 0.8 of home's): Mars's red dust (painted 197,102,61) stays red (OpenGL 248,167,86 → 248,142,71; Vulkan 233,119,65, the phones had 244,152,91) | `361e7c25`; `test_look.gd`, `test_look_sky.gd` | none |
| **The title diorama beside the wordmark**, sized for the screen's shape (4:3 to 21:9) | `240021a1`; `test_look_title.gd` | none (a transform) |

### The sway: why only HIGH

On OpenGL the sway cost +0.3-0.7 ms in the Meadows views. On Vulkan's Mobile renderer a **cave view under a forest cost
25-27 ms of GPU instead of 16-17** (interleaved A/B, two runs each, `tools/look_shots.gd --views=ground,water,cave`). Taken
apart one by one: the sway's vertex work (removed: still slow), its normal map (removed: still slow), its second sampler
(one: still slow), the cave lantern (`--no-lantern`: still slow), the draw order (`render_priority` -1: still slow), a
separate plain material for the leaves (fast) and a minimal custom cut-out shader (slow): **any custom cut-out shader
draws the leaves about twice as dear as StandardMaterial3D's cut-out there** (without the sun's shadows still 13.6 against
7.2 ms). The cause inside the renderer is not found (no engine source on this PC). A phone's GPU is 3-5x slower, so
MEDIUM (a phone's default) and LOW keep the plain cut-out; HIGH sways. The choice is made when a library is built
(`BlockLibrary.set_sway` returns a change, `WorldService` drops its cached library): the next world meshed shows it.

## The bench (GPU ms a frame, before → after, the same views)

`tools/look_shots.gd`, 1600 x 720, MEDIUM (the default phone preset: shadows 40 m, view 128), seed 12345, 89 frames a
view after the land is meshed; "before" is `lead-merge` `7cc3c439`, "after" this branch's final code (the sway off on
MEDIUM). The PC's load 6-18. A space world's first view (noon blocky) is taken while its land still streams in: its
numbers wander between runs either way.

**OpenGL (the web, the emulator), Green Meadows:**

| View | Style | GPU ms before | GPU ms after | Wall ms before (worst) | Wall ms after (worst) | Draws before / after |
|---|---|---:|---:|---:|---:|---:|
| u1_noon | blocky | 13.73 | 13.18 | 14.00 (17.4) | 14.65 (23.6) | 753 / 713 |
| u1_morning | blocky | 14.18 | 14.13 | 14.45 (17.8) | 14.40 (16.0) | 1297 / 1297 |
| u1_sunset | blocky | 12.96 | 13.13 | 13.29 (17.3) | 13.34 (14.9) | 884 / 884 |
| u1_night | blocky | 12.28 | 12.37 | 12.49 (14.4) | 12.61 (14.3) | 664 / 664 |
| u1_ground | blocky | 16.91 | 16.96 | 17.18 (18.9) | 17.18 (19.0) | 970 / 972 |
| u1_water | blocky | 8.61 | 8.44 | 12.53 (46.8) | 11.88 (31.6) | 307 / 307 |
| u1_cave | blocky | 18.77 | 18.69 | 19.06 (21.8) | 20.22 (44.1) | 1049 / 1041 |
| u1_noon | realistic | 15.14 | 15.17 | 15.40 (17.3) | 15.37 (17.6) | 753 / 751 |
| u1_morning | realistic | 15.02 | 15.11 | 15.23 (17.2) | 15.31 (19.0) | 1303 / 1303 |
| u1_sunset | realistic | 14.29 | 14.43 | 14.58 (26.6) | 14.62 (16.8) | 885 / 885 |
| u1_night | realistic | 13.63 | 13.63 | 13.85 (17.1) | 13.82 (18.4) | 668 / 668 |
| u1_ground | realistic | 21.46 | 21.49 | 21.63 (25.3) | 21.66 (23.7) | 977 / 976 |
| u1_water | realistic | 8.69 | 9.20 | 8.88 (11.2) | 10.31 (24.9) | 315 / 313 |
| u1_cave | realistic | 22.67 | 22.62 | 22.85 (25.8) | 22.80 (27.4) | 1054 / 1054 |
| **mean** | | **14.88** | **14.90** | | | |

**Vulkan Mobile (a phone), Green Meadows:**

| View | Style | GPU ms before | GPU ms after | Wall ms before (worst) | Wall ms after (worst) | Draws before / after |
|---|---|---:|---:|---:|---:|---:|
| u1_noon | blocky | 21.15 | 22.76 | 22.62 (33.2) | 24.34 (28.4) | 267 / 342 |
| u1_morning | blocky | 25.66 | 25.96 | 26.51 (30.2) | 27.55 (31.9) | 525 / 526 |
| u1_sunset | blocky | 21.34 | 20.44 | 22.15 (24.7) | 21.88 (25.8) | 391 / 390 |
| u1_night | blocky | 19.99 | 18.97 | 20.84 (23.1) | 20.30 (24.2) | 295 / 295 |
| u1_ground | blocky | 19.71 | 18.75 | 20.54 (25.1) | 20.13 (22.9) | 397 / 396 |
| u1_water | blocky | 6.81 | 7.07 | 12.46 (37.0) | 11.67 (43.1) | 206 / 218 |
| u1_cave | blocky | 16.12 | 16.74 | 18.86 (44.9) | 18.90 (36.4) | 425 / 430 |
| u1_noon | realistic | 29.12 | 28.66 | 30.00 (32.7) | 29.04 (30.7) | 338 / 340 |
| u1_morning | realistic | 41.90 | 41.64 | 42.75 (45.3) | 42.06 (45.0) | 530 / 530 |
| u1_sunset | realistic | 24.96 | 23.88 | 25.79 (27.5) | 26.22 (31.7) | 391 / 391 |
| u1_night | realistic | 24.56 | 24.29 | 25.38 (28.1) | 28.17 (33.7) | 295 / 296 |
| u1_ground | realistic | 29.83 | 29.56 | 30.70 (34.0) | 34.06 (37.7) | 399 / 400 |
| u1_water | realistic | 7.15 | 7.25 | 7.82 (12.6) | 7.91 (23.6) | 223 / 224 |
| u1_cave | realistic | 22.75 | 23.35 | 24.27 (66.6) | 23.76 (29.3) | 428 / 437 |
| **mean** | | **22.22** | **22.09** | | | |

**Every world's views** (the menu, the Moon, Mars, Venus, Saturn's rings, the Wonders; 32 views each): the mean GPU time
5.15 → 4.82 ms on OpenGL, 4.33 → 4.43 on Vulkan (each view within its noise; Mars and Venus with their own sunlight:
u19 noon 6.14 / 4.79 ms after, u24 noon 3.31 / 2.81 on OpenGL / Vulkan). **Nothing here costs a frame**: the changes
are colours, uniforms and a few ALU of water; the one that cost (the sway on Vulkan) is on HIGH only. The menu's worst
frame before (294-481 ms) was the realistic sky's first light bake as the style switched, not a steady cost.

## Rulings (what each costs if wrong)

1. **No forced sRGB decode anywhere.** Measured on this PC's OpenGL, the emulator's app (the lead's shot) and the web
   build in the emulator's Chrome: all three decode already. Cost if wrong: on an OpenGL device whose driver does not
   decode (what M1b saw once, 2026-09-23, on an earlier emulator image), colours look washed out there: restore
   `albedo_texture_force_srgb` for that case only (a device check), never for all.
2. **ACES at exposure 0.75 for every world and the menu** (`world/world.tscn`). Phones (Vulkan) looked paler before
   (Filmic 1.0: the noon light about twice the painted colour). Cost if wrong: the owner prefers the paler look: one line
   (`tonemap_mode`, `tonemap_exposure`) back, and `DayCycle.MOON` back to 0.4.
3. **The haze is the sky's horizon colour** (a palette's `fog` no longer decides the haze). Cost if wrong: a world whose
   designer wanted a haze unlike its horizon (none found: Mars, Venus, Titan's were close) loses it; the seam comes back
   if `sky_meets_fog` is dropped.
4. **The fog starts at 0.45 of the view.** Cost if wrong: the middle distance is hazier than a child wants from a hill:
   `WorldService.FOG_BEGIN`.
5. **The photo sky's dusk and night by the fog's wash** (uniform over the sky) rather than a sky shader of its own
   (a new shader to warm, a changed PanoramaSkyMaterial every test checks). Cost if wrong: the photo sky's clouds are
   washed evenly, with no glow toward the sun; a sky shader later.
6. **The sway only on HIGH** (above). Cost if wrong: MEDIUM children never see the leaves move; turning it on for MEDIUM
   is one key in `GraphicsPreset.PRESETS` once the Vulkan cost is understood (the emulator runs OpenGL: measure a real
   Vulkan phone).
7. **The title diorama left of the wordmark** (was under it). Cost if wrong: M5's layout: `TitleDioramaRules.place`.
8. **Mars's and Venus's own sunlight** (0.7 and 0.8 of home's; not the real 0.43 for Mars: a child must still see well).
   Cost if wrong: Mars looks dim at noon: its descriptor's `sun_light`.
9. **The census edited by hand, not played again**: only the `albedo_texture_force_srgb` flag left its 8 materials (the
   same 40 draws, no two merged). Cost if wrong: none expected; the lead runs the census after merging as always.
10. **Not done** (the roadmap's §5 "what comes next"): the wordmark's shine and the loading card's look (2D, first sight
   is the menu's: a new canvas shader would compile before the first frame in a browser), a colour variation on big
   fields (a shader for every block page: the same Vulkan cost as the sway), water's colour by depth and a soft shore
   (the depth texture: a full-screen copy on phones), the REALISTIC noon's pale band where the fogged land meets the
   photo's horizon, Venus's still very pale noon (its cream haze covers the islands: its own haze colour or a later fog
   start there), clouds in the painted sky.

## What the lead checks on the emulator

A debug APK of the merge, MEDIUM graphics, a quiet PC (`uptime` with every run); every adb call with
`ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554`.
1. **The colours** (the emulator runs OpenGL): the grass a natural green, not neon; stone grey, not white. A washed-out,
   whitish world means this image's driver does not decode: ruling 1.
2. **FPS in both styles at noon, sunset and night:** the developer menu's AUTOPILOT BLOCKY and REALISTIC in Green Meadows
   (`/time` or waiting for the clock), `AUTOPILOT result ... frames_over_100ms=`: nothing here costs a frame on OpenGL
   (the bench), so the numbers should match the last runs.
3. **The look:** the far hills melting into the sky from a hill; a golden morning; REALISTIC's orange sunset and blue
   night; moonlit blocky night (dark but readable); the sea's water deeper blue with a glint.
4. **The menu:** the buddy on its island beside the wordmark, whole, waving.
5. **HIGH:** leaves sway (the next world after choosing HIGH), and its FPS.
6. **A phone's look** (Vulkan): the same, if a phone is at hand; the web in the emulator's Chrome the same as the app.

## Tests and the full suite

New: `tests/unit/test_look_colours.gd` (3), `test_look.gd` (7), `test_look_sway.gd` (9), `test_look_title.gd` (2),
`tests/integration/test_look_sky.gd` (7). Changed with the rules they pin: `test_sky_cycle.gd` (the fog's start),
`test_title_diorama.gd` (beside the wordmark), `test_meadows_blocks.gd`, `test_desert_blocks.gd`,
`test_wonders_blocks.gd` (a page block's material through `BlockLibrary.block_material`), `test_universe_world.gd` (a
universe's haze is its horizon's colour).

The full suite (`tests/run_tests.sh`, once, 2026-10-01 02:39-03:35, the PC's load 7-20): **1,019 scripts, 9,333 tests,
9,329 passing, 2 failing, 2 risky/pending as always, no script error.** Both failures were fixed after it and checked
by the files that show them:
- `test_page_sizes.gd` (89.7 MB of realistic pages against 70): my look tests' REALISTIC warm-up twins kept every page's
  photo textures alive, and the pages' own tests decompress an image in place to read its pixels; the look tests now
  drop the twins (`31df2a80`). The block, page and look tests together: 285 passing, 63.8 MB.
- `test_universe_world.gd` `test_the_daytime_sky_takes_the_universes_colours` pinned a palette's fog as the haze (the
  old rule; ruling 3): updated (`e0e90f75`), 9 passing.
