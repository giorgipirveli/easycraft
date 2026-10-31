# Balance Altar, phase B (owner #133, #134)

The brief: `docs/superpowers/plans/2026-10-18-game-altar-b1-brief.md` (B1, "the altar works"); the design:
`docs/design/games/balance-altar.md` (approved by the lead's review, which decides its open questions); the authority:
`docs/design/future-lessons.md` (the five tests). Built by the game agent on the worktree branch
`worktree-agent-a652751970651f0bd`, cut from lead-merge at `384a998b`. No editor, no emulator, no adb, no downloads, no
agents, no server change.

## 1. The pattern for the places

**Picked: Inside a Leaf's pattern** (merged meshes plus MultiMeshes on the census's vertex-colour materials, in places
that are `LifeRoom`s), with the altar's own kit.

- `AltarKit` (`entities/play/altar/`) builds every place from pieces with its own `Mesher` (boxes, lathes, tori, tubes,
  discs, panels, appended meshes), whose every triangle is turned to face along its first corner's normal (Godot's
  front face), so no part of the temple is lit from inside; `test_mesh_winding.gd` holds every mesh of the three places
  and every Glimmer to it. Four materials, all the census's: `lit` and `shiny` (the Theater's lit vertex colours; also
  instanced), `glow` (the launch blinker's unshaded vertex colours; also instanced: what gives light) and `glass` (the
  rainbow arch's see-through vertex colours; never instanced). `test_shader_warmup_sources.gd` proves the four in its
  census check and lists `altar_kit.gd` in COVERED (the only altar file that makes a material).
- `AltarRoom` (a `LifeRoom`) is the places' common contract: flat views, targets, VR stands (G0's and the leaf's), the
  ring of altars (`build_ring`: one MultiMesh of altars at rest, one of their crystals, one full `BalanceAltar` in the
  active slot; `set_active` turns the ring so the active altar is in front of the child), the focus (the current altar's
  targets become the room's), Hoot, the place's own sky and tone.
- `BalanceAltar` is one altar in about nine draws: its body (one lit mesh: dais, steps, pedestal, plaque, fluted pillar,
  the crown's two gold bars, beam, cords, pans, the tool stands, the gem bag, the bowls, the pump), its glow (the ice
  chains, the seal, the crystals' frost bands), the crystals (glass, rebuilt when they change), the sleeping Glimmers (a
  MultiMesh), the awake Glimmer, the gems, balloons and strings (MultiMeshes: a lift is an instance raised and tinted
  amber), the carved runes (one small mesh, rebuilt on every move).
- The rune line is **carved geometry**, never a label: seven-segment strokes for numerals, raised signs, the crystal's
  ice-blue icon, gold dots in rows of five (stacked, a ten-frame). `test_altar_place.gd` checks that the places hold no
  `Label3D` and that the plaque carves exactly `AltarRunes.line` at each stage.

*Rejected:* a node per gem or balloon (16 gems and 7 balloons a pan, hundreds of draws over a ring of altars);
`Label3D` runes (a billboard label is a different look from carved stone, and words in the place are what rule 0
forbids: the subject's symbols are geometry); a free-swinging physics beam (ruling 3 of the design: the chains hold it).

## 2. The rules, and the cheat test as a test

`core/play/altar/` (pure, seeded, no nodes), ported from `docs/design/games/balance-altar/model/altar_rules.py`:
`AltarState`, `AltarMoves` (the twin moves and the hands' waiting batch), `AltarSolver` (breadth-first, cached; the
ghost's next step, the budget), `AltarGen` (the model's forms and ranges), `AltarHalls` (data `data/play/altar/halls.json`,
`lines.json`), `AltarRunes` (the line at every stage of the fade, its reading, every rune's name), `AltarBeats` (each
altar judged into one SkillShown event), `AltarRun` (one room's flow, beyond §4.3's list like the leaf's `LeafRun`: the
help policy, the demonstrations, Hoot's cues), `AltarProgress` (`user://balance_altar.json`), `AltarTwinRules` (VR).

`tests/unit/test_altar_cheat_bots.gd`: the model's players (`tests/unit/altar_bots.gd`) play whole rooms through
`AltarRun` at the hands' level, 1,000 seeded visits each (57 s). The bar is MasteryRules' (the hall's 7 of 8, the Sky
Room's 5 of 6):

| Player | Entrance Hall (model) | first time, of 8 | Sky Room (model) | of 6 |
|---|---|---|---|---|
| knows the rule | **100 %** (100 %) | 8.00 | **100 %** (100 %) | 6.00 |
| knows it, slips on 4 % of moves | **94.8 %** (95.3 %) | 7.62 | 97.1 % (97.0 %) | 5.71 |
| keeps the balance, greedy (reported, not a cheat) | 100 % (100 %) | 8.00 | 100 % (100 %) | 6.00 |
| keeps the balance, no plan | 0.4 % (0.2 %) | 3.03 | 0.2 % (0 %) | 1.20 |
| guesses which move | 0 % (0 %) | 1.53 | 0.1 % (0.2 %) | 1.45 |
| habit: always take away | 0 % (0 %) | 4.00 | 0 % (0 %) | 1.00 |
| habit: divide by the number | 0 % (0 %) | 3.00 | | |
| **the hall's habit** (take away, then share) | | | **0 %** (0 %) | **2.00** |
| random moves | 0 % (0 %) | 0.34 | 0 % (0 %) | 0.16 |
| random taps | 0 % (0 %) | 0.16 | 0 % (0 %) | 0.05 |
| one pan only, carries across, weighs (chained beam) | 0 % (0 %) | 0 | 0 % (0 %) | 0 |

The test asserts the brief's thresholds (the rule at least 99 %, slips at least 90 %; every guesser at most 1 %; the
hall's habit never reaches the Sky Room's bar, the rule always does). **Checked against two mutations** (a one-pan lift
that counts; a judge that counts any freed crystal): both turn the test red, the second with every bot at 100 %.

The other tests (TDD, each failing first for the right reason): `test_altar_state` 7, `test_altar_moves` 18,
`test_altar_solver` 6, `test_altar_gen` 5, `test_altar_halls` 11, `test_altar_runes` 7, `test_altar_beats` 7,
`test_altar_run` 10, `test_altar_progress` 6, `test_altar_twin_rules` 5, `test_altar_place` 10, `test_altar_budget` 3,
`test_altar_cheat_bots` 5, and one in `test_mesh_winding`.

## 3. The pictures, and what changed after looking

`tools/altar_shots.gd` in a real window (the Vulkan Mobile renderer on this PC's Intel UHD, 1280 x 720), under nice,
one at a time; the final set in `docs/devlog/parts/game-altar-b/`: 01 the arrival, 02 the open door, 03 the hall, 04 an
altar as the child plays it (a gem lifted, amber), 05 an altar close up (three crystals, a cat asleep in each), 06 a
crystal freed (gold, its fox awake beside it), 07 the Great Altar at the chorus, 08 the dome and the lit chandelier from
below, 09 the Sky Room's altar (a gem from the bag waiting under a balloon), 10 the Sky Room wide. Four passes:

- **First look:** everything washed out (sun 1.05 and ambient 0.62 over near-white vertex colours, a big yellow pool of
  light on the floor; the Sky Room nearly white); the altar small in the frame; the crystal invisible against cream;
  gems pale lumps; Hoot showing his back (BlockyAnimal's owl faces -Z); every box's underside black (my `Color()`
  default is opaque black: the portico's ceiling); the arrival's dome hidden behind the pediment from the cloud stair;
  the dome's coffers stains and its ribs dashes; the chandelier's crystals too small to glow; a thin bright line down
  the door (the sky through the gap between the leaves); the far Mirror Halls a striped box (see-through halos in an
  opaque mesh).
- **Changed:** lights down (the hall's sun 0.74, ambient 0.4; the Sky Room's 0.72 and 0.4), richer sandstone floor
  bands, the pool a faint glow; the play camera closer (1.12 m up, 0.98 m in front); crystals bluer and more solid with a
  soft frost halo, the sleeping Glimmers bigger; gems deeper gold with their facets baked; Hoot turned; boxes'
  undersides their own stone; the arrival's drum given an attic and a taller dome, a lower portico, a coffered portico
  ceiling, the drifting gems glowing; the dome rebuilt as recessed coffers with gold rosettes; a bigger chandelier
  with star halos (crossed soft discs) and hanging drops; arched door leaves that overlap; windows with cloud wisps
  and a keystone (no painted sun, no keyhole bar); the Sky Room's floor in sharp bands (white stone, sky blue, gold) and
  its far halls a hazy temple on its own cloud; bigger runes (a 0.6 m plaque, glyphs up to 1.3x); deeper bowls with dark
  insides; the Great Altar's crystals 1.35x on wider pans; the freed Glimmer 1.4x.
- **Still for B2 and B3:** the beam's breathing, the chains snapping, the Glimmers' flight to the chandelier, the
  chorus's blaze, the door's swing, the cloud lift; the hall could take a little more evening mood once the HUD and
  the avatar are in.

## 4. The draws

The tests' count (`test_altar_budget.gd`: each visible mesh or MultiMesh one draw a surface) at the heaviest moments:
**the hall at the chorus 17** (the shell 3, the door 1, the ring 2, the sockets and their halos 2, the Great Altar 8,
Hoot 1), **the hall at an altar 17**, **the Sky Room full 17**, **the arrival 9**. With the HUD's 10-20, a flying
Glimmer's 1-3 and the VR hands' 4 on top: **32-44 in the hall** (the design's estimate 45-55; the Quest's budget 100,
aim 70), about the same in the Sky Room (estimate about 40). A real frame's draw calls in the window
(`RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`): the hall 15-17, the Sky Room 17-18, the arrival 8-10; 60-120 fps on this
PC's integrated GPU (not the emulator's check: B2's bench and the lead's emulator and Quest runs are).

## 5. Rulings (each with its cost if wrong)

1. **The altar's own mesher** (`AltarKit.Mesher`), not LeafKit's: every triangle faces along its normal by construction.
   *Cost:* a second mesher beside the leaf's (about 250 lines); they may drift.
2. **`AltarRun` beyond §4.3's list** (as the leaf's `LeafRun`): one room's flow (the help policy, the demonstrations,
   the cues) that both B2's host and the bots drive, so the cheat test tests what a child meets. *Cost:* B2's host
   must step it rather than AltarMoves directly.
3. **The bots act with the hands** (lifts, handfuls, the bag's gems pair by pair, the bowls), deciding as the model's
   players. A move the other pan cannot twin waits rather than breaking at once (as the place really works), so the
   habits' altars end at the cap (SHOWN) instead of after breaks. *Cost:* per-player break counts differ from the
   model's; every mastery number is within half a point of it.
4. **Every act counts toward the cap of 40** (a tap on nothing too, as the model's tapper). *Cost:* none in practice
   (the host forwards only taps on targets).
5. **Putting back returns the whole waiting batch.** *Cost:* to lift one fewer, put all back and lift again.
6. **A break while the batch cannot be twinned is noted "no twin"** (else "one pan"): the Sky Room habit's signature in
   the journal. *Cost:* none known.
7. **Consecutive shares merge into one operation** (the model's tag: sharing by 2 twice is one move). *Cost:* 4x = 12
   halved twice is SOLVED; the lead may want it stricter.
8. **The rack has 2-6 bowls** (the model searched to 12). No hall or Sky Room altar needs more than 4; the numbers are
   unchanged. *Cost:* phase C's bigger shares need a bigger rack.
9. **A pan holds at most 16 things in phase B** (the model's top Great Altar: 3 crystals of 4 and 4 gems; four rows of
   five), the twin forms' ranges are phase C's. *Cost:* the design's "12-15" is exceeded once.
10. **AltarGen's ranges are the model's**, inside G6AlgebraGen's except one gem beside the crystal (the generator's
    a starts at 2). *Cost:* the gentlest altar is one rung below the generator.
11. **The taught altars have fixed numbers** (x + 2 = 5, x + 3 = 7, 2x = 6) so their lines hold ("Two crystals weighed
    six"). *Cost:* a replay shows the same three teaching altars.
12. **Altar 5's demonstration frees it** (the ghost sets two bowls and presses the seal, §3.5 step 5); altar 6 is the
    child's first share (judged). *Cost:* the child never presses the seal on a taught altar.
13. **The Great Altar's event is NEW_SETTING** (the lead's ruling 6), noted "the Great Altar"; MasteryRules counts it in
    the 7 of 8 like SOLVED and the round keeps it apart as transfer. *Cost:* if the lead meant it should not count
    towards the hall's star, `AltarBeats.masters` and the room's record change (the hall would need 7 of 7).
14. **Help is noted by kind** (ghost step, eye, hint, ghost freed it); H16's hint is help, S3 (`remind_goal`) is not
    (the design's ruling 16). *Cost:* none.
15. **Praise follows a counted altar only, by strategy** (take, share, straight to the answer), never twice in a row.
    *Cost:* a helped altar gets no praise line (its see-why instead).
16. **The Great Altar's Glimmer is a dragon** (the hall's biggest); the Sky Room's six are birds. *Cost:* one more
    Glimmer model.
17. **The rune line is carved geometry**: seven-segment numerals, the crystal's icon, gold dots in rows of five
    stacked as a ten-frame (not one long row: sixteen fit the plaque). *Cost:* numerals look carved and angular; phase
    C needs glyphs for y, x², ÷, <.
18. **The ring's altars face out** (the child walks the walkway between the ring and the wall; the ring turns).
    *Cost:* from the hall's middle the altars show their backs.
19. **The Great Altar** is 1.45x in structure, its pans 1.04 m apart (two hands' reach) at the same height, the bag and
    bowls on taller stands; its view and VR stand at the hall's middle. *Cost:* in VR the child is moved there (B2's
    blink).
20. **Hoot is BlockyAnimal's owl** (head and all, wound right since the lead's fix) in a teacher's cap, one draw.
    *Cost:* none (one owl for the game, as the lead wished).
21. **One light, the place's own `LifeRoomSun`; the worlds' ACES tone kept with the place's own warm ambient**
    (`AltarKit.own_tone`); the rooms' default sky dome hidden and each place's own sky drawn. *Cost:* the hall's sky is
    painted (windows, oculus, the door's view).
22. **The ring's crystals are opaque and glowing** (instanced glass is not warmed); only the active altar's are
    see-through with their Glimmers. *Cost:* far crystals show no sleeper.
23. **The places keep what they show** (`_hidden_slots`, `_shown`, `_lifted`) and never read MultiMesh data back: a
    headless renderer keeps none (finding 1). *Cost:* none.
24. **The arrival's drum is taller outside than the hall's wall inside** (an attic, 8.4 m against 6.4 m) so the dome
    rises above the pediment from the cloud stair. *Cost:* outside and inside differ by an attic nobody can see.
25. **The tools stand at hip height** (the bag and the pump on the left, the bowls on the right, tops at 0.5 m) so the
    VR hands reach them from the stand. *Cost:* they stand on pedestals rather than "at the altar's foot".
26. **The play camera** is 1.12 m up and 0.98 m in front of the active altar, looking at 0.6 m: every target in the
    free band and over a fingertip (the crystal and the seal the tightest, about 60 px). *Cost:* the chandelier is out
    of the play view (the wide and chorus moments show it).

## 6. Findings for the lead

1. **A headless renderer keeps no MultiMesh instance data**: `get_instance_transform` reads back nothing useful, so a
   test that asks a MultiMesh what it shows passes or fails by accident. The altar's places track what they set.
2. **The cheat test can be mutated red**: worth keeping as a habit for every game's bots (a rule broken and a judge too
   kind each turned this one red).
3. **The design's Great Altar estimate** (twice the size) needs its pans within two hands' reach in VR: 1.04 m apart is
   the most `test_altar_place` allows (1.1 m).

## 7. What works (B1), and what B2 needs from the lead

**Works:** the rules (section 2), the bots as tests, the places and ten pictures (section 3), the draws (section 4).
**Not yet** (the brief's B2 and B3): `AltarTempleHost` (input, camera, the ring's glide, the demonstrations shown, the
voice, the record, the end card, VR), `AltarHud`, sounds and music, juice.

**B2 needs:** (1) the registry hook for a game with its own host, once Inside a Leaf's B2 merges it (an entry
`"balance_altar": {"name": "Balance Altar", "host": "res://entities/play/altar/altar_temple_host.gd"}`); (2)
`g6.maths.equations`'s play block `{"game": "balance_altar", "params": {"room": "entrance"}}` (the School's content
file); (3) Back and the pause key to the temple (`AltarTempleHost.any_open` beside `PlayHost.any_open` in `menu.gd`, W1's
`room_open` / `close`); (4) the Academy's Maths door (`AcademyPlaza.opens`) for the unit; (5) the lead's word on rulings
7 (merged shares) and 13 (the Great Altar in the bar); (6) later, a census phase through the temple
(`tools/shader_probe_steps.gd`) so a browser's first sight compiles nothing.

## 8. The full suite

Right before it, lead-merge was merged into the branch (`cfe651b3`: two documents only) and `tests/run_tests.sh` ran once
on that tree under the PC-wide slots, uncut: **12,341 tests in 1,338 scripts, 12,338 passing, 0 failing, 3 risky or
pending** (the known ones: the voxel column cache's two tests don't assert, the Nakama move is off), 5,636 s, no script
errors. In it the bots' numbers were section 2's.

Before it, the repo's scans caught one thing in my files: `test_no_guilt_words.gd` found the word "streak" in
`AltarProgress`'s saved keys (the fade's counter of altars in a row). EasyCraft has no streaks, so it is `in_a_row`
now (`541dfaab`); the scans (no guilt words, English only, identity words, inner classes, the assets pack, the updater)
and the altar's files reran green before the full suite.

## The lead's review of B1 (2026-10-18 11:15)
**B1 passes.** The rules (with `AltarRun`, one room's flow driven by both the host and the bots), the cheat bots as tests
(the rule 100 % in both rooms, 94.8 % and 97.1 % with slips; every no-rule player at most 0.4 %; the hall's habit 0 % in
the Sky Room) with two deliberate mutations that turned them red, the places and ten pictures (looked at: the temple on
sunset clouds, the coffered dome and the chandelier, the altars with frosted crystals and gold gems, the runes "3♦ =
12" and "2♦ + 1 = 7", the Sky Room's balloons: beautiful), the draws (32-44 with the HUD and the hands, of the Quest's
100), every temple mesh in `test_mesh_winding.gd`. Merged into `lead-w1b`: 205/205 on the altar, winding, warm-up and
registry files. Decisions:
- **Two sharing moves in a row count as one:** accepted (sharing by two twice is sharing by four: a correct path, and
  first-time right).
- **The Great Altar towards the hall's 7 of 8:** accepted; ruling 6 meant the Great Altar alone never gives the
  one-step unit its first star (it is recorded as NEW_SETTING), not that it is left out of the hall's count.
- **B2's hooks:** in the B2 brief (`docs/superpowers/plans/2026-10-18-game-altar-b2-brief.md`).
