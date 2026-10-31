# VR round 4, VR-WONDER: hold a planet, the telescope and the magnifier, the Lab bench by hand (owner #110)

The owner (2026-10-16 11:24, #110): "research what can be done else, what exciting things with vr". The plan:
`docs/superpowers/plans/2026-10-16-vr-round4.md` (the VR-WONDER row); the research with each idea's design, rulings and
sources: `docs/devlog/parts/vr-ideas-research.md` (§5.3 ideas 1, 2 and 4, §6, §7: R7 "zoom only inside the lens"). This
agent is **VR-WONDER**, in the worktree branch `worktree-agent-a31292368d2c108aa` from `lead-merge` at `0705d40d` (VR-HANDS'
shared grab, VR-SOUND, Life L1, the cars), beside Life L2 and the Tools agent (none of their files touched). Built on
VR-HANDS' grab (`docs/devlog/parts/vr-r4-hands.md`: `VrGrabber`, `VrGrabbable`, `VrGrabRules`): a planet is a
`VrGrabbable` of kind `&"two_hand"`, the lenses and the magnet `&"tool"`, the Lab's cubes `&"hold"`. No editor, no emulator,
no adb, no download. Logs: the session scratchpad's `vrwonder_*`.

## What a child does in the headset

- **Hold a planet (idea 1).** Fly up through the sky until the Star Map opens: the solar system is a moving orrery in
  front of you, a little more than a metre across, under the map's panel. The planets go round the Sun where they really
  are today (an Earth year in 40 seconds), their moons round them; Uranus spins on its side. Put a hand near one and it
  waits for you. Squeeze: it is in your hand, and it grows to its real size against Earth (Earth 4 cm, Jupiter 45 cm, the
  Moon 1 cm), its bands turning, its card open on the panel (its three facts read aloud with "Read to me"; the Space Book
  learns it). Both hands on it and pull apart: it grows. Earth in one hand, Jupiter in the other: "Jupiter is 11 times as
  wide as Earth!" floats over the orrery. Let go: it glides home. Drop it in the gold LAND ring beside the orrery: you
  fly there, as the card's LAND (or HOME); a planet with no ground says so on the panel. TRUE SIZE (on the panel): every
  planet glides into a row in its true size before a Sun 1.3 m across (109 Earths); ORRERY puts them back.
- **The telescope and the magnifier (idea 2).** Choose the Telescope (or the Magnifier) in the palette's SMART page (the
  LOOK row; in Survivor they are in your things for free): it is in your pointing hand. Hold the telescope up and look
  at its round eyepiece: far things come close inside it, an animal across the valley, a tower, the Moon in the night
  sky. Squeeze the trigger: 2x up to 8x, steadied so a shaky hand still sees. The zoom is only ever inside the lens; the
  world around never changes. The magnifier shows what is behind its glass two to four times bigger; hold it over sand,
  a leaf, a tree trunk, snow, ore: within 60 cm the glass shows what the eye can't (sand's grains, a leaf's veins, the
  trunk's rings, snow's six-sided crystals, gold flecks) with its name and a short fact ("Sand is tiny bits of rock and
  shell, worn down by water and wind."). Choose another hotbar slot: it is put away.
- **The Lab bench by hand (idea 4).** Tap a lab bench and choose Float or sink? (or Magnetic or not?): a real bench
  stands in front of you at hand height (its green handle lifts or lowers it). On its shelf: little cubes of wood, stone,
  ice, an iron nail, a leaf, a gold ring, a dry sponge, a glass marble (the magnets' run: a paper clip, a copper wire, a
  food tin...). Put each in the basket you think, FLOATS or SINKS: that is your guess (the panel says "On the bench: put
  each cube in the basket you think it goes in."). Press TRY IT! on the panel. Take each cube and let it go over the
  water tank: it bobs at the top or sinks to the bottom, as the Lab says ("The wood floats!"). Magnets: take the red
  magnet and hold it near each thing: the iron nail, the steel paper clip and the steel food tin jump to it from 10 cm
  with a click and a buzz and hang there; the wood, the glass, the gold, the copper and the pebble are tried when you
  touch them, and stay put. WHAT HAPPENED? and the why cards come after the doing, on the panel; the Lab Book's star as
  before.

## The School's units (every wonder teaches)

Checked against the curriculum (each a real unit with its lessons written: the rules' tests).

| Wonder | Units (`OrreryRules.UNITS`, `LensRules.UNITS`, `LabBenchRules.units_of`) |
|---|---|
| The orrery | g4 science "How rockets work", g5 "The Sun and other stars", g8 "The solar system", g8 "Gravity and orbits"; maths g6 "Ratios" (Jupiter 11 Earths across, the Sun 109), g7 "Scale drawings" (TRUE SIZE is a scale model); the Space Book (each planet taken) |
| The lenses | g4 science "Light and seeing", g6 "Light travels" (a lens bends light); what the magnifier shows: g3 "Rocks and soils", g4 "Plant and animal parts", g3 "Materials and their properties", g4 "States of matter" (ice, snow) |
| The Lab bench | the experiments' own: float or sink g3 "Materials and their properties", g5 "Properties of materials"; magnets g3 "Magnets", g5 "Properties of materials", g8 "Electricity and magnetism"; and g3 "Working like a scientist" (predict, try it, find out why) |

## The ids

Items **TELESCOPE 500** and **MAGNIFIER 501** (`data/items/item_ids.gd`, `ItemIds.LENSES`, `is_lens`; 502-511 stay free),
names "Telescope" and "Magnifier", icons drawn in code (`ui/hud/lens_icons.gd`, `LensIcons`, hooked in `BlockIcons.icon`).
No block id, no atlas tile.

## How it is built

| What | Where |
|---|---|
| The orrery's sums: real diameters (NASA's fact sheets), places today (StarMap.longitude), sizes on the orrery, in a hand and in TRUE SIZE, the TRUE SIZE row, the ring, the comparison words, the School units | `core/vr/orrery_rules.gd` (`OrreryRules`) |
| The orrery: bodies as `VrGrabbable`s (`&"two_hand"`), one MultiMesh of 16 spheres (a small shader: per-instance colours and bands, lit from the orrery's Sun), the Sun, Saturn's ring, the orbits, the LAND ring, the comparison label | `entities/vr/vr_orrery.gd` (`VrOrrery`) |
| The Star Map's VR branch: the orrery under Vr while the map is open, a planet taken opens its card (read aloud), the ring's drop = LAND / HOME / why not, TRUE SIZE; the flat map's solar system hidden and its stars one draw (CanvasBatch) in a headset | `ui/space/space_panel.gd` (`vr_orrery`, `true_size_button`, `vr_land`, `_vr_*`) |
| The lenses' sums: zoom, field of view, steady filter, close-ups (block id → picture, name, fact), School units | `core/vr/lens_rules.gd` (`LensRules`) |
| The lens in the hand: VrGrabbable `&"tool"`, a SubViewport camera (VrPhotoCamera's way), the round disc, the magnifier's close-up and fact; `keep_in_hand` (the hotbar's lens in the pointing hand) | `entities/vr/vr_lens.gd` (`VrLens`) |
| The close-up pictures (17, our own, procedural) | `entities/vr/vr_lens_closeups.gd` (`VrLensCloseups`) |
| The lenses in the VR palette (SMART's LOOK row; Survivor's owned view: free); a lens is never placed as a block | `ui/hud/block_palette.gd` (VR only), `entities/player/block_interactor.gd` (`place_block`) |
| The bench's sums: its place and lift, the shelf, the baskets, the tank, where things rest, the magnet's reach, the School units | `core/vr/lab_bench_rules.gd` (`LabBenchRules`) |
| The bench: cubes as `VrGrabbable`s (`&"hold"`, one MultiMesh), baskets, the tank, the magnet (`&"tool"`), the handle; the guess through the Lab's `LabPredict.tap`, a drop or a pull through the Lab's view's own thing buttons (`LabThingsView.thing_buttons[i].pressed`) | `entities/vr/vr_lab_bench.gd` (`VrLabBench`) |
| The Lab panel's VR branch: the bench while float-or-sink or magnets shows (PREDICT, TRY, WHY), its 2D copies hidden and the words for the bench | `ui/lab/lab_panel.gd` (`vr_bench`, `vr_step`, `vr_words`, `_vr_*`) |
| The draws bench | `tools/vr_wonder_bench.gd`, `tools/vr_wonder_bench_steps.gd` |

**VR-HANDS' grabber: VR-WONDER's small additions** (marked "VR-WONDER" in `entities/vr/vr_grabber.gd`; nothing of the
frozen contract changed): `give(side, g) -> bool` (puts a grabbable in a hand as a grip would: the hotbar's lens comes into
the hand without a grip), `take_back(g)` (lets go of it quietly: the lens put away frees the hand at once), and one call
at the end of `step`, `VrLens.keep_in_hand(self, delta)` (the session's only per-frame place outside `autoloads/vr.gd`,
which stays untouched: the lens needs a frame hook in every VR session and VrLens keeps all its logic). Why they were
needed: a lens is the hotbar's item, so it must be in the hand without a squeeze, and its trigger must be the lens's (a
held grabbable's `used`), never a tap that would ask the host for block 500.

Other small hooks: `ItemIds` (the two items; `is_item`, `is_free_tool`), `BlockIcons.icon` (one line),
`BlockPalette._smart_page` and `_show_owned` (VR only), `BlockInteractor.place_block` (a lens is never a block, as a pet
treat), `test_shader_warmup_sources.gd`'s census (the three new VR scripts, "rare: VR only").

## Rulings (the cost if wrong)

- **RW1: the orrery stands under the eye panel** (its middle 0.65 m ahead and 0.55 m under the eyes, 1.06 m across),
  not at chest height as the research had: the eye panel takes every laser that reaches it (VR-UI), so the far pull to a
  far-side planet must pass under the panel's bottom edge. [A child must look down a little: raise `ORRERY_DROP` if the
  panel moves or shrinks.]
- **RW2: a planet in a hand is its true size against Earth** (Earth 4 cm; Jupiter 45 cm, Saturn with its rings 87 cm,
  Pluto 7 mm), on the orrery the flat map's sizes ("bigger means bigger"); **the Sun is never taken** (a hand-size Sun
  would be 4.4 m). [Jupiter feels too big to hold: `HAND_EARTH_RADIUS` smaller; the Moon and Pluto too small: true, kept.]
- **RW3: a hand near a planet, or holding, locking or pulling one, holds the orrery's time still** (the flat map's open
  card does the same). [Children want the orrery moving while they hold one: time only stops on a hover.]
- **RW4: planets are never thrown**; let go, they glide home in 0.6 s. The ring takes a planet whose middle **or the hand
  that let it go** is within 13 cm of the ring's middle (a 45 cm Jupiter fits no 18 cm ring). [A child who throws one at
  the ring: a throw-to-ring along the release velocity.]
- **RW5: the landing ring is on the pointing hand's side** (beside the orrery, a little up and towards the child); it does
  exactly what the card's button does (LAND, HOME), else opens the card and says why on the panel (no ground, coming soon,
  a mission needed, you are here). [None known.]
- **RW6: TRUE SIZE is sizes, not distances**: one scale for every body (Earth 1.2 cm, the Sun 1.3 m behind the row); at
  that scale Earth would be 141 m from the Sun and Neptune 4.2 km. [Distances wanted: a TRUE DISTANCE walk later.]
- **RW7: in a headset the flat map's solar system is the orrery**: the panel hides its 17 solar bodies, their orbits and
  captions, and draws its 160 stars and the planet below as one draw (`CanvasBatch`); the far worlds (Planet Boing, the
  universes), the card and the buttons stay. The Star Map in VR was 433 draws (355 of them the canvas); now 166.
  [A child who wants to tap a planet on the panel with the laser takes it from the orrery instead.]
- **RW8: the lenses are VR's for now**: not in `ItemIds.ALL` (no palette row, chest or shop off VR: phones and the web
  unchanged); in VR the SMART page's LOOK row, and in Survivor's owned view as free tools (never counted, like the
  paints). A lens left in a hotbar and tapped off VR asks the host for nothing. [The research's "Survivor finds the
  telescope" needs a loot change that touches off-VR chests and their tests: the lead's call; "off VR a zoom view in the
  HUD" is the research's later small task.]
- **RW9: the lens is in the pointing hand while it is the hotbar's item** (the grabber is given it; letting go of the grip
  keeps it, as a sword stays in the hand); another slot puts it away. The other hand may take it. [The pointing hand's grip
  cannot step the hotbar while a lens is held: the other hand's grip or the wrist hotbar does.]
- **R7 (the research's) kept: the zoom happens only inside the lens.** The lens camera's field of view is what the disc
  covers from the eyes divided by the zoom (`LensRules.fov_degrees`: an 8 cm eyepiece at 40 cm covers 11.4°, so 8x sees
  1.4°); the telescope looks along its tube, the magnifier along the line from the eyes through its glass. The head's
  camera, its field of view and the current camera never change (the test checks all three).
- **RW10: the steady filter** turns the lens camera towards the lens's aim at `STEADY_RATE / zoom` = 32/zoom a second (a
  zoomed tremor is magnified by the zoom, so it is smoothed by as much). [At 8x the view lags about a quarter second behind
  a quick turn: `STEADY_RATE`.]
- **RW11: the magnifier's close-up** shows within 60 cm (`CLOSE_RANGE`) of a block that has one, in place of the
  magnified view (its camera rests: no second render); the name and the fact float over the glass whenever the close-up
  shows and are read aloud once a run ("Read to me"). [The jump from the world to the drawing is abrupt: a crossfade.]
- **RW12: the lens's own meshes are on render layer 1 << 16**, which its camera never draws (the magnifier's camera saw
  its own disc: Vulkan's "same texture in framebuffer attachment and a uniform", every frame); the head draws that layer.
  [A new feature that takes layer 17 must pick another.]
- **RW13: the close-ups are drawn in code** (17 pictures of 96 px, a fixed seed each), not texture files: no import, no
  download, our own work. [The owner wants photographs: CC0 macro photos, credited.]
- **RW14: the bench** starts 0.45 m ahead and 0.45 m under the eyes (seated children too); its handle (a green post at
  its right end) moves it with the hand between 0.2 and 0.8 m under the eyes. The things are 5.5 cm cubes in the
  material's colour (wood brown, iron dark grey, gold yellow...), their name shown while a hand is on one. [Children
  can't tell the cubes apart: little pictures on their faces.]
- **RW15: the bench speaks through the Lab's own controls**: a cube in a basket is `LabPredict.tap` until it is in that
  group (TRY IT! opens on the panel when every cube is sorted); a cube let go over the tank, or a thing the magnet
  catches, presses that thing's button in the Lab's 2D view, so the Lab's tested model decides, the Lab says what happened,
  plays its sound and opens WHAT HAPPENED?. While the bench is open those 2D copies are hidden (P5's budget) and a line
  says what to do on the bench. [In VR the laser cannot sort with the cards: the bench is the way; the cards come back
  with the bench gone.]
- **RW16: the magnet's pull** reaches a magnetic thing 10 cm from its surface (`PULL_REACH`) and tries any other only at
  a touch (3 cm): the pull through the air is the lesson; a stuck thing hangs from the tip (a 160 Hz click buzz) and goes
  with the magnet. [The reach feels too long or short on the headset: the two constants.]
- **RW17: only float-or-sink and magnets are done by hand** for now; heat, colours, plants and the circuit stay on the
  panel (the research's "later"). [None: the next round's.]
- **RW18: the orrery, the lens and the bench live under `Vr`** (added by their panels: the orrery and the bench go on
  while a game played alone holds still for the map, and go with the session); a closed one's grabbables are disabled at
  once (a test found a closed bench's cube taken in the frame before it was freed).

## Draws beside P5's budget (at most 100 in play)

`tools/vr_wonder_bench.gd` (the VR preview on the Quest APK's platform, the `vr` preset, Green Meadows NEW seed 12345,
6 s a phase; this desktop's frame rates, never a Quest's; `lens` is the lens's own viewport, inside `draws_3d`):

| Phase | draws (average) | most | scene (3D) | canvas | lens |
|---|---|---|---|---|---|
| playing, looking ahead | 98.2 | 101 | 76.1 | 22.1 | |
| playing, looking down | 100.0 | 100 | 78.0 | 22.0 | |
| the Star Map with the orrery (the game held still) | 166.0 | 166 | 84.0 | 82.0 | |
| TRUE SIZE | 165.0 | 165 | 83.0 | 82.0 | |
| a planet in the hand (its card open) | 189.0 | 189 | 84.0 | 105.0 | |
| the telescope at 8x | 105.8 | 107 | 80.8 | 25.0 | 5.5 |
| the magnifier (its magnified world) | 108.0 | 108 | 83.0 | 25.0 | 7.0 |
| the Lab bench, float or sink | 142.0 | 142 | 84.0 | 58.0 | |
| playing again after | 102.9 | 103 | 77.9 | 25.0 | |

The orrery is **+6 scene draws** (one MultiMesh for 16 bodies, the Sun, Saturn's ring, the orbits, the LAND ring and its
word; +1 for the comparison while two planets are held). Before RW7 the Star Map alone drew 433 in a headset (355 canvas:
every star, orbit and body a draw of its own); now 166, most of it the panel's far worlds and card. A lens is **+5 to +7**,
nearly all of it the lens's own small render (a 1.4° frustum sees little); the magnifier's close-up stops that render.
The bench is **+6 scene draws** (the bench with its baskets and handle, the cubes, the glass, the water, two basket words,
the cube's name while a hand is on one); hiding the Lab panel's 2D copies took the Lab in VR from 207.5 to 142. The canvas
rises by 3 once a lens is in the hotbar (its icon). Like VR-HANDS' table (102), a lens in play sits a few draws over P5's
100 on Green Meadows, whose 16-cube blocks are P5-1's price (VR-HANDS: 32-cube blocks with the physics thread give ~46
back).

## What only the Quest 3 can check (the lead, on the owner's headset)

- The orrery: its place under the eye panel (seen without strain, a near planet reached, a far one pulled by the laser
  under the panel), its 1.06 m size, the planets' look (bands, the lit side towards the Sun), the Sun bright but never
  glaring, Uranus on its side; Jupiter 45 cm in the hand (exciting, or too big?), the two-hand stretch, the comparison's
  words readable; the ring's catch; TRUE SIZE's 1.3 m Sun behind the panel.
- The telescope: the eyepiece disc at arm's length (readable, comfortable), the steady view at 8x (`STEADY_RATE`), the
  zoom felt only inside (no unease); the magnifier: holding it over sand and leaves, the switch to the close-up, the fact's
  letters (1.7 cm at 0.0005 m a pixel). The lens's second render on the Quest's GPU (the desktop counts 5.5-7 draws; the
  sun's shadow pass in that viewport is the unknown): watch VR_BENCH's GPU ms with a telescope at 8x.
- The bench: its height for a standing and a seated child, the handle's lift, the cubes' size for small hands, the
  baskets' drop, the tank's see-through look (glass, water and cubes sorted right), the magnet's 10 cm pull and its click.
- Whether the eye panel (drawn over everything) ever covers the orrery or the bench for a small child (both sit under its
  bottom edge for an adult's eye height).

## Tests

`tests/unit/test_vr_r4_wonder_orrery_rules.gd` (15: the real sizes and the Star Map's facts agree, places today, orbits
in order and in reach, moons, sizes on the orrery, in a hand and in TRUE SIZE, the row, Saturn's ring, the landing ring,
the words, the year, the Sun never taken, the School units), `_lens_rules.gd` (10: the two items and that they stay out of
the catalogue, their icons, the zoom, the field of view, the steady filter, the close-ups and their facts, the close
range, the School units), `_bench_rules.gd` (9: the bench's place and lift, the shelf, the baskets, eight in a basket, the
tank, a floater and a sinker, the magnet's reach, the words, the School units); `tests/integration/test_vr_r4_wonder_orrery.gd`
(13: the orrery in VR under the panel, the flat map's solar system hidden and back, off VR as before, a planet taken grows
and opens its card, read aloud, two hands stretch it, Jupiter and Earth compared, let go it glides home, the ring's LAND,
no ground says why, here says so, TRUE SIZE, time held still, gone with the map and the session), `_lens.gd` (8: the
telescope in the hand, the zoom only inside the lens (R7) and its own layer, the steady view, the magnifier over sand,
the grip keeps it, another item puts it away, the VR palette, off VR nothing), `_bench.gd` (8: the bench at hand height,
the panel's words and hidden copies, a guess in a basket and TRY IT!, the tank's floats and sinks with the Lab's words
and the star, the magnet's pull, the handle, the bench with its experiment and the Lab, off VR as before). Every VR test
(`tests/**/test_vr_*.gd`, 62 scripts): 490/490 before the full run.
