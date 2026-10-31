# M1b review minors M8 and M12: cached per-frame work, a guest's pets when the guest leaves

Two deferred minors from the M1b whole-branch review (Task 15), fixed test-first in a worktree on a
branch cut from `m1b-underground` (2026-09-24). No editor or emulator use; the lead verifies on the
emulator. Godot ran only after the lead's quiet-emulator lock was lifted.

**Suite:** 513 tests before, 524 after. `tests/run_tests.sh` exited 0 before each commit
(513 → 516 → 517 → 524).

## Scope change (from the lead, mid-task)

The lead found on the emulator that animals are the main M1b frame-time regression: each
`Animal._physics_process` costs about 0.7 ms per physics step on the desktop, and 20 animals caused
spikes and a physics-step spiral up to 150 ms frames. The lead is reworking the animal simulation cost
in `entities/animal/animal.gd` (activity by distance, throttled AI checks, skipping `move_and_slide`
when idle, and the per-frame `players` group queries).

So here:
- **Dropped:** M8's "animals query the `players` group every physics frame". A cached
  `Animal.players_in(tree)` (one lookup per physics frame, keyed on the frame, the group size and the
  validity of the cached nodes) was written and then reverted uncommitted. Its RED test
  (`test_thirty_animals_look_the_players_up_once_per_physics_frame`) was removed with it.
- **Kept:** Ambience write-on-change (M8b), the ON_CHANGE replication modes in `Animal._build` (M8c,
  a 4-line edit), and M12 as small helpers in their own section at the end of `animal.gd`.
  `_physics_process` is not restructured. Its only change is an `else: _come_home()` in the
  fall-out-of-world branch, and `_follow_owner` gains one line (`_note_owner(owner)`).

## M8b: Ambience writes light and fog only when they change

**Before:** `Ambience._apply` wrote the sun energy, four Environment properties (ambient energy, fog
colour, fog begin, fog end), the lantern's energy and range, and the underwater tint on every frame:
8 writes, each a RenderingServer call. In the open air nothing changes between SkyCycle's
once-a-second updates.

**Fix:** a new `_put(target, property, value)` helper compares the new value with the one the object
holds now. It writes only when they differ by at least `EPSILON` (0.001; for colours, per channel).
`Ambience.writes` counts the writes. The `visible` setters already return early when nothing changed,
so they stay direct.

| Test (`tests/integration/test_ambience.gd`, new, real world) | RED | GREEN |
|---|---|---|
| `test_nothing_is_written_again_while_nothing_changes` | failed: `[32] expected to equal [8]` (8 writes per apply; three unchanged moods wrote 24 more) | passes |
| `test_the_cave_mood_reaches_the_sun_the_fog_and_the_lantern` | guard (passes before and after) | passes |
| `test_a_fog_distance_set_elsewhere_is_put_back` | guard | passes |

For RED, the eight writes first moved into a `_put` that always wrote and counted. That step changed
no behaviour, so the test failed on the count, not on a missing name.

## M8c: animal owner, name and sitting are sent only when they change

**Before:** the animal's `MultiplayerSynchronizer` sent `position`, `rotation`, `owner_peer`,
`pet_name` and `sitting` to every client on every network frame (all `REPLICATION_MODE_ALWAYS`).

**Fix:** `owner_peer`, `pet_name` and `sitting` use `REPLICATION_MODE_ON_CHANGE`. They arrive with the
spawn (the spawn flag stays on, so late joiners get them) and after that only when they change, over the
reliable channel. Position and rotation are unchanged (always, unreliable). Host and clients build the
same config in `Animal._build`.

| Test | RED | GREEN |
|---|---|---|
| `test_owner_name_and_sitting_are_sent_only_when_they_change` | failed: `[1] expected to equal [2]` for all three (ALWAYS, not ON_CHANGE) | passes |

## M12: a guest's pets when the guest leaves

**Before:** when a LAN guest left, their pets (`owner_peer` = the guest's peer id) stood still for the
rest of the session. If the ground under them unloaded (the guest's VoxelViewer goes with the guest),
they fell out of the world and stayed frozen below it: the fall rescue only knew how to bring a pet
to its owner. A guest who rejoins gets a new peer id, so the owner never "comes back" in that session.

**What a child sees now:**
- **The pet sits down where it is and waits** for its friend. It wags its tail (pets wag faster) and
  turns to look at players who come close. It keeps its name tag and its collar in the friend's colour.
- **A waiting pet that falls out of the world comes back up next to the world spawn**, the place
  every player knows. It lands on the ground and waits there. Several pets get different spots
  around the spawn column (8 spots in turn), and the spawn column itself stays free for players. If the
  ground at the spawn is not loaded yet (nobody near it), the pet waits below the world, where nobody
  can see it, and comes up as soon as the ground is loaded.
- **If its owner is back** (a player with that peer id), a pet that sat down only to wait stands up and
  follows again. A pet its owner told to sit stays sitting.
- **After a reload** the pet belongs to the host, as before (ruling 15 in `2026-09-23-m1b.md`).

The code is in `entities/animal/animal.gd`, section "Review M12":
- `_note_owner(player)` makes the pet sit and wait while its owner is gone, and stand up when the owner
  is back.
- `_come_home()` handles the fall to the spawn: it picks the spot once and checks each frame whether
  the ground there is loaded (`is_area_ready`). It never runs the spawn search again.

| Test (`tests/integration/test_animal.gd`, fake owner id 99 that no player has) | RED | GREEN |
|---|---|---|
| `test_a_pet_whose_owner_left_sits_down_and_waits_wagging_its_tail` | failed: "it sits down where it is and waits" | passes |
| `test_a_waiting_pet_stands_up_when_its_owner_is_back` | failed (never sat down) | passes |
| `test_a_waiting_pet_that_fell_out_of_the_world_comes_back_at_the_world_spawn` | failed: 55.4 blocks from the spawn, y −69 instead of 10.05, not sitting | passes |
| `test_fallen_pets_come_back_side_by_side` | failed: `[1] expected to equal [3]` spots | passes |
| `test_a_pet_told_to_sit_still_sits_when_its_owner_is_back` | guard | passes |
| `test_a_pet_that_fell_comes_back_to_its_owner` | guard | passes |
| `test_a_wild_animal_that_fell_out_of_the_world_is_gone` | guard | passes |

The tests drive the host's `_physics_process` directly. `FlatWorld` is a `WorldService` test double
(stone below y 10; the test sets the spawn column and whether the ground there is loaded). Guests
are real player scenes named after their peer id, with the VoxelViewer freed. Spec §3b (pets) has one
new line for this behaviour.

## Rulings (decisions made on the owner's behalf)

1. **Ambience compares with the value the object holds, not with a private "last written" copy.**
   `apply_graphics` writes the fog distances directly. Underground, the cave fog then stays the same
   while the Environment holds the open-air value, and a private copy would never write the cave fog
   back (`test_a_fog_distance_set_elsewhere_is_put_back` pins this). SkyCycle already uses the same
   "compare with what the object holds" pattern.
   *Cost if wrong:* 8 property reads per frame. These are plain getters, not RenderingServer calls.
2. **EPSILON 0.001 for Ambience.** A slow change (the day cycle's steps, the lantern fade) is written
   once it adds up to 0.001, which cannot be seen.
   *Cost if wrong:* a final value can sit up to 0.001 away from its target until the next change.
3. **ON_CHANGE sync is reliable and spawn-sent.** A sit/stand or a new owner now arrives reliably,
   once; before, it was sent unreliably every frame.
   *Cost if wrong:* if Godot's delta sync ever skipped a peer (visibility filters could do that, and
   animals use none), that client would show a stale name or pose until the next change.
4. **A pet whose owner left sits and waits; the host does not adopt it at once.** The host may already
   have 3 pets, and the collar would change colour mid-session. Adoption happens at the next reload
   (ruling 15).
   *Cost if wrong:* the host's child cannot take the friend's pet along in this session. A later
   "three pets adopt a waiting pet" rule would fix that and would need spec §3b first.
5. **No grace time before sitting.** Pets are restored after the host player has spawned, and a
   guest's Player node only disappears when the guest leaves, so a missing owner means the owner left.
   *Cost if wrong:* if a future flow briefly removes the owner's Player node, the pet sits for that
   moment and then stands up again.
6. **A fallen waiting pet waits below the world until the ground at the spawn is loaded.** The other
   option was to drop it at once onto the generated surface height. On unloaded ground it would fall
   again (a loop every ~3 s), ignore player builds at the spawn, and could end up inside the top
   block.
   *Cost if wrong:* the pet is "missing" until someone goes near the spawn (the host usually plays
   there). If the world is saved meanwhile, the pet is saved below the world. After a reload it
   belongs to the host, and the existing owner rescue brings it to the host at once.
7. **Fallen pets land on the 8 columns around the spawn, in turn (a static counter), not on the spawn
   column.** Three pets on one column would look like one dog with three name tags, and a player
   spawning there would stand inside a dog (they don't collide).
   *Cost if wrong:* a neighbour column can hold a player's build; `find_standing_y` then puts the pet
   on top of it, as it does for players.

## Found while doing this (not fixed, for the lead)

- **A pet that follows its guest far from the host has no ground on the host.** The host simulates
  animals. Remote players' VoxelViewers on the host set `requires_collisions = false`
  (`Player._ready`), so the host builds no terrain collision near a guest who is far from the host.
  A guest's pet there falls through the ground, and below `FALL_LIMIT_Y` it is teleported back next to
  its owner. That repeats every ~3 s: on the guest's screen the pet sinks into the ground and pops
  back. Wild animals do not spawn there, because `AnimalDirector.is_ready` needs meshed terrain.
  Not verified in a LAN run (no editor or emulator use here). Possible fixes: pets of a far owner
  follow without physics (keep them at the owner's height), or the host builds collision around
  guests (costs meshing time on the host).
- Buddies have the same "owner left" freeze (`Buddy._physics_process` returns when its owner is
  null), outside this task.

## Commits

| Commit | What |
|---|---|
| `dc17491` | perf(ambience): write light, fog and tint only when they change (review M8) |
| `094a9f0` | perf(animals): sync owner, name and sitting only when they change (review M8) |
| `c9e5cb5` | fix(animals): a guest's pets sit and wait when the guest leaves (review M12) |
| (this commit) | docs: these notes and `DEVELOPMENT.md` §9 |
