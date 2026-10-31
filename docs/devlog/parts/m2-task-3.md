# M2 Task 3: gathering and counted blocks (spec §12.2)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `2430164`).
No editor or emulator was used: the lead verifies on the emulator after the merge. Plus three
child-friendly feedback pieces the lead asked for mid-task (break ring, place pop, first-time picture
hint).

## What was built

**Rules (pure, `core/survival/`)**
- `GatherRules`: pickaxe tiers (`NONE`, `WOOD` … `COSMIC`; the M1b pickaxe is wood), `tier_of(item)`,
  `pickaxe_tier(inventory)` (the best pickaxe owned), `refusal(block, tier)` / `can_break`,
  `drop(block, tier)` (grass gives dirt; leaves, water and bedrock give nothing; an open door gives a
  door; the rest themselves), `cost(block)` (what placing uses: an open door uses a door) and
  `change(old, new, is_undo, tier)`, what one cell change gives and takes.
  - Ore gates: coal and iron need any pickaxe ("You need a pickaxe for this!"), gold, diamond and
    crystal an iron pickaxe or better ("You need an iron pickaxe for this!"). Nothing breaks then.
- `GatherLedger`: one edit request's accounting against the requester's `Inventory`. The host calls
  `pays(old, new)` before it changes a cell and `changed(old, now)` with what the cell really became
  (so a cell the world didn't change never costs anything). `reserve(cells)` pays for a batch's
  placements whole or not at all. `message` is the first refusal, for the player.

**Host (`autoloads/session.gd`)**
- `_host_apply` and `_host_apply_batch` ask the ledger (`gather_ledger`, `_batch_ledger`); a few added
  lines each. Sandbox (`UNLIMITED_BLOCKS`) gets no ledger, so nothing changes there.
- New section `# --- M2 Task 3: gathering and counted blocks` at the end: `inventory_changed` (signal),
  `my_inventory` (this game's player's blocks and items), `gather_ledger`, `send_inventory(peer)`, and
  the snapshot RPC `_rpc_inventory`.
- `Inventory` now emits `changed` on every add or take. Session watches each player's inventory
  (`set_inventory`, `inventory_of`) and sends that player **one snapshot per frame** (deferred,
  coalesced; a 1600-cell stamp sends one). The host's own player reads the host's object itself.
  So the pickup bag (Task 2) and the trader (Task 7) reach the HUD without doing anything, as long as
  they change inventories through `add`/`take` (or `set_inventory`).

**HUD**
- `Hotbar.counted` (Survivor): a count badge on each slot (blocks always; a single tool or item has
  no number) and a faded slot (alpha 0.35) when the player has none. `count_text(i)`, `is_faded(i)`.
- `BlockPalette.counted` (Survivor): `open()` shows only what the player owns, in the order it was
  got, with counts, in a scroll area of the same panel. It says "Nothing yet! Break blocks to collect
  them." when empty, and follows `inventory_changed` while open. The Sandbox layout is untouched.
- Both refresh on `Session.inventory_changed` only, never per frame. `Hud.setup` sets `counted` from
  `Game.allows(ModeRules.UNLIMITED_BLOCKS)`.

**The lead's child-friendly feedback**
- **Break ring** (`entities/player/break_ring.gd`): `TouchClassifier.hold_progress(t)` (0..1 while a
  finger holds still) drives a ring on the targeted face, filling in 24 steps until the block breaks
  (the hold is 0.25 s). `LookBuildArea` updates it each frame while a finger holds, and hides it when
  there is no hold or the game pauses. `BlockInteractor.show_break_progress(hit, progress)`.
- **Place pop** (`entities/player/place_pop.gd`): after a successful tap placement, a soft glow over
  the new block grows from 0.8 to 1.0 (back-ease, 0.14 s) and fades (0.22 s).
- **Shared resources only**: one ring and one pop per player's `BlockInteractor`, reused. The track, the
  25 fill arcs, the pop's box and the materials are static, made once. Both use one material setup
  (unshaded, alpha, no depth test, two-sided), so there is one shader. `BlockInteractor.prewarm_feedback`
  draws both once, tiny, in front of the camera on `spawned` (the `Fx.prewarm` lesson). A "no hold"
  every frame doesn't cut that short (a test found this).
- **First-time picture hint** (`ui/hud/picture_hint.gd`, the HUD's last section): the first time the
  host refuses a break with "You need an iron pickaxe for this!", a panel below the toasts shows the
  pickaxe icon in the iron colour (rare blue, `4da3ff`, §13.2) with "Shiny ores need an IRON pickaxe!
  Tilly the trader sells one." for 5 s. It is shown once per profile: `ProfileData.hints_seen`
  (strings, at most 64, each at most 32 characters; junk is dropped).

## Tests (RED → GREEN)

| Test file | RED (why) | GREEN |
|---|---|---|
| `tests/unit/test_gather_rules.gd` (12) | parse error: `GatherRules` not declared | 11/11, then +1 guard: a door toggle costs nothing (passed first time; it pins the contract for Task 8) |
| `tests/unit/test_gather_ledger.gd` (13) | parse error: `GatherLedger` not declared | 13/13 |
| `tests/integration/test_survivor_gathering.gd` (20) | 17 of 20 failed: nothing was counted (placing didn't take, breaking didn't give, no refusals), no `my_inventory` / `_rpc_inventory` | 20/20 |
| `tests/integration/test_counted_hotbar.gd` (10) | 10/10 failed: no `counted`, no counts | 10/10 |
| `tests/unit/test_touch_classifier.gd` (+2) | `hold_progress` missing | 10/10 |
| `tests/integration/test_build_feedback.gd` (9) | written before the classes, but not run in between (it could only fail on missing classes); the later `test_no_hold_does_not_cut_the_prewarm_short` was RED ("still drawn this frame"): the look area's per-frame "no hold" hid the prewarm before it was drawn | 9/9 after the fix |
| `tests/unit/test_profile_data.gd` (+1) | `hints_seen` missing | 11/11 |
| `tests/integration/test_picture_hint.gd` (4) | parse error: no `IRON_HINT` / `PictureHint` | 4/4 |

The integration tests go through `Session` and the player's `BlockInteractor`, as in the game:
- Placing takes one. At zero the placement is refused: "You have no Stone left!", `edit_rejected`, and
  no undo step.
- Grass gives dirt, leaves nothing. Coal needs a pickaxe; gold needs an iron one (nothing breaks
  without it).
- A house stamp one plank short builds nothing ("You need 1 more Planks!"), and builds whole with one
  more. Mirror copies cost a block each.
- The axe fells a tree into logs, the hammer smash gathers dirt and stone, and the pickaxe step leaves
  a diamond it may not mine.
- Undo: undoing a placement returns the block, undoing a break takes it back out, and broken grass
  costs its dirt. A spent block makes the undo wait ("You have no Brick left!", kept for later), then
  it works once the block is owned again. A stamp's undo gives everything back. A felled tree's undo
  puts back what the player still owns (one log waits).
- Sandbox never counts.
- The local player hears three changes in one frame as one update. The host sends a LAN guest exactly
  one snapshot. A guest shows what it got. A WorldMeta save round trip keeps the counts and still pays.

**Full suite:** 637 tests in 79 scripts before, **708 in 85 scripts after**, all passing
(`tests/run_tests.sh` exit 0, "All tests passed").

**Real-world smoke run** (a throwaway `--script` driver, not committed, private `XDG_DATA_HOME`):
- A new Survivor world had the starter kit.
- The hotbar showed 16 planks, with stone faded.
- Breaking the ground beside the feet gave dirt; a plank placed there cost one.
- Gold was refused with the wooden pickaxe and stayed, and the iron-pickaxe picture showed.
- The hotbar followed (15 planks).
- After a save, the inventory was saved under the home key.

Result: 16/16 checks.

## Rulings (each with its cost if wrong)

1. **An undo is the exact reverse of its edit, decided on the host.**
   - Undoing a placement gives the block itself back: grass comes back as grass, and a placed gold ore
     comes back without an iron pickaxe.
   - Undoing a break takes back what the break gave: broken grass costs a dirt, broken leaves are free.
   - If the player no longer has it, the cell is not restored. The host sends it back as "not restored
     yet" ("You have no Brick left!"), so it waits in the undo stack for later.
   - So undo can never duplicate. *Cost if wrong:* a child who spent the blocks can't undo a break
     until they get one again; restoring for free would duplicate blocks.
2. **Undo requests are trusted as undos (LAN trust, like gold ruling 9).** A modified LAN client could
   send an "undo" to get a block itself instead of its drop, or to break an ore without the pickaxe.
   *Cost if wrong:* a LAN cheat until M4. The fix is for the host to remember each player's undo cells
   (about 40 lines).
3. **An undo of an old edit can still replace a block a friend built there since** (as in M1). In
   Survivor the undoer then gets that block. *Cost if wrong:* rare LAN theft of one block. The fix is
   to send the expected current id with undo requests and skip changed cells (about 20 lines, changes
   the undo RPC).
4. **Batches:**
   - Placements (stamps, mirror copies) are all-or-nothing, with "You need N more X!" / "You have no X
     left!". No half houses, no lone mirror copies.
   - Breaking batches (tool powers) are partial: every cell that may break breaks, and gated ore cells
     stay, with the message.
   - Undo batches are paid cell by cell (what can't be paid waits for later).
   - What a batch breaks counts towards what it places.

   *Cost if wrong:* a child with too few blocks must gather more or turn Mirror off; partial stamps
   would be two lines in `GatherLedger.reserve`.
5. **Replacing is breaking plus placing.** A stamp over terrain gathers what it replaces (ore cells it
   may not break are skipped), and a block placed into water gives nothing. *Cost if wrong:* stamps
   mine terrain; the alternative, stamps that only fill air, would change Sandbox stamps too.
6. **At 999 a break still happens and the extra block is not kept, with no message** (a child with 999
   stone doesn't miss one). *Cost if wrong:* silent loss at the cap; a "Your bag is full of Stone!"
   message is one line in `GatherLedger.changed`.
7. **An open door gives a door, and placing an open door uses a door.** So a door toggle (DOOR ⇄
   DOOR_OPEN) through `Session` costs nothing in Survivor (`test_opening_or_closing_a_door_costs_nothing`).
   Task 8 may toggle through `request_set_block`. *Cost if wrong:* none known; Task 8 may change the
   mapping in `GatherRules.DROPS` / `cost`.
8. **Snapshots rather than deltas**: the whole inventory (a few dozen `[id, count]` pairs), at most one
   per player per frame. *Cost if wrong:* a little bandwidth on LAN.
9. **The hotbar shows counts for blocks always, and for tools and items only above 1; an empty slot is
   faded (alpha 0.35).** A tool the player doesn't own is faded too. *Cost if wrong:* cosmetic.
10. **The Survivor palette lists owned things in the order they were first got** (`Inventory.ids()`), in
    the same panel (it scrolls). *Cost if wrong:* cosmetic; sorting is one line.
11. **Guests' inventories were not wired by Task 1.** A LAN guest in Survivor starts empty (the host's
    `inventory_of` makes an empty one) and is not saved. I left that alone: it belongs with guest homes
    (Task 10 note) and the knock-out bag (Task 2). *Cost if wrong:* LAN guests start without a kit.
    The lead can give guests `Inventory.starter_kit()` (or the saved one, by chat name) on
    `client_ready` with `Session.set_inventory`; the snapshot then goes out by itself.
12. **The lead's feedback pieces:**
    - **Ring colours:** a dark track (alpha 0.45) and the hotbar's selection gold. It is drawn over the
      terrain (no depth test) and two-sided, so it can't vanish on a wrong winding. *Cost if wrong:* it
      can show through a block that half-covers the face; cosmetic.
    - **The pop is a glow over the block**, not the block itself: a voxel block can't be scaled. The
      real block appears at once, and the glow grows 0.8→1.0 and fades over it. *Cost if wrong:* if the
      owner wants the block itself to grow, it needs a temporary textured cube per block id (cached)
      and a hidden voxel until it ends (bigger).
    - **The "soft sound" is the existing place sound** (already soft; Task 11 owns new sounds). *Cost if
      wrong:* one `Audio.play` line when a softer pop sound exists.
    - **On a LAN guest, the pop and the place sound play when the tap is sent**, before the host
      confirms (as the sound always did). *Cost if wrong:* a refused placement still pops once on a
      guest.
    - **The picture hint is only for the iron-pickaxe ores** (the lead's ask). It is shown once per
      profile, below the toasts (y 176, centred; transient). The same mechanism (`hints_seen` +
      `PictureHint.show_hint`) can carry more first-time hints. *Cost if wrong:* a child who forgot
      sees only the toast afterwards.

## For the lead: merge and emulator checks

- **Merge points:**
  - `session.gd`: two small hooks in `_host_apply` / `_host_apply_batch`, one line each in
    `set_inventory`, `inventory_of` and `survivor_reset`, and the new section at the end.
  - `hud.gd`: two lines in `setup`, one in `_ready`, and a section at the end.
  - `block_interactor.gd`: one line in `_ready`, one in `place_at_screen`, and a section at the end.
  - `look_build_area.gd`: one line in `_process`, one in `_notification`, and a function at the end.
  - `inventory.gd`: the `changed` signal. **Any new mutating method (Task 2's bag, Task 7's trade) must
    emit `changed`**, or its change won't reach the HUD.
  - `profile_data.gd`: `hints_seen`.
- **Task 6:** tier pickaxes join `ItemIds.ALL` there. Until then, `Inventory.add(PICKAXE_IRON)` returns
  0, and my tests put one in directly (`_give`). The gates then work in the game unchanged.
- **Untracked uid files from Task 1** (`tests/integration/test_main_menu_modes.gd.uid`,
  `test_survivor_session.gd.uid`) appeared in this worktree after `--import`. I did not commit them
  (each worktree makes different uids, so they would conflict); the lead may commit the main
  checkout's.
- **On the emulator (Survivor, new world):**
  - The hotbar shows 16 and 8 on planks and dirt, and the other slots are faded.
  - Holding a finger on grass shows the gold ring filling for about a quarter second; the block
    breaks, and dirt goes to 9.
  - A tap places a plank with a glow pop, and planks go to 15. The palette shows only owned things,
    with counts.
  - Mirror with one block left refuses ("You need 1 more …").
  - Gold with the wooden pickaxe: the toast, and the first time only, the blue pickaxe picture.
  - Undo after a place gives the block back.
  - Measure the first hold and the first place for a frame spike (the prewarm should remove it on the
    GL renderer).
  - In Sandbox, nothing is counted or faded and the palette is unchanged.

## Incidents

- **I stopped the whole machine's GUT runs once (my mistake).** Around 10:14, stopping my own stale
  suite, I ran `pkill -f gut_cmdln.gd`. That matches every GUT run on this PC, including other agents'
  runs in their worktrees; it also killed its own shell. Any other worktree's run at that moment ended
  early and should be run again. Stop a background run by its task id instead; never `pkill -f` a
  shared tool name. (This is also in DEVELOPMENT.md §8.)
- **The first suite run after a fresh `--import` stopped mid-run with exit 0** (at
  `test_weapon_assets.gd`, before any integration test ran). The next run was complete (637/637).
  `tests/run_tests.sh` passes such a truncated run, so check for "All tests passed" and the script
  count, not only the exit code. Cause not found.
