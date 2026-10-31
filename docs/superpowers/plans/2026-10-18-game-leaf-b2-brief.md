# Inside a Leaf, phase B2: the voyage plays — the agent brief (owner #133, #134)

B1 ("the leaf works") passed the lead's review on 2026-10-18 (`docs/devlog/parts/game-leaf-b.md`, its last section). This
is **B2, "the voyage plays"** (the design's §4.8 step 2, about two sessions): a child can play voyages 5.1 (The Drooping
Sunflower) and 5.T1 (the desert night) from start to end, flat and in VR, opened from the School, DISCOVER and the
Academy, and the record lands in the child's progress. Work autonomously; do not ask questions (decide, and write each
ruling down with its cost).

## Read first
`docs/design/future-lessons.md`; the design in full (`docs/design/games/leaf-voyage.md`: §3.4-3.10, §4.3-4.8, §7, the
lead's review); your own B1 notes (`docs/devlog/parts/game-leaf-b.md`, rulings 1-23 and the lead's review: finding 2
accepted, finding 3 fixed by the lead in `99f33b97`, so one owl model is enough now); G0's foundation
(`docs/devlog/parts/play-g0.md`, DEVELOPMENT.md "The foundation's API, for the game agents"); W1
(`docs/devlog/parts/play-w1.md`: `DiscoveryDirector`, DISCOVER = Hoot's pick, the crystals, `AcademyPlaza.opens()`);
the VR rules (`Vr`, `VrRules`, owner #127's raised-forearm panel, #128's swing); the godot-prompter skills first
(xr-development, input-handling, camera-system, player-controller, godot-optimization, hud-system).

## Build (B2)
1. **The registry for a game with its own host: built once, for every deep game** (Balance Altar and Fraction Bakery
   adopt it next; the lead's reviews decided this). `data/play/mechanics.json` gains a `"signature"` table (§4.7.1:
   `"leaf_voyage": {"name": "Size Magic Voyages: Inside a Leaf", "host": "res://entities/play/leaf/leaf_voyage_host.gd"}`);
   one small pure entry point (your naming, e.g. `PlaySignature.host_for(unit_content) -> String` and a host contract:
   `setup(unit, content, seed, stars, unit_info, params)`, `open()`, `close()`, `finished(outcome)`, `stopped`,
   `any_open()`, `closed`) that every caller uses: **`SchoolScreen.show_play`** (PLAY opens the host when the unit's
   `play.game` names one, `play.params.voyage` choosing the voyage), **`DiscoveryDirector._open_place`** (Hoot's pick, a
   crystal and an Academy door open the same host), and the end recorded exactly as a `PlayHost` round's (MasteryRules,
   EarnRules, the gold once, `SkillShown`). Test first: a unit naming a signature game opens it from all three; a unit
   naming none opens `PlayHost` as today; an unknown name falls back to `PlayHost` with a warning, never a crash.
2. **`g5.science.plants_air_water`'s `play` block** (§4.7.2): `{"game": "leaf_voyage", "params": {"voyage": "5.1"}}`.
3. **Back and the pause key belong to the voyage while it shows** (§4.7.3: `menu.gd` beside `PlayHost.any_open`; W1's
   `room_open`/`close_if_open`).
4. **`LeafVoyageHost`, flat** (§4.4): open/close; the third-person camera and the camera button; one tap glides and acts
   (≤ 1.2 s), a drag looks; keys, mouse and a game controller; the demonstrations (Hoot's ghost hand); the voice through
   `PlayVoice` (every line spoken by itself; no words on the screen while a voyage plays); the record through `LeafBeats`
   → `SkillShown` (the lead's ruling on finding 2: the sunflower records the water-and-air balance, the desert's
   weather beats are NEW_SETTING evidence); the break, STOP FOR NOW (records nothing), the end card and the voyage board
   (pictures only); `LeafProgress` on the device; `--leaf-voyage=5.1|5.T1` for developers.
5. **`LeafVoyageHost`, VR** (§4.4): the garden at `Vr.anchor`; the can lifted and tilted; the dive (the garden grows round
   the feet, the head never moves); swimming (`LeafSwimRules`), the laser grapple, snap turns, the comfort choice; doors
   by a two-hand squeeze or one trigger; sugar carried by hand to the pipe; the HUD hidden, the raised forearm's panel
   (owner #127); Hoot at the shoulder. Tests with `Vr.simulate`, `sim_hand`, `sim_input`.
6. **The budget and the warm-up**: `tests/integration/test_leaf_budget.gd` (the heaviest moment ≤ 100 draws, the place's
   own counter, as `test_play_budget.gd`); `tools/leaf_bench.gd`; **a census pass through the leaf**
   (`tools/shader_probe_steps.gd`) so the web compiles nothing mid-voyage (your finding 5).
7. Tests as §4.6: `test_leaf_host.gd` (flat and simulated VR through 5.1 and 5.T1: the hook, the dive, Act 1, Act 2, the
   return, the record, the break, stop for now, Android Back), `test_leaf_voice.gd`, the registry's tests, the budget.
   `tools/leaf_smoke.gd` (both voyages with the rule bot, flat and simulated VR, headless, checking the record).

Not in B2: the desert's full dressing, sounds, music and juice (B3). Keep each new file in your allocation; the hooks in
others' files are exactly the three above and small.

## Allocation and rules
- Yours: `core/play/leaf/*`, `entities/play/leaf/*`, `ui/play/leaf/*`, `data/play/leaf/*`, tests `test_leaf_*.gd` and the
  registry's tests, tools `tools/leaf_*`, notes `docs/devlog/parts/game-leaf-b.md` (add a B2 part). **Granted hooks:**
  `data/play/mechanics.json` (the signature table), one new pure file for the registry under `core/play/`,
  `ui/school/school_screen.gd` (`show_play` only), `entities/discovery/discovery_director.gd` (`_open_place` only),
  `ui/menus/menu.gd` (Back and pause only), `data/school/g5/science/plants_air_water.json` (the `play` block only),
  `tests/unit/test_shader_warmup_sources.gd` and the census (if a material needs it). Nothing else of G0's, W1's or the
  School's.
- TDD (superpowers:test-driven-development); `--import` after new class_name scripts; logs `leafb2_*` in the session
  scratchpad; pictures and the bench in a real window under `nice`, one at a time; the FULL suite once at the end, right
  after merging the base branch you were cut from (`lead-w1b`) again. Never open the editor or an emulator, never touch
  adb; never merge into lead-merge or push; no downloads; never start agents; no server changes. CC0 or own assets
  only. English only. Commits end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge the
  base again first, then run it once more; report it either way.

## Finish
Notes (what works, the registry's API for the next games, the draws, the pictures, the rulings), DEVELOPMENT.md (the
registry in "The foundation's API, for the game agents"; the leaf's commands). Report: branch, commits, the registry's
API, the full suite, the draws, the pictures, and what B3 and the lead's emulator and Quest check need.
