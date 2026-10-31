# M2 Task 8: defenses (door, spike trap, lantern)

Spec §12.6 (defenses), plan Task 8. Built in an isolated worktree cut from `m2-survive-the-night` at
`c86fd0f` (Tasks 1, 2, 3, 4, 6, 7, 11, 14, 15 and M3 Tasks 13, 16 merged). No editor or emulator was
used; the lead checks on the emulator after the merge. Allocations used: block ids DOOR 25, DOOR_OPEN 26,
SPIKE_TRAP 27, LANTERN 28 (from Task 1); atlas tiles (3..7, 4) and (7, 3); Session section
`# --- M2 Task 8: defenses (doors)`.

## What was built

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/defense_rules.gd` (`DefenseRules`) | Door toggle and door stacks (at most 3), a closed door in a monster's way at its feet, the trap under or around the feet and its 2-a-second timing, lantern fear (level 2 or less keeps 6 blocks away), the nearest lanterns |
| Doors (host) | `autoloads/session.gd`, section at the end | `request_door(pos)` / `host_door(peer, pos)` / `_rpc_door`: the host takes the whole stack from its own world, checks reach, never closes on a player, a bot friend that is up or a monster (`DOOR_MONSTER_MESSAGE`), applies it like an edit (Survivor ledger, one undo step); signal `door_toggled(at, open)` and the door sound on every game |
| Tap | `entities/player/block_interactor.gd` (one line in `place_at_screen`, section at the end) | A tap on a door toggles its doorway whatever is in the hand (after the pickup bag and Tilly, before weapons); something standing in front takes the tap; a hold still breaks the door |
| Traps and lanterns | `world/defense_director.gd` (`DefenseDirector`, node `Defenses` on every peer) | Host tick (10 Hz): trap stabs through `take_hit(2, trap top, ZERO)` and the spike pop RPC; the lantern index (16-block chunks); weak monsters' lantern lists (every 0.3 s, in turn). Every game: 2 shared warm lights on the lanterns nearest the camera |
| Monster hooks | `entities/monsters/monster.gd` (three lines and a section at the end) | `_mind_defenses()` before `_keep_safe()` in `_decide` (lantern fear), `and not _door_ahead()` on the goblin's step hop, `if _door_ahead(): return` before a slime's hop; `lanterns` (set by the director) |
| Spikes | `entities/fx/fx.gd`, section at the end | `Fx.spikes(parent, cell)`: nine cones shoot up out of the trap and sink back (CPUParticles3D, one cached `CylinderMesh` cone, the shared Fx material) |
| Looks | `tools/make_atlas.gd`, `tools/make_realistic_atlas.py`, `world/block_library.gd` | Door (planks top and bottom), open door (cut-out frame), spike trap (warning stripes), lantern (glow material) in both styles; the open door has no collision in the terrain's physics |
| Palette | `data/blocks/block_ids.gd`, `ui/hud/block_palette.gd` | DOOR, SPIKE_TRAP, LANTERN join `PLACEABLE`; the block grid widens to keep at most 3 rows (`block_columns()`) |
| Trader | `core/economy/shop_rules.gd` | Doors come in pairs (`PACKS`, "×2" on the card, "You got 2 Doors!"); lantern 5 and spike trap 15 were already priced by Task 7 |
| Sounds | `tools/make_defense_sfx.py`, `autoloads/audio.gd` | `door_open` (latch click and a short creak), `door_close` (a soft knock and a click), `spikes` (a metal shing); original work, credited |
| Wiring | `scenes/sandbox.gd` (a line in `_ready`, one in `_start_host_or_solo`, section at the end) | Closures over the world; `block_changed` feeds the index on the host; a guest's index looks again every 2 s; Low graphics has no lantern lights |
| Smoke run | `tools/defense_smoke.gd` (+ `_steps`) | Real terrain and voxel collision: a pen with a doorway, monsters of every level kept after the player, a pit trap, a lantern, the costs |

## Tests (RED → GREEN)

Suite: **1321 → 1390** passing (140 → 146 scripts; `tests/run_tests.sh` exit 0, "All tests passed").

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_defense_rules.gd` | 16 | parse error: `DefenseRules` not declared |
| `tests/unit/test_block_library.gd` (+4) | own tiles, lantern glows, open door is a cut-out frame with no collision (also no mesh collision), warning stripes in both styles | tiles were Task 1's placeholders; atlas tiles empty (alpha 0); opaque material; later `is_mesh_collision_enabled` true |
| `tests/unit/test_block_ids.gd` (+1, size 23 → 26) | defense blocks placeable, the open door never picked | not in `PLACEABLE` |
| `tests/integration/test_block_palette.gd` (+1) | the blocks take at most 3 rows | 4 rows: the panel reached 10 px above the screen and 8 px into the hotbar |
| `tests/integration/test_doors.gd` | 16 | `request_door` missing; a tap placed a plank against the door. (Hold-to-break passed at once: a guard.) |
| `tests/integration/test_door_saves.gd` | 2 | Save round trip passed at once (block ids persist: a guard). Physics: an open door stopped a ray across real terrain |
| `tests/unit/test_defense_sounds.gd` | 2 | sounds not registered, no credit |
| `tests/integration/test_monster_defenses.gd` | 8 | with only `Monster.lanterns` added: every monster climbed a single closed door into the house (deepest x 8.49 against the door at 5); weak monsters walked up to the lantern (0.66 blocks); a slime stayed next to a new lantern. The two-door doorway, the open door and "never changes a door" passed at once (physics; guards). Night spawns 8 blocks from lanterns passed at once (Task 4's rule; mutation: blinding the spawner to lanterns makes it fail) |
| `tests/integration/test_defense_director.gd` | 17 | parse error: `DefenseDirector` not declared; mutation checks (no scan budget, no "loaded" check, a stab every tick) made 3 tests fail. The trap-placed-under-a-still-monster test guards the feet memo (added later): without its reset on `note_block`, it fails |
| `tests/unit/test_shop_rules.gd` (+1, 1 changed), `tests/integration/test_shop_panel.gd` (+1) | doors in pairs, "You got 2 Doors!" | amount 1; "You got 2 Door!" |

## Smoke run (headless, real terrain)

`XDG_DATA_HOME=<fresh private dir with "smoke" and a copy of profile.json> godot --headless --path . --script res://tools/defense_smoke.gd`
→ `DEFENSE_SMOKE result fails=0`, 17 checks: the host opens and closes a doorway of two doors; 10
monsters (goblins and slimes, levels 1-5) kept after the player for 12 s never got into the closed
doorway (deepest 0.18 short of the door's face) and the door stayed closed; opened, they came in within
0.5 s; a level-5 goblin in a pit trap lost 6 HP in 3 s; a level-1 slime next to a new lantern walked
6.0 blocks away in 5.4 s and knew the lantern from the index; a light sat on the lantern; a level-3
goblin was never told about lanterns.

**The smoke run found a real bug the unit tests could not**: the first run's monsters never came in
through the *open* door. They pressed on the doorway's face exactly half their width away. The terrain's
physics comes from mesh surfaces with collision on (`VoxelBlockyModel.collision_enabled_0`), while
`collision_aabbs = []` only affects Voxel Tools' own box queries. A physics-ray probe on real terrain
showed rays stopping at the open door, the bush and water. Fixed for the open door (and the bush, which
shares that branch; it is meant to be walked into) with `set_mesh_collision_enabled(0, false)`, RED
first (`42ab615`).

## Measurements (desktop, busy shared PC: load average in brackets)

| What | Result |
|---|---|
| A lantern look as one box copy (the Task 4 way) on settled terrain (a scratch benchmark, not committed: 200 looks, `copy_box` + `MonsterDirector.find_blocks`, 6 lanterns placed) | radius 8 (4 913 cells) 0.021 ms, radius 12 (15 625 cells) 0.072 ms [46] |
| The same while the terrain around was still streaming | radius 8: **19.3 ms average, 202 ms worst**; radius 12: 12.2 ms average [42]. The copy waits on the voxel threads |
| Defense tick, 20 monsters (8 weak), index warm, first version | 265-321 µs a tick [36-40]: trap checks 78 µs (2 voxel reads each), lantern lookups 224 µs (28 µs each, mostly sorting chunks) |
| Sort chunks only when one must be copied; each weak monster told every 0.3 s, in turn | 259 µs a tick [31]; a lookup 16 µs |
| What is under a monster's feet read again only when it changes cells (cleared when a trap is placed or broken); nothing counted for a monster off the traps | **83 µs a tick, worst 93 µs** [25-30], so about 0.8 ms a second at 10 ticks a second |
| Index warm-up (a new area) | 16-24 chunks copied, 2.6-18 ms spread over 30 ticks (4 copies a tick at most) |

## Rulings (decided on the owner's behalf; cost if wrong)

1. **A door is one block; a doorway is two doors stacked, and a tap opens or closes the whole stack**
   (at most 3, always holding the tapped door; a half-open stack follows the tapped door). One item is one
   cell, so placing, breaking, undo, stamps, mirror, the pickup bag and Survivor counting all stay as they
   are. *Cost if wrong:* a child who places one door sees a one-block door and has to put a second on
   top; a real 2-tall door needs a door-top block id and per-door accounting (duplication risks in
   Survivor).
2. **Tilly sells doors in pairs**: ×2 for 10 gold, so the spec's "door 10" buys a doorway. *Cost if
   wrong:* a child who wants one door gets two; one line (`ShopRules.PACKS`).
3. **A tap on a door toggles it whatever is in the hand** (block, sword, pickaxe, wand), after the pickup
   bag and Tilly; a creature standing in front takes the tap (so a sword hits the goblin at the door); a
   hold still breaks the door. *Cost if wrong:* a block can't be placed against a door's face (place it
   on the wall beside it).
4. **Opening never checks bodies** (it traps nobody, so a child leaning on the door can open it);
   **closing is refused on a player** ("Someone is standing there!"), **a bot friend that is up**, or **a
   monster** ("A monster is in the doorway!"; its size box shrunk by 0.05, so touching is not "in").
   Animals are not checked. *Cost if wrong:* a pet in a closing doorway is pushed out by the physics,
   perhaps to the other side.
5. **A toggle is an edit**: the host's own world decides the stack, the change goes through the
   Survivor ledger (a toggle gives the door back and uses it again: nothing counted, even with no doors
   owned) and makes one undo step. An undo of a toggle is a normal edit (it can wait if someone stands in
   the doorway). A LAN guest only sends the tapped cell. *Cost if wrong:* none known.
6. **Monsters never step up onto or hop over a closed door** at their feet (the goblin's step hop, the
   slime's hop); they never open one. A goblin pushes against a closed door, a slime waits in front of
   it. *Cost if wrong:* monsters look like they bang on doors instead of giving up; Tasks 5 and 18 may
   make them search elsewhere. A door higher up is part of a wall like any block.
7. **The open door is a cut-out frame** (both posts and the door leaf seen edge-on, no facing), non-solid,
   with no collision in the terrain's physics. *Cost if wrong:* cosmetic; an oriented leaf needs a mesh
   model and a facing per door.
8. **The spike trap is a full solid block** with spikes drawn on top: put it in the floor (monsters walk
   over it) or on it (they climb onto it); either way "on or in" counts (the cell under the feet, or the
   feet's own cell when a trap was placed on a monster). *Cost if wrong:* a low plate is one line
   (`m.height`), and the on-or-in rule already covers it.
9. **Stabs: 2 damage once a second from the first step** (`take_hit(2, trap top, ZERO)` as the task
   says); the wait keeps running off the trap, so hopping on and off never hurts faster. `take_hit` makes
   the monster turn on the player nearest the trap (within 4 blocks). A trap defeat drops coins like
   any defeat. Any node in group `monsters` with `take_hit` is stabbed (waves and the Golem too).
   *Cost if wrong:* a trap next to the house wakes the monster up to the player inside.
10. **The spikes pop on every stab**, not only the first step (the sound too, 4 dB softer). *Cost if
    wrong:* cosmetic.
11. **Only LANTERN scares monsters** (LIGHT blocks and crystals do not; LIGHT still stops night spawns,
    Task 4's ruling). Otherwise a 5-gold lantern would be worse than light blocks at 4 for 1 gold.
    *Cost if wrong:* one list.
12. **"Within 6 blocks" is 3D, from the lantern cell's middle to the monster's feet.** A weak monster
    stops before a decision's move (and its stopping distance) would take it closer; one already closer
    walks straight away. A chaser waits at the edge facing its target. *Cost if wrong:* numbers to tune
    (`DefenseRules.LANTERN_KEEP_AWAY`).
13. **The lantern index** (see Measurements): 16-block chunks copied once when loaded, at most 4 copies
    a tick (and 4 a light look), nearest first, never before the chunk is loaded; the host updates it
    from `WorldService.block_changed`; a guest's world does not announce edits, so its chunks are looked
    at again after 2 s; the index forgets everything past 1024 chunks. Weak monsters get their list (8
    blocks) every 0.3 s in turn. *Cost if wrong:* a lantern placed by a guest lights up to 2 s late on
    other guests; a monster in a chunk not copied yet does not know its lanterns for a few ticks (spawns
    never happen within 8 of one anyway).
14. **Light: 2 shared shadowless OmniLight3D** (warm, range 7, energy 1.6, 35% of that by day) on the
    lanterns nearest the camera within 12 blocks, moved every 0.5 s; none on the Low preset; every
    lantern glows through its unshaded tile anyway. Never a light per lantern: on the emulator's GL
    renderer each light is another pass over every mesh it touches. Precedent: Ambience's cave lantern is
    the same kind of light. *Cost if wrong:* with 3+ lanterns near, only 2 light the ground; if 2 lights
    cost too much on the emulator, `DefenseDirector.MAX_LIGHTS` 1 (or 0).
15. **The palette's block grid widens instead of growing a 4th row** (`MAX_BLOCK_ROWS` 3): 26 blocks are
    9 columns, with Task 5's three 10 columns. *Cost if wrong:* cosmetic.

## Skills and patterns

- `godot-prompter:ai-navigation`: chose **steering on top of the existing chase** (a flee direction away
  from a lantern, a stop at its edge, doors as obstacles the step and hop respect). Rejected
  NavigationAgent3D and a baked navmesh: the world is edited all the time and baking costs.
- `godot-prompter:multiplayer-basics`: **client → host `any_peer` reliable request carrying only the
  tapped cell**; the host decides the new state from its world and answers with an `authority`,
  `call_local` event (the sound). Rejected letting the guest send "set DOOR_OPEN here" (a stale guest
  could place an open door into air).
- `godot-prompter:particles-vfx`: **CPUParticles3D, one-shot, POINTS emission**, one cached mesh and the
  shared Fx material. Rejected GPUParticles3D (a new process-material shader to compile, a hitch on the
  emulator's GL renderer).
- `godot-prompter:3d-essentials`: **an emissive (unshaded) tile plus a small pool of shadowless
  OmniLight3D**. Rejected the per-lantern dynamic light recipe (cost grows with lanterns).

## What to check on the emulator (the lead)

1. Sandbox palette: Door, Spike Trap, Lantern (9 columns; 10 after Task 5); icons read; the panel stays
   above the hotbar.
2. Build a 2-high doorway of two doors in a wall. A tap opens both (creak), a tap closes both (knock),
   also with the sword or pickaxe in hand; a hold breaks one. **Walk through the open doorway** (the
   collision fix); a closed door stops you. Both styles: the door, the open frame, the trap and the
   glowing lantern.
3. Stand in the open doorway and close it: "Someone is standing there!". `/time night`,
   `/summon goblin 1` outside a closed door: it pushes against it and never gets in; open it and it
   comes in; with it in the doorway: "A monster is in the doorway!".
4. Put a spike trap in the floor where a goblin walks: spikes pop, its health bar drops 2 a second,
   confetti (and coins in Survivor).
5. At night a lantern lights the ground around it (warm) in both styles; `/summon slime 1` next to it:
   it hops away to about 6 blocks; `/summon goblin 3` walks right past it.
6. Survivor: Tilly's HOME tab shows the door card ×2 for 10, lantern 5, spike trap 15; bought things
   are in the palette with counts; placing uses one, breaking gives it back; opening a door costs
   nothing.
7. Performance: the autopilot at night with lanterns near the path (2 lights on the GL renderer), both
   styles; watch for a hitch at the first spike pop (shared material, should be none).
8. LAN: a guest's tap opens the host's door; both hear it; the guest sees the lantern light.
9. The Low preset: no lantern lights, lanterns still glow.

## Merge notes

- Shared files, each with a line or two and a section at the end: `autoloads/session.gd`,
  `entities/player/block_interactor.gd`, `entities/monsters/monster.gd` (three hook lines: in `_decide`
  before `_keep_safe()`, the goblin's hop in `_walk_step`, the slime's hop in `_hop_step`),
  `scenes/sandbox.gd`, `entities/fx/fx.gd`, `autoloads/audio.gd` (three `SOUNDS` lines).
  `world/block_library.gd`: the TILES lines, the `DOOR_OPEN, BUSH` branch (now `cutout` for both and no
  mesh collision) and `LANTERN` with the glow branch.
- **Atlases are binary**: after merging the scripts with Task 5's and Task 16's, run
  `godot --headless --path . --script res://tools/make_atlas.gd`, then
  `python3 tools/make_realistic_atlas.py`, then `godot --headless --path . --import`. My tiles use their
  own RNGs, so the order of the tasks' blocks in the scripts does not matter.
- `tests/unit/test_block_ids.gd` expects 26 placeable blocks; with Task 5 it is 29.
- Task 18 (creature minds): keep `_mind_defenses()` right before `_keep_safe()` if `_decide` changes;
  lantern fear and doors are hard rules, not something a mind learns around.
- Task 5 (stealth): "near a lantern" visibility can ask `DefenseDirector.lanterns_near(pos, radius)`
  (the index) instead of copying boxes; the bush now has no terrain physics too.

## Found, not from this task

- **Water may be solid to the terrain's physics.** The same physics-ray probe on real terrain stopped
  at a placed water block (and leaves, which are solid by design). Water has `collision_aabbs = []` but
  its mesh collision is on. If a player can't walk into placed or natural water on the emulator, the
  fix is `m.set_mesh_collision_enabled(0, false)` in the WATER branch of `BlockLibrary.build`. I did
  not check swimming on real terrain; Task 14's tests use collision boxes.
- Task 4's spawn light check copies a 17³ box per spawn candidate (up to 8 a second at night). While
  terrain streams, such a copy took 19 ms on average in my benchmark; the lantern index could serve it
  (with LIGHT blocks added).
