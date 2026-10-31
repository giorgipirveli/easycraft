# Balance Altar, phase B1: the altar works — the agent brief (owner #133, #134)

Phase A (research and design) passed the lead's review on 2026-10-18 (`docs/design/games/balance-altar.md`, its last
section; the owner's page `balance-altar-owner.md`, https://claude.ai/artifact/DRoDygURZvmxE23znLfgr8). Phase B builds
the **Entrance Hall** and the **Sky Room** complete and beautiful, flat and VR, in three briefs; this is **B1, "the altar
works"** (the design's §4.8 step 1, about two sessions). It needs nothing from the host registry that Inside a Leaf's B2
is building now: B2 (the temple plays) adopts that registry once it has merged. Inside a Leaf's B1 is the model of a
good B1 (`docs/devlog/parts/game-leaf-b.md`, its pictures and the lead's review; `core/play/leaf/`,
`entities/play/leaf/`, `test_leaf_cheat_bots.gd`). Work autonomously; do not ask questions (decide, and write each ruling
down with its cost).

## Read first
`docs/design/future-lessons.md` (the five tests, the gates), the design **in full** (`docs/design/games/balance-altar.md`:
§3.4-3.5b the verb and the beats, the Entrance Hall and the Sky Room beat by beat, §3.8 show/say/do, §3.10 the record,
§3.11 the look, §4 the tech plan, the rulings, the honesty table, and the lead's review), the pictures
(`docs/design/games/balance-altar/`), the models (`model/`: the rules you port are `model/altar_rules.py`), G0's foundation
(`docs/devlog/parts/play-g0.md`, DEVELOPMENT.md "The foundation's API, for the game agents"), `LifeRoomKit` and the rooms'
look (`docs/devlog/parts/rooms-look.md`: decor merged per material, `LifeRoomSun` as a place's only light), Inside a Leaf's
B1 notes (how it ported its model and how its pictures were judged and fixed). The lead fixed BlockyAnimal's winding
(`test_mesh_winding.gd`): every box mesh you build must face outwards the same way (Godot's front faces are clockwise
seen from outside); add your meshes to that test.

## Build (B1)
1. **The pure rules, `core/play/altar/`**, test first (§4.3, §4.6): `AltarState`, `AltarMoves`, `AltarSolver`, `AltarGen`,
   `AltarBeats`, `AltarRunes`, `AltarHalls` with `data/play/altar/halls.json` and `lines.json`, `AltarProgress`,
   `AltarTwinRules`; **`test_altar_cheat_bots.gd`: the cheat and transfer tests as tests**, with the phase A model's
   players and thresholds (the Entrance Hall's bar: the rule bot at least 99 %, with 4 % slips at least 90 %; random
   tapping, random moves, one pan only, carrying across, both half-habits and guessing the move each at most 1 % of 1,000
   seeded visits; the Sky Room: the hall's habit never reaches the bar, the rule always does); every voice line at most 12
   words and never a question that needs reading; the rune readings at most 12 words.
2. **The places, `entities/play/altar/`**: `AltarKit` (over `LifeRoomKit`: merged meshes and MultiMeshes, only shaders the
   warm-up holds), `TempleHall` (the dome, the ring of altars, the chandelier, the great door), `BalanceAltar` (the
   fulcrum, the chained beam, the pans, the crystal and its sleeping Glimmer, gems and balloons as MultiMeshes, the rune
   plaque, bowls, the gem bag; its `LifeReach` targets), `GlimmerModel`, the Sky Room's first dressing, `TempleArrival`'s
   first version; `test_altar_place.gd` (targets in the flat free band and fingertip-sized, VR reach, warmed shaders, no
   shadows, one light: the place's own `LifeRoomSun`); `tools/altar_shots.gd`: pictures of the arrival, the hall, an
   altar close up, a crystal freed, the Sky Room, **in a real window under `nice`, one at a time**, looked at and fixed
   until they are beautiful (the owner's bar: "amazing and best visuals").
3. **The draws counted** at the heaviest view (the design's §4.5 estimate), against the Quest's 100.

Not in B1: the host's input, camera and VR (B2), sounds, music and juice (B3). Keep the API the design's §4.3 names so
B2 builds on it.

## Allocation and rules
- Yours: `core/play/altar/*`, `entities/play/altar/*`, `ui/play/altar/*`, `data/play/altar/*`, tests `test_altar_*.gd`,
  tools `tools/altar_*`, `tools/make_altar_sfx.py`, notes `docs/devlog/parts/game-altar-b.md`; one line per new
  material-making file in `tests/unit/test_shader_warmup_sources.gd`'s COVERED (proved in its census check, as the
  rooms' look did) and your meshes in `tests/unit/test_mesh_winding.gd`. Nothing in G0's, W1's, the leaf's or the
  School's files.
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (3d-essentials,
  procedural-generation, godot-optimization, shader-basics, component-system, xr-development); `--import` after new
  class_name scripts; logs `altarb_*` in the session scratchpad; the FULL suite once at the end of B1, right after
  merging `lead-merge` again. Never open the editor or an emulator, never touch adb; never merge into lead-merge or
  push; no downloads; never start agents; no server changes. CC0 or own assets only. English only. Commits end with
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes (what works, the bots' numbers, the pictures' paths with what you changed after looking, the draws, the rulings),
DEVELOPMENT.md (a short "Balance Altar" section: the rules' API, the commands). Report: branch, commits, the cheat bots'
results, the pictures, the draws, the full suite, and what B2 needs from the lead.
