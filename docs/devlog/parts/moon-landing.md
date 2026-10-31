# Owner #106: a real landing, and what a crash costs (2026-10-15/16)

The owner (2026-10-15 23:19): "landing a rocket to the moon is simply too easy. So failing while descending from the
moon. To the earth and you will have half the hearts. Even the rocket is falling like you and when it crashes down on
to earth, some parts break and have to rebuild it. But it's random. But not catastrophic like 1 block survived and 99%
is damaged." Brief: `docs/superpowers/plans/2026-10-15-moon-landing-brief.md`. Branch `worktree-agent-a5c74f295f6669dea`
(from `lead-merge` 79c0a1d5).

## What a child sees

**A good landing.** The trip is as before up to the landing (the autopilot still takes LIFT-OFF, STAGE, a burn, LEGS
or CHUTE for a child who waits: a trip never sticks before the landing). LEGS out, the ground rises to 120 m, then the
words say "Now you land it! Hold the throttle to slow the fall. Touch down slower than 3 m/s." Over the dashboard three
big dials: HEIGHT in metres (and a bar emptying toward the ground), SPEED in m/s in its colour (green: there is room to
slow down, and near the ground a safe touchdown; yellow: slow down now; red: too fast; blue: going up) with "safe: under
3 m/s" under it, and the lander's FUEL. The panel's frame glows the same colour. A beep quickens as the ground comes up
(higher and quicker when red). Short words on the yellow line change with the colour: "Good speed. Watch the colours.",
"Careful: slow down a little.", "Slow down! Hold the throttle!", "Good: gently now.", "Going up! Ease off the
throttle.", "30 seconds of fuel left: down gently, not too slow.", "10 seconds of fuel left! Land now!", "Out of
fuel!" (read aloud when they change, at most every 2.5 s). The throttle lever, Shift, or the big BURN button held (full
throttle) slow the fall; 40% holds the lander still. Touchdown at 3 m/s or less: "Touchdown at 1.8 m/s: a soft landing!
You landed it yourself!", the dust, the fanfare, the Moon's world loads as before ("Mission complete!").

**The first try** on a world (never landed there: the same rule as SKIP's) is the easy one: it starts at 80 m falling
4 m/s with half as much fuel again, and a card holds it still first: "LAND IT YOURSELF! Hold the THROTTLE (or BURN) to
slow the fall. Keep the speed GREEN and touch down slower than 3 m/s. Watch your fuel!" with GO! (ACTION and Space are GO
too; after 10 s it goes by itself).

**A crash.** Faster than 3 m/s (or out of fuel above the ground, nothing slows the fall): a bump, dust, the lander tips
over. "Too fast: the lander crashed on the Moon! Everyone is safe: the capsule's rescue rockets carry the crew up and
away." The capsule lifts off the dust; inside, the Earth ahead grows: "Heading home to Earth. Real landers crashed too:
Beresheet in 2019 and Luna 25 in 2023. India's lander crashed in 2019, and their next one landed on the Moon in 2023!"
(the distance screen says TO EARTH). A fiery re-entry ("Into Earth's air: the heat shield glows hot!") into the clouds,
and out of them over the home world: the capsule under its orange-and-white parachute comes down beside the pad (14 m to
its side, never on the rocket standing there): "The parachute opens. Home, by the Launch Site!". The camera on the
ground looks at the pad: "Look up: your rocket falls too!", the whole rocket tumbles down beside the pad and hits the
ground in a cloud of dust; at that moment 15-35% of the parts of the rocket standing on the pad break (puffs of dust at
each), and the words say "9 parts broke: rebuilding costs 120 gold. Rebuild at the Mission Board and try again!". The
screen fades, and the child stands at the Mission Board with the HUD back: Survivor "Home safe, with half your hearts.
Rest a little: they come back by themselves." (the hearts come back by themselves, 1 HP every 3 s after 5 quiet
seconds), the Sandbox "Home safe! The Sandbox keeps your hearts: only some rocket parts broke." (it shows hearts for its gentle monsters, but a knock-out costs nothing there: ruling 21). About 25 s from the crash. The
Moon is not on the route (only a landing puts it there): the Star Map still says "Mission needed".

**The damaged rocket and the rebuild.** 2.5 s later the Mission Board opens on MY ROCKET: "Your rocket crashed: 9 parts
broke. Rebuild them: 120 gold." (spare parts that cover it: "… Your spare parts cover them: BUILD IT FOR ME puts them
back."). BUILD IT FOR ME puts the plan's missing cells back (the Sandbox: free to build; Survivor: from the bag, BUY THE
MISSING PARTS first as for any rocket); BUY THE PARTS FOR THIS ROCKET asks "Buy 9 parts for 120 gold?"; LAUNCH again.
A child who walked away sees the line at the next walk-up.

**A practice landing.** The Star Map's LAND ends with the same descent as a practice ("Practice landing! …"): a crash
is only a bump ("Bump! 5.2 m/s is too fast: slower than 3 m/s is safe. Try again from the top!"), the lander back at
120 m after 1.5 s; after 3 tries Mission Control lands it ("Mission Control landed this one for you. Practise again next
time!"). No hearts, no parts. SKIP on a repeat landing still lands at once.

**Crew flights.** The pilot flies the descent; each crew member's cockpit shows the pilot's descent on its own dials
("Anna lands us: watch the speed! Green is safe."). The pilot's crash is everyone's: every crew member's flight plays the
same way home and ends by the host's Launch Site; the host halves every crew member's hearts in Survivor (it decides
hearts); only the host's rocket breaks; nobody's world moves; a crew member's words add "Home with your crew! The rocket
is your pilot's to rebuild: then try again together."

**VR** (the seated flight, owner #101): never a shake (FlightShots.vr_pose covers the new poses); the way home is a fade
cut: the view darkens over the crash's second half, the flight jumps to the rocket's fall (out of sight, black: the
parts still break), and the seat lets go with Vr's blink at the Mission Board.

## The numbers

| What | Value | Why |
|---|---|---|
| Safe touchdown | ≤ 3.0 m/s | The Apollo lunar module's landing gear was specified for touchdowns up to 3.05 m/s (10 ft/s) straight down (2.13 m/s with 1.22 m/s across); flights stayed well inside (source 1). |
| Descent start | 120 m, falling 8 m/s (easy: 80 m, 4 m/s) | ~15 s for a good pilot, ~8 s to the ground for nobody: room to react, never long. |
| Engine | 2.5 × the world's pull at full throttle (hover at 40%) | Sims (scratchpad `landing106/sim2.py`): 3 × was too forgiving; 2.5 × makes a late reaction (0.8 s, red only) crash. |
| Pull | real surface gravity, kept in 1.0-3.71 m/s² | Moon 1.62, Mars 3.71, Mercury 3.70, Io 1.80, Ganymede 1.43, Titan 1.35, Europa 1.31; Pluto (0.62), Triton (0.78), the rings (0.49) play at 1.0; Venus (8.87) and Boing (5.89) at 3.71. |
| Fuel | 20 s of full throttle + 2 s per fuel tank in the lander, at most 30 s (easy × 1.5) | A good pilot uses ~8 s; a child hovering at 1.5 m/s all the way runs dry (50 hover-seconds), with the 30 s and 10 s call-outs first. |
| Colours | green: v ≤ √(3² + 2·0.5·brake·h); yellow up to 0.85·brake; red above; blue going up | brake = engine − pull: green means half the engine still stops it in time. |
| Damage | 15-35% of the rocket's parts, at least 1 (a share drawn per crash, rounded, clamped to ⌈15%⌉…⌊35%⌋) | The owner's "random, not catastrophic". |
| Which parts | weights: engines, space engines, tanks, fins 3; nose cone, separator 2; capsule, service module, heat shield, parachute, legs, solar array 1 | Over 300 seeded crashes engines/tanks/fins broke far more than twice as often as the crew's parts (test). |
| Hearts | min(hp, ⌈max/2⌉), never below 1 | "half the hearts": 20 HP → 10; never a knock-out, never a heal. |
| Practice | 3 tries, 1.5 s on the ground between | Never stuck. |

Mission Control's Moon rocket (36 parts, 450 gold) loses 6-12 parts: 30-230 gold to rebuild (1,000 seeded crashes,
`test_mission_controls_moon_rocket_loses_6_to_12_parts`).

## Files

- `entities/flight/flight_descent.gd` (new, `FlightDescent`): the descent's pure rules (physics in 1/60 s steps,
  zones, words, beeps, fuel from the lander's tanks, the easy first try and its hold, `snapshot`/`follow` for the crew,
  `test_pilot` for tests and smokes only).
- `core/rules/rocket_crash.gd` (new, `CrashRules`): damage, weights, words, `rebuild_gold`, `hearts_after`, the fact.
- `entities/flight/flight_plan.gd`: DESCENT/DESCEND after LANDING (6 s now, legs; a landing on its own 3-3.5 s),
  `descent_step`, `crash_steps` (CRASH 3.5, ESCAPE 6, HOME_ENTRY 4, HOME_CHUTE 6, WRECK 4.5, HOME 3.5 s).
- `entities/flight/flight_run.gd`: DESCEND gives the throttle to the descent (no autopilot, `act` never completes it);
  a crash replaces the steps after the DESCENT with the way home; `practice`, `PRACTICE_TRIES`, `helped()`,
  `crashed()`, `descent_over`, the snapshot's "d"/"crash" for the crew, `test_throttle()`.
- `entities/flight/flight_shots.gd`, `flight_dials.gd`: the poses (tilt, side, wreck, look) and dials (metres, TO EARTH,
  the lander's fuel from the descent; DESCENT holds most of the lander's fuel weight).
- `entities/flight/rocket_flight.gd`: `first_try`, `wreck`, `crashed`, the descent's cockpit state, beeps, words, the
  falling rocket (`wreck_node`), the VR fade cut; a crashed flight puts everything back and frees itself.
- `ui/flight/flight_cockpit.gd`: `_DescentDials`, the hint card (`go_pressed`), BURN in the descent, TO EARTH.
- `entities/launch/launch_director.gd`: `crash_damage(seed)`, `notice_crash(words)`, `crash_notice`.
- `core/rules/mission_data.gd`: `lost` per device and `lose_parts` (merged by the bigger count; the parts owned are
  bought less broken). Not in `core/save` (the accounts agent's).
- `scenes/sandbox.gd` (section "Owner #106"): `_on_flight_crashed`, `mission_crash`, `_crash_hearts`, `_crash_home`,
  `_crash_words`, `_flight_wreck`; `_start_flight` sets `first_try`, `wreck`, `crashed`.
- `ui/missions/crew_flights.gd`: `crashed()` (host) and `follower_crashed()`; `core/missions/crew_flight_rules.gd`:
  DESCEND's crew words, `CRASHED_HOME`.
- Tools: `tools/mission_smoke_steps.gd` (the crash, the rebuild, the flown landing), the child of
  `tools/flight_smoke_steps.gd`, `tools/flight_shots_steps.gd` and `tools/net_test.gd` flies the descent.

## Rulings (each with what it costs if wrong)

1. **Safe speed 3 m/s** (the Apollo LM gear's 3.05 m/s, rounded down). *Cost:* `FlightDescent.SAFE_SPEED`, the words
   and the hint card say "3 m/s".
2. **The descent is the last 120 m** (the easy try 80 m), the LANDING before it shortened to 6 s (from 14-16). *Cost:*
   `START_HEIGHT`, `EASY_HEIGHT`, `landing_steps`.
3. **The pull is real but kept between 1.0 and 3.71 m/s²** so every world plays (Pluto's would take a minute; Venus's
   thick air would brake a real lander). *Cost:* `G_LEAST`, `G_MOST`; Venus and Boing at Mars's pull.
4. **"The lander's fuel from its real tanks"**: 20 s of full throttle plus 2 s per fuel tank in the lander stage, at most
   30 s; the FUEL dial is the lander's gauge (the share of its tanks kept for the landing, ~64% at the descent's start,
   times what the descent has left). *Cost:* `fuel_for`, `FlightDials._BURNS[DESCENT]`.
5. **Out of fuel above the ground is not a crash by itself**: the engine stops and the fall decides (from any height
   that matters it is a crash; a lander a few centimetres up still lands). *Cost:* one line in `FlightDescent.tick`.
6. **No autopilot on the descent; every other action keeps its autopilot** (LEGS too: the legs are not the landing).
   *Cost:* the DESCEND branch of `FlightRun._wait`.
7. **The easy first try** is "never landed on this world" (the Space Book's LANDED, SKIP's rule): it repeats until a
   landing, so a child who keeps crashing keeps the easy one. *Cost:* `RocketFlight.first_try` in `_start_flight`.
8. **The Star Map's LAND is a practice** (no hearts, no parts), with Mission Control landing after 3 tries (a trip that
   loads a world must never stick). *Cost:* `FlightRun.practice`, `PRACTICE_TRIES`.
9. **The way home is the crew's capsule's** (a launch-escape style lift from the crash, then a re-entry and parachute
   over the home world); the "rocket" that falls by the Launch Site is a copy of the whole rocket (the one that flew),
   and the rocket standing on the pad is the one that breaks. *Cost:* `crash_steps`, `_wreck_tick`.
10. **The damage is drawn when the falling rocket hits** (WRECK at 45%), by the host's sandbox, seeded with `randi()` per
    crash and printed (`MISSION crash: … (seed N)`), so the child sees the pad lose its parts. *Cost:* `_flight_wreck`.
11. **15-35% of the rocket's parts, rounded and clamped to ⌈15%⌉…⌊35%⌋, at least 1** (1 wins over 35% for a rocket of
    1-2 parts, which can't fly a mission anyway). *Cost:* `CrashRules._count`.
12. **The crew's parts break less often** (weight 1 against 3 for engines, tanks, fins; 2 for the rest). *Cost:*
    `CrashRules.WEIGHTS`.
13. **Broken parts are gone**: from the pad (air) and, in the Sandbox, from what the child owns (`MissionData.lose_parts`,
    per device and merged by the bigger count so the server backup never brings them back); Survivor's came from the
    bag and are not refunded. An older game reading a newer save ignores `lost` (it would show the broken parts as
    owned again until the newer game saves). *Cost:* `lost` in `mission_data.gd`.
14. **The board's gold is what rebuilding really costs**: the parts the rocket had less what the child still owns (the
    Sandbox) or has in the bag (Survivor), so spare parts make it cheaper. *Cost:* `CrashRules.rebuild_gold`.
15. **Half the hearts = min(hp, ⌈max/2⌉), never below 1**: never a knock-out, never a heal; the regeneration brings them
    back. *Cost:* `CrashRules.hearts_after`.
16. **Home is the Mission Board's front** (the board opens 2.5 s later on MY ROCKET with the crash's line). *Cost:*
    `_crash_home`, `LaunchDirector.NOTICE_SECONDS`.
17. **A crew crashes together; the host decides hearts** (host-authoritative, `Session.broadcast_health`) and only the
    host's rocket breaks; no world moves. *Cost:* `mission_crash`, `CrewFlights.crashed`.
18. **VR: a fade cut** to the rocket's fall (black), never the ride home; the parts still break. A VR crew member whose
    pilot is not in VR sees black for the whole way home (~25 s; VR is stopped). *Cost:* `_on_step`'s ESCAPE jump,
    `_vr_place`.
19. **Real landers' names in the way home's words** (Beresheet, Luna 25, India's lander): the brief asked for them;
    rocket-flight ruling 19 (no film's, mission's or brand's name) still holds for every other word, and the crash steps
    are in `test_no_film_s_or_mission_s_name_anywhere` now. *Cost:* `CrashRules.FACT`.
20. **The tools' child flies the descent with `FlightDescent.test_pilot`** (`FlightRun.test_throttle`), never the game.
    *Cost:* those helpers.
21. **"Where hearts count" is where a knock-out costs something** (`ModeRules.LOSSES`: Survivor). The Sandbox does show
    hearts (`DAMAGE`, for its gentle night monsters) but a knock-out costs nothing there, and the lead's brief says the
    Sandbox has no harm and its cost is the parts: its hearts stay whole and the words say so. *Cost:* one condition in
    `mission_crash` and `_crash_words` (`LOSSES` → `DAMAGE` halves the Sandbox's hearts too).
22. **QUIT during the way home** (the pause menu) aborts the flight like any: if the rocket had not hit the ground yet,
    nothing on the pad breaks and the child keeps the hearts. *Cost:* none (a rare, kind edge).

## The facts and their sources

1. Apollo LM landing gear: the specification touchdown envelope went to 3.05 m/s (10 ft/s) vertical, 2.13 m/s (7 ft/s)
   with 1.22 m/s (4 ft/s) horizontal, and all landings were within it. W. F. Rogers, *Apollo Experience Report — Lunar
   Module Landing Gear Subsystem*, NASA TN D-6850 (1972), figures 6 and 8:
   https://ntrs.nasa.gov/citations/19730010151
2. Beresheet (SpaceIL, Israel) crashed on the Moon on 11 April 2019: a command to reset a failed inertial measurement
   unit set off a chain that shut the main (braking) engine down; it restarted too late.
   https://www.planetary.org/articles/software-command-doomed-beresheet ,
   https://www.timesofisrael.com/5-6-attempts-to-restart-israeli-moon-landers-engine-failed-investigation-finds/
3. Luna 25 (Roscosmos) crashed on 19 August 2023: a pre-landing orbit burn ran 127 s instead of 84 s.
   https://spacepolicyonline.com/news/luna-25s-engines-fired-longer-than-planned/ ,
   https://us.cnn.com/2023/08/21/world/russia-luna-25-crash-cause-engine-issue-scn
4. India: Chandrayaan-2's lander crashed during its final descent on 6-7 September 2019 (a software glitch);
   Chandrayaan-3 landed near the Moon's south pole on 23 August 2023, with strengthened legs and more fuel.
   https://en.wikipedia.org/wiki/Chandrayaan-2 ,
   https://www.downtoearth.org.in/science-technology/india-becomes-first-nation-to-soft-land-on-south-side-of-moon-91332
5. Surface gravities (m/s²): NASA's planetary fact sheets (Moon 1.62, Mars 3.71, Mercury 3.70, Venus 8.87, Io 1.80,
   Europa 1.31, Ganymede 1.43, Titan 1.35, Pluto 0.62, Triton 0.78). https://nssdc.gsfc.nasa.gov/planetary/factsheet/
6. A capsule under its parachutes comes down at about 7-8 m/s (the HOME_CHUTE dial's 7 m/s, rounded).

## Tests and runs

- New: `tests/unit/test_landing_descent.gd` (16), `test_landing_run.gd` (9), `test_landing_shots.gd` (8),
  `test_crash_rules.gd` (10), `test_crash_parts.gd` (4); `tests/integration/test_landing_flight.gd` (7),
  `test_crash_launch_site.gd` (6), `test_crash_crew.gd` (2).
- Changed for the new rule (the autopilot never lands now): `test_flight_run.gd` (nobody touching anything reaches the
  descent, crashes and comes home; a child who does what is asked lands), `test_flight_plan.gd` (DESCENT in the order,
  the actions, the landing on its own's practice descent, the crash steps in the names check), `test_crew_follow_run.gd`,
  `test_rocket_flight.gd`, `test_crew_flight_follow.gd`, `test_vr_rig_rocket.gd` (their child flies the descent with
  `run.test_throttle()`; a landing on its own takes about half a minute now).
- The missions smoke and the full suite: see the end of this file.

## What the lead must check on the emulator

1. A Moon mission: the descent's dials over the dashboard (both views: INSIDE and OUTSIDE), readable at phone size; the
   colours change as expected; the beep quickens and is not annoying; the BURN button held and the lever both work;
   the hint card's GO on the first try; the frame time in the descent (`RocketFlight` adds one drawn panel).
2. A crash: the tipped lander, the dust, the lift-off of the capsule, the Earth growing, the re-entry into the clouds,
   the parachute beside the pad (not inside the rocket or the tower), the falling rocket in the launch camera's view,
   the dust where it hits, the pad losing parts, the fade, the child at the board with the HUD and the right toast; the
   board on MY ROCKET with the line; BUILD IT FOR ME and BUY THE PARTS FOR THIS ROCKET; LAUNCH again.
3. Survivor: half the hearts on the HUD after a crash, and the bag paying for the rebuild.
4. The Star Map's LAND (practice) on a world already reached: the bump, the try again, Mission Control after 3.
5. A crew flight (LAN): the crew member's dials during the pilot's descent, both come home, the crew member's hearts.
6. The 100 ms frame budget in the descent and the crash steps (the falling rocket reuses the stages' meshes built at
   the start, nothing is built then; the pad's broken cells are one `set_blocks` of 6-12 cells for the Moon's plan).

## Results

- **Missions smoke** (`SMOKE_ALL_DIR=<scratch>/landing106_smoke tools/smoke_all.sh mission`): PASS in 264 s, 76 checks,
  0 fails. The crash flight (SKIP to its landing, nobody on the throttle; the first try's 80 m at 4 m/s): 9 of 36 parts
  broke (seed 1795986671: 2 space engines, 6 fuel tanks, 1 stage separator; the first run's seed 1872223192 broke 8),
  no world loaded, the Moon not on the route, home at the board, "Home safe! The Sandbox keeps your hearts: only some
  rocket parts broke.", MY ROCKET "Your rocket crashed: 9 parts broke. Rebuild them: 95 gold.", BUILD IT FOR ME whole
  again in 2.1 s, BUY 95 gold, LAUNCH again; the second descent flown touched down at 1.4 m/s; the rest as before (the
  Moon's world, "Mission complete!", HOME, Survivor's bag). The first run's 4 fails were the smoke's own count (the
  biggest connected piece after the crash split the rocket) and the Sandbox's hearts (ruling 21): both fixed.
- **Flight smoke** (`tools/smoke_all.sh flight`): PASS in 174 s, 0 fails: the whole flight to the Moon with the descent
  flown took 125 s; the Star Map's LAND to Mercury (its practice descent flown) and the loading 19.0 s.
- **Full suite** (`tests/run_tests.sh`, log `landing106_full_suite2.log`): **10,033 passing, 0 failing**, 11 risky/pending,
  7,891,268 asserts, 3,664 s, no script errors (exit 0). A first run stopped mid-way in `test_rocket_flight.gd` with no
  error and no summary (the Godot process ended from outside: alone, that file and its neighbour pass); the second ran
  whole, `test_rocket_flight.gd` included.

## The lead's emulator check (2026-10-16, 1.0.5's debug build, `emulator-5554`, the developer menu's FLY ROCKET)
Five flights to the Moon (the test flight: no pad rocket, so no parts list; the autopilot does every step before the
descent, after 5 s each).
1. **The descent (item 1): checked.** "Now you land it! Hold the throttle to slow the fall. Touch down slower than
   3 m/s." with the panel over the dashboard: HEIGHT, SPEED ("safe: under 3 m/s") and FUEL, big and readable at phone
   size; the border and the speed turn green, yellow and red; the words change with them ("Good speed. Watch the
   colours.", "Careful: slow down a little.", "Slow down! Hold the throttle!", "Good: gently now.", "Nudge up to aim at
   the landing pad!"). **The BURN button held and the lever held both work** (the lever rises with BURN; a finger held on
   the lever sets the throttle; 16 m/s down to 9.9 m/s, fuel 64% to 54%). Not seen: the first try's hint card (this
   profile had flown before) and the beep (no sound checked).
   **No landing was flown on the emulator**: a scripted finger that reads the speed's colour from screenshots (about one
   look a second, and the first look only some seconds into the descent) always came down at 4-6 m/s. The numbers show a
   child can do it: from 120 m at 8 m/s, a full burn stops the fall to 3 m/s in about 20 m, and the colours narrow to
   3 m/s at the ground (green means "you can still slow down in time", so "Good: gently now." asks for gentle braking all
   the way down). A simulation of the rule with a one-second reaction lands most tries with the lever at 42% on green and
   full on yellow or red. The landing itself is the smokes' (`tools/mission_smoke_steps.gd` flies it).
2. **A crash and the way home (item 2): checked.** "Too fast: the lander crashed on the Moon! Everyone is safe: the
   capsule's rescue rockets carry the crew up and away." (the tipped lander, the capsule's flames); "Heading home to
   Earth. Real landers crashed too: Beresheet in 2019 and Luna 25 in 2023. India's lander crashed in 2019, and their
   next one landed on the Moon in 2023!"; "Into Earth's air: the heat shield glows hot!" (the clouds); "The parachute
   opens. Home, by the Launch Site!" (the parachute beside the tower, not inside it); "Look up: your rocket falls too!";
   "Some parts broke. Rebuild them at the Mission Board and try again!"; then Mission Control opens, and the child stands
   at the Mission Board with all 10 hearts (the Sandbox keeps them).
3. Survivor's half hearts, 4. the Star Map's LAND, 5. a crew flight: not on the emulator (the smokes and the suite).
6. **Frame times (item 6)**, from SurfaceFlinger's present times (`dumpsys SurfaceFlinger --latency`), with nothing else
   running on the emulator: 96.5 s from the descent to home, **53 FPS on average; the descent 60 FPS, its worst frame
   34 ms; two frames over 100 ms (115 and 124 ms), both at the moment the home world appears under the parachute.** (A
   run that also took a screenshot every second showed 330-476 ms frames there: the screenshots' own stalls, not the
   game.) Those two frames are the one thing over the budget: a candidate for a fade or a pre-load at that switch.
- **The developer path only:** FLY ROCKET starts the Sandbox where the player was saved; after a crash that is beside
  the Mission Board, which opens when the player walks up to it, so the board opened on the first frame and stayed over
  the whole test flight (it is last in the layer). A child's real LAUNCH closes the board and starts away from it, so
  only the test flight meets this; walking away from the board first avoids it.
- **Seen on the side:** after the emulator was killed (`adb emu kill`, a power cut) a minute after a LOG IN, the online
  prefs file was empty (0 bytes): LOG OUT forgets the account files, so the LOG IN's write was the file's first and had
  no `.bak`, and `JsonStore.write_atomic` flushes but does not sync the disk. The game then showed LOG IN for a
  logged-in player until its next sign-in (which writes the name again). Only a real power cut right after a first
  write can do this on a phone; noted, not changed.

## The lead's ruling after VR-RIG's finding (2026-10-16): green means "you will land"
VR-RIG found that the speed dial's green ended exactly at the crash speed, so a child who only keeps the dial green crashed
about half the time. `FlightDescent.zone()` now calls it green only when a child who keeps coasting for `REACTION` (0.45 s,
a child's reaction with room) and then brakes at `GREEN_BRAKE` of the engine still touches down at or under
`SAFE_SPEED - GREEN_MARGIN` (2.85 m/s); when the ground comes sooner than that, green only if it lands as it falls. Yellow
and red are as before. Test: `test_a_child_who_keeps_the_dial_green_lands_on_every_world` (13 worlds, 0-0.3 s late: was
red on the old rule, touchdowns up to 4.8 m/s), `test_green_leaves_room_for_a_childs_reaction`. The landing stays the
child's own skill (no autopilot); it is only honest now. Cost if wrong: the green band is narrower high up (yellow
sooner), so the dial asks for braking a little earlier than a perfect pilot needs.
