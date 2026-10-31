# Deferred M1 minors: touch after pause, name filter, giants, LAN undo

Four minors from the M1 final review (listed in `docs/DEVELOPMENT.md` §9), fixed test-first on a
worktree branch cut from `m1b-underground`. No editor or emulator was used: the lead verifies on the
emulator after the merge.

**Where the review's details came from.** The M1 review text is not in the repo (the M1 dev log was
never written down there). It is in the archived review session (`claude-hist search "Scrappy"`,
agent session of 2026-09-23 18:00). The relevant lines:
- "Touch releases are lost while paused. The HUD pauses with the game, so a finger lifted during the
  pause menu is never seen. After resume, a held JUMP/UP action stays pressed, or the classifier fires
  a stray HOLD and breaks a block. Fix: release or reset all touch state when pausing."
- "Innocent names are blocked. Peacock, Whatever, Skillful, Scrappy, Dickens and Tweedle are all
  rejected (verified). The comment at `username_rules.gd:8` says the match is whole words, but `:46`
  matches substrings."
- "Giants don't auto-step and can stay stuck. The 0.65 m step probe (`player.gd:230`) sits inside the
  Giant's 0.9 m radius, so auto-step never fires. `_unstuck` (`:293`) only checks the centre column."
- "Undo gaps on LAN clients. A client's single edit always records an undo entry, even if the host
  rejected it. Cells skipped inside a batch are dropped from its undo."

"No network rate limiting for block edits (M4)" stays open, as planned.

## 1. Touch releases were lost while paused

**Cause.** The HUD pauses with the game. The engine never delivers input to paused nodes, and for
GUI touches it also forgets which control owned the finger (Godot 4.7.2 `viewport.cpp`: a release
for a paused control is dropped and `touch_focus` is erased). So a finger lifted while the pause
menu is open never reached the controls:
- a TouchButton (JUMP/UP, DOWN, ATTACK) kept its action pressed after RESUME;
- the built-in `VirtualJoystick` kept its move actions pressed (the player walked on by itself) and
  kept its `touch_index`, so the next finger on the stick was ignored;
- the look/build area kept the touch, and after RESUME its HOLD timer fired and broke a block.

**Fix.** Pausing lets go of every touch. `NOTIFICATION_PAUSED` reaches every pausable node
synchronously when `get_tree().paused` turns on, so each control handles it itself and no wiring is
needed (any future pause is covered too):
- `TouchButton`: releases its action and emits `released`, exactly like hiding it or lifting the finger.
- `LookBuildArea`: `TouchClassifier.cancel()` forgets the touch without a gesture; the preview clears.
- `Hud`: resets the joystick. `VirtualJoystick` has no reset method; its private `_reset()` runs on
  `NOTIFICATION_RESIZED` (it forgets the finger and releases the four actions), and `Control` itself
  only emits `resized` for it. So the HUD sends `joystick.notification(NOTIFICATION_RESIZED)`.

**Tests** (RED, then GREEN):
- `tests/unit/test_touch_classifier.gd` `test_cancel_forgets_the_touch_without_a_gesture`
  (RED: `cancel` did not exist).
- `tests/integration/test_touch_pause.gd` (new). The real `Hud` lives in its own 1280x720
  `SubViewport`, and touches are pushed into it with `push_input`, so the engine routes them exactly
  as on a phone, including dropping them while paused.
  - `test_a_finger_lifted_while_paused_lets_go_of_the_joystick`: RED "no walking on by itself after
    RESUME" and "the next finger steers again" (move_forward stayed pressed; a new finger was ignored).
  - `test_a_finger_lifted_while_paused_lets_go_of_jump`: RED "JUMP is not held after RESUME".
  - `test_pausing_forgets_a_finger_on_the_look_area`: RED "no late HOLD breaks a block after RESUME".
- Full suite: 513 → 517, all passing.

**Rulings** (each with its cost if wrong):
- *Pausing counts as lifting every finger.* A drawn bow therefore shoots when the game pauses (the
  arrow waits, frozen, until RESUME), like a Minecraft bow that fires when you let go. *Cost if
  wrong:* the owner may prefer that pausing cancels the draw; that is a separate `canceled` signal on
  `TouchButton` connected to a "stop drawing" in `WeaponUser` (about 10 lines).
- *A finger still resting on a control through the pause is not picked up again after RESUME.* The
  child lifts it and touches again (the joystick is dynamic, so it re-centres under the new touch).
  *Cost if wrong:* one extra touch after resuming.
- *The joystick reset uses the engine's resize path.* If a future Godot changes `VirtualJoystick`'s
  resize handling, `test_a_finger_lifted_while_paused_lets_go_of_the_joystick` fails and says so.
  *Cost if wrong:* none silent; the test guards it.

## 2. The name filter blocked "Peacock" and "Scrappy" (the Scunthorpe problem)

**Cause.** `UsernameRules.validate` matched every blocked stem anywhere in the name ("Peacock" has
"cock", "Whatever" "hate", "Skillful" "kill", "Scrappy" "crap", "Dickens" "dick", "Tweedle" "weed").
Its comment claimed whole words.

**Fix.** A short list of innocent words that contain a blocked stem (`INNOCENT_WORDS`: peacock,
whatever, skill, scrap, dickens, tweed, closer, dumbo, dumbledore, cockatoo, chateau, …). Each
innocent word in the name is covered with "|" before the stems are matched, in both the plain and
the l33t-decoded name. A stem inside an innocent word no longer counts; the same stem anywhere else
still does, and the cover can't join letters into a new word.

**Tests** (`tests/unit/test_username_rules.gd`):
- `test_innocent_names_that_contain_a_blocked_word_pass`: RED for all 13 names (Peacock, Whatever,
  Skillful, Scrappy, Dickens, Tweedle, Skyscraper, Closer_7, Cockatoo, Dumbledore, Hitchcock, Sk1llz,
  Chateau), then GREEN.
- `test_real_bad_names_are_still_blocked`: a guard that passed before and after (xxStupidxx,
  iamstupid, BigDick, bigdick, Killer99, k1ll3r, UrDumb, Peacock_dick, SkillKill, Scrap_crap,
  sh1thead, Hitler_1, Whatever_idiot).
- The chat filter (`test_chat_rules.gd`) and name suggester tests share the word list and still pass.
- Full suite: 517 → 519, all passing.

**Rulings:**
- *Innocent-word list instead of word boundaries.* A username has no spaces, so a word-boundary match
  (a stem must start a word) lets run-together bad names through ("bigdick", "iamstupid", "urdumb").
  Only a list of known innocent words can tell "peacock" from "bigdick". The list is "word-aware"
  in that sense. *Cost if wrong:* an innocent name that isn't on the list is still refused. The child
  sees "That name isn't allowed. Try another one!" and picks another. Adding a word is one line
  plus a test name.
- *Some innocent-looking words stay blocked on purpose:* "pussycat" (the stem is too risky for a kids'
  game), "Killua" and "killer" (kill), "Dickie". *Cost if wrong:* a few fan names are refused.
- *An innocent word hides only what is inside it.* "BigDickens" passes (Dickens is innocent). This is
  the price of any allowlist. *Cost if wrong:* a determined child can write a borderline name; the
  owner's M4 account system adds reporting and server-side checks.

## 3. Giants didn't auto-step, and unstuck checked only the centre column

**Cause.** `Player._auto_step` probed for a ledge 0.65 m ahead of the centre, a normal player's
0.3 m radius plus 0.35 m. A giant's radius is 0.9 m, so the probe sat inside its own body, where no
block can be: a giant stopped dead at every 1-block bump. `_unstuck` looked only at the column under
the centre, so a giant (3 blocks wide) that grew beside a wall kept its side inside the wall.

**Fix.** New pure rules in `core/rules/step_rules.gd` (`StepRules`), used by the player:
- `wants_step(feet, dir, radius, clearance, solid)`: the probe reaches `radius + 0.35` ahead (the
  same 0.35 m past the body's edge at every size). The ledge must be 1 block high, with `clearance`
  free rows on top (2 normal, 6 giant: the body's height in blocks) and a free row above the head for
  the hop. For a normal player this is exactly the old rule.
- `footprint(feet, radius)`: every block column under the body's square footprint (a body touching a
  face by up to 1 cm doesn't count as standing in that block).
- `first_free_y(feet, radius, clearance, max_y, solid)`: unstuck for the whole footprint, the first
  row where every column has room.
- `Player._auto_step` and `_unstuck` call these with `body_radius()` (0.3 × size) and
  `SizeMagic.clearance_blocks`. Tiny still never auto-steps (a block is twice its height).

**Tests** (RED, then GREEN):
- `tests/unit/test_step_rules.gd` (new, 9 tests; RED: `StepRules` did not exist): normal and giant
  steps, a 2-block wall, the giant's head room on the ledge and above its head, the footprint sizes,
  and unstuck lifting a giant whose side is in a wall.
- `tests/integration/test_giant_steps.gd` (new): a real `Player` with Jolt physics on a fake world
  (a floor and a 1-block step made of box shapes, with matching `get_block`):
  - `test_a_giant_walks_up_a_one_block_step`: RED, the giant stopped at x = 7.1 against the step and
    stayed at y = 10.0; GREEN, it is on the step (y > 10.9, x > 9). Passed 4 runs out of 4.
  - `test_a_normal_player_walks_up_a_one_block_step`: a guard that passed before and after.
  - `test_growing_into_a_giant_beside_a_wall_climbs_onto_it`: RED, it stayed at y = 10.05 with its
    side in the wall; GREEN, it stands on the wall at 13.05.
- Full suite: 519 → 531, all passing.

**Rulings:**
- *Giants auto-step 1-block ledges only, as the task and the review describe.* In proportion, a
  giant could step 3 blocks, but then it would walk over the walls children build around their
  houses. *Cost if wrong:* giants still jump for 2–3 block steps; a `max_step` per size in
  `wants_step` would change it.
- *The hop keeps its existing speed formula* (`AUTO_STEP_VELOCITY × jump_factor`, 12.9 m/s for a
  giant, about 3.5 m high). It is bouncy but clears a 1-block ledge with a wide margin against the
  giant's round, 0.9 m capsule bottom. *Cost if wrong:* giants bob on bumpy ground; a lower factor is a
  one-line change, but re-run `test_a_giant_walks_up_a_one_block_step` (and check on the emulator).
- *Unstuck uses the square footprint (the same AABB the host uses for "never place inside a player"),
  not the round capsule.* It can lift a body whose corner only nearly touches a block. A normal player
  straddling a block edge now checks 2–4 columns instead of 1. *Cost if wrong:* rarely, leaving Ghost
  mode or growing next to a pillar lifts you onto it instead of leaving you pressed against it.

## 4. LAN client undo had gaps

**What the review meant** (the M1 review text, see the top of this file), checked against the code:
1. A LAN client recorded an undo step the moment it *sent* an edit (`request_set_block` returns true
   once sent), even when the host then refused it (too far, someone standing there). Its undo stack
   drifted from the world: an undo press did nothing, or put back a block that someone else had
   changed since.
2. The host skips invalid cells inside a batch (mirror pairs, stamps, tool powers), but the batch's
   undo step still held every cell. Undoing it could break a friend's block that was built later in a
   cell the host had skipped. This happened in solo play too.
3. When an undo of a batch was only partly possible (a player standing in one cell), the whole step
   was popped anyway, so the skipped cells were lost. A client lost even a fully refused undo, because
   it could not know about the refusal.

**Fix: undo steps come from the host.** It is the only one that knows what really happened.
- `Session.request_set_block(pos, id, is_undo)` / `request_set_blocks(changes, is_undo)`: the RPCs
  carry `is_undo`.
- After applying, the host sends the requester one undo step (`_send_undo_step`): a local signal for
  its own player, `_rpc_undo_step` (authority → that client) otherwise. Entries are
  `[pos, id to put back, id there now]`:
  - an edit: every cell it really changed (validated, written, and different from before);
  - an undo: every cell it could not restore yet (for example, a player stands there): kept for later.
  - Nothing is sent when the step is empty.
- `BlockInteractor` records undo steps only from `Session.undo_step_received`, and only for the
  local player (the host's copies of remote players ignore it). It no longer records at request
  time, and `undo()` no longer pushes entries back itself. Malformed entries are skipped.

**Tests** (`tests/integration/test_edit_undo.gd`, new). A dictionary-backed `WorldService` stands in for
the terrain. A fake `MultiplayerPeerExtension` makes this game a LAN client (peer 2, packets go
nowhere) or a host with client 2 connected. RED then GREEN:
- `test_cells_the_host_skipped_are_not_in_the_undo_step`: RED "the friend's block stays" (undo
  turned the friend's BRICK to air).
- `test_cells_an_undo_could_not_restore_yet_are_kept_for_later`: RED "B is kept for later" (0 steps
  left, B never came back).
- `test_a_lan_client_records_no_undo_step_before_the_host_confirms`: RED (1 step recorded before the
  host answered).
- `test_the_host_tells_a_lan_client_what_it_changed`: RED (no packet to the client).
- `test_a_refused_undo_of_one_block_is_kept_for_later`: a guard that passed before and after.
- Written with the fix (the RPC they call is new, so they could only fail as "missing method"):
  `test_a_lan_client_records_the_undo_step_the_host_sends`, `test_a_lan_client_ignores_malformed_undo_steps`,
  and `test_only_the_local_player_records_undo_steps`. The last one was checked by removing the
  `is_local` guard: it fails (1 step on the remote copy), then passes with the guard back.
- Full suite: 531 → 539, all passing.

**Over a real network** (two headless instances on this PC, `--auto-host` / `--auto-join=127.0.0.1`
with `--lan-test`, private `XDG_DATA_HOME` folders):
- `tools/lan_test.gd` placed its two blocks near (0, 0), which terrain v2 moved about 16 blocks away
  from the spawn, so the host refused both. The client's first run showed exactly the fixed gap: its
  block was refused and it recorded no undo step (`undo=0`; the old code would have recorded 1).
- The tool now places them by the world spawn column and logs `undo=`. Run 2: the host placed A
  (purple) and the client placed B (red); both see both. Each side reports `undo=1`, the client's
  step arriving over ENet. No script errors.

**Found while verifying, not fixed here (pre-existing).** When the host quits, the LAN client can
crash with signal 11 in `world/ambience.gd:41` (`player.is_spawned()` in `_process`, once the
disconnect has freed the player). It crashed in 2 of 3 runs: once with this branch, and once with
the base commit `e83c3c9` exported by `git archive` and given the same `lan_test.gd`. So it is not
caused by these fixes. Listed in `docs/DEVELOPMENT.md` §9.

**Rulings:**
- *Undo steps are the host's answer.* On a client, an edit's undo step arrives one network round trip
  later (a few ms on LAN). An UNDO pressed within that moment undoes the previous step instead.
  *Cost if wrong:* on a laggy network a fast double-tap can undo out of order; request ids would fix
  it (not needed on LAN).
- *Cells an undo can't restore stay on top of the stack*, exactly as a refused single-block undo
  already did in M1 (the M1 ruling "a blocked undo is kept for later"). The next UNDO tries them
  again; on a client they come back after the round trip. *Cost if wrong:* while a friend keeps
  standing in the spot, UNDO keeps retrying that cell before older steps.
- *No-op cells are not undo steps.* Placing the same block that is already there, or a stamp's air
  in empty air, is left out of the step. *Cost if wrong:* none found; UNDO skips cells that never changed.
- *Any edit this player asks the host for becomes an undo step*, including the developer LAN test's
  direct `Session` calls. Only `BlockInteractor` (and that tool) send edits today. *Cost if wrong:*
  a future edit source that shouldn't be undoable needs a flag.
