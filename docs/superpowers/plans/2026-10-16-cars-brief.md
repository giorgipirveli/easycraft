# Cars to drive, different kinds, and flying cars — the agent brief (owner #109)

The owner (2026-10-16 11:21): "in the game we also should have a cars to drive, different kind of cars and flying cars".
You are building it in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools, Jolt physics; phones, the web, PC and VR on
the Meta Quest). Work autonomously; do not ask questions (decide, and write each ruling down with what it costs if wrong).

## Today (read first)
- `core/magic/ride_rules.gd` + `world/ride_director.gd`: a buddy built with a SADDLE rides; WHEELS make it DRIVE like a car
  (10 m/s, turns, bumps off walls, climbs 1 block), WINGS make it FLY (11 m/s, JUMP climbs, CROUCH dives), on water it
  SAILS; saddled horses and camels (AnimalRideRules). Host-authoritative: the host decides who rides and moves the
  ridden body from the rider's stick; the RIDE / HOP OFF context button (HudLayout spot `ride`). **Nothing rides faster
  than the paid Fly (Player.FLY_SPEED, 11 m/s)**: a ruling to keep the paid Fly worth buying.
- The gadgets (`core/rules/gadget_rules.gd`, `entities/gadgets/gadget_models.gd`: one merged vertex-coloured mesh per model
  with one shared material, built once and cached), Tilly's shop, Survivor's gold, the Sandbox's palette.
- VR: `docs/devlog/parts/vr-rig.md` (P3: rides seated, comfort vignette, no roll, fade cuts; `Vr.anchor(node, &"seat")`).
- The fair-fun rules (`docs/design/`), the performance budget (DEVELOPMENT.md §7: ≥ 30 FPS on the emulator, no frame
  over 100 ms; the autopilot's 2 km flight at 11 m/s is the streaming test).

## The design (the lead's rulings; refine them in your notes)
1. **Real cars, ready-made**, beside the built-buddy rides (those stay as they are). Six ground kinds, each with its own
   feel, look and seats: a **go-kart** (small, quick turns, 1 seat), a **jeep** (climbs 2 blocks, 2-4 seats), a **race
   car** (the fastest on flat ground, 1 seat), a **pickup truck** (carries a load of blocks in its bed, 2 seats), a **bus**
   (slow, room for the whole team: friends ride along), a **monster truck** (huge wheels, climbs 3 blocks, bounces); and
   **flying cars**: a **hover car** (drives on the ground; FLY lifts it off; flies like the FLY ride, gently, never
   higher than the world's flight ceiling) and a **sky taxi** (a flying car with seats for friends). Built from boxes in
   the game's own blocky style (CC0 or our own; no brands, no real makes), a few colours each (cosmetic, chosen in the
   garage).
2. **Driving is arcade and kind**, host-authoritative like the rides (a CharacterBody3D-style kinematic car on RideRules'
   model is the default; VehicleBody3D only if it is better with Jolt AND stays predictable for children: a ruling with
   tests). The stick drives (forward, back, turn); buttons HOP OFF, HORN, and FLY / LAND on flying cars; PC: WASD, Space
   (FLY), E (HOP OFF); a pad as the rides. No crashes that hurt: a car bumps and stops; it never runs a player over
   (players and animals are pushed gently aside); in water ground cars float back to the shore (or a ruling). Speeds:
   the fastest ground car 14 m/s on flat ground at most (measure that the world streams ahead at that speed, headless,
   with the existing streaming checks; the lead checks the emulator), flying cars ≤ the paid Fly's 11 m/s.
3. **Getting a car:** the Sandbox: free, from a CARS page (the palette or a garage block: your choice) that places the car
   in front of the child; Survivor: a **garage** (Tilly's shop or a new garage stand) sells each kind for gold (the
   go-kart cheap, flying cars the dearest: prices in line with the rocket's parts, a ruling), kept like the gadgets (owned
   once, CALL MY CAR brings it near). A car left alone stays where it was parked and is saved with the world.
4. **Together online:** the driver drives; friends take the free seats (RIDE near a car with a free seat), see each other
   inside, and hop off anywhere safe; the host checks every seat and every move (cheat-proof like the rides). Cars on a
   guest's screen move smoothly (the existing interpolation).
5. **VR:** seated in the car (Vr.anchor to the seat), the comfort vignette while moving, no roll, a fade on getting in and
   out; the steering from the controllers as the rides do (VR-RIG's input). No VR files of yours: only the car's seat
   node and the ride's existing calls.
6. **Learning (the game's heart):** each kind has a short card the child can read and hear (how a car's engine and wheels
   work, why a monster truck has big wheels, electric cars, how a hover car floats, real flying cars that were tested,
   e.g. the Klein Vision AirCar) — every fact checked, with its source in your notes.
7. **Kind and fair:** never a paywall for a child (gold earned by learning buys cars); no damage, no fuel to run out on
   the ground; a lost car is called back.

## Allocation and rules
- Yours: `entities/vehicles/*` (new), `core/rules/vehicle_rules.gd` (+ `car_kinds` data), `world/vehicle_director.gd` (new),
  `ui/vehicles/*` (the garage, the car card), the HUD's driving buttons through HudLayout (take a free spot; say which),
  the shop entries, the save of parked cars, tests `tests/**/test_car*.gd` and `test_vehicle*.gd`, notes
  `docs/devlog/parts/cars.md`, spec §3b "Cars" (written first) and DEVELOPMENT.md. Hooks into `scenes/sandbox.gd` only in
  marked blocks ("owner #109"), as few as possible.
- **Ids:** blocks (if you need a garage block or parts): page 44, ids 752-767 (`BlockIds.NEXT_PAGE_FIRST_ID` → 768 when you
  take it); items (keys, the car items): the next free item ids after the highest in use (find them; write the range in
  DEVELOPMENT.md's id tables). Nobody else takes ids now.
- Other agents run now: VR-RIG (entities/vr/*, autoloads/vr.gd) and VR P5 (core/rules/graphics_preset.gd, world_service's
  VR parts, entities/fx/*, ui/hud/* icons for VR): don't touch their files; ask in your report for any change there.
- TDD; `--import` after new class_name scripts; logs named `cars109_*` (others share the scratch folder); the FULL suite once
  at the end; a headless smoke that drives each kind 300 m and flies the flying cars (a `tools/smoke_all.sh` step if it
  fits). Never open the editor or an emulator, never touch adb; never merge or push; no downloads (our own models only);
  never start agents. English only.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Finish
Notes (what a child sees and does with each car, every ruling and its cost, the facts' sources, the ids, what the lead
must check on the emulator and in VR), DEVELOPMENT.md, spec. Report: branch, commits, the kinds and their numbers (speed,
climb, seats, price), the full suite's result.
