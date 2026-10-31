# Round 4b, Tools: the ten motions, the device run, the Tool Book, and Real Builder (owner #116, #117, #118)

The owner (2026-10-16 15:04, #116): "using vr it should be possible to build a house for example like in real world, take
brick or stones and put in apropriate place and etc like in real life"; (15:10, #117): "building is one of the example how
we are going to teach childrens, also like in development there should be different instruments used while building
houses, we should teach and they should be able to use any instrument and devices. but this is one example, we must use
same aproach for any skills children need in real life"; (19:51, #118, relayed while this ran): dangerous things learned
safely, with "safe mistakes". The design: `docs/design/life-skills.md` §13 (the method, the ten motions, the device model,
the catalogue, the Tool Book) and §14 (#118); the plan: `docs/superpowers/plans/2026-10-16-vr-round4.md` "Round 4b" and
"Round 4b's base". This agent is **Tools**, in the worktree branch `worktree-agent-a090e57ad7626a49c` cut from
`lead-merge` at `0705d40d` (merged up to `3080df4a`), beside Life L2 and VR-WONDER (none of their files touched). No
editor, no emulator, no adb, no download. Logs: the session scratchpad's `tools4b_*`.

## What a child does

**Real Builder** is a practice building site (a yard, a hoarding, a bench with the tools, a pallet, a mortar board; Middle
and Big a mixer, a saw station, a slab). Every track starts with **safety first** (the hard hat and gloves; Middle and Big
the goggles too) and ends with a name-it card, the picture check, the stamps and **Try it for real**.
- **Little, a little wall (16 steps):** the real big concrete blocks (440 x 215 x 100 mm) on a footing: spread a bed of
  mortar with the trowel; lay three blocks where they glow; tap a high block down with the trowel; the spirit level along
  the row (the bubble in the middle); mortar again; "How should the second row start?" (a half block); lay the second row
  (a half, two whole, a half: each across two below); the coach's quick test wall with its joints in one straight line:
  push it, **it splits along the straight joint**; push yours, **it holds**; the third row; the level again; count the
  rows. Expert: the second row has no glowing places.
- **Middle, a garden shed (24 steps):** measure the front with the tape (hook on the corner peg, pull to the other: "1.79
  metres"); "a brick and its joint take 22.5 cm: how many fit along 180 cm?" (8); the mixer's order (a grown-up's job in
  real life: switch on, a little water, four shovels of sand, one of cement, water to soft butter, switch off; gloves and
  goggles first); goggles off after it; the front's first row with the doorway left open; a high brick tapped down; the
  level; the team lays the corners and other walls ("corners first"); the second row between the corners, with half
  bricks at the doorway; the push test (straight joints split, staggered ones hold); the plumb line at the corner; the team
  builds up (a time-lapse); "what goes over the doorway?" (a lintel); lay the lintel; the walls to the top; **saw a
  rafter** (goggles: trying without them is a safe mistake); three pairs of rafters; nail one with the hammer; "why does a
  roof slope?"; four rows of tiles from the bottom up.
- **Big, a small house (29 steps):** measure the 3.14 m front and count its bricks (14); **set out a square corner with
  3-4-5** (measure between pegs at 60 and 80 cm: 1 m) and why (3 x 3 + 4 x 4 = 5 x 5); the mixer; build the corner pier
  left of the doorway (three rows: a half brick at the reveal on the second); the plumb line from a hop-up; the walls up to
  the window; the window's lintel, then **measure its bearing** (21.5 cm: more than the 15 cm a lintel needs); the door's
  lintel; the walls to the top; saw a rafter (goggles); four pairs of rafters; nail one; why tiles overlap; five rows of
  tiles; **walk in through your own front door** (the tour), the finish inside.

**Flat:** a row of the room's tools along the bottom (the tray): tap one to hold it; then the real motion with a finger on
the work (drag along the bed to spread, tap the brick to strike, hold on the row to read the level, drag from the peg to
the end to measure, drag back and forth on the pencil line to saw). A tap alone never spreads mortar. The wrong tool says
kindly "That works better with the trowel. The spirit level is for checking that a row is level and a wall is straight
up." and the trowel glows. Bricks: tap where one goes (the nearest free place to the finger). **VR:** the tools lie on the
bench: take one by hand (VR-HANDS' grab; far ones with the laser's pull), use it the real way on the work (the trowel's
blade low along the bed, a swing down onto the brick, the level laid along the row and held still, the tape hooked and
pulled, the saw back and forth on the line); a good use buzzes softly; let go, it goes back to the bench. Bricks: take one
from the pallet with the free hand, carry it near its place (a see-through brick shows where it snaps), let go: laid. A
squeeze at the row lays nothing: bricks are carried. Raised work (the corner's top, the lintels) from a builder's
hop-up; the roof from the scaffold (a blink up); the long tape walks the child to its far end once hooked.

## The engine (built once, used by every Life Experience, the Lab and the School)

| Part | What | Where |
|---|---|---|
| **The ten motions** | `ToolMotion.ALL` = strike, stroke, twist, squeeze, press, spread, measure, pour, aim, cut (the single list; equal to `LifeCheck.MOTIONS`, a test holds them equal); `ToolMotion.new(motion, tool_checks, step_checks)`, `feed(sample) -> {progress, done, verdict (good / almost / bad), said, buzz}`, `fraction()`, `count`, `reading`, `hooked()`; `CHECKS` (each motion's numbers), `HOW` (each in words, VR and phone), `problem(motion, checks)` | `core/tools/tool_motion.gd` |
| **One sample for both** | `ToolSample.work_frame(origin, along, up)`; `vr(frame, tip, trigger, dt, other)` (a held tool's tip, the other hand for the claw); `flat(frame, ray_from, ray_dir, down, dt, reach)` (a finger's ray on the work's surface, a fingertip's size there) | `core/tools/tool_sample.gd` |
| **The device run** | `ToolDevice.from(data, id)` on Life L1's device data as written (words) or entries (`{id, words}`, an order's `{do, value, shows}`, safety's `{id, words, before}`); `use(control, value) -> {ok, said, safety, done}` ("First: pull the pin.", "Safety first: goggles on."), `next_do()`, `fraction()`, `display(id)`, `displays`, `problems(data)` | `core/tools/tool_device.gd` |
| **The Tool Book** | `data/tools/tools.json`: 56 entries (42 tools, 10 devices, 4 safety gear) in the design's 11 areas, each with its name, what it is for, how to hold it, its motions, its safety rule, a grown-up's job, its own numbers, a device's run data; every tool and device Life L1's steps name. `ToolBook.entry / ids / of_area / motions / checks / device / icon / right_tool(wanted, held) / problems()` | `core/tools/tool_book.gd` |
| **The stamps** | `ProfileData.tools` (`ToolData`): per tool Done it, By myself, Expert and uses; `record([{tool, hinted}], expert)`, `can_use()`, merged by the backup without losing one | `core/tools/tool_data.gd`, hooks marked owner #116 in `core/save/profile_data.gd` and `profile_backup.gd` |
| **The room host** | `ToolRoomHost` extends `LifeRoomHost`: every frame's LifeCheck sample goes through the engine first (motions, the right tool, safety first and safe mistakes, devices, placing); the room opts in (`has_work(target)`, `work_frame(target)`, `has_device(id)`), so L1's rooms play exactly as before (a test opens every L1 Experience in it: nothing taken over); `tools_used(entries, expert)` and `tool_entries()` for the Tool Book | `entities/tools/tool_room_host.gd` |
| **Tools in a room** | `ToolProp` (a VrGrabbable of kind `&"tool"`, tips per motion, back to the bench when let go), `ToolModels` (true size, the rooms' warmed kit) | `entities/tools/` |
| **The pages** | `ToolBookPage` (by area, the stamps, "you can use N tools", a tool's page: for, hold, its motion in VR and on a phone, safety, a device's order, "a grown-up's job"), `ToolTray` (flat), `ToolIcons` (37 pictures in code) | `ui/tools/` |
| **Real Builder** | `RealBuilder` (its data in Life's format, `data/tools/real_builder.json`, checked with Life's rules and the engine's), `BrickBond` (real brickwork as rules), `RealBuilderSite` (the room), `BoxBatch` (a house in a few meshes) | `core/tools/`, `entities/tools/real_builder/` |

The motions' checks (metres, m/s, radians, s; a tool's and a step's numbers change any):

| Motion | Done well (VR) | On a phone | Almost (kind words, no count) | Bad (never counts) |
|---|---|---|---|---|
| strike | 3 hits landing within 4 cm, 1-6 m/s, within 0.6 rad of straight in (the swing's last 0.06 s) | a tap on it | too soft, too hard, beside it, at a slant | a swing at something else (silent) |
| stroke | 6 strokes of 8 cm+, within 2.5 cm of the line, at most 2.5 a second, touching | drag back and forth | short, fast, drifting | far off the line |
| twist | 2 turns the step's way, the tool in line within 0.35, on it within 3 cm | a circle drawn round it | a slant; the other way (it undoes) | - |
| squeeze | 1.5 s at 0.55-1.0 (steady: letting go starts again) | press and hold | too light, too hard | - |
| press | 1 cm in, within 5 cm; seconds held; a rate band if set | press (and hold) | not far enough, just beside, off the beat | - |
| spread | 80% of the bed's 12 cells, within 3 cm of it, under 1.6 m/s | drag over it | too fast, too high, off the surface | - |
| measure | hooked within 3 cm of the start, held still 0.6 s at the length within 2 cm | drag from start to end | short, past, not hooked | - |
| pour | tilted past 0.5 rad over it (within 8 cm), stopped within 0.08 of the level | hold, let go at the line | a little more; too much (a little goes back) | - |
| aim | within 0.06 rad of the direction (either way for a level), held 1 s moving under 2 cm | point and hold | nearly; shaking | - |
| cut | along the line within 1.2 cm, under 0.4 m/s, to its end | drag along it | fast, off the line, a jump ahead | fingers ahead of the blade (the claw) |

## The lead's hooks (each small, marked owner #116; nothing here touches core/life, entities/life or ui/life)

1. `core/life/life_experience.gd`: `IDS` gains `"real_builder"`, and `data(id)` reads `RealBuilder.PATH` for it (or the
   file moves to `data/life/experiences/real_builder.json`).
2. `entities/life/life_rooms.gd`: `"building_site": return RealBuilderSite.new(track)` (and `KINDS`).
3. `ui/life/life_screen.gd` `_open_room`: `host = ToolRoomHost.new()` (it plays every L1 Experience exactly as
   LifeRoomHost: the engine opts in by the room) and, in `_on_room_finished` before the save,
   `profile.tools.record(host.tool_entries(), expert)` (the `tools_used` signal comes after the screen's own handler,
   so too late for that save); a **TOOL BOOK** button beside PASSPORT on Life's map: `ToolBookPage.new(profile)` with
   `closed` back to the map.
4. `data/life/life.json`: the three Real Builder units (one marked block in the Home area) swap `"soon": "real_builder"`
   for `"file": "../tools/units/real_builder_<track>.json", "experience": "real_builder"` (the path from `data/life` works:
   `test_the_units_files_are_reachable_from_lifes_folder`; their content meets the School's bar:
   `test_the_life_units_meet_the_schools_bar`). `test_the_catalogue_has_one_entry_per_track_waiting_for_the_hook`
   follows the switch by itself.
5. (Optional) `core/life/life_check.gd`: `const MOTIONS := ToolMotion.ALL` (one list; equal today).

The lines, as they would read:
```gdscript
# core/life/life_experience.gd
const IDS: Array[String] = ["little_lifesaver", "fire_escape", "money_stall", "real_builder"]   # owner #116
	# in data(id):
	var path := RealBuilder.PATH if id == RealBuilder.ID else "%s/%s.json" % [DIR, id]   # owner #116
# entities/life/life_rooms.gd
		"building_site":   # owner #116: Real Builder
			return RealBuilderSite.new(track)
# ui/life/life_screen.gd, _open_room
	host = ToolRoomHost.new()   # owner #116: Life's room host with the tool engine (L1's rooms are not taken over)
# ui/life/life_screen.gd, _on_room_finished, before save_profile.call()
	if host is ToolRoomHost:   # owner #116: the Tool Book's stamps
		profile.tools.record((host as ToolRoomHost).tool_entries(), bool(trying.expert))
```
Once the id is known, Life's own tests and tools that follow `LifeExperience.IDS` see Real Builder too: the room, screen,
words, pictures, motions, auto-player and catalogue tests pass with its data (this branch's own tests hold it to the same
rules), but `test_the_three_experiences_load` asserts the exact list (one line to update), the Passport page gets a fourth
row (check its fit in the frame), `tools/life_smoke_steps.gd` cannot do the real motions (skip `real_builder` there: it has
its own smoke, `tools/real_builder_smoke.gd`), and `tools/life_review_sheet.py` reads `data/life/experiences/` only (Real
Builder's facts are in this file's sources and its data).

Until then Real Builder plays fully through `ToolRoomHost` (the tests and the smoke): it swaps in its site and steps when
Life's catalogue does not know the id; the Life map shows it as "coming soon".

## Rulings (decided, with what each costs if wrong)

1. **JSON, not .tres**, for the catalogue and Real Builder (Life's own convention; its review tooling reads JSON).
   *Cost:* no inspector editing.
2. **The engine opts in by the room** (`has_work`, `work_frame`, `has_device`): steps keep LifeCheck's kinds (a tool step
   is `touch` + `motion` + `tool`), and the engine presses the target only when the motion is done well; its progress
   keeps the coach waiting (`run.idle`), its fraction fills the HUD's bar. L1's steps name motions and devices as data but
   their rooms give no frames: they play as before. *Cost:* L2/L3 rooms add frames (a Transform3D per target) to use it.
3. **One sample in the work's frame** for hands and fingers. A finger has no speed, angle, depth or pressure: flat, a tap
   is a good strike, a hold a good squeeze or press, a fingertip (44 px) widens "on it". *Cost:* the phone can't teach "how
   hard"; VR does.
4. **The numbers** are the table's (constants in `ToolMotion.CHECKS`, the Tool Book's per tool: the trowel taps gently
   0.6-4 m/s, the spirit level either way round lying on the row, the plumb line any direction held still at the wall).
   *Cost:* tuned with fake hands on the desktop; the Quest 3 with children tunes them.
5. **Almost and bad never count and are never a miss** (no hint counted); the same words at most every 3 s. *Cost:* a
   child who never gets a motion right hears words and gets the coach after 10 s, as everywhere in Life.
6. **The trowel taps with its blade** ("tap it down with the trowel"). *Cost:* bricklayers often use the handle's end.
7. **Bricks are laid in bond, snapped, never free physics:** the child's rows accept only the plan's places (the nearest
   free one to the finger; in VR within 15 cm of the carried brick). The stagger is taught by the choice ("a half block"),
   the half bricks at the ends and the reveals, and the coach's test wall's push test (it splits, the child's holds).
   *Cost:* the child never builds a weak wall themselves; L3's safe-mistake kind can let them (BrickBond.straight_joints
   on the child's own pieces).
8. **Little's "big bricks" are real concrete blocks** (440 x 215 x 100 mm: one takes the place of six bricks). *Cost:*
   wording if the owner meant toy bricks.
9. **The child lays the representative pieces** (Little the whole wall, 10 blocks; Middle the front's first two rows, 10
   bricks; Big the corner pier, 6 bricks); **the team** lays the rest in the same bond (time-lapses: the shed 564 bricks,
   the house 1,143). *Cost:* a child can't lay every brick of a house (hours).
10. **Raised footings and slabs** (0.35 m, 0.3 m) bring the first rows within a child's reach in VR; **hop-ups** and a
    **scaffold** (a blink up to a railed deck) for the higher work. *Cost:* real walls start at the ground; standing on a
    raised deck in VR needs the headset's comfort check.
11. **Gable roofs at 35°** (plain tiles' usual minimum), rafters in pairs, tile rows from the eaves up, gables of timber
    boards (no raking cut bricks). *Cost:* a mono-pitch roof is more usual on a shed.
12. **Rafters and tiles are pressed into place** (the hand or the laser at the glowing place); **bricks and lintels are
    carried** (VR). *Cost:* less real for the roof (carrying long rafters on a scaffold is unwieldy in VR).
13. **Lintels:** concrete, one course high, resting at least 150 mm each side (the plan's nearest joint gives 215 mm).
    *Cost:* real lintels are often steel or two courses.
14. **A long tape walks the child:** hooked at the start, a blink to its far end (`walk`). *Cost:* no real walking with
    the tape in VR.
15. **The mixer is a grown-up's job:** the child gives the order; gear already on does its safety steps; the goggles come
    off after it ("until the next dusty job"), so the saw asks again. *Cost:* realism of goggles off and on.
16. **Owner #118's safe mistakes are shaped, not built:** Middle and Big steps carry `safe_mistake {wrong, event, why,
    right}` (the saw without goggles; straight joints; no lintel). Today: trying the saw without goggles says the coach's
    why ("Sawdust and chips fly up towards your eyes. That's why goggles go on before the saw."), puffs sawdust at the work
    (never at a face) and glows the goggles, never a miss; straight joints are the coach's test wall; no lintel is the
    choice's why. Little never (the coach guides first). *Cost:* L3's kind adds the frozen time and the child's own wrong
    try (the data is ready for it).
17. **ProfileData.tools** (two hook lines in `profile_data.gd`, two in `profile_backup.gd`, marked owner #116). *Cost:*
    one more field in the backup (at most 300 tools).
18. **The Tool Book's stamps:** Done it for a finished run's step with that tool; By myself when none of its steps in
    the run needed a hint; Expert on the Expert try without one; gear and devices count; "you can use N tools" counts By
    myself. *Cost:* one good use counts as "can use".
19. **Real Builder in Life's format in `data/tools/`** (RealBuilder reuses LifeExperience's resolve, vars and fill; its
    problems() mirrors Life's and adds the engine's); the host swaps its site and steps in while Life doesn't know the id.
    *Cost:* two loaders until hook 1.
20. **The catalogue entries are one marked block of three units** ("coming soon" until the hook). *Cost:* Life's map
    says "coming soon" until then.
21. **The flat tray** is a layer over the HUD (41), bottom centre, only on tool steps; the room's things to tap stay above
    590 px (the site test's band). VR hides it. *Cost:* it covers the bottom 130 px while shown.
22. **VR presses use either hand; a free hand carries while the other holds a tool;** a tool let go goes back to the bench
    at once (never thrown). *Cost:* no putting a tool down elsewhere.
23. **Tool pictures** are `ToolIcons` (37, in code); a step's choice pictures stay Life's (`LifeIcons`, the HUD's).
    *Cost:* a choice about tools shows a neutral picture until LifeCards takes ToolIcons.
24. **A house in a few meshes** (`BoxBatch`: two brick shades, mortar, lintels, rafters, tiles; rebuilt when a piece is
    laid): the room shows 30 (the wall) to 70 (the house) meshes, 78 in VR. *Cost:* a rebuild of a few thousand vertices
    per brick.
25. **The facts and sources** are the authorities' as known (Wikipedia's brickwork, brick, block, mortar, lintel, plumb
    bob, spirit level, roof tiles and pitch, Pythagorean triple; the HSE's construction pages; the NHBC Standards for the
    150 mm bearing; the Brick Development Association named on the cards): **not re-fetched** in this session (no
    downloads); the experts' review checks every URL and number. *Cost:* a wrong figure until then.

The experts' review sheet, written from the data: `docs/devlog/parts/tools-r4b-review.md`
(`tools/real_builder_review_sheet.py`, `--check` says when it is out of date): every step's words, each tool's motion and
numbers, the safe mistakes, the checks, the cards, the sources and the Tool Book's words for the tools used.

## What only the Quest 3 can check (the lead, on the owner's headset)

- Each motion's numbers with a child's hand: the trowel's sweep low along the bed (3 cm), the strike's 0.6-4 m/s tap, the
  level held still (2 cm in 0.25 s), the plumb line held at the wall top, the tape's hook (3 cm) and the walk's blink, the
  saw's strokes (8 cm, 2.5 cm off the line), the hammer's swing; the buzzes.
- Taking tools from the bench (near and the laser's pull), their size in the hand, the tips where a child expects them
  (the trowel's blade, the hammer's face, the saw's teeth), a tool let go going back.
- Carrying a brick from the pallet with the free hand, the see-through brick snapping within 15 cm, the reach of the
  first rows on the raised footing and slab, a side step for a row's far end.
- The hop-ups and the scaffold (a raised spot with rails: comfort), the roof's rafters and tiles by hand and laser.
- The flat tray and finger motions on the emulator: a drag to spread (the bed at the real screen size), the saw's back and
  forth, the level's hold, the tape's drag; the tray's 104 px buttons.
- The meshes' cost in VR beside P5's budget (the room 30-78 meshes plus the HUD's canvas), 72 Hz.

## Tests and measurements

- **Unit** (`tests/unit/test_tools_*.gd`, `test_real_builder_data.gd`): the ten motions each done well, badly and almost,
  VR and flat (56); the sample (11); the device run on structured data and on L1's (12); the Tool Book (12); the stamps and
  the profile hooks (12); BrickBond (11: true sizes, bond at corners, openings with half bricks, lintels with their
  bearing, nothing floats, the push test); Real Builder's data (15: Life's rules, the auto player finishes every track
  with no hint, safety first, the tools' real motions, the numbers are BrickBond's, the mixer is the Tool Book's, kind
  British words, the units meet the School's bar, the safe mistakes shaped, the catalogue's entries).
- **Integration** (`test_real_builder_site.gd` 19: targets and views, work frames, the bench, everything on screen from its
  view, everything within reach in VR, only warmed shaders and no shadows, a house in at most 110 meshes, laying, the glow,
  the wall in bond, the test wall's split, the high block, the rise, lintels, the roof, goggles, the mixer, sawdust, the
  boxes' faces; `test_real_builder_host.gd` 15: L1's Experiences untouched, a tap never spreads, the wrong tool, the
  nearest brick, the mixer's order, the saw's safe mistake, Little / Middle / Big / the Expert try played through flat
  with no hint, VR: the tray hidden, a tool taken and used with its real motion, a brick carried, a squeeze lays nothing,
  Little and Middle played through in VR; `test_tools_book_page.gd` 10; `test_tools_hands.gd` 11: **all ten motions
  through the whole chain**, a Tool Book tool taken by a fake hand in a simulated headset and moved the real way (its
  ToolProp's tip, the trigger, the other hand for the claw), and each motion's phone gesture through a camera and a
  finger's rays, each done well and badly).
- **The smoke** (`tools/real_builder_smoke.gd`, 9 runs, a fixed clock): little, middle and big, flat, VR and the Expert
  try, all PASS: the wall 10 blocks in bond, the shed 564 bricks and the house 1,143 with every lintel, rafter and tile,
  nothing floating, the Tool Book's By myself stamps (4 tools on Little, 10 on Middle and Big), 30-78 meshes.
- Life's own tests and the shader census (16 files, 187 tests) pass on this branch.
