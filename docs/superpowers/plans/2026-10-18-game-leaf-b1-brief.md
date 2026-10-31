# Inside a Leaf, phase B1: the leaf works — the agent brief (owner #133, #134)

Phase A (research and design) passed the lead's review on 2026-10-18 (`docs/design/games/leaf-voyage.md`, its last
section "The lead's review"; the owner's page `leaf-voyage-owner.md`). Phase B builds voyages **5.1** (The Drooping
Sunflower) and **5.T1** (the desert night) complete and beautiful, flat and VR, in three briefs; this is **B1, "the leaf
works"** (the design's §4.8 step 1: about two sessions). Work autonomously; do not ask questions (decide, and write each
ruling down with its cost).

## Read first
`docs/design/future-lessons.md` (the five tests, the gates), the design **in full** (`docs/design/games/leaf-voyage.md`:
§3.4-3.5b the verb and the beats, §3.8 show/say/do, §3.10 the record, §3.11 the look, §4 the tech plan, §7 the rulings,
§9 the honesty table, and the lead's review), the pictures (`docs/design/games/leaf-voyage/`), the two models
(`model/`), G0's foundation (`docs/devlog/parts/play-g0.md`, DEVELOPMENT.md "The foundation's API, for the game
agents"), `LifeRoomKit` and the rooms' look notes (`docs/devlog/parts/rooms-look.md`, if merged), Size Magic.

## Build (B1)
1. **The pure rules, `core/play/leaf/`**, test first (§4.3, §4.6): `LeafSim`, `LeafWeather`, `LeafBeats`, `LeafVoyages`
   with `data/play/leaf/voyages.json` and `lines.json`, `LeafProgress`, `LeafSwimRules`, `LeafSpace`; the tests
   `test_leaf_sim.gd`, `test_leaf_beats.gd`, **`test_leaf_cheat_bots.gd` (the cheat test as a test: random, always-open,
   always-closed, greedy and "open when bright" bots under 1 % of 1,000 seeded runs; the rule bot over 99 %; the slow
   rule bot over 60 % flat and 95 % VR; in 5.T1 the sunflower-habit bot never wins, the cool-rule bot always)**,
   `test_leaf_voyages.gd` (every line ≤ 12 words, never a question that needs reading), `test_leaf_swim_rules.gd`.
2. **The places, `entities/play/leaf/`**: `LeafKit` (over `LifeRoomKit`: merged meshes and MultiMeshes, only shaders
   the warm-up holds), `LeafPlace` (the leaf's inside: §3.11), `LeafGarden` and `SunflowerModel` (the terrace, the pot,
   the can, the two block scales, droop/stand/bud/bloom), the dive's first version, `CactusDressing`'s first version;
   `test_leaf_place.gd` (targets in the flat free band and fingertip-sized, VR reach, warmed shaders, no shadows);
   `tools/leaf_shots.gd`: pictures of the garden, the dive, inside and the desert night **in a real window under `nice`,
   one at a time**, looked at and fixed until they are beautiful (the owner's bar: "amazing and best visuals").
3. **The draws counted** at the heaviest view (the design's §4.5 estimate: about 45-55 inside, 35 in the garden).

Not in B1: the host's input, camera and VR (B2), sounds, music and juice (B3). Keep the API the design's §4.3 names so
B2 builds on it.

## Allocation and rules
- Yours: `core/play/leaf/*`, `entities/play/leaf/*`, `ui/play/leaf/*`, `data/play/leaf/*`, tests `test_leaf_*.gd`,
  tools `tools/leaf_*`, `tools/make_leaf_sfx.py`, notes `docs/devlog/parts/game-leaf-b.md`. Nothing in G0's, W1's or the
  School's files in B1 (the hooks of the design's §4.7 come in B2, approved by the lead's review).
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (3d-essentials, procedural-
  generation, godot-optimization, shader-basics, component-system, xr-development); `--import` after new class_name
  scripts; logs `leafb_*` in the session scratchpad; the FULL suite once at the end of B1, right after merging
  lead-merge. Never open the editor or an emulator, never touch adb; never merge into lead-merge or push; no downloads;
  never start agents; no server changes. CC0 or own assets only. Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes (what works, the bots' numbers, the pictures' paths with what you changed after looking, the draws, the rulings),
DEVELOPMENT.md (a short "Inside a Leaf" section: the rules' API, the commands). Report: branch, commits, the cheat
bots' results, the pictures, the draws, the full suite, and what B2 needs from the lead.
