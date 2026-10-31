# A real landing, and what a crash costs — the agent brief (owner #106)

The owner (2026-10-15 23:19): "landing a rocket to the moon is simply too easy. So failing while descending from the moon.
To the earth and you will have half the hearts. Even the rocket is falling like you and when it crashes down on to earth,
some parts break and have to rebuild it. But it's random. But not catastrophic like 1 block survived and 99% is damaged."
You are building it in EasyCraft (Godot 4.7.2, typed GDScript). Work autonomously; do not ask questions (decide, and note
rulings with what they cost if wrong).

## Today (read first)
`entities/flight/flight_run.gd` (the steps, the actions, **the autopilot that does any action a child waits on: "so a trip
never sticks"**), `flight_plan.gd` (`landing_steps`: "Steer over the landing pad. Hold the throttle for a soft landing!"),
`flight_steering.gd`, `rocket_flight.gd`, `flight_dials.gd`, `ui/flight/flight_cockpit.gd`, the crew flights
(`core/missions/crew_*`, `net` crew sync), the mission's arrival (`scenes/sandbox.gd` `mission_arrive`), the rocket plans and
BUILD IT FOR ME (`core/rules/rocket_plan.gd`, `entities/launch/launch_director.gd`, notes `docs/devlog/parts/rocket-easier.md`),
hearts and knock-outs in Survivor and whether the Sandbox has hearts, the VR seated flight (`docs/devlog/parts/vr-rig.md`:
no shake and fade cuts in VR — keep them), the fair-fun rules in `docs/design/`.

## The design (the lead's rulings)
1. **The landing is the child's (every mission, the Moon first):** the final descent is flown, not watched: height, falling
   speed and the lander's fuel (from its real tanks) on big dials with colours (green safe, yellow careful, red too fast),
   a beep that quickens, short words ("Slow down!", "Good: gently now"). Throttle slows the fall; touching down at or
   under a safe speed (decide a fair number with tests, e.g. 3 m/s) lands; faster, or out of fuel above the ground, is a
   **crash**. **No autopilot on the final descent** (the earlier steps keep theirs, so a trip never sticks before it). A
   first-time hint card and an easy first try are fine; a practice landing from the Star Map's LAND is a bonus if cheap.
2. **A crash fails the mission:** the crew's capsule falls back to Earth (a short fall and re-entry, a parachute at the
   end; in VR a fade cut, no shake) and lands the child by their home world's Launch Site **with half their hearts** (where
   hearts count: Survivor; in the Sandbox, which has no harm, say so and the cost is the parts). The world is not on the
   route until a landing succeeds. A friendly line, and a real fact (real landers crashed too: Beresheet 2019, Luna 25 2023,
   check the facts with sources in the notes).
3. **The rocket crashes down too:** it falls by the Launch Site (a short moment the child sees) and comes back to the pad
   **damaged**: a random share of its parts broken, **between 15% and 35%** (never fewer than 1, never more than 35%), seeded
   per crash so tests can pin it; the capsule and the parts the crew needs break less often than engines, tanks and fins
   (a ruling). Broken parts are gone from the pad and from what the child owns (Sandbox: `MissionData.parts`; Survivor: they
   were taken from the bag); the board says "Your rocket crashed: 9 parts broke. Rebuild them: 120 gold." with BUILD IT FOR ME
   and BUY THE PARTS FOR THIS ROCKET working on the damaged rocket as they do on any.
4. **Crew flights:** everyone on board crashes together (half hearts each, back at the host's Launch Site); only the
   host's rocket is damaged.
5. Kind and fair for children (the fair-fun rules): a crash is a setback, never a disaster; the words never shame; a
   second try is one rebuild away.

## Allocation and rules
- Yours: `entities/flight/*`, `ui/flight/*` (cockpit dials and words), `core/rules/rocket_*` (a `CrashRules` for the
  damage), `entities/launch/*` (the damaged rocket back on the pad), the mission's arrival and failure hooks in
  `scenes/sandbox.gd` (marked "owner #106"), tests `tests/**/test_landing*.gd`, `test_crash*.gd`, the missions smoke, notes
  `docs/devlog/parts/moon-landing.md`, spec §21d "As built (owner #106)".
- Another agent works on accounts (`ui/online/*`, `net/*`, `core/save/*`, `server/*`, `ui/menus/menu.gd` for LOG OUT): don't
  touch those. VR is stopped: keep the VR seated flight's rules (no shake, fade cuts) working; its tests must stay green.
- TDD; `--import` after new class_name scripts; logs named `landing106_*` (other agents share the scratch folder); the
  missions smoke 0 fails; the FULL suite once at the end. Never open the editor or an emulator; never touch adb; never merge or
  push; never start agents.

## Finish
Notes (what a child sees: a good landing, a crash, the way home, the damaged rocket, the rebuild; every ruling with its cost;
the facts' sources; what the lead must check on the emulator), DEVELOPMENT.md, spec. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, the flows, the numbers (safe
speed, the damage range), the full suite's result.
