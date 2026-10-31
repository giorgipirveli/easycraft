# Cars to drive, different kinds, flying cars (owner #109) — the cars agent's notes (2026-10-16)

The owner (2026-10-16 11:21): "in the game we also should have a cars to drive, different kind of cars and flying
cars". The brief: `docs/superpowers/plans/2026-10-16-cars-brief.md`; the spec: §3b "Cars". Built test-first on the
cars agent's branch (from `lead-merge` at 2209d181), nothing merged.

## What a child sees and does

- **MORE → CARS opens the garage** (every world but Monster Wave's arena): eight car tiles with their pictures (drawn
  from each car's own model), FREE in the Sandbox, the price or YOURS in Survivor. A tap picks one: its picture in the
  picked colour, its name (a speaker reads its name and card), one line, its numbers ("Top speed 14 blocks a second ·
  climbs 1 block · 1 seat"), four colour buttons, DID YOU KNOW? with its facts, and one big button: GET IT (the
  Sandbox), BUY 200 (Survivor, not yet the child's), CALL MY CAR (owned), CALL IT (out already); PUT AWAY sends a car
  that is out back. The button closes the garage, so the child sees the car pop out in front of them with a puff and
  "Beep beep! Here's your Race Car!".
- **Getting in:** next to a car with a free seat the RIDE button says **DRIVE** (with a car's picture), or **GET IN**
  when only a passenger's seat is free; a tap on the car does the same. The first in drives: "Vroom! The stick drives."
  (a flying car: "FLY lifts it up!"); a PC driver also sees its keys ("W A S D drive · H horn · E hop off", with
  "Space flies (C dives)" in a flying car), a pad driver the buttons.
- **Driving:** stick forward speeds up, back brakes and then backs up slowly, left and right turn (sharply in a go-kart,
  slowly in a bus; a little even standing still). The camera swings round behind a moving car by itself (a big car's
  camera sits further back) unless the child just turned it. HORN (a button over the hotbar, H on a PC, JUMP in a ground
  car) honks for everyone: a go-kart's and a race car's quick "meep meep", a car's two tones, a bus's and a monster
  truck's deep honk. The engine hums with its speed.
- **The road:** a car hops up the steps it can climb (a go-kart, race car, pickup, bus, hover car and sky taxi 1 block,
  the off-roader 2, the monster truck 3, and it bounces when it lands from a height) and bumps gently back off higher
  walls ("thud"). It never runs anyone over: a child, an animal, a monster, a buddy or a bot friend in its way stops it
  and is pushed gently aside (a little hop sideways; never in VR). No damage, no fuel. In water a ground car floats like
  a boat at a slow 3 m/s and climbs out onto a bank; the hover car glides over water at full speed.
- **Flying cars:** the hover car drives on the ground; FLY (a button for its driver, Space on a PC, A on a pad) lifts it
  off; in the air the stick flies it, JUMP (UP) climbs, CROUCH (DOWN) dives, letting go hovers; LAND brings it down
  gently and it drives again (on water it lands and floats). The hover car stays within 24 blocks of the ground; the
  sky taxi flies up to the flight ceiling (150, under the sky's darkening: a car never reaches space). If the driver
  hops off in the air, the car comes down gently by itself.
- **HOP OFF** (the RIDE button, E or Y on a PC, Triangle / Y on a pad) puts the child beside the car (never inside
  blocks); an empty car stops at once.
- **Friends:** they take the free seats (the bus has 8: the whole team), see each other inside (the open cars show their
  riders; the bus, the pickup's cab and the sky taxi have open windows), and hop off anywhere. Only the driver's stick
  moves the car and only the driver flies it; anyone in it may honk.
- **The pickup truck:** a tap on its bed holding blocks loads 8 of them (up to 32, four kinds; they show as little
  cubes in the bed); a tap holding nothing placeable unloads it: in Survivor back into the bag, in the Sandbox tipped
  out behind the truck as real blocks (a little dump truck).
- **Survivor:** a car costs Survivor gold (earned by learning; never real money) once and is the child's own for good,
  in every Survivor world (and in a friend's world, as a guest). A car left alone stays where it was parked and is saved
  with the world. A lost car (far away, fallen off an island) is called back with CALL MY CAR; one that falls out of the
  world is carried back to the ground it last stood on, its riders still in it.
- **VR:** the child sits on the car's seat as on a ride: a black blink on getting in (facing the car's front) and out,
  the comfort vignette (stronger: motion the child did not make), the walking stick drives, A flies up, B dives, no
  roll ever, never a camera move by itself.

| Kind | Top speed (m/s) | Reverse | Turn (rad/s) | Climbs | Seats | Survivor price | Its own thing |
|---|---|---|---|---|---|---|---|
| Go-Kart | 9 | 4 | 3.0 | 1 | 1 | 40 | small, the sharpest turns, the quickest off the mark |
| Off-Roader (the brief's jeep) | 10 | 4 | 2.2 | 2 | 4 | 120 | big tyres, a roll bar, a spare tyre |
| Race Car | 14 | 4 | 2.0 | 1 | 1 | 200 | the fastest on flat ground; low, a wing |
| Pickup Truck | 10.5 | 4 | 2.0 | 1 | 2 | 150 | its bed carries 32 blocks |
| Bus | 7 | 3 | 1.4 | 1 | 8 | 180 | slow; the whole team |
| Monster Truck | 9.5 | 4 | 1.8 | 3 | 2 | 250 | huge wheels; it bounces |
| Hover Car | 10 (flies 10) | 4 | 2.4 | 1 | 2 | 400 | no wheels: floats, glides over water, flies 24 over the ground |
| Sky Taxi | 8 (flies 11) | 3 | 1.8 | 1 | 4 | 500 | a flying car with seats for friends, four rotors |

## How it is built

| File | What |
|---|---|
| `core/rules/car_kinds.gd` | `CarKinds`: the eight kinds' numbers, seats, sizes and boxes, wheels, colours, prices, cameras, horns, lines and facts |
| `core/rules/vehicle_rules.gd` | `VehicleRules`: driving, flying, the ceiling, hops, pushes, getting in, seats, where a called car goes, the garage's limits, ownership, the save, the pickup's bed, the chase camera, the driver's hint |
| `entities/vehicles/vehicle.gd` | `Vehicle`: a car in the world (synced seats, flying, colour, load; the host's step; every game's riders, wheels, rotors, bob, bounce, engine) |
| `entities/vehicles/car_models.gd`, `vehicle_sounds.gd` | the looks (cached meshes) and the sounds |
| `world/vehicle_director.gd` | `VehicleDirector`, node `Vehicles`: the spawner, the requests and the host's decisions, the save, this game's HUD, taps, camera and VR |
| `ui/vehicles/garage_panel.gd`, `car_picture.gd`, `car_card.gd` | the garage, the cars' pictures, the learning card |
| `tools/make_car_sfx.py`, `tools/cars_smoke.gd` (+ `_steps`) | the sounds; the headless smoke |
| Hooks (marked "owner #109") | `scenes/sandbox.gd` (the node, restore, save, the local setup, Back), `entities/player/player.gd` (`riding_vehicle`, `in_car`, `_car_tick`; `is_riding`, `mount`, `_ride_place`, `get_off_at`; no GLIDE from a seat), `world/ride_director.gd` (`cars`: DRIVE / GET IN), `ui/hud/hud.gd` (`show_ride_button`'s word and picture, `add_car_controls`), `ui/hud/hud_layout.gd` (spots `horn`, `car_fly`; APART pairs), `ui/hud/hud_icons.gd` (`car`, `horn`), `entities/player/block_interactor.gd` (`vehicle_tap`), `world/world_meta.gd` (`cars`), `autoloads/audio.gd` (four sounds), `core/net/sync_pace.gd` (cars at the players' pace) |

## Rulings (with what they cost if wrong)

1. **A kinematic CharacterBody3D on VehicleRules' arcade model, not VehicleBody3D.** It is the rides' model, exactly
   predictable for children and tests (a step is hopped by the rules, a wall bumps), cheap (one box, no wheel rays),
   and never tips or rolls. [Cars feel toy-like: a VehicleBody3D with Jolt for one kind (the race car), its numbers
   tested the same way.]
2. **The stick is a throttle and a steering wheel** (forward speeds up, back brakes and backs up, left and right turn),
   not the rides' "point the stick where to go": the brief's "forward, back, turn", and what children know from other
   driving games; the camera swings round behind a moving car so "forward" stays ahead. [A small child steers badly:
   a SIMPLE setting where the car turns to face the stick, as the buddy car does.]
3. **The brief's jeep is called the Off-Roader** ("Jeep" is a make's name; no brands). [Children call it a jeep anyway:
   nothing; renaming is one line.]
4. **The garage is a panel in MORE (MORE → CARS), in every world but the arena**, not Tilly's shop, a stand or a block:
   it can't be missed or lost, works the same in the Sandbox and Survivor, and needs no block or item. [Children want
   a place in the world: a garage stand near the spawn that opens the same panel.]
5. **A bought car is the child's for good: `"car:<kind>"` in `ProfileData.bought`** (like the Gold Shop's things),
   bought with Survivor gold in the garage (the host spends it: `Session.gold_spend`), not a per-world key in the bag:
   kinder (bought once, in every Survivor world and as a guest), and a bag's `/clearbag` can't lose it. A guest's cars
   are what its profile says when it arrives (trusted like its LAN gold). No block id and no item id were taken (page 44
   and items 500-511 stay free). [A cheating guest calls cars it never bought: harmless (the Sandbox gives them all);
   the server could keep them like the wallet.]
6. **Prices 40-500** (the go-kart 40, a crew capsule's price; the hover car 400 under the Moon rocket's 450; the sky
   taxi 500 under the Mars rocket's 615; all eight about a week of learning). [Too dear for the flying cars that save the
   paid Fly: raise them, or make Survivor flights end on landing as the dragon's do.]
7. **One car of each kind per child in a world; at most 4 out (the oldest parked one goes home); 12 in a world.** A
   second GET IT brings that car (repainted), so a world never fills with copies. [A child wants a parking lot of buses:
   PER_PLAYER up, MAX_CARS stays.]
8. **Cars are solid like the world (layer 1):** children bump into a parked car and can climb onto it; the camera's
   spring arm and the world's rays see cars (the rider's own car is kept out of its arm); the host's car is stopped by
   players, buddies, animals, monsters and bot friends (its mask), its own riders excepted. A body in the way stops the
   car and is pushed aside at 3 m/s with a little hop, at most every 0.5 s (players by the knockback RPC: never in VR).
   [Monsters chasing a child get stuck behind parked cars: put cars on their own layer and add it to the players' mask.]
9. **Ground cars float in water (3 m/s, climbing out onto a 1-block bank)** instead of being carried back to the shore:
   the child stays in control and the rides' boat rules already do it. [Children drive into the sea and get lost: the
   compass's home arrow, or a slow pull to the nearest shore.]
10. **The flight ceiling is 150** (`SpaceRules.CLIMB_FROM` 160 minus 10): a car never darkens the sky or opens the space
    picker; the hover car flies at most 24 over the generator's ground (gently), the sky taxi to the ceiling. Flying
    cars climb 5 and dive 6 m/s (the dragon 6 and 8); LAND descends at 4. [Children want to fly to space in the taxi:
    the rocket is the way, by design.]
11. **VR: the rides' way, not `Vr.sit`.** The rider's body sits on the car's seat (a `Marker3D` per seat) and the
    origin follows the body (the feet anchor), so the comfort vignette counts the car's motion (with the seat anchor it
    counts nothing) and a guest's own car is followed through the alpha-beta filter (`Player.is_riding()` is true in a
    car). Getting in: the body onto the seat, then `Vr.blink()` and `Vr.face(car's yaw)`; getting out: the snap's blink.
    The view never turns with the car (as on a horse). No VR file changed. [Driving feels odd when the view doesn't turn
    with the car: a seat anchor whose frame turns with the car at `VrRules.SEAT_TURN_DEGREES`, the vignette from the
    car's own speed.]
12. **An empty car brakes to a stop at once** (BRAKE 18 m/s², not the 3.5 coast): a child who hops off at speed never
    sends a car rolling into the next one (the smoke's first run found it). [Nobody notices: nothing.]
13. **A parked car sleeps (no physics at all)** until someone gets in or the ground under it goes, and only wakes on
    loaded ground (a chunk nobody is near reads as air: it would fall through). [A car parked over a hole someone dug
    while far away floats until they come back: it falls then.]
14. **A car below the fall line (the void's in the Dragon Realm) is carried back** to the last ground it stood on, with
    its riders in it, a puff. [The child wanted to fall: the riders could get out instead.]
15. **The RIDE button is the cars' too** (DRIVE / GET IN / HOP OFF): one button gets on and off everything. HORN and
    FLY / LAND have spots of their own over the hotbar, left of the middle (`horn` at SLEEP's and WAKE UP's place,
    `car_fly` beside it: APART with SLEEP, WAKE UP and STOP FOR TODAY, which never show in a car); checked at every
    button size, both hands, both test screens (`test_car_hud.gd`, the layout's `clashes()`). [They are hard to reach
    with a thumb: move them under JUMP's cluster at BIG.]
16. **Keys:** E hops off (it is fly_up's key, which a car never uses), Y as for rides, H honks (KnockoutDirector's HELP
    UP key too: a driver beside a knocked-out friend also starts helping; harmless), Space honks a ground car and flies
    a flying car, C / Q / Shift dive. A pad's (and the Quest's) Triangle / Y, the physics switch's button, hops off.
    [Children press the WALK / FLY button on a phone in a car: it still switches the physics mode, as on a buddy.]
17. **The pickup's load:** 32 blocks, 4 kinds, 8 a tap; Survivor's never makes free blocks (back into the bag), the
    Sandbox tips the load out as real blocks behind the truck (no undo step, no ledger: the Sandbox's). [Survivor
    children want to dump their load where they build: tip it out there too (their blocks), with the ledger.]
18. **Gravity is the cars' own 20 m/s² in every world** (the Moon's low gravity isn't applied). [A moon buggy should
    float over craters: the world's gravity factor in `Vehicle.host_step`.]
19. **Cars sync at the players' pace (20 a second, only what changed)**, by their group (`SyncPace.FAST_GROUP`: the
    autoloads, which pace every synchronizer, never compile the cars for it). A guest's driving is the host's (its stick
    goes by the car's RPC, unreliable ordered): online it feels its round trip behind the stick, smoothed. [Too laggy on
    a slow connection: predict the guest's own car with VehicleRules, as VR-RIG's ruling 17 says for mounts.]
20. **The cars' RPCs live on the `Vehicles` node and each car, never on Session** (an older build's Session keeps its
    RPC numbers). An older guest has no `Vehicles` node: it sees no cars (the spawner's packets fail on it). [Mixed
    builds online: the version handshake should refuse them anyway.]
21. **`Player.riding_vehicle` is typed `Vehicle`**: the Vr autoload names Player, so starting the game compiles the cars'
    scripts too (about 1,800 lines on top of about 80,000; the menu's `MENU ready_ms` 10.5-11.0 s headless here under load
    12, too noisy to see it). [Phones start slower: type it Node3D and call by name, so the cars compile with the
    sandbox.]
22. **GLIDE never from a seat** (`Player.can_glide` says no while riding): it showed in the air on a dragon before, and
    would have on a flying car. [Nothing.]
23. **The garage's pictures are drawn from the models' boxes** (a side view, far side first) instead of 3D renders: no
    SubViewport, nothing to warm up, the same look. [They look flat: render them once into textures.]
24. **No new material, no Label3D:** the cars use `WeaponModels.material()` (vertex colours; the warm-up's census has
    it), the pickup's load the blocks' own (the voxel library), so the shader census needs no new run. [The census
    test says otherwise: list `car_models.gd` as "shares: vertex colours".]

## Facts and their sources

Each card's facts were checked (2026-10-16):
- Go-kart: no suspension, the chassis flexes as one; the engine's power to the rear axle by a chain (Wikipedia
  "Go-kart"); the first kart built in August 1956 in Glendale, California, by Art Ingels and Lou Borelli (Wikipedia
  "Kart racing"); a piston engine turning a shaft (any engine primer).
- Off-roader: four-wheel drive turns all four wheels (Wikipedia "Four-wheel drive"); tread's grooves grip and let water
  out (Wikipedia "Tread"); ground clearance (common knowledge).
- Race car: low and wide against tipping (the centre of mass and track width); wings make downforce, more grip in
  corners (Wikipedia "Downforce"); the first Formula E championship race, Beijing, 13 September 2014 (Wikipedia "2014
  Beijing ePrix").
- Pickup: the bed (Wikipedia "Pickup truck"); stiff (leaf) springs over the back axle (Wikipedia "Leaf spring"); more
  mass needs more force to speed up (Newton's second law).
- Bus: a 12 m city bus carries about 65-80 seated and standing (makers' sheets: BMC Procity, Yutong E12, Kiwibus);
  most cars carry one or two (average car occupancy about 1.5: the EEA, the US NHTS); regenerative braking (Wikipedia
  "Regenerative brake"); Shenzhen's 16,359 buses all electric at the end of 2017, the first city to do it (Engadget
  2017-12-29, Bloomberg 2018-05-08, WRI).
- Monster truck: 66-inch (1.7 m) tyres (Wikipedia "Monster truck"); a bigger wheel climbs a higher step (the step a
  rolling wheel can mount grows with its radius); long-travel suspension (Wikipedia "Monster truck").
- Hover car: an air cushion under a skirt (Wikipedia "Hovercraft"); Christopher Cockerell's invention; the SR.N1 crossed
  the Channel on 25 July 1959 (Wikipedia "SR.N1"); the flying is marked as game magic on the card.
- Sky taxi: the Klein Vision AirCar's 35-minute flight between Nitra and Bratislava airports in June 2021 (Wikipedia
  "Klein Vision AirCar"); eVTOL air taxis with many electric rotors take off straight up (Wikipedia "eVTOL"); lift is
  air pushed down (momentum theory).

## Tests

81 tests: `tests/unit/test_car_kinds.gd` (7), `test_vehicle_rules.gd` (20), `test_car_models.gd` (4),
`test_vehicle_save.gd` (2); `tests/integration/test_vehicle_drive.gd` (16), `test_vehicle_director.gd` (20),
`test_car_garage.gd` (7), `test_car_hud.gd` (2), `test_vehicle_vr.gd` (2), `test_vehicle_net.gd` (1). RED was seen for every rule and behaviour
before its code (the class missing, then each failure: a hop that went straight up against the step's face, a car
waking over unloaded ground, a car landing on a lake, a called car out of reach or on a parked car, an empty car
rolling on, the keys' hint, the garage too tall for a phone with the hover car's card (756 px), a sink too slow over
a cliff); the car-as-a-wall test was checked by taking its fix out (it failed); `test_car_hud.gd`, `test_vehicle_vr.gd` and `test_vehicle_net.gd` came with or just after
their code (the VR test was checked by removing the blink: it failed). The rides' and the HUD's tests pass unchanged.

## The smoke run (`tools/cars_smoke.gd`)

`XDG_DATA_HOME=<a private "smoke" folder> godot --headless --path . --script res://tools/cars_smoke.gd -- --smoke-seed=1683554885`,
2026-10-16, this desktop shared with other agents (load 10-24): **fails=0**. Every kind went its 300 m (2.4 km of road
in all, from the spawn along -z) at exactly its top speed and never past it; the ground 24 m ahead was ready in every
sample taken above 8 m/s (the race car's 81 samples at 14 m/s included); the hover car never went over the flight
ceiling (highest y 116.7 over mountains) and at most 2.3 blocks over its own 24-over-the-ground while sinking back
over a drop; the sky taxi flew at 11 m/s up to y 77; every HOP OFF was beside the car, never inside blocks; the save kept
the child's 4 cars (the garage sent the 4 oldest home).

| Kind | 300 m in | Top m/s | Ahead samples / missed | Avg frame ms (FPS) | Frames > 100 ms | The car's own step, avg / max ms |
|---|---|---|---|---|---|---|
| Go-Kart | 33.7 s | 9.00 | 125 / 0 | 12.3 (82) | 11 | 0.53 / 33.0 |
| Off-Roader | 30.6 s | 10.00 | 113 / 0 | 10.4 (96) | 22 | 0.45 / 12.2 |
| Race Car | 22.1 s | 14.00 | 81 / 0 | 11.4 (88) | 18 | 0.40 / 11.2 |
| Pickup Truck | 29.2 s | 10.50 | 108 / 0 | 10.6 (94) | 3 | 0.45 / 3.4 |
| Bus | 43.6 s | 7.00 | (never over 8 m/s) | 10.1 (99) | 29 | 0.56 / 27.9 |
| Monster Truck | 32.2 s | 9.50 | 117 / 0 | 13.0 (77) | 30 | 0.42 / 9.4 |
| Hover Car (flown) | 35.2 s | 10.00 | 108 / 0 | 9.7 (103) | 20 | 0.15 / 9.8 |
| Sky Taxi (flown) | 30.2 s | 11.00 | 99 / 0 | 15.5 (65) | 31 | 0.20 / 16.1 |

The long frames are this busy desktop's headless run with the smoke itself laying 7 road cells and clearing 28 above
them each frame ahead of the car (chunks re-meshed all along the 2.4 km) and new terrain streaming in; the budget is
the emulator's (the lead's check below). A car's own step costs about half a millisecond here (a phone: 1.5-2.5 ms;
one driven car per child). The first runs found three things the rules now hold: an empty car rolled on after HOP
OFF and blocked the next one (it now brakes at once), a called car could come out of reach (now always within
BOARD_REACH) or on a parked car (never), and the smoke's own flying start in a road tunnel.

## What the lead must check

On the emulator (Pixel_8_API_35, MEDIUM, both styles):
1. MORE → CARS: the garage fits the screen, its tiles and buttons are big enough, the speaker reads a card; GET IT
   brings each car in front of the child with its puff and words.
2. Drive each kind 300 m: ≥ 30 FPS and no frame over 100 ms (the race car at 14 m/s over new ground: the world must
   stream ahead; the headless smoke saw the ground 24 m ahead ready in every sample); HORN, HOP OFF, the camera behind.
3. A flying car: FLY, UP / DOWN, LAND; the hover car's 24-block ceiling; the sky taxi to 150.
4. Survivor: BUY with gold (and "You need more gold" without), CALL MY CAR in another Survivor world.
5. LAN or online: a guest buys and calls its car, rides along in the host's bus (seen inside through the windows),
   drives (smooth on the host's and its own screen), hops off; a passenger's stick does nothing.
6. The pickup: load and unload; the Sandbox tips the blocks out behind it.

In VR (the Quest, or `--vr-preview` on the desktop): getting in blinks and faces the front; the vignette while it
moves; the walking stick drives, A flies up, B dives, Triangle / Y (the turning stick's click) hops off; no roll;
getting out blinks; a guest's own car follows smoothly.

## Next (the game never ends)

Car races on Game Blocks courses (START / CHECKPOINT / FINISH, the race clock), a garage stand in the world, roads
and traffic signs to build (a road block that speeds cars up a little), a car wash and paint shop for patterns, more
kinds (a fire engine with a ladder, a tractor that ploughs the Gold Farm, an ice-cream van, a moon buggy that bounces
in low gravity, a submarine car), lessons from the cars (how gears work, why tyres grip), and a SIMPLE steering setting
for the youngest.
