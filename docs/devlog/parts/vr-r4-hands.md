# VR round 4, VR-HANDS: hands that hold things, bricks laid by hand, waves and high-fives, the Build Table, the Giant's Table (owner #110, #116)

The owner (2026-10-16 11:24, #110): "in vr mode we should have hands and be able to hendle items using vr joysticks";
and (15:04, #116, relayed by the lead): "using vr it should be possible to build a house for example like in real world,
take brick or stones and put in apropriate place and etc like in real life". The plan:
`docs/superpowers/plans/2026-10-16-vr-round4.md` (the VR-HANDS row, the frozen contract `9fb0c96e`); the research:
`docs/devlog/parts/vr-ideas-research.md` (§1, §5.3 task 0 and ideas 3, 5, 6, §6, §7's rulings R1-R12). #116 overrides
R5 for the world itself, as R5's own cost-if-wrong foresaw. This agent is **VR-HANDS**, in the worktree branch
`worktree-agent-a43a958b255c3cd5b` cut from `lead-merge` at `df69e2e1`, beside VR-SOUND and Life L1 (none of their files
touched). No editor, no emulator, no adb, no download. Logs: the session scratchpad's `vrhands_*`.

The frozen contract is untouched: `VrGrabbable`'s exports, signals and `held_by()`; `VrGrabRules`' names and numbers
(its body adds new names only); `Vr.haptic(side, amplitude, seconds, frequency := 0.0)`. The grabber is generic: Life's
coins, cloths and extinguishers, VR-WONDER's planets and lenses, VR-SOUND's mallets add a `VrGrabbable` and listen.

## What a child does in the headset

- **Take things (task 0).** A hand near something it can take makes it glow with a soft tick; the grip takes it (the
  mitten closes). Something far away under the laser glows; the grip locks it; a flick of the wrist (towards the head or
  up) or simply keeping the grip squeezed for 0.6 s flies it into the hand on a little arc. Let go with a small flick: it
  flies 1.5 times as fast (capped at 12 m/s). Over the shoulder a thing goes into its bag. Two hands on a two-hand thing
  stretch it. While a hand holds something its trigger is that thing's (VR-WONDER's lens zoom, a mallet), never a block's.
  A pickup bag in Survivor is taken by the hand (near, or pulled in by the laser): the host decides as for a tap.
  The hand's picture stops at a block's face (it never goes into a wall), with a faint outline where the real hand is.
- **Build a house like in real life (#116).** Reach over the shoulder and squeeze: the selected block comes out of the
  bag as a brick-sized block in the hand (its own texture; a tool there opens BLOCKS instead). Or squeeze at a slot of the
  hotbar on the other wrist: that block. Or press the hand on a wall and squeeze: that block comes out (Survivor: its drop,
  into the bag). Carry it: a life-size see-through ghost shows the cell it goes into, flush against the face the brick
  touches, only where a block may go (touching a block or the ground, never in a player, in reach). Let go: it is laid
  with a soft click (the laser's own place: one undo, Survivor's bag, online through the host). A wall goes up row by row.
  In the air, let go: it goes back to the bag. Higher than the arm: the laser, as before.
- **The wrist hotbar.** Touch a slot on the other wrist with the index finger: it is picked (a little buzz).
- **Wave and high-five (idea 3).** Raise a hand and wave: buddies near wave back, the nearest animals look up, bot
  friends wave; the nearest buddy holds up a glowing paw for 6 s: slap it for a high-five (a pop, sparkles, both
  controllers buzz, the buddy cheers). A friend in VR holding up a hand: slap it: both games clap. Buddies' googly eyes
  look at the child's eyes within 8 m. Nobody's hands or body come into a child's face (the 0.5 m bubble).
- **The Build Table (idea 5).** MORE → BUILD TABLE: a table at hand height in front, a 16 × 16 grid of 10 cm cells.
  Point the hand at it: a ghost cube snaps under the fingers; pull the trigger: the selected block is placed with a click;
  hold the trigger on a block: it breaks. MIRROR (MORE) mirrors across the middle. One hand on the rim slides and lifts
  the table (it stays at hand height); two hands on the rim twist the build round in quarter turns. Poke the buttons on
  its front edge: SAVE STAMP (it joins My Stamps, then is placed in the world like any stamp), WAKE IT (the build appears
  two blocks in front in the world and the wand wakes it: a little dog built in the hands walks beside the child), CLEAR,
  CLOSE. In the School, a "build the answer" round's board becomes the table by itself (a wall, a farm from above): build
  the answer with the hands and press CHECK on the panel as before.
- **The Giant's Table (idea 6), the Sandbox only.** MORE → MODEL VIEW: a blink, and the child is a giant 25 times their
  size standing on their own world: the land round them (40 blocks) a model about 3 m across at their feet, builds and
  animals tiny and alive; walk round it in the room. Their own body stands small in it with a glowing figure: pull it up
  with the laser (or take it) and put it down somewhere else: a green ring where they may go (red where not); let go on
  green: black, and they are there at their own size. Two hands twist the world round in 45° steps. MORE → MODEL VIEW
  again: back where they stood.

## How it is built

| What | Where |
|---|---|
| The grab: near and far picks, the lock and pull, holds, throws, two hands, the bag; claimers for other grips | `entities/vr/vr_grabber.gd` (`VrGrabber`, `Vr.grabber`), `core/vr/vr_grab_rules.gd` (body), `entities/vr/vr_grabbable.gd` (body: `GROUP`, `radius`, `follows_hand`, `enabled`, `stretch`, `thing()`, `takeable()`) |
| The grip's two jobs (R1): VrInput asks the grabber first | `entities/vr/vr_input.gd` (`_grip_to_hands`), `Vr.hand_busy(side)` |
| The hand stopped at a block's face, its outline; the fingertip | `entities/vr/vr_hand_model.gd` (`follow`, `stop_at_face`, `ghost_shown`, `fingertip`) |
| Bricks laid by hand (#116), the wrist hotbar's touch | `entities/vr/vr_bricks.gd` (`VrBricks`, `Vr.bricks`), `core/vr/vr_brick_rules.gd`; `BlockInteractor.place_block` / `break_block` (the tap's own tails) |
| Waves, high-fives, eyes; the bubble | `entities/vr/vr_gestures.gd` (`Vr.gestures`), `core/vr/vr_gesture_rules.gd`; `VrBody._bubble`, `Player.vr_bubbled()`, `Buddy.look_target` |
| The Build Table | `entities/vr/vr_build_table.gd` (`Vr.build_table`, `Vr.open_build_table`), `core/building/build_table_rules.gd` |
| MODEL VIEW | `entities/vr/vr_model_view.gd` (`Vr.model_view`, `Vr.toggle_model_view`, `Vr.body_waits`), `core/vr/model_view_rules.gd` |
| MORE → BUILD TABLE, MODEL VIEW (VR only) | `autoloads/vr.gd` (`_step_more_buttons`), `ui/hud/hud_icons.gd` (`&"table"`, `&"model"`) |
| Panels, tray and wrist for the world scale | `entities/vr/vr_panel.gd` (`scaled_round_head`), `entities/vr/vr_wrist.gd` |
| The bench | `tools/vr_hands_bench.gd`, `tools/vr_hands_bench_steps.gd` |

Per frame (`Vr.step`): VrInput (the grips' presses go to `VrGrabber.claim` / `let_go`), the grabber, the hands'
pictures, the bricks, the gestures, the Build Table, MODEL VIEW, the MORE buttons. Off VR none of these exist; every
`Vr` call stays a no-op. The grip's order when it goes down: a grabbable near the hand, then one under the laser, then
the claimers in order (the Build Table's rim, the bricks, MODEL VIEW's twist), else the hotbar's step as before.

## Rulings (the cost if wrong)

- **RH1 (R1 extended): the grip's order** above. [A child who meant to step the hotbar with a hand on a wall takes a
  block out of it: `VrBrickRules.FACE_REACH` (5 cm) smaller, or the hotbar only on the wrist.]
- **RH2: only the pointing hand pulls far things** (its laser is the one drawn). [The other hand can't pull: an off-hand
  laser while its grip is half pressed.]
- **RH3: the world's own things a hand takes are pickup bags** (asked of the host as a tap, never moved on this game
  alone); everything else comes from the agents who make it (Life's coins, VR-WONDER's planets). A RigidBody3D grabbable
  is thrown by physics; anything else hears `released` and decides. [Little to throw in the world until those land.]
- **RH4: the shoulder bag** takes a held thing whose node has `vr_into_bag(side)`; an empty hand there takes the selected
  block as a brick (a tool there opens BLOCKS, Y's palette). [Children expect the palette every time: it is Y anyway.]
- **RH5 (#116): a brick's ghost** is the cell it is in when that touches a block or the ground; pushed into a block, the
  cell before the face it went through; else none. The laser's own checks on this game (air or water, in reach, never in
  a player) and the host's again. Blocks have no turn of their own in this game, so the ghost is the grid's cube. A brick
  let go off a ghost goes back to the bag: bricks are laid, never thrown. [A child who wants to toss a brick onto a wall:
  a throw-to-place along the throw velocity.]
- **RH6 (#116): a block out of a wall** is the laser's break through the host (instant, Survivor's pickaxe gate and drop
  into the bag); the hand shows the drop at once; a guest's brick waits up to 1 s for the host and goes if the block is
  still there. [A guest sees a brick vanish when the host refuses.]
- **RH7 (#116): Survivor** takes a brick from the bag only with one there (else a short buzz; the slot is faded already).
- **RH8: the wrist hotbar's slots** are VR-UI's strip as drawn (2.5 cm a slot at 0.0004 m/px), the nearest slot along
  the row; a touch within 2 cm, a grip within 6 cm, only by the pointing hand. Meta asks 22 mm targets with 12 mm gaps:
  a headset check. [Mis-picks: a bigger strip while the other hand is near.]
- **RH9 (R2): the hand's picture stops at the first face** on the way from its last free point (the voxels' own ray,
  GridRay: no physics query, so it works with the physics thread), with a faint sphere where the real hand is past 3 cm.
  [The hand sticks where it went in instead of sliding along the wall: a slide along the face.]
- **RH10: a VR wave plays no avatar emote** (friends already see the real hand through VrPoseLink) and teaches no trick;
  its answers are this game's own (buddies' `wave`, the three nearest animals' `cheer`, bot friends' wave emote). [The
  owner wants waves to teach tricks: `Player.play_emote(&"wave")` on a wave.]
- **RH11: the paw** is held up by the nearest buddy within 4 m for 6 s (a following buddy waits 3.5 m away: time to walk
  over). [A paw out of reach: the buddy hops over first.]
- **RH12: a high-five with a friend rides on the VR pose** as one spare byte after VrPoseRules' 21 (a clap count), only
  once there was one; no new RPC: Godot numbers a node's RPCs by their sorted names, so a new method on VrPoseLink would
  shift `_listen` and `_pose` for every older build. [A lost pose packet: the count comes with the next one, at most the
  1 s keepalive later.]
- **RH13 (R8): the bubble:** another player's hands shrink from 0.65 m and vanish inside 0.5 m of the child's head; a
  body whose eyes come inside 0.5 m is not drawn on this game. [A friend standing very close blinks out: R8's 0.4 m.]
- **RH14: eyes look, bodies don't turn** (a buddy's body is the host's; turning it here would fight the sync); animals'
  heads don't look yet (Animal has no head-look). [Next: a yaw-only head turn in Animal.]
- **RH15 (idea 5): the table stays in the world where it opened** (walk round it; BUILD TABLE again brings it in front),
  16 × 16 cells of 10 cm (1.6 m): the far half is reached by turning the build (two hands) or sliding the table (one).
  [Too big for a child's reach: `BuildTableRules.SIDE` 12.]
- **RH16: a table block stands on the table or on another** (as bricks); a School board's cell anywhere on its board.
- **RH17: SAVE STAMP's front** is the table's near side; **WAKE IT** builds the stamp two blocks ahead of the feet facing
  the child (one edit through the host: Survivor's bag pays, a stamp replaces what is there) and asks the host's wand on
  its first block (the reach, the buddy cap). [A hill in front gets the build half inside it: the first free row.]
- **RH18: the School's board becomes the table by itself** when a BuildBoard comes into the VR canvas; the panel keeps
  CLEAR and CHECK; the table's own buttons hide; it closes with the board. The exercise data and BuildCheck are unchanged
  (the seam is BuildBoard's own `paint`, `cells`, `changed`). [A child who wants the old tapping: the panel still takes
  the laser's taps.]
- **RH19 (idea 6, R6): MODEL VIEW** is the Sandbox's (the MORE button hides elsewhere), 25 times the child's size, the
  origin on a still spot at the feet with the real floor as the ground (`VrRig.real_height` meanwhile), the body frozen
  (no walking, no buttons but the menu and MORE, no room-scale step), the model cut round at 40 blocks by the head's far
  plane (125 draws looking down without it), the figure dropped where TeleportRules' reasons allow except its distance
  and sight (anywhere on the model). Stamps from the model are not built: the host's batch reach (32 blocks) refuses far
  ones. [Stamps wanted there: a host request for a model-view stamp.]
- **RH20: the VR panel, the tray and the wrist strips scale with the world scale** (MODEL VIEW's panel was between a
  giant's eyes; Size Magic's GIANT gets the same). [VR-UI's GIANT look changed: bigger in the world, the same to the eye.]
- **RH21 (follow-up a): a tap waits for the physics step only while the physics has its own thread** (the project
  setting, `BlockInteractor.physics_threaded()`); off it nothing changes, at once as before.

## VR P5's follow-ups

**(a) The ray queries in the physics step.** Every ray of `BlockInteractor` (the animal, buddy, hittable, bag and
befriend rays) and `SecretTaps` goes through `BlockInteractor.space_ray(query)`; a tap that may read the space runs
through `in_space(tap, done)`: at once when the space can be read (the physics on the main thread: phones, the web, the
desktop), else in the next `_physics_process` (VrInput's trigger, and `_unhandled_input`'s keys and buttons). Tests:
`test_vr_r4_hands_space.gd` (with a test's `BlockInteractor.physics_thread = 1`: no ray outside the step, the tap runs in
it, its buzz heard then; `0` and the project's own setting: at once, as before). **Measured with the real thread** (an
`override.cfg` with `physics/3d/run_on_separate_thread=true` in a scratch run, `tools/vr_hands_bench.gd -- --taps`,
Green Meadows through the preview, every phase): 40 world taps through `in_space` and the whole session (play, the
table, a brick, MODEL VIEW): **no "Space state is inaccessible"** but the one control tap made the old way from
`_process` on purpose (it logged the engine's error, plus `VehicleDirector.tap_at_screen`'s own direct ray, which is
reached only through `place_at_screen`, so `in_space` covers it in VR). **With 32-cube terrain blocks again** (the `vr`
preset's `mesh_block` 32, a scratch change, put back): play **52 draws (98 with 16-cube blocks), looking down 55 (100),
the Build Table 58 (102), MODEL VIEW 51 (92)**: −46, P5's "about −45". **So yes: 32-cube blocks can come back in VR**
once the lead sets `physics/3d/run_on_separate_thread.quest=true` in `project.godot` and `mesh_block` 32 in the `vr` and
`vr_plus` presets (`core/rules/graphics_preset.gd`, P5's lines 37 and 45), measured on the headset (P5's collision
spikes: 0 long frames walking with the thread on this desktop). Other direct `intersect_ray` users: `world/vehicle_director.gd:662`
(covered as said), `tools/smart_smoke_steps.gd` (a tool) and tests.

**(b) The VR_BENCH line** prints `vr_preset=vr|vr_plus` (`VrBench.preset_name`: the headset's VR preset in a session, the
child's own off one) and `draws_3d=` (every viewport's 3D and shadow draws) / `draws_2d=` (the canvases') beside
`draws=` (`VrBench.draw_split`, the viewports read once a line). `test_vr_r4_hands_bench.gd`.

## Draws beside P5's budget (at most 100 in play)

`tools/vr_hands_bench.gd` (the VR preview on the Quest APK's platform, the `vr` preset, Green Meadows NEW seed 12345,
6 s a phase; the frame rates are this desktop's, never a Quest's):

| Phase | draws (average) | most | scene (3D) | canvas |
|---|---|---|---|---|
| playing, looking ahead | 98.2 | 101 | 76.0 | 22.1 |
| playing, looking down at the hands | 99.8 | 100 | 77.8 | 22.0 |
| the Build Table open with a little house (6 × 6, 52 blocks) | 102.0 | 102 | 80.0 | 22.0 |
| a brick in the hand (its ghost when on a cell) | 100.0 | 100 | 78.0 | 22.0 |
| MODEL VIEW, looking down at the model | 92.0 | 92 | 70.0 | 22.0 |

The table is +2 (its frame and its blocks; the first build was +7: four Label3D words, a MultiMesh, a textured top);
a brick +1 and its ghost +1 while it shows; the paw +1 for its 6 s; a hover's glow +1; MODEL VIEW draws fewer than
playing (the head's far plane cuts the land at 40 blocks; uncut it drew 125). Green Meadows alone sits at P5's
100 here; the 16-cube blocks are P5-1's price, which 32-cube blocks with the physics thread give back (above: 52-58).

## What only the Quest 3 can check (the lead, on the owner's headset)

- A grab feels sure: the glow and the tick, the far pull's catch at the hand, the flick for a child's small wrist
  (1.2 m/s), the 0.6 s hold; the throw's strength (×1.5).
- The hand stopped at a wall without feeling stuck; the outline readable, never scary.
- Bricks: the ghost settles where the hand expects, a wall row by row standing in front of it, the soft click; pulling a
  block out of a wall never happens by accident (FACE_REACH 5 cm); the brick's size (12 cm) in the hand.
- The wrist hotbar's 2.5 cm slots: picked by the fingertip and by the grip without mis-picks.
- A wave is heard (and nothing else is: laying bricks overhead), the paw's place and the slap, the clap's sound and buzz
  (both controllers), a friend's high-five on both headsets; the bubble's shrink at 0.5-0.65 m.
- The Build Table: its height, its reach (1.6 m), the ghost's snap, the words on the buttons readable lying flat
  (TextMesh, 2.9 cm letters), the poke's depth, the rim's slide and the two-hand quarter turn.
- MODEL VIEW: the scale (fog, sky and the cut edge look right at 25), the blinks calm, the floor where the real floor
  is, the figure pulled up and the ring's green and red, the 45° twist; the panel and the wrist at a giant's size.
- The physics thread with 32-cube blocks on the headset: no long frames walking, every tap works.

## Tests

`tests/unit/test_vr_r4_hands_grab_rules.gd`, `_brick_rules`, `_gesture_rules`, `_table_rules`, `_model_rules`,
`_bench`; `tests/integration/test_vr_r4_hands_space.gd` (follow-up a), `_grab` (a near grab, R1's hotbar, a flick, the
hold, a throw, a two-hand stretch, the bag, the trigger, the hand at a face, a pickup bag, off VR), `_bricks` (#116: take
from the bag, the ghost, lay it with one undo, the air, a wall row by row, out of a wall, Survivor's drop, the hotbar
when nothing is there, a tool opens BLOCKS, off VR), `_wrist` (the touch and the grip), `_gestures` (a wave, the paw's
high-five, a friend's high-five on the pose, a friend's clap heard, the bubble, the eyes, off VR), `_table` (MORE in VR
only, the placing, the support, a hold's break, the two-hand turn, the lift, SAVE STAMP, WAKE IT, the poke, the School's
board, off VR), `_model` (the giant, the body waits, the Sandbox only, the figure's good and bad drops, the laser's pull,
the twist, MORE again, off VR). Every VR test (`tests/**/test_vr_*.gd`): 406/406 at the end.

**The full suite** (once, at the end, `tests/run_tests.sh`, log `vrhands_full.log`): **10473 tests, 10467 passing, 3
failing, 3 risky or pending** (the same 3 as P5's, none of this branch's). The 3 failing: (1) `test_shader_warmup_sources.gd`'s
census wanted this branch's six new VR scripts listed: listed (rare, VR only, as `vr_comfort.gd`), 3/3 since (`b8425755`);
(2, 3) `test_assets_pack_load.gd`'s two strip tests: this agent's shell had a Claude plugin's `python3` PATH shim that
refuses bare `python3` (the test runs `tools/pck_tool.py` through `OS.execute("python3", …)`): with a plain PATH it is
5/5, nothing of the game's. Three small changes came after the run's start, each with its own files' tests green:
MODEL VIEW's clean start (`1bf75938`, 10/10), a brick taken back out (`89d4303f`, 10/10), the census entries.
