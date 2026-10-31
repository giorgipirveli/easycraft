# The rocket flight: fly it yourself, from the pad to the Moon (owner #79, #86, #87; spec §25.3, §21d.4)

The owner: "when ship is built, you just sit into it at steering wheel and fly to moon, you actually fly into moon, here
we need real animations and visuals" (#79); "on the space ship we should have visuals from different movies" (#86);
"landing on mercury should be done like real landing" (#87, the coordinator's addition mid-task: the landing reusable on
its own, played by the Star Map's LAND). Brief: `docs/superpowers/plans/2026-09-29-rocket-flight-brief.md`. Built by a
worker agent in its own worktree (branch `worktree-agent-acd55e8e9377851b0`, reset to `lead-merge` ece9d079), without
the editor, the emulator or adb; pictures and frame times from windowed and headless runs of `tools/flight_shots.gd`.

## Allocations (used; nothing else touched)

| What | Where |
|---|---|
| New code | `entities/flight/*` (RocketFlight and its rules and nodes), `ui/flight/*` (the cockpit), `tools/flight_*.gd`, `tools/make_flight_textures.py`, `tools/make_flight_sounds.py` |
| Pictures, sound | `assets/flight/` (earth, moon, mars, mercury, dust, noise, cloud; engine_roar.wav), `tools/data/earth_mask.png` (with a `.gdignore`: never imported) |
| Tests | `tests/unit/test_flight_*.gd` (8 files), `tests/integration/test_rocket_flight.gd`, `test_flight_cockpit.gd`, `test_flight_looks.gd` |
| Small additions to shared files | `scenes/sandbox.gd` (section "Owner #79, #86, #87: the rocket flight"; `space.travel = land_on_space`; `_rocket_local()` after `_space_local()`), `scenes/main.gd` (`--fly-moon`, `--fly=`, `--land=`), `ui/menus/menu.gd` (FLY ROCKET in the developer menu's WORLD row), `core/platform/keys_rules.gd` (4 lines), `project.godot` + `tools/setup_input_map.gd` (7 input actions), `data/shader_warmup.json` (3 draws, phase `flight`), `tests/unit/test_shader_warmup_sources.gd` (6 scripts listed) |
| Block ids, pages, HUD spots | none (the missions' page 32, ids 560-575, is drawn when it exists; before that its ids get a stand-in look) |
| Never touched | `core/rules/rocket_check.gd`, `mission_rules.gd`, `launch_site.gd`, `entities/launch`, `ui/missions` |

## What a child sees and does (the Moon, a two-stage rocket; about 2 minutes, up to 2.5 with the waits)

1. **Sit at the controls** (BOARD, 3 s). LAUNCH at the Mission Board: the camera glides from the child's own view into the
   capsule of the rocket they built, standing on its pad. The cockpit lights up: the hull round a big window, the dashboard
   with glowing green screens (SPEED 0.0 km/s, HEIGHT ABOVE EARTH 0.0 km, TO THE MOON 384,400 km, TRIP 0 min, FUEL a bar
   per stage), the Moon's hologram turning (its real seas in one glowing colour, scan lines drifting), the steering wheel,
   the big orange THROTTLE lever on the left, the round ACTION button on the right, MENU, OUTSIDE (and SKIP on a repeat
   visit). "Climb in and buckle up! You are the pilot."
2. **The countdown** (10 s): big yellow numbers 10 … 1, each with a beep and spoken aloud (the device's voice). At 3 the
   engines light: flame at the rocket's foot, white smoke billowing out over the pad, a small shake.
3. **Lift-off** (6 s): "Push the throttle all the way up!" The rocket waits, roaring, until the child pushes the lever up
   (a drag, or Shift on a PC), or taps LIFT-OFF!, or (after 5 s) the autopilot does it. "Lift-off! We have lift-off!" The
   camera cuts to the ground beside the pad: the rocket they built rises on its flame, smoke rolling over the pad, the
   view shaking.
4. **Up through the clouds** (18 s): back inside, the ground drops away through the window, the sky darkens, "Steer into
   the green ring!" (a ring the child keeps round the nose; it wanders a little so there is something to do; kind words
   after a while, "Nudge down to aim at the green ring!"). Clouds rush down past the window, everything white, and out
   of them: the Earth's curve below (oceans, continents, white clouds), the sky black with stars, the rocket leaning
   over toward the horizon.
5. **STAGE** (5 s): "Stage 1 is empty. Let it go: press STAGE!" The ACTION button glows STAGE; outside, the empty
   booster falls away tumbling with a puff, the next engine lights. "It falls back to Earth. Now the rocket is lighter!"
   Its FUEL bar is crossed out.
6. **Orbit** (16 s): "We are in orbit! Going round the Earth at almost 8 km every second!" (the dial: 7.8 km/s). The Moon
   appears as a small ring ahead: "Aim at the Moon and hold the throttle to burn!" The child holds BURN (or Shift) for
   2.5 s; the speed climbs to 10.9 km/s. "Off we go to the Moon!" The Earth swings away behind, huge and blue.
7. **The trip** (22 s): "Off to the Moon! The real trip takes 3 days: we show it in 20 seconds." The distance counts down
   (128,619 km …), the trip clock runs (1 day 13 h … 3 days), the speed slows away from Earth and quickens near the Moon;
   the Earth behind is a blue marble, the Moon ahead grows from a dot into a big grey world with its real seas (Imbrium,
   Serenitatis, Tranquillitatis …) and craters (Tycho's rays, Copernicus), half in sunlight.
8. **Into orbit round the Moon** (12 s): "Turn round: the engine must push against our way to slow us down!" The rocket
   turns round; "Hold the throttle to burn, or we fly past!"; the Moon fills the view below. "We are in orbit round the Moon!"
9. **The landing** (18 s): "Coming down from orbit over the Moon: the engine burns to slow us down!" (the lander tips
   upright, its engine burning, the Moon's surface curving below), then "Landing legs out: press LEGS!" (four struts swing
   out), "Steer over the landing pad. Hold the throttle for a soft landing!": the grey ground rises, boulders, the landing
   pad in the brand's teal with a golden star, the Earth hanging in the black sky; near the ground the engine blows the
   dust away in a ring.
10. **Touchdown** (4 s): a thud, a burst of dust, the fanfare: "Touchdown! You flew to the Moon!" The screen fades, the
    Moon world loads: the child stands on the landing pad ("You landed on the Moon! Jump: you float!"), the lander they
    flew standing a few steps to their left.

**Mars** (and Mercury, Venus): the same to orbit, then **light speed** ("Light speed! The stars stretch into lines. Real
rockets take about 7 months to reach Mars. Real rockets cannot go faster than light: light speed is our game's
shortcut!"): the stars stretch into long lines, a white flash, the lines rush past; a **warp tunnel** of gold and
rainbow streaks ("A warp tunnel! Only in stories and games: our shortcut through space."); "Here comes Mars!" growing
red ahead (the dark lands, the canyon, the volcanoes, the white cap); no burn into orbit: a **fiery entry** ("Mars has
air! Rushing through it makes the heat shield glow hot!": a glowing shield, plasma streaming past, the shake, the
butterscotch air), **CHUTE** (a striped orange and white parachute opens), then the engines and the legs, the landing on
the pad in a butterscotch sky. **Europa, Io**: light speed, **the asteroid belt** ("millions of rocks going round the Sun
between Mars and Jupiter. Steer past them! (Really they are far apart.)": lumpy rocks tumbling past, never in the way),
the warp tunnel. **Titan, Saturn's rings, Pluto, Triton**: light speed, the belt, **a wormhole** (the game's own golden
portal swirl opening ahead, then a twisting teal and violet tunnel: "Scientists wonder if shortcuts like this could exist.
Nobody has found one yet."). **Planet Boing, Rainbow Planet** (our own far planets): the wormhole and **a nebula** (big
soft clouds of pink, teal, gold and violet drifting past: "where new stars are born").

**The landing on its own** (owner #87; the Star Map's LAND, ~14 s): the small default lander in orbit over the world
("Coming down from orbit over Mercury: the engine burns to slow us down!"), tipping upright, the legs coming out by
themselves, the ground rising, the engine's dust, touchdown on the pad, then the world. Worlds with air: a short fiery
entry and the parachute instead of the burn down. Nothing waits for the child (the autopilot does the legs and the
chute); the child may steer over the pad. SKIP from the second visit on.

**Controls.** A phone: the THROTTLE lever (drag it up; let go and it springs back down: a burn is held), the round ACTION
button (it says what to do now and glows), OUTSIDE/INSIDE, MENU, SKIP; a drag anywhere else steers (110 px is a full
turn). A PC (owner #84): WASD or the arrows steer, Shift is the throttle, Space (or Enter) the ACTION button, V inside or
outside, Esc the menu; the lever and the button show their keys ("Shift", "Space"); the KEYS card has four new lines. The
mouse works the buttons and the drag like a finger.

## The interface (for the lead)

- **The missions' LAUNCH** calls the sandbox's `fly_rocket(rocket) -> String` (their `fly` Callable): `{"destination",
  "cells" {Vector3i: id, relative to the pad's corner, y up}, "stages" [[Vector3i …] bottom first], "seats"}`, optionally
  `"origin"` (Vector3: the pad's corner in the world; without it the rocket stands 7 blocks in front of the child).
  Returns "" when it lifts off, else the words why not (another world's file missing, friends in the game, flying not
  allowed there). One flight at a time. `landed(destination)` → the sandbox's `_travel_space` (the landing's words and
  dust as before), then the lander parks by the pad (`FlightTicket.parked`, this session).
- **The Star Map's LAND** → `space.travel = land_on_space` (the landing on its own, then the world). The missions agent
  may change the Star Map (the MISSION state): keep `land_on_space` as the travel callable when merging.
- `RocketFlight.start(rocket, from_world)`, `land(destination, lander = {})`, `abort()`, `skip()`; signals `landed`,
  `ended`, `pause_requested`. The sandbox passes hooks: take_over (hide and hold the player, the HUD, the interactor;
  close the Star Map and the KEYS card), world_light, sky_climb, keep_safe (`health.protect` every 2 s: nothing hurts the
  child left on the pad), ground_at, ui_parent (the cockpit goes under the pause menu).
- **QUIT** in the pause menu aborts a flight (everything put back); the pause menu holds it (the flight's clock stops).

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **Keys:** the walking keys steer (W nose up, never inverted: the child pushes toward where they want to go), Shift is
   the throttle, Space/Enter the ACTION button, V the view: seven `rocket_*` actions (the cockpit takes every key but Esc
   and F1 while flying, so the game underneath never walks or toggles). *Cost:* the bindings in `tools/setup_input_map.gd`.
2. **The throttle springs back** ("hold to burn"), on a phone and a PC; the big ACTION button is a full throttle for
   LIFT-OFF and a held BURN. *Cost:* `FlightCockpit.THROTTLE_SPRING`, one rule in `_process`.
3. **Never stuck, never a crash:** the rocket waits 5 s for the child at every action (`FlightPlan.ACTION_WAIT`), then the
   autopilot does it kindly (a burn: it holds the throttle itself); off the target for 6 s the autopilot brings the aim
   back (`FlightSteering.AUTOPILOT_AFTER`), and the aim never gets farther than 25°. *Cost:* constants.
4. **Two minutes of play:** the Moon's steps are 116 s (with 5 actions at most 141 s); every destination 119-125 s; the
   landing on its own 13.5-14 s. *Cost:* the seconds in `FlightPlan.steps` / `landing_steps`.
5. **The movie moments by destination** (owner #86): the Moon none (its real trip is the show); Mars, Venus, Mercury light
   speed and the warp tunnel; Jupiter's moons light speed, the asteroid belt (really between Mars and Jupiter) and the
   tunnel; Saturn's and beyond light speed, the belt and a wormhole; our own planets and any other world a wormhole and a
   nebula. The words always say it is the game's shortcut and what is true. *Cost:* `FlightPlan.moments`.
6. **Air means entry and a parachute** (Mars, Titan, Venus, Boing, Rainbow), no burn into orbit (the air slows it). *Cost:*
   `FlightPlan._AIR`.
7. **The camera follows the story** (inside to board and count down, the launch camera on the ground at lift-off, inside
   up through the clouds, outside for the stage, orbit and the landing) until the child presses OUTSIDE/INSIDE: from then
   their pick holds. *Cost:* the steps' `view`, `RocketFlight._view`.
8. **The world only to the clouds:** the rocket rises 320 m over the real pad, then under the clouds' white-out the scene
   becomes the flight's own space set (60 km over the world, its own visual layers, light and sky). The voxel world
   cannot show 100 km. *Cost:* `FlightShots.CLOUD_AT`, `RocketFlight.SET_OFFSET`.
9. **Scale:** a world close by is a sphere of 20,000 set units; far away it is drawn nearer and smaller with its size in
   the sky kept; the destination is never smaller than 1.1° (a dot to aim at) and the Earth behind never smaller than 2°
   (a marble). The dials show the real numbers. *Cost:* `FlightSet.MIN_TARGET`, `EARTH_MIN`.
10. **The cockpit is 2D** over the 3D view (the inside camera does not draw its own rocket). *Cost:* a 3D interior later.
11. **The seat and the engines are read from the blocks:** the seat on the rocket's axis in the top stage's layer under
    its nose; each stage fires from its bottom layer. With the missions' part ids known, the capsule and engine parts could
    place them exactly. *Cost:* `RocketStages.seat`, `nozzles`.
12. **Stages** are ordered by their lowest block; a block in no stage joins the nearest; a stage cell with no block goes;
    the last STAGING lets every lower stage go (only the top stage, the lander, lands). *Cost:* `RocketStages.normalize`,
    `FlightRun._complete`.
13. **Unknown ids** (the missions' parts before their page exists) are the painted-white tile tinted by id (white, silver,
    red, orange, sky blue, gold). *Cost:* `RocketMesh.TINTS`.
14. **The lander stands by the pad** 7 blocks to the child's left (the portal home is in front), a box to bump into, for
    this session (not saved). *Cost:* a WorldMeta field to keep it.
15. **SKIP on a repeat visit** (the Space Book says LANDED): a whole flight skips to its landing, a landing on its own ends
    at once. *Cost:* `sandbox._been_to`.
16. **The Star Map's LAND always plays the landing** (owner #87), first visit or not (SKIP after the first). *Cost:*
    `space.travel` back to `travel_to_space`.
17. **The countdown is spoken** with the device's voice every time (`ReadAloud.speak`, like a speaker button), the other
    words only with "Read to me" (`ReadAloud.auto`). *Cost:* one call each.
18. **Distances** are the average from Earth (the middle of nearest and farthest): the Moon 384,400 km, Mars 225 million,
    Mercury and Venus 150 million, Jupiter's moons 778 million, Saturn's 1.43 billion, Triton 4.5 billion, Pluto 5.9
    billion; our own planets "far, far away". **Trips** as real spacecraft: the Moon 3 days (the crewed trips), Mars about 7
    months, Venus about 4 months, Mercury about 7 years (they loop round planets to slow down), Jupiter about 6 years,
    Saturn about 7, Pluto about 9, Neptune about 12. **Speeds:** orbit 7.8 km/s, leaving for the Moon 10.9 (planets 11.5),
    arriving at the Moon 2.3 into a 1.6 km/s orbit, Mars's entry 5.6. Sources: NASA's solar system and mission pages
    (distances, trip lengths), the Apollo-era figures for the Moon's trip (in general words in the game: no mission name).
    *Cost:* `FlightDials` tables.
19. **No film's, mission's or brand's name** anywhere in the flight's words (`test_flight_plan.gd` checks a list); the
    moments are our own look (the game's portal swirl, gold and rainbow, teal). *Cost:* none.
20. **The Earth's coastlines are Natural Earth's** (public domain, like the classical recordings), everything else drawn by
    our script; the Moon's, Mars's and Mercury's features at their real places from the IAU gazetteer (rounded). *Cost:*
    replace the mask with our own continents.
21. **The flight never loads a world's descriptor on its first frame:** the skies of the worlds with air and Mercury's big
    Sun are copied into `FlightLooks` (a test keeps them equal to the worlds' own). *Cost:* keep the copies in step (the
    test fails when a descriptor changes).

## Frame times (this shared PC; the lead measures on the emulator)

The flight's own work per frame (`flight_tick`, headless, CPU): **0.23-0.52 ms on average in every phase**, worst 0.5-4 ms,
~8-14 ms on the touchdown frame (the dust burst and the fanfare). Every phase after the boarding runs at the 60 FPS cap
in a window.

Windowed, 1280 × 720, 60 FPS cap, a new Sandbox world, the flight 6 s after the spawn (`tools/flight_shots.gd`); the PC's
load average 8-22 (other agents' suites):

| Run | Boarding (3 s) | Countdown | Lift-off | Ascent … Landed |
|---|---|---|---|---|
| Moon, OpenGL (`--rendering-method gl_compatibility`, the emulator's and the web's renderer), 01:22 | worst 133 ms, 3 frames > 100 | worst 98 ms, 0 > 100 | worst 128 ms, 1 > 100 | worst 31 ms, none over 33 ms; avg 16.7-17.0 |
| Moon, OpenGL, 00:37 (load 8) | worst 150 ms, 1 > 100 | worst 105 ms, 1 | worst 89 ms, 0 | worst 21.5 ms |
| Mars, Vulkan Mobile renderer, 01:24 | worst 136 ms, 2 > 100 | worst 77 ms | worst 57 ms | worst 62 ms (the switch into space), else 16.7 |
| Mercury, landing on its own, OpenGL | first second: worst 142 ms, 2 > 100 | | | worst 17.7 ms |

- **The countdown's and lift-off's long frames are this desktop's voice:** `DisplayServer.tts_speak` blocks 55-90 ms on
  Linux (speech-dispatcher; measured: 60, 66, 71 ms for "10", "9", "8"); the flight's tick without it is under 3 ms.
  Android's and the browser's speech are asynchronous: the emulator will show whether its countdown is clean.
- **The boarding's (and a landing's first second's) long frames are shaders compiled at first sight**: the tool starts
  the world directly, so the game's warm-up (which has the flight's three new draws in its census, phase `flight`) never
  ran; the flight also draws each of its looks once, one a frame, during the boarding's glide. In the real game on the
  web/OpenGL the menu's warm-up compiles them first.
- **Fixed on the way** (measured before → after): the LAUNCH frame 560 ms → 50 ms (the refusal loaded every space world's
  descriptor: 290 ms; the looks loaded the Moon's descriptor: 360 ms); a landing's first frame 138 → 65 ms headless (the
  map waited behind other threaded loads: 270 ms; the Sun and the ground now come a frame later); the world's scene
  compiles RocketFlight on a worker as it appears; the set, the moments and the cockpit's screens are built a piece a
  frame over the boarding; fog stays on in the flight's space (a 143 ms compile at the landing on OpenGL gone).
- **Draw calls and particles:** the rocket a surface per block material per stage (the test rocket 3-5 per stage), the
  stars one mesh (700 quads), the Earth and the destination one sphere each (64 × 32), the landing ground 3 (dust, pad,
  rocks), each moment 1 (the asteroids one MultiMesh of 40, the nebula 7 quads); particles: the flame 48, the trail 36,
  the pad's smoke 56, the engine's dust 40, the plasma 40, all halved on LOW (`Fx.scaled`). Textures: 4 maps of 1024 × 512
  (lossless with mipmaps; only the Earth's and the destination's load in a flight, on worker threads), 3 small ones.

## Textures and their sources

| File | Size | Source |
|---|---|---|
| `assets/flight/earth.png` | 1024 × 512 RGBA (clouds in alpha) | Natural Earth 1:50m land, lakes, glaciated areas (public domain) via `tools/data/earth_mask.png`; colours and clouds drawn by `tools/make_flight_textures.py` |
| `assets/flight/moon.png` | 1024 × 512 grey | drawn: 21 seas and 12 named craters at their real places, 1,400 small craters |
| `assets/flight/mars.png` | 1024 × 512 RGB | drawn: dark and bright lands, 5 volcanoes, the canyon, both caps at their real places |
| `assets/flight/mercury.png` | 1024 × 512 grey | drawn: 4 basins (Caloris …), the northern plains, 4 rayed craters, 1,800 craters |
| `assets/flight/dust.png`, `noise.png`, `cloud.png` | 256², 256 × 128, 128² | drawn (tiling ground, other worlds' patches, the nebula's puff) |
| `assets/flight/engine_roar.wav` | 1 s, 22,050 Hz mono | our own noise (`tools/make_flight_sounds.py`), a forward loop |

Everything else is the game's own: the blocks' atlas pages (the rocket), Fx's particles, the golem's glow (the flame, the
pad, the heat shield), the night sky's material (stars, the Sun's disc, light speed's lines, the nebula), the portal swirl
(the wormhole's mouth); two new shaders (`planet.gdshader`, `tunnel.gdshader`) and the hologram's canvas shader.

## Tests and checks

- 89 tests: `test_flight_stages` 10, `test_flight_rocket_mesh` 9, `test_flight_plan` 11, `test_flight_run` 9,
  `test_flight_dials` 9, `test_flight_steering` 6, `test_flight_shots` 9, `test_flight_ticket` 4, `test_rocket_flight` 11,
  `test_flight_cockpit` 7, `test_flight_looks` 4. Plus the developer menu's, the KEYS card's and the warm-up sources'
  tests with the new lines.
- `tools/flight_smoke.gd`: 24 checks, 0 fails (the missions' fly, one flight at a time, the pause menu, QUIT, a whole flight
  to the Moon in 115-119 s, the lander by the pad, the Star Map's landing on Mercury in 13 s). The space smoke (34 checks)
  and the Mars, Europa, Io, Titan and Mercury smokes pass with the landing in their Star Map trips.
- **The full suite, twice** (2026-09-30, the PC's load 12-22 with other agents' suites):
  - 01:34-02:14: 848 scripts, 7,831 tests, 7,829 passing, 2 risky as before; one assert failed that GUT's summary did not
    count (grep the log for `[Failed]`): `test_audio_credits.gd` (the roar credited with the wrong path; fixed). Files were
    edited while it ran (it skipped `test_rocket_flight.gd` and hung at the engine's exit: killed); the threaded loads a
    flight leaves are now always taken (`FlightLooks.settle`, the sandbox's `tree_exiting`).
  - 02:05-02:45, nothing edited: 869 scripts (inner test classes counted), **7,996 tests, 7,991 passing, 2 risky as before
    (`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`), 3 failing**: the settings panel's HELP
    page measured 797 px high (over 720) in `test_install_offer_menu`, `test_settings_access_page` and
    `test_settings_words_page`, while the same run's own prints of that page say 613 px. The three pass alone, after every
    flight test, and after their neighbours (`test_pc_mode` … `test_settings_panel`: 74 passing, the page 613 px); the
    page uses none of the flight's code. For the lead's merge suite to recheck. `test_flight_cockpit` built its screens a
    frame late once (fixed: the test builds them).
  - Every flight test file passes alone and together (48 with the settings tests); the flight and space smokes pass
    (24 and 34 checks), and the Mars, Europa, Io, Titan and Mercury smokes pass with the landing in their trips.

## What the lead must wire and check on the emulator

Wire: the missions' `fly` → `sandbox.fly_rocket` (with `"origin"` = the pad's corner); keep `space.travel =
land_on_space`; after merging `data/shader_warmup.json`, run the census if it was re-made, then
`godot --headless --rendering-method gl_compatibility --path . --script res://tools/flight_census.gd`; the missions'
page 32 needs nothing (RocketMesh reads registered pages).

Check on the emulator (the developer menu's FLY ROCKET, WORLD for Mars or Titan; or LAND on the Star Map):
1. **The boarding** (the first 3 s after LAUNCH): frames over 100 ms? (the builds are spread a piece a frame; the
   shaders are in the census: did the menu's warm-up reach the LATER tier?)
2. **The countdown and LIFT-OFF!**: Android's speech should not block (it does on this Linux desktop).
3. **Lift-off from the pad** at MEDIUM and LOW: the flame, the trail, the pad's smoke with the world around (the launch
   camera sees a lot of terrain).
4. **The clouds' white-out** (the switch into space; a compile there is hidden under white).
5. **The Earth's and the Moon's big views** (full-screen spheres: fill rate), **the nebula** (7 big see-through quads:
   overdraw) and **the warp tunnel** (a full-screen added glow).
6. **The landing** (the ground, the pad, the dust) and **the Star Map's landing on Mercury and the Moon** (~14 s).
7. **The feel of steering** with a finger (the drag's reach, 110 px; the lever), and on a PC with the keys.
8. **Both styles**: the rocket's blocks in REALISTIC (checked here in a window: they restyle with the world).
9. **Arrival**: the child on the pad, the lander a few steps to the left.

## Next (the game never ends, #71)

The crew in their seats (phase 2, spec §21d.6), flying home from the planet in the lander (§21d.4), the lander kept in the
save, a 3D cockpit interior, the missions' part ids placing the seat and the engines exactly, Jupiter and Saturn hanging
in the sky on the way to their moons, Venus's cloud city's arrival (it floats: no ground), more movie-style moments (a
comet's tail, a solar flare seen safely), the trip home to Earth with its own fiery entry and splashdown.
