# M3 Task 8: building tools — paint, LINE, FILL, COPY / PASTE, Build Rewind, Build-and-Wear (notes)

Built by a background agent in its own worktree (branch `worktree-agent-a6bb046066c594cc8`, cut from
`m2-survive-the-night`, with `lead-merge` merged in at `27306da` and again at `f230f81`), without the editor, the
emulator or godot-mcp. Brief `docs/superpowers/briefs/prompt-m3t8.md`; spec §14.5 (refined there), §3a, §5.5, §3b
(`/fill`, `/copy`); plan Task 8. Stopped once by the API's usage limit (00:40–03:00) and resumed.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Ids | `data/blocks/block_ids.gd`, `data/items/item_ids.gd` | Blocks **240–255** `PAINTED_WHITE … PAINTED_PINK` (page 12; `BlockIds.COUNT` 256). Items **435–450** `PAINT_*` (`ItemIds.PAINTS`) and **408–411** `LINE_TOOL`, `FILL_TOOL`, `COPY_TOOL`, `REWIND` (`ItemIds.BUILD_TOOLS`); `ItemIds.is_free_tool` (the paints and REWIND are never counted or faded in Survivor's hotbar). |
| Paint rules | `core/building/paint_rules.gd` (`PaintRules`) | 16 tints (names, colours), item ↔ tint ↔ painted block, `paintable` (a named, solid block without a job: not doors, beds, lights or anything glowing, hiding spots, traps, pads, portals, stations, smart and Game Blocks, gadget blocks, the saddle, the secrets' blocks, slippery ice, bouncy gumdrops, cacti), `precious` (it needs a pickaxe or Tilly buys it), `refusal` (NOT_PAINT, SAME, CANT, Survivor's PRECIOUS), child-friendly messages. |
| Page 12 | `data/blocks/paint_page.gd` (`PaintPage`), `tools/make_paint_page.gd`, `tools/make_paint_page.py`, `data/blocks/pages/paint*.png` | Tint t at tile (t % 8, t / 8), one tile on every face, one shared material; registered as `BlockLibrary` loads and before every build. Pixel tiles: the tint with a fine grain and a bevel. Realistic twin: ambientCG **Plaster001** (CC0) painted in each tint. |
| Power tools | `core/building/power_tools.gd` (`PowerTools`) | LINE cells (one axis step at a time, always the axis furthest behind: a staircase on diagonals, both ends included, ≤ 64), boxes (FILL ≤ 4,096), copies (≤ 16 a side, read from a buffer's bytes), stamp coordinates for a copy (x right, z away from the child, centred like a gift stamp), quarter turns, paste cells, "empty" = air or water, messages. |
| Rewind record | `core/building/rewind_log.gd` (`RewindLog`) | This child's edits within 32 blocks of a spot (a cube), ≤ 5,000, 5 bytes each; `blocks_after(n)`, the replay's pace (¼ s an edit, faster for big builds: ≤ 20 s), saved deflated in base64; a broken save is dropped, an unknown id replays as air. |
| Wear rules | `core/avatar/wear_rules.gd` (`WearRules`), `core/avatar/avatar_look.gd` (section) | HAT, BACKPACK (`back`), WINGS; ≤ 5 × 5 × 5 and only placeable blocks; BuildCodec's text, decoded under its own limits on every load; `AvatarLook.builds` (slot → code: saved in the profile, sent in the look code, which may now be 2,048 characters), `wear`, `take_off`, `builds_from`; `resolve()` hides the catalogue hat / cape / wings a build replaces. |
| The host | `autoloads/session.gd`, section "M3 Task 8" | `request_build_tool(kind, changes)` / `host_build_tool`: PAINT (both modes, ≤ 2 cells: a tap and its mirror copy, no ledger), LINE / FILL / PASTE (Sandbox, capped and refused whole beyond, only into air or water, never inside a body, within 48 blocks of the eyes), UNDO (through the host's per-player log of the last 20 tool steps: only what this player's tool changed, still holding it, each entry once; a cell that can't come back yet returns as a new step and a new log entry). Written 16 cells at a time (one read, one copy and one paste of their box: `WorldService.blocks_at`, `set_blocks`), each physics frame until 8 ms have gone (at least one chunk; an edit of at most 64 cells at once); each LINE / FILL / PASTE cell is checked as its chunk is written, each paint or undo cell against what it held at the request (a cell someone changed meanwhile stays). One undo step at the end (`tool_undo_step_received`); "Nothing to build there!" when every cell was taken. |
| Bulk cells | `world/world_service.gd` (section) | `blocks_at(cells)` (one copy of their box when they fill it well) and `set_blocks(changes)` (one copy and one paste, then `block_changed` for every changed cell; a box not all loaded, or scattered cells, go cell by cell). |
| In the hand | `entities/player/build_tool_user.gd` (`BuildToolUser`), `entities/player/block_interactor.gd` (section + 5 lines), `core/building/undo_stack.gd` (`via`) | The BlockInteractor's `tools` (like `gadgets`): paint (and its mirror copy), the two taps of LINE / FILL / COPY with the block held last, the glow of the line or box being chosen (M4 I's `BuildOutline`), paste turned with the child, TURN, NEW COPY, CANCEL, REWIND (start, or open the time-lapse), Rewind's recorder, the wand's `offer_wear`; `undo()` sends a tool step back through the host (`via: &"tool"`) and says what it undoes (`undoing`). |
| Screens | `ui/building/` (`BuildToolBar`, `RewindView`, `RewindPreview`, `WearCard`), `ui/hud/build_tool_icons.gd`, `ui/hud/block_icons.gd` (2 lines), `scenes/sandbox.gd` (section + 2 lines) | The tools' bar (top centre, only with LINE, FILL or COPY in the hand). The time-lapse: its own World3D in a SubViewport, one MultiMesh per block id, a camera orbiting on `PhotoOrbit`, AGAIN, NEW, CLOSE (SHARE hidden: M5's `export_video`), solo pauses, the game's 3D isn't drawn and the HUD hides while it shows (as in photo mode: a HUD button hears a touch before any GUI control). The wand's card: WAKE UP, HAT, BACKPACK, WINGS (pictures drawn in code), CANCEL. |
| Palette | `ui/hud/block_palette.gd` (section + 4 lines), `ui/hud/hotbar.gd` (1 line), `ui/hud/hud.gd` (1 line) | A BUILD tab (tab 6): the TOOLS row and two rows of paint buckets. Survivor shows the tab with the paints and REWIND; their hotbar slots are never faded, and a crafted thing never takes their slot. |
| Wearables | `entities/player/wear_mesh.gd` (`WearMesh`), `entities/player/avatar_model.gd` (section + 1 line), `ui/avatar/avatar_editor.gd` (3 lines) | A wearable baked into one cached mesh: only the faces open to the air, each with its block's tile, one surface per block-library material (both styles, restyled with the blocks); a hat stands on the head, a backpack hangs on the back, wings are the build and its mirror image (they flap). The editor's HAT, CAPE and WINGS tiles take the built one in that place off. |
| Chat | `core/rules/chat_commands.gd`, `scenes/chat_command_runner.gd` (sections) | `/fill block [n \| w h d]` (a box two blocks ahead, 1–16 a side, empty cells only, one FILL request) and `/copy` (the build you look at goes into the COPY tool, in your hand); Sandbox cheats, rate-limited like `/build`, Georgian names შევსება and კოპირება (a native speaker checks them). |
| Save | `world/world_meta.gd` | `WorldMeta.rewind` (host and solo). |
| Smoke run | `tools/build_tools_smoke.gd` (+ `_steps`) | Everything above in a real Sandbox world, plus the measurements below. |

## Tests (RED → GREEN)

New: unit `test_paint_rules.gd` (7), `test_paint_page.gd` (5), `test_power_tools.gd` (10), `test_rewind_log.gd` (9),
`test_wear_rules.gd` (9); integration `test_build_tool_session.gd` (12), `test_build_tool_user.gd` (11),
`test_build_ui.gd` (4), `test_chat_fill_copy.gd` (3), `test_palette_build.gd` (5), `test_rewind_view.gd` (8),
`test_wearables.gd` (8), `test_world_bulk_edits.gd` (3): 94 tests, plus one more in `test_chat_commands_more.gd`. Changed: `test_block_pages.gd` (its test page moved from 12
to 13), `test_chat_commands_more.gd` (the "wait for Task 8" test became two real ones), `test_item_ids.gd`,
`test_palette_armory.gd`, `test_palette_gifts.gd`, `test_counted_hotbar.gd` (the BUILD tab).

- **Proper RED** (the tests written first and run against stubs that parsed, failing on their assertions): paint
  rules (5 of 7 red), Rewind's log (7 of 9), wear rules and the look's builds (9 of 9), the host's tools (1 of 10:
  the 4,096-block undo, before the tool undo path), wearables on the avatar (3 of 7, before `_dress_builds` and the
  editor's hook), the tools' bar (1: NEW COPY didn't refresh it), the palette suites' tab counts (before the tab).
- **Written first but first run with the code, then mutation-checked** (the guard removed, the test run red, the
  guard put back): the FILL cap (`>=` instead of `>`: 1 red), a quarter turn's direction (turning left survived the
  first tests, so `test_turn_quarter_turns` got a direction check: then 1 red), Survivor's precious blocks (1 red),
  the undo log's "from what" check (1 red), the request cap (2 red), the wearable's 5-a-side cap (1 red), Rewind's
  32-block cube (1 red), the paint page's tiles (2 red), Survivor hiding the power tools (1 red), /fill's 16-a-side
  cap (1 red), /copy putting the tool in the hand (1 red), "the block held last" (2 red), wearing built parts at all
  (3 red), a chunk leaving a cell someone changed meanwhile (1 red).
- Found by the smoke run and fixed test-first: a 4,096-block undo took 5 s (one scan of the log per cell): one pass
  over the step now; a 4,096-block fill took 1.5–5 s on the main thread: bulk reads and writes, then a little every
  frame against a time budget, the checks moved into the chunks (`test_a_big_fill_is_written_a_chunk_at_a_time`,
  `test_a_frame_writes_chunks_until_its_time_is_spent`, `test_world_bulk_edits.gd`).
- Full suite: before **4,502 tests, 4,500 passing** (465 scripts; the 2 failures were the pets' voices, fixed by the
  lead's `cfd9a51`, merged in); after: see "Suite" at the end.

## Measurements (this PC, shared: the load average is given; phones are 3–5× slower)

| What | Result |
|---|---|
| **Paint's cost** (the ruling): the block library | 222 → 256 models (every id below 256; 16 real cubes more); a fresh `BlockLibrary.build()` bake 8.4 ms (load 11) |
| Draw calls per chunk | a 16³ chunk of stone meshes into 1 surface; the same chunk with all 16 tints into **2** (`test_painting_adds_one_draw_call_to_a_chunk`): one shared material for every tint |
| FILL 4,096, cell by cell (the first version) | 1.5–5 s in one frame (load 11–34), and its undo 5 s (a scan of the log per cell) |
| Where a cell's time went (the smoke run's probes) | a box copy or paste 0.1 ms; each changed cell's `block_changed`: about ten listeners, 13–20 µs together once the world is settled (4,096 announced in 54–110 ms at load 27–37), up to 0.4–0.9 ms while the world still streams (their neighbour reads, and a PC at load 30 starving the main thread: plain GDScript ran 10–40× slower in the first seconds of a world; one `validate_edit` is 1.6 µs outside a world) |
| FILL 4,096 now (the smoke run, a world still streaming, load 22–37) | the tap 30 ms (was 400–800 ms with the checks in the request's frame); written over 2–4 s, the slowest frame 16–42 ms (budget 8 ms, one chunk of 16 at least); its undo the same (slowest 28–53 ms). On a settled world the same budget writes about 400–600 cells a frame |
| Build Rewind's preview, 5,000 edits (MultiMesh, the ruling) | setup 21–34 ms, every edit shown 14–22 ms in all (≈ 0.015 ms a frame over 20 s), 4 draw calls (one per block id) (load 11–37) |
| The alternative: remeshing the edits' box with the blocky mesher | 18–24 ms for one 63 × 43 × 63 remesh: a time-lapse would need one every step |
| The time-lapse opening (5,000 edits) | 21–33 ms on a settled world; 215–650 ms in a world's first seconds on a loaded PC (a full-screen view opening: check on the emulator) |
| The whole smoke run | 18 checks, 0 failed (the last three runs); two earlier runs each had one miss from the terrain (a line and a paste that met a hill: both moved higher in the air) |

## Rulings (decided on the owner's behalf; each with its cost if wrong)

1. **Paint is 16 painted blocks on page 12 that a plain block turns into**, not tinted variants of a few blocks.
   Measured: one shared material, so any number of tints costs a chunk one draw call (1 → 2 surfaces), and the
   library grows by 16 cubes (bake 8–15 ms, once). Tinted variants of even two blocks would need 32 ids (only 32 are
   Task 8's) and give a child far fewer paintable blocks; a real tint channel doesn't exist in the blocky mesher.
   A painted block is smooth painted plaster in its tint (the brick's pattern goes). *Cost if wrong:* a later
   "stained" look is a new page of variants; saves keep working (240–255 stay painted plaster).
2. **Item ids 408–411 for LINE, FILL, COPY and REWIND** (the gadgets' free ids; 412–414 stay free). The plan gives
   Task 8 only 435–450 and the 16 paints fill them; one bucket per colour (not one bucket and a colour picker)
   lets a child keep red and blue in two slots, with no reading. *Cost if wrong:* 4 constants to renumber before
   any save holds them; the plan's allocation line now says so.
3. **Paint's rules.** Only plain blocks: anything with a job keeps it (a painted door would stop being a door).
   Survivor: paint is free both ways (no ledger, and undoing a paint is free through the host's log), a precious
   block (it needs a pickaxe, or Tilly buys it: coal, iron, gold, diamond, crystal, frozen ore) is never painted
   ("Diamond is too precious to paint!"), and a painted block drops as itself and sells for nothing, so paint is no
   way to lose or farm anything. Painting a stone costs the stone (it becomes the painted block). *Cost if wrong:*
   the JOBS list and `precious` are one table each.
4. **The tools are items in a new BUILD tab**, not modes: the BLOCKS page's TOOLS row is full (the palette must fit
   above the hotbar), and the brief's "put new tools there" is kept in spirit: the tab has its own TOOLS row. LINE
   and FILL build with **the block held last** (the brief's "the held block": the tool itself is in the hand).
   *Cost if wrong:* a tool badge on the hotbar slot could show the block; the rule is one variable.
5. **The tools only ever fill empty cells (air or water)**: nothing is broken or replaced, so no tool can grief a
   friend's build on LAN (review focus 3), and COPY pastes only blocks (its air never carves). A paste stands on the
   tapped face, centred, reaching away, turned the way the child looks; TURN adds quarter turns. *Cost if wrong:* a
   "replace" FILL would need its own host rules.
6. **Reach**: the two taps are within building reach when made; the host writes a tool's cells within 48 blocks of
   the eyes (the collision distance: loaded chunks), a paint within the batch reach (32). *Cost if wrong:* one
   constant.
7. **Undo goes through the host's log**: the host keeps each player's last 20 tool steps (the undo stack's depth)
   and undoes a cell only when its log says this player's tool made that change and the cell still holds it. A guest
   can't undo into something that was never there, nor undo another player's tool edits; Survivor's free paint
   can't be undone into a free block. *Cost if wrong:* memory: at most 20 steps × 4,096 cells × 20 bytes a player.
8. **Big edits are written a little every frame against a time budget**: 16 cells at a time (one read, one copy and
   one paste of their box), each physics frame until 8 ms have gone, at least one chunk; an edit of at most 64 cells
   (paint, a line, a small paste) at once. Each cell is checked as its chunk is written, so the request's frame does
   no per-cell work either (the child's game sends every cell; the host skips the taken ones). A 4,096-block FILL
   appears over a few frames on a settled world (every changed cell costs its ten `block_changed` listeners 13–20 µs
   here) and over 2–4 s while the world still streams (up to 0.9 ms a cell). Accepted whole, undone whole (one undo
   step at the end); a cell someone changed meanwhile stays as it is. A fixed 1,024 cells a frame was tried first: its
   frames took 300–1,000 ms while the world streamed. *Cost if wrong:* `TOOL_CHUNK`, `TOOL_FRAME_MS`; a FILL slowly
   rising while a phone streams is part of the fun ("it is being built").
9. **Tool edits don't count as blocks placed** (M3 Task 12's XP): a FILL would hand out thousands. *Cost if wrong:*
   one line (`progress_placed` over the step).
10. **Mirror mode mirrors paint only**; LINE, FILL and PASTE are not mirrored (a mirrored 4,096 fill would break
    the cap). *Cost if wrong:* the tools could send mirror copies within the cap.
11. **Build Rewind is one recording per world**, started by the first REWIND tap (the spot), recording this child's
    own edits (the host's undo steps, tools included, and the undos asked for: an undo the host couldn't finish comes
    back as a step and cancels itself in the record), within a 32-block cube, up to 5,000 (then it stops). NEW
    forgets it. Saved with the world by the host and solo; a LAN guest's stays in its memory. Allowed in Survivor
    too (it never changes the world). *Cost if wrong:* several recordings are a list in `WorldMeta.rewind`.
12. **The time-lapse is MultiMeshes in a world of its own**, not a second small VoxelTerrain (measured above: no
    streaming, no voxel threads, O(1) an edit, one draw call per block id; a remesh of the box per step would cost
    18 ms each on this PC). It starts from what each cell held before its first edit (a dug-out block shows, then
    goes). The camera orbits the recorded box on `PhotoOrbit` (a Callable that says "no blocks": nothing to bump
    into on the stage). Solo pauses (like photo mode); the game's 3D isn't drawn behind the full-screen view.
    *Cost if wrong:* the preview is one class (`RewindPreview`).
13. **The video export is M5's**: `RewindView.export_video()` and a hidden SHARE button (`VIDEO_EXPORT`). *Cost if
    wrong:* none.
14. **Build-and-Wear is on the wand**: a wand tap on a build that fits 5 × 5 × 5 (BuildPicker, the connected
    non-natural blocks) opens WAKE UP / HAT / BACKPACK / WINGS; a bigger build wakes as always. The build is copied
    (it stays in the world), turned so the side the child sees is its front. One per place: a built hat takes the
    catalogue hat's place, a backpack the cape's, wings the wings'; picking a hat, cape or wings in the avatar editor
    takes the built one off. *Cost if wrong:* a small build needs one more tap to wake (WAKE UP is the first, green
    choice); a separate WEAR item would be one more palette button.
15. **Wearables are BuildCodec text in the look** (`AvatarLook.builds`), so they are saved in the profile, backed up
    with it, sent in `Player.look_code` (now ≤ 2,048 characters: three of the busiest 5³ builds fit) and checked on
    every load (size, count, only placeable blocks; a bad one is dropped alone). Any player's own builds are theirs
    (no ownership check). *Cost if wrong:* M4's server can check them like gifts (the same format).
16. **A wearable is one cached mesh in its blocks' own materials** (the block library's, both styles, restyled with
    the world); no material is made for it. A hat's block is 0.1 m (five blocks are the blocky head's width), a
    backpack's 0.08, a wing's 0.1. *Cost if wrong:* three constants; check the look on the emulator.
17. **/fill and /copy** (owner #40's list): `/fill block [n | w h d]` builds a box two blocks ahead like `/build`
    (default 3, 1–16 a side: 16³ is the FILL cap), `/copy` copies the build you look at (its connected blocks, like
    the wand) into the COPY tool. Sandbox cheats, local (the host checks the edits), rate-limited. *Cost if wrong:*
    the parse is one function.
18. **`ui/building/`**, not `ui/build/`: `.gitignore` ignores every `build/` folder (found when the first suite run
    couldn't find the classes). *Cost if wrong:* none.

## Godot patterns (the house rule: the godot-prompter skill first)

- `godot-prompter:godot-testing`: GUT, RED against parsing stubs, fakes for the world (an `EditWorld` whose
  `copy_box` reads its own cells), `wait_until` for the writes spread over frames; rejected mocking Session (the real autoload
  with a fake world is what the other tasks' tests use).
- `godot-prompter:3d-essentials`: `MultiMeshInstance3D` per block id for the preview (chosen) over a second
  VoxelTerrain or per-step remeshing (rejected by the measurements); a `SubViewport` with `own_world_3d` for a stage
  that can never touch the game's world; shared materials only (the block library's), no per-event materials;
  shadows off on small pieces.
- The UI follows the house's own kit (`UiKit`, `OnlineUi`) and SharePanel's bar placement; no new HUD spot (the bar
  and the card are context screens registered as the look area's blockers).

## What the lead should check on the emulator

1. Palette → BUILD: the TOOLS row and 16 buckets fit above the hotbar on the 20:9 screen; every picture reads.
2. Paint a wall of stone in several colours in both styles (Settings → style): the tints look right (not washed
   out on the Compatibility renderer), the realistic plaster is visible; painting a door or a lamp says why not;
   UNDO gives the stone back; Mirror paints both sides.
3. LINE: two taps, the glow shows the staircase while choosing; a diagonal can be walked up. FILL 16 × 16 × 16 in the
   air: no frame over 100 ms (autopilot probe or the FPS label), the box appears within a few frames, one UNDO
   takes it away. The bar's words, CANCEL, TURN and NEW COPY work with a finger.
4. COPY two corners of a small house, turn round, paste: it faces you; TURN turns it; a friend's blocks in the way
   stay.
5. REWIND on a spot, build, REWIND again: the time-lapse plays (≤ 20 s), the camera orbits, AGAIN / NEW / CLOSE;
   the game comes back unpaused and drawn; quit and reload: the recording is still there.
6. The wand on a 3-block build: the card; HAT: the build sits on the head (both styles, the realistic head too);
   BACKPACK hangs on the back; WINGS flap; the avatar editor's HAT tile takes the built hat off; a LAN friend sees it.
7. LAN guest: tools work near the guest, a guest in Survivor gets "The building tools work in Sandbox!".
8. `/fill glass 5`, `/copy` while looking at a build.

## Suite

Every full run went through the slot gate (`tests/suite_slots.sh tests/run_tests.sh`), on a snapshot of the staged
tree (DEVELOPMENT.md §8), under a load of 25–37 from other agents' suites.
- Before (this branch with `lead-merge` at `27306da`): 465 scripts, 4,502 tests, 4,500 passing (the pets' voices,
  fixed by the lead's `cfd9a51`, merged in with `f230f81`).
- `3df4403` (the feature): **478 scripts, 4,596 / 4,596 passing, exit 0** (690 s).
- `e2b2e04` (big edits a little every frame): **478 scripts, 4,597 / 4,597 passing, exit 0** (686 s).
- One earlier run was stopped: `ui/build/` was git-ignored, so the snapshot had no screens (ruling 18).

Commits: `3df4403` feat, `e2b2e04` perf, then this notes commit.
