# M3 Task 20a — Rideable buddies ("the dragon you built and fly")

Agent notes, 2026-09-24. Spec §14.16 (added by this task), §16 (signature moment), plan Task 20 (20a). Branch cut from
`m2-survive-the-night`, `lead-merge` merged in first (main + owner #38, M4 I, M3 Task 4).

## What was built

- **The SADDLE block** (id **216**, page 10): tiles (0,2) top and (1,2) side/bottom in both styles —
  `tools/make_portal_page.gd` draws brown leather with stitching, a pommel, gold rivets, a strap, a buckle and a
  steel stirrup; `tools/make_portal_page.py` makes the realistic twin from CC0 ambientCG **Leather026** (credited).
  The portal tiles stay byte-identical (checked: new tiles are drawn after the old ones, RNG in step).
  `BlockIds.COUNT` 210 → 217. Sandbox: the palette's MAGIC row (`BlockPalette.MAGIC_BLOCKS`), not the block grid.
  Survivor: Tilly's HOME section, 60 gold × 2^(u−1), not bought back. Capturable (the wand wakes it with the build).
- **`RideRules`** (`core/magic/ride_rules.gd`, pure): kind from the shape (FLY / DRIVE / WALK; SAIL on water),
  `normalise` (a build whose wings or wheels run the other way turns a quarter, with the yaw that keeps its look),
  the seat on the highest saddle, speeds, acceleration, turning, caps, the flyer's climb and dive, `bump`,
  `climb_height` / `wants_hop` (1 block yes, 2 no), `can_mount`, `dismount_spot` (never inside blocks),
  `ride_over` (Survivor: a flight ends at landing), `clean_wish` (the host's copy of the stick), the lines.
- **`Buddy`** section "M3 Task 20a": `ride_kind` from its blocks on every game; synced `rider_peer` and `ride_mode`;
  `start_ride` / `end_ride` / `set_ride_input`; the host's `_ride_step` (every physics step: `RideRules.step`,
  gravity for walkers and cars, floating for boats, a flyer coming down on water stops on its top, hops, a car's
  bump with a thud RPC) and `_ride_decide` (10 Hz: water, the water's top, a 1-block step ahead, take-off);
  `resting()`; a flyer's wing blocks are meshed apart on two hinges and beat while it is ridden (a soft whoosh each
  beat). Still **one BoxShape3D** capped at `MAX_FOOTPRINT` (owner feedback #9); wings never get colliders.
- **`Player`** section "M3 Task 20a": `riding` (set on every game by the buddy), `is_riding()`, the sit pose (and back
  to sitting after an emote), placed on the seat every frame in `_process` (after the buddy moved on that game:
  host physics, or `RemoteSmoother` in the Session autoload, which processes first); its own game's `_ride_tick`
  sends the stick (camera-relative, world x/z, up/down) at most 20 times a second and every 0.25 s while held,
  JUMP gets off anything but a flyer; `get_off_at(spot)` (the host's spot, `_unstuck`, a gentle drift down).
  Getting on stops a paid flight (NORMAL) and crouching.
- **`RideDirector`** (`world/ride_director.gd`, node `Rides` in the sandbox on every game): the RIDE button (scan 10
  times a second: a saddled buddy nobody rides within reach, the player able to ride), HOP OFF while riding, Y on
  a keyboard; UP/DOWN for a flyer. Host: `host_ride` (refuses without a saddle, too far, taken, busy — knocked out,
  asleep, hiding, already riding), `host_ride_off`, `host_ride_input` (only the rider's stick), `end_ride`
  (`dismount_spot` → `Session.send_ride_off`), `host_check` 10 times a second (gone or unable riders get off;
  Survivor "Nice landing!").
- **Session** section "M3 Task 20a": `request_ride`, `request_ride_off`, `ride_input` (unreliable-ordered),
  `send_ride_off`, their RPCs and signals.
- **HUD**: `ride_button` (`add_ride_controls`, `show_ride_button`, `set_ride_up_down`; one line in `_show_up_down`),
  spot `ride` in `HudLayout.SPOTS` (right of BOOK), picture `ride` (a saddle with a stirrup) in `HudIcons`.
- **Sandbox**: `_add_rides()`, `_rides.setup_local`, the wake line and `normalise` in `_on_spark`, "Hop off first"
  in `_on_sleep`. `PlaydateDirector` leaves ridden buddies alone; `SleepDirector` offers no bed from a saddle.
- **`tools/ride_smoke.gd`** (+ `ride_smoke_steps.gd`): the headless smoke run with cost windows (DEVELOPMENT.md §4).

Skills: `godot-prompter:player-controller` — chose the CharacterBody3D velocity loop (`move_toward`, then
`move_and_slide`, in the physics step) that the buddy already used; rejected a RigidBody/VehicleBody3D car (per-wheel
rays, engine-driven, unpredictable for children, not one compact shape). `godot-prompter:multiplayer-sync` — chose
input sync for the rider (the stick goes to the host, the host simulates, state goes back through the buddy's
MultiplayerSynchronizer with the existing RemoteSmoother interpolation); rejected client-side prediction with
reconciliation for a guest rider (much more code; the brief says the host decides) and handing the buddy's
authority to the rider.

## Tests (RED → GREEN)

| Script | Tests | RED |
|---|---|---|
| `tests/unit/test_ride_rules.gd` | 31: shapes (wings, one-sided and low "wings", wheels, a hollow ring, a table, wings over wheels, sideways dragon and car turned with their look kept), saddle and seat, water and sailing, lines, top speeds and caps against `Player.WALK_SPEED`/`FLY_SPEED`, climb and dive, turning, bump, 1 block yes / 2 no, reach, dismount (open ground, a wall, a tunnel, the air, 200 random fields never inside blocks), Survivor landing, the host's stick cleaning | parse errors: no `SADDLE`, no `RideRules` |
| `tests/unit/test_saddle_block.gd` | 7: page 10, solid, valid, not an item id, capturable, tiles in both styles drawn (pixel alpha, brown realistic leather), the page material, the icon from the page, Tilly's price × 2^(u−1), `/give` | no tiles, price 0 |
| `tests/integration/test_ride_buddy.gd` | 14: kinds, the seat turned, one compact box for a very wide dragon, wings beat, the host flies a dragon (≤ 11 m/s, climbs, dives), a stale stick lets go, no steering before the first stick, a car on the ground bumps off a 2-block wall and never passes it, climbs a 1-block step, floats and sails on water, lands on water not under it, every game seats the rider, a freed buddy lets go, save/load keeps the saddle and shape | the water landing: no `resting()`; the others were written just after the buddy code, then mutation-checked (removing the hop, the float or the bump each fails its test) |
| `tests/integration/test_ride_director.gd` | 12: RIDE only next to a saddled free buddy, gets on and HOP OFF beside it on the ground, UP/DOWN on a dragon, the host's refusals, JUMP off a walker but climbs a dragon, the stick ≤ 20/s, riders who can't ride get off, Survivor flight ends at landing (Sandbox not), off in the air drifts down with no damage and the rider re-sits after an emote, no SLEEP while riding, a guest only asks (packets to the host only), the host decides a guest's ride and only its stick steers | the air/emote and sleep tests RED (no re-sit, SLEEP offered); the rest written just after the director, mutation-checked (the rider check on the stick, the landing rule, the reach check) |
| `tests/integration/test_block_palette.gd`, `test_counted_hotbar.gd` | the saddle in the MAGIC row, counts + `MAGIC_BLOCKS` | no `MAGIC_BLOCKS` |
| `tests/integration/test_hud_layout.gd` | RIDE and HOP OFF (with UP/DOWN) in the no-overlap check on 2400 × 1080 and a 16:9 phone, both modes | — (the spot was chosen for both screens first) |

Honest note: the Buddy and RideDirector integration tests were written right after their code (the rules came first,
RED then GREEN). Each was mutation-checked instead; the later ones (water landing, re-sit, no SLEEP) went RED first.

## Rulings (each with its cost if wrong)

1. **Fly speed 11 m/s** (`Player.FLY_SPEED`, the M2 paid Fly), not 12: the brief caps at 12 *and* "never faster
   than paid Fly". Cost: none; one constant.
2. **Wings** = blocks of the upper half (from the middle row up) beyond both ends of the lower half, ≥ 2 each side.
   A tree with a saddle (trunk, wide canopy) flies. Cost: some odd builds fly; a thickness rule in `wings_along`.
3. **Wheels** = the four bottom corners filled, front and back ≥ 2 apart with a gap on both sides, ≥ 2 layers high.
   A table drives, a hollow house doesn't. Cost: a car with solid full-width axles walks; relax `has_wheels_along`.
4. **Either axis**: a flyer whose wings run along z (or a car whose wheels are apart along x) turns a quarter when it
   wakes (`normalise`, yaw −90°, looking the same), so its face (−z, the eyes) looks where it goes. Cost: when it
   sleeps its blocks come back turned (buddies always sleep in their block frame, never their facing).
5. **The boat is a place, not a shape**: any non-flyer on water sails (6 m/s), and walks or drives again on land; a
   boat hops out onto a 1-block bank. Cost: a boat-shaped build on land walks.
6. **Flyers land on water's top** (float there, `resting()`), never on the bed with the rider under water — the
   smoke run's first flight dove into the sea and landed on the sea floor. Survivor counts it as a landing.
7. **Survivor "a ride lasts until landing"**: a flight ends when the dragon is back on the ground (or water) after
   having been off it ≥ 0.4 s; the child hops off beside it and must press RIDE again. Hovering costs nothing (no
   stamina). Cost: a dragon can stand in for paid Fly on long trips; the saddle costs 60 gold (six minutes of paid
   flying) and each landing ends the ride. A glide or stamina would be one rule in `RideRules.step`.
8. **Anyone may ride a free saddled buddy** (co-op fun), the owner still decides its sleep, and a ridden buddy can't
   be put to sleep ("Hop off first, then it can sleep!"). Cost: a friend can take your dragon; restrict in
   `host_ride` by `owner_peer`.
9. **RIDE sits top left, right of BOOK** (`ride`: (306, 161), 135²): on a 16:9 phone the bottom right and bottom
   middle are full (TEAM PHOTO, SLEEP, HELP UP, CROUCH, ATTACK). While riding it reads HOP OFF and is lit. Desktop:
   Y (B is SLEEP). Cost: the left thumb reaches up once per ride.
10. **JUMP gets off** walkers, cars and boats; on a flyer JUMP climbs, so HOP OFF (or landing, in Survivor) is the way
    off; CROUCH (held), DOWN and Q/Shift dive.
11. **The stick** goes as a world-space wish (camera-relative) on change at most 20 times a second and every 0.25 s
    while held, unreliable-ordered; the host lets go after 0.6 s of silence (a dropped link stops the mount). Cost
    of the host deciding: a LAN guest sees its ride through the buddy's sync (10 a second) and RemoteSmoother's
    150 ms creature delay: roughly RTT/2 + 100 + 150 ms from stick to motion. Prediction on the guest is the next step
    if it feels slow on the emulator.
12. **The rider** is placed on the seat every frame on every game (the RemoteSmoother restarts for that body each
    frame, harmless); the rider's own body does no `move_and_slide` while riding; players and buddies never collide.
13. **A car** steers by facing (2.4 rad/s, a turning circle, no reverse), bumps only head-on hits (≥ 60°) over 2 m/s,
    30 % back and the rest sliding at half, at most every 0.4 s, with a thud on every game (one unreliable RPC).
14. **Wings beat** only while ridden and flying: two extra MeshInstances per flying buddy (shared library materials,
    no new material), no colliders.
15. **Page 10's tiles**: two per id, index 2 × (id − 208) — the saddle (0,2)/(1,2). 14a, 21b, 21c and crafting also
    draw on page 10: the PNGs are binary, so after merging their `PortalPage.TILES` entries run both page tools again.
16. **Nothing new is saved**: the saddle is a block of the buddy (WorldMeta buddies already keep every block and the
    yaw); who rides is not saved. A child saved in the air on a dragon comes back there without it and falls (no fall
    damage exists in the game; Health: "No hunger, thirst or fall damage").
17. **Getting off** is the host's `RideRules.dismount_spot` (beside, level first, ground preferred, else in the air
    beside a flyer, else on top), the middle of a cell, then the rider's own `_unstuck`; off in the air drifts down at
    4 m/s (`soft_falling`).

## Measurements (headless smoke run, this desktop, busy PC)

`XDG_DATA_HOME=<private smoke dir> godot --headless --path . --script res://tools/ride_smoke.gd -- --smoke-seed=923184279`
(all 33 checks ok). Headless: CPU only, no drawing; the PC was shared (other agents' suites), so frame times
are only comparable within the run. Each phase: `avg_fps`, `max_frame_ms`, frames over 100 ms, the physics step
(`Performance.TIME_PHYSICS_PROCESS`), and the steps the run times itself (the ridden buddy's and the player's).

Run 5 (the final code, load 18–21):

| Phase (load) | avg fps | worst frame | > 100 ms | physics avg / max | buddy step avg / max (> 2 ms) | player step avg / max (> 2 ms) |
|---|---|---|---|---|---|---|
| stand, the dragon beside (21) | 66.2 | 90.6 ms | 0 | 19.8 / 27.2 ms | — | — |
| **dragon flight** 60 s, 645 m, top 11.00 m/s (18) | 119.8 | 116.1 ms | 1 | 10.1 / 25.0 ms | **0.094 / 17.1 ms (7 of 3600)** | 0.520 / 14.7 ms (105) |
| the same flight without a dragon (player's Fly) 659 m (19) | 108.0 | 104.9 ms | 1 | 12.6 / 35.9 ms | — | 0.674 / 12.7 ms (169) |
| car up its road, 10 s (18) | 126.3 | 44.9 ms | 0 | 8.9 / 15.7 ms | 0.194 / 0.9 ms (0 of 600) | 0.821 / 2.5 ms (25) |

Run 4 (the same world on a busier PC, load 20–31):

| Phase (load) | avg fps | worst frame | > 100 ms | physics avg / max | buddy step avg / max (> 2 ms) | player step avg / max (> 2 ms) |
|---|---|---|---|---|---|---|
| stand (31) | 80.8 | 54.8 ms | 0 | 12.1 / 13.8 ms | — | — |
| dragon flight, 646 m (21) | 103.9 | 111.8 ms | 3 | 13.1 / 32.5 ms | 0.119 / 5.5 ms (4 of 3601) | 0.725 / 10.3 ms (350) |
| without a dragon, 659 m (27) | 91.5 | 146.7 ms | 19 | 20.2 / 65.4 ms | — | 0.856 / 22.8 ms (279) |
| car, 10 s (30) | 55.3 | 133.3 ms | 13 | 22.2 / 30.7 ms | 0.381 / 27.2 ms (14 of 604) | 1.46 / 15.9 ms (100) |

- A ridden dragon costs the host about **0.1 ms a physics step** on this desktop (phones 3–5× more: ~0.5 ms), and
  the whole ride (buddy + rider: 0.61 ms in run 5, 0.84 in run 4) costs no more than the player's own flight (0.67,
  0.86 ms): riding adds nothing measurable over flying yourself. The slow frames in both flights are the terrain streaming in at 11 m/s (the
  plain flight had more of them).
- The car costs about 0.2 ms a step (run 5, worst 0.9 ms). Run 4's worst car steps (up to 27 ms, 14 of 604) came right
  after the run teleported the player 650 m back to the pad, while the terrain and its collision streamed in again. Earlier runs of the same world at load 16–27: dragon step 0.105–0.126 ms average.
- The emulator numbers (≥ 30 FPS, no frame over 100 ms, both styles) are the lead's check below.

## For the lead: what to check on the emulator

1. Sandbox: build a dragon (a body on two legs, wings of ≥ 2 blocks each side on its back, a SADDLE from the MAGIC row
   on top), wake it with the wand: "… is alive! Your dragon can fly!". RIDE shows top left (right of BOOK) near it,
   not near a buddy without a saddle. Tap: the child sits on the saddle, UP and DOWN replace JUMP/CROUCH, the stick
   steers, UP climbs, DOWN dives, the wings beat with a soft whoosh; HOP OFF: beside it, on the ground.
2. Fly it for a minute over hills in **both styles**: ≥ 30 FPS average, no frame over 100 ms (the AUTOPILOT flight
   for comparison). The saddle's look in both styles (brown leather, stirrup).
3. A car (four corner wheels, a body, a saddle): "Vroom! A car!", drives, turns in a circle, climbs a 1-block step,
   bumps back from a 2-block wall with a thud, JUMP gets off. A walker (a small build with a saddle) on a lake sails
   and hops out onto the bank.
4. Survivor: Tilly's HOME sells the saddle (60 gold; 120 in universe 2); a dragon's flight ends when it lands ("Nice
   landing!"); no hearts lost getting off high up (a gentle drift down).
5. LAN (host + guest): the guest rides the host's dragon; on the host the guest sits on the saddle and moves smoothly;
   on the guest the ride feels responsive enough (ruling 11); a third look from the host's side at the guest's car.
6. The wand on a ridden buddy says "Hop off first, then it can sleep!"; no SLEEP button while riding.
7. AUTOPILOT 10 BUDDIES unchanged (buddies without saddles do exactly what they did).

## Merge notes

Shared files touched (small, marked "M3 Task 20a"): `data/blocks/block_ids.gd` (SADDLE, COUNT 217, name),
`data/blocks/portal_page.gd` (TILES), the three `data/blocks/pages/portals*.png` (binary: re-run both tools after
merging other page-10 owners), `tools/make_portal_page.gd` / `.py`, `core/economy/shop_rules.gd` (HOME price),
`ui/hud/block_palette.gd` (MAGIC_BLOCKS), `ui/hud/hud.gd` (section + one line in `_show_up_down`),
`ui/hud/hud_layout.gd` (spot `ride`), `ui/hud/hud_icons.gd` (picture `ride`), `autoloads/session.gd` (section at the
end), `scenes/sandbox.gd` (`_add_rides`, `setup_local`, `_on_spark`, `_on_sleep`, section at the end),
`entities/player/player.gd` (two hooks + section), `entities/buddy/buddy.gd` (five hooks + section),
`world/playdate_director.gd` and `world/sleep_director.gd` (one condition each), `assets/CREDITS.md`, tests
(`test_block_palette`, `test_counted_hotbar`, `test_hud_layout`). Likely conflicts: `BlockIds.COUNT` and the page-10
PNGs with 14a/21b/21c/crafting, the palette counts with anyone adding palette buttons, `HudLayout.SPOTS` and
`HudIcons.SYMBOLS` with other context buttons.
