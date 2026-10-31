# Balance Altar, phase B2: the temple plays — the agent brief (owner #133, #134)

B1 ("the altar works") passed the lead's review on 2026-10-18 (`docs/devlog/parts/game-altar-b.md`, its last section).
This is **B2, "the temple plays"** (the design's §4.8 step 2, about two sessions): a child plays the Entrance Hall and
the Sky Room from start to end, flat and in VR, opened from the School, DISCOVER and the Academy's Maths door, and the
record lands in the child's progress. **The registry for a deep game's own host is built** (Inside a Leaf's B2,
`PlaySignature`, merged into `lead-w1b`): you adopt it, you do not build another. Work autonomously; do not ask
questions (decide, and write each ruling down with its cost).

## Read first
The design's §3.5-3.10 and §4.4-4.8; your B1 notes with the lead's review; **the registry**: `core/play/play_signature.gd`,
DEVELOPMENT.md "The foundation's API, for the game agents" (the `signature` table, `make_host`, the host contract: a
`PlayHost` subclass, `setup(unit, content, seed, stars, outline, count)`, `first_try_gold`, `open`, `close`, `finished`,
`stopped`, the outcome's optional `then`), Inside a Leaf's B2 notes (B2.1-B2.9: how its host was built, how
`test_play_signature_callers.gd` proves every door) and `entities/play/leaf/leaf_voyage_host.gd` as the worked example;
W1 (`DiscoveryDirector`, the Academy's doors, `DiscoveryPlays.subject_unit`); the VR rules (`Vr`, owner #127's raised
forearm panel, the comfort vignette); the godot-prompter skills first (xr-development, input-handling, camera-system,
godot-optimization, hud-system).

## Build (B2)
1. **The registry entry and the play block:** `data/play/mechanics.json`'s `signature` table gains `"balance_altar":
   {"name": "Balance Altar", "host": "res://entities/play/altar/altar_temple_host.gd"}`; `data/school/g6/maths/
   equations.json` gains `"play": {"game": "balance_altar", "params": {"room": "entrance"}}` (the Sky Room via the end
   card's `then`). Copy `test_play_signature_callers.gd`'s pattern: the School's PLAY, Hoot's pick, a crystal and the
   Academy's Maths door each open the temple for that unit; no other change in those callers is needed or allowed.
2. **`AltarTempleHost`, flat** (§4.4): open/close; the ring's turn between altars; a tap lifts a gem and its twins glow,
   a tap on a twin completes the move, a drag does both, a long press takes a handful; the bowls and the seal; the gem
   bag; the demonstrations (Hoot's ghost hand); the voice through `PlayVoice` and the rune reading (each symbol says its
   name when touched); the record through `AltarBeats` → `SkillShown`; the break, STOP FOR NOW (records nothing), the
   end card and the room board (pictures only); `AltarProgress` on the device; `--altar-hall=entrance|sky`.
3. **`AltarTempleHost`, VR** (§4.4): the hall's spot at `Vr.anchor`, the active altar 0.45 m in front; the two-hand twin
   (the grip claimer, both gems dissolving with the chime and a buzz in both hands), the one-handed trigger mode, a
   handful scooped, the bowls pulled off the rack, the seal pressed with a palm, the gem bag reached into; the HUD hidden,
   the raised forearm's panel; Hoot on the altar's crown. Tests with `Vr.simulate`, `sim_hand`, `sim_input`.
4. **The budget and the warm-up:** `test_altar_budget.gd` (the heaviest moment ≤ 100 draws, the place's own counter);
   `tools/altar_bench.gd`; **a census pass through the temple** (`tools/shader_probe_steps.gd`, `data/shader_warmup.json`,
   as the leaf's B2 did) so the web compiles nothing mid-temple; the temple built a step a frame if its first open is
   slow (the leaf's B2 finding: build behind the garden).
5. Tests: `test_altar_host.gd` (flat and simulated VR through both rooms: the arrival, the hall's altars, the Great
   Altar, the chorus, the Sky Room, the record, the break, stop for now, Android Back), `test_altar_voice.gd`, the
   callers' test, the budget. `tools/altar_smoke.gd` (both rooms with the rule bot, flat and simulated VR, headless,
   checking the record).

**Not yours:** `SchoolScreen.show_play` and `DiscoveryDirector._open_place` (Inside a Leaf's B3 is adding a loading moment
there now; the temple gets it for free through the registry); sounds, music and juice (B3).

## Allocation and rules
- Yours: `core/play/altar/*`, `entities/play/altar/*`, `ui/play/altar/*`, `data/play/altar/*`, tests `test_altar_*.gd`,
  tools `tools/altar_*`, notes `docs/devlog/parts/game-altar-b.md` (a B2 part). **Granted:** the `balance_altar` entry
  in `data/play/mechanics.json`, the `play` block in `data/school/g6/maths/equations.json`, the census files above,
  `test_shader_warmup_sources.gd`, `test_mesh_winding.gd`, and the two G0 tests that count deep games from the registry
  (`test_play_audit.gd`, `test_play_mechanics.gd`) if they need the new entry.
- First `git merge lead-w1b` into your branch (it has the registry, the leaf's B2, the rooms' look and your B1). TDD;
  `--import` after new class_name scripts; logs `altarb2_*` in the session scratchpad; the FULL suite once at the end,
  right after merging `lead-w1b` again. Never open the editor or an emulator, never touch adb; never merge into
  lead-merge or push; no downloads; never start agents; no server changes. CC0 or own assets only. English only.
  Commits end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.

## Finish
Notes (B2: what works, the draws, the pictures, the rulings), DEVELOPMENT.md ("Balance Altar": the host and its
commands). Report: branch, commits, the full suite, the draws, the pictures, and what B3 and the lead's emulator and
Quest check need.
