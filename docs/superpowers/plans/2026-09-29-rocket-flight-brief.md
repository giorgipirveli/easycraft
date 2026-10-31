# Fly the rocket yourself: from the pad to the Moon — the agent brief (owner #79; spec §25.3, §21d.4)

You are building **the rocket flight** of EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools; the Mobile renderer and
the web's Compatibility renderer), a game for children. The owner: "when ship is built, you just sit into it at steering
wheel and fly to moon, you actually fly into moon, here we need real animations and visuals". Work autonomously; do not
ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the performance budget, both graphics styles, the web build), spec **§25.3
   and §21d (your design)**, §21 (space: the space line, the sky's climb, landing), §3c (our own look), §7.5
   (phones). Study: `world/space_director.gd` and the sandbox's space travel (`travel`, the landing words, the dust,
   `SpaceDirector.landing`), `SkyCycle` (the climb to space's black, the planets in the sky), the camera rig, the
   particles the game already has (the geyser puffs `SpaceGeysers`, the portal swirl), `BlockLibrary` (the atlas
   materials of both styles), the HUD and the touch controls.

## The interface (another agent builds the rocket and the missions at the same time)
- The missions agent's `RocketCheck` passes you a **rocket**: `{"destination": int (a world), "cells": {Vector3i
  (relative to the pad's corner, y up): block id}, "stages": [[Vector3i, …] (bottom stage first), …], "seats": int}`.
  Build your own test rockets in this form (engines at the bottom, tanks, a capsule on top, fins, legs).
- You provide **`RocketFlight`** (`entities/flight/rocket_flight.gd` + its scene/UI): `start(rocket: Dictionary,
  from_world: int)`; signal `landed(destination: int)` when the flight is over (the sandbox then loads the planet
  with the rocket standing on its pad); `abort()` for the pause menu's QUIT. A developer hook (the developer menu or
  `--fly-moon`) starts it with a test rocket, so you and the lead can try it before the missions exist.
- The lead joins the two when merging (the Mission Board's LAUNCH calls your `start`). Never touch the missions' files.

## What to build (spec §25.3)
1. **Sit at the controls**: the camera moves into the capsule: the window ahead, the dials (speed in km/s, height,
   fuel per stage, the distance to the Moon counting down from 384,400 km), a steering wheel or stick and a big throttle
   (touch: big buttons and a drag; keys on desktop). Friends' seats may stay empty for now.
2. **Lift-off from the pad**: a countdown (10 … 1, spoken), the engines' fire and smoke (particles), the pad shaking,
   the rocket they built (a mesh made from its cells with the blocks' atlas look, one draw call per material) rising,
   the camera switching between inside and a chase view (a button).
3. **Up and away**: through the clouds, the sky turning black (reuse the climb), the first stage falling away with a
   puff (from `stages`), the Earth's curve then **the whole Earth** (a sphere: blue oceans, land, white clouds turning;
   our own or CC0 textures, credited), stars, the Sun's light; the child steers toward the Moon's marker, the autopilot
   keeps it safe (never a crash: kind corrections, "Nudge left to aim at the Moon!").
4. **To the Moon**: the Moon a real sphere growing ahead (its seas and craters), the trip's 3 days shown in a couple of
   minutes (the words say so), into orbit round it, the engine burn to slow down, the landing legs out, the ground
   rising, dust on touchdown at the landing pad; then `landed` and the Moon world, the child stepping out.
5. **Mars** (and any destination): the same shape with the long cruise in a few seconds, and a fiery entry through
   Mars's air (the heat shield glowing, then the parachute, then the engines). Other worlds: a sensible default (the
   destination's colours, from `StarMap`'s bodies).
6. **Movie-style moments** (owner #86: "on the space ship we should have visuals from different movies"), in our own
   look (spec §3c, §25.3): the jump to light speed for the long cruise (stars stretching into lines, a flash), a warp
   tunnel, a wormhole's swirl on the way to far worlds, an asteroid field and a coloured nebula to fly through, glowing
   cockpit screens and a hologram of the destination. Never a film's own ships, logos, sounds or music (only our own
   or CC0, credited). The trip's words keep the science true ("real rockets cannot go faster than light: this is our
   game's shortcut").
7. **Real animations and visuals** in both graphics styles, and **fast**: ≥ 30 FPS and no frame over 100 ms on the
   emulator (the lead measures; you measure frame times headless and in a window, and keep particles, textures and
   draw calls small; the web's Compatibility renderer must work).

## Allocation and rules
- New files: `entities/flight/*`, `ui/flight/*`, textures under `assets/flight/` (made by a script of yours, or CC0,
  credited in `assets/CREDITS.md`), tests `tests/**/test_rocket_flight*.gd`, `test_flight_*.gd`, notes
  `docs/devlog/parts/rocket-flight.md`. Small additions: `scenes/sandbox.gd` (the landing after a flight), the
  developer menu. No block ids (the parts are the missions agent's page 32, ids 560-575: use existing blocks in your
  test rockets, or those ids as plain numbers).
- TDD for the rules (the flight's phases and timings, steering and the autopilot's corrections, the dials' numbers, the
  rocket mesh from cells, stage separation); screenshots in a window for the look (a tool of yours like
  `tools/space_shots.gd`), described in your notes (say so if you cannot open a window). `--import` and grep Parse Error
  after new class_name scripts. Single tests with `tests/run_tests.sh -gtest=…`; the FULL suite once at the end. Never
  open the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
Notes (rulings, what a child sees and does, frame times, textures and their sources, what the lead must check on the
emulator: the feel of steering, the frame rate at lift-off and at the Earth/Moon views); spec §25.3 "As built";
`docs/DEVELOPMENT.md`. Commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
Report: branch, commits, what a child sees, the tests' results, what the lead must look at.
