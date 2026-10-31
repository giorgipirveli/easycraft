# M1b Task 10: beds, sleeping and day/night

Owner request (2026-09-23 22:44): "we also should be able to make sleep player". Spec §3b
"Beds, sleeping and day/night", plan Task 10. Built in a worktree from `6afe171`
(`m1b-underground`) in parallel with other tasks. The lead merges.

## What was built

- **Day/night cycle.** A 20-minute clock: 12 minutes of day, 2 of dusk, 4 of night and 2 of dawn.
  - The sun rises in the east (+X) and sets in the west (−X). Its path leans 30° towards +Z, so
    noon shadows aren't straight down.
  - The moon is opposite the sun. One `DirectionalLight3D` plays both: the sun by day, blue
    moonlight by night. It switches at the horizon, where its energy is 0.
  - Nights are moonlit and never pitch black: moon 0.4 × the day sun, ambient 0.8 × the day's, both
    bluish.
  - Dusk and dawn turn the horizon, fog and sunlight orange.
- **Sky in both styles.**
  - Blocky: `ProceduralSkyMaterial` colours for day, twilight and night. The sky's glow around the
    light is smaller at night, around the moon.
  - Realistic: the HDRI `PanoramaSkyMaterial` is dimmed at night (`energy_multiplier` 0.12).
  - A billboard moon (a generated 64 px texture with craters and a glow) and 320 stars in one mesh
    of small quads. Both are unlit and unfogged, follow the camera at 230–250 m (the camera's far
    plane is 300 m) and are hidden by day.
- **SkyCycle does not fight Ambience.** Every second it writes the open-air `sun`, `ambient` and
  `fog_color` into `world.ambience_base`, and Ambience adds caves and water on top every frame.
  - Fog distances stay `apply_graphics`'.
  - SkyCycle also sets directly what Ambience never touches: the light's rotation and colour,
    `ambient_light_color`, and the sky material.
- **Bed block**, `BED = 24` (`COUNT` is now 25), last in `PLACEABLE`, named "Bed". It is placeable
  and breakable.
  - The model is a `VoxelBlockyModelCube` with `height = 0.5625`, so its collision is also
    1 × 0.5625 × 1.
  - Atlas row 4: (0,4) top (pillow at the +Z end, folded sheet, quilted red blanket, wooden rim),
    (1,4) side, (2,4) bottom (planks and legs).
  - A half-height cube's side face shows only the bottom 9 rows of its side tile: blanket,
    mattress and frame. The rows above only appear in the hotbar icon: a headboard and a pillow,
    clear everywhere else.
  - The realistic versions are procedural cloth on the cached CC0 Wood095 and WoodFloor043 textures.
- **Sleeping.**
  - Standing on the floor within 3 blocks of a bed shows a **SLEEP** context button, centred just
    above the hotbar. **B** does the same on a keyboard.
  - The host checks the request: a bed, in reach, on the floor, not flying or in water, air above
    the bed, and nobody else in it.
  - Every peer then lays the sleeper's **whole avatar node** on its back on the mattress, head on
    the pillow, with "Z"s floating up.
  - The sleeper's screen fades to dark with a floating "Z z z", and the button becomes
    **WAKE UP** (JUMP also wakes).
  - When every player in the game sleeps, the host waits 2.5 s (the lie-down and fade), then jumps
    the clock to the next sunrise at night or the next sunset by day, and wakes everyone. The screen
    flashes black and fades back in with "Good morning!" or "Good evening!".
  - Sleepers who are waiting see "Zzz... n of m asleep".
  - Other players see the lying avatar and a toast: "A friend is sleeping...".
- **Home.**
  - Every bed you sleep in becomes your home.
  - Falling out of the world in normal mode takes you home: to the bed, or to the world spawn if you
    have no bed or it is gone. A bed too far away to be loaded is checked on arrival.
  - Breaking a bed, by any route (tap, stamp, batch or wand capture), clears it as a home and wakes
    whoever sleeps in it.
- **Saving.** `WorldMeta.time_of_day` (a new world starts at 0.3, morning) and `WorldMeta.homes`
  (`{player name: [x, y, z]}`) are saved with the world. Old saves load with the defaults, and broken
  entries are ignored.
- **Multiplayer.**
  - The host owns the clock. It sends it every 10 s, on every jump, and to each player who joins.
    Clients run the same clock in between.
  - Sleep, home and go-home are host-validated messages through `Session`.
  - Players who leave never block the skip and never count as asleep.

## Files

| File | What |
|---|---|
| `core/rules/day_cycle.gd` (new) | `DayCycle`: clock, phases, sun and moon directions, `is_night`, `wake_time`, `look(t)` (every sky value) |
| `core/rules/bed_rules.gd` (new) | `BedRules`: `check`/`message`, `find_bed`, `lie_position`, `home_position`, `all_asleep`/`asleep_count`, `lost_homes`, `home_target` |
| `world/sky_cycle.gd` (new) | `SkyCycle` node: drives light, sky, stars, moon and `ambience_base`; the host clock and its sync |
| `world/sleep_director.gd` (new) | `SleepDirector` node: local bed scan and sleep display; host sleep, skip, homes and bed breaks |
| `ui/hud/sleep_overlay.gd` (new) | `SleepOverlay`: the fade and "Z z z" |
| `data/blocks/block_ids.gd` | `BED = 24`, `COUNT = 25`, `PLACEABLE`, name |
| `world/block_library.gd` | `TILES[BED]`, `height = BedRules.TOP` |
| `tools/make_atlas.gd`, `tools/make_realistic_atlas.py` | Bed tiles, appended with their **own RNG** |
| `data/blocks/atlas.png`, `realistic_albedo.png`, `realistic_normal.png` | Regenerated. A pixel diff shows **only tiles (0,4), (1,4) and (2,4) changed** in all three; `water_waves.png` is byte-identical |
| `world/world_meta.gd` | `time_of_day`, `homes`, `MAX_HOMES`, tolerant parsing |
| `autoloads/session.gd` | End section: `time_received`, `bed_sleep_requested`, `bed_wake_requested`, `sleep_state_received`, `home_received`, `go_home_received`, with their request, broadcast and send functions and RPCs |
| `entities/player/player.gd` | Sleeping early-out in `_physics_process`; a NORMAL-mode fall goes home; end section: `set_sleeping`, `set_home`, `go_home`, Z puffs |
| `ui/hud/hud.gd` | End section: `sleep_button`, `sleep_overlay`, `add_sleep_controls`, `show_sleep_button`, `set_sleeping` |
| `scenes/sandbox.gd` | Three one-line calls (`_add_sky` for host and client, `_setup_sleep`, `_save_time_and_homes`); end section: `sky`, `_sleep`, `set_time_of_day`, `go_home`, home save and restore |
| `docs/DEVELOPMENT.md` | Block table row 24; atlas row 4 |

## Tests

53 new tests; the full suite is 317 passing (baseline 264).

- `tests/unit/test_day_cycle.gd` (14):
  - `test_a_day_lasts_twenty_minutes`
  - `test_phases_last_12_2_4_and_2_minutes`
  - `test_named_times_fall_in_their_phases`
  - `test_phases_come_in_order`
  - `test_the_sun_rises_in_the_east_is_highest_at_noon_and_sets_in_the_west`
  - `test_the_sun_moves_smoothly_without_jumps`
  - `test_the_moon_is_opposite_the_sun`
  - `test_it_is_night_while_the_sun_is_down`
  - `test_wake_time_is_the_next_sunrise_at_night_and_the_next_sunset_by_day`
  - `test_nights_are_moonlit_and_never_pitch_black`
  - `test_night_is_darker_and_bluer_than_day_with_stars_and_a_moon`
  - `test_sunset_glows_orange`
  - `test_the_look_changes_smoothly`
  - `test_noon_matches_the_world_scene` (the day palette equals `world.tscn`'s)
- `tests/unit/test_bed_rules.gd` (13):
  - `test_can_sleep_standing_next_to_a_bed`
  - `test_needs_a_bed`
  - `test_the_bed_must_be_within_reach`
  - `test_not_while_flying_jumping_or_swimming`
  - `test_needs_room_above_the_bed`
  - `test_one_sleeper_per_bed`
  - `test_every_refusal_has_a_friendly_message`
  - `test_finds_the_nearest_bed_within_reach`
  - `test_lies_on_top_of_the_bed`
  - `test_time_skips_only_when_every_player_sleeps`
  - `test_players_who_left_never_block_the_skip`
  - `test_breaking_a_bed_clears_every_home_on_it`
  - `test_home_is_the_bed_or_the_world_spawn_when_it_is_gone`
- `tests/unit/test_world_meta.gd` (+3):
  - `test_time_of_day_and_homes_round_trip`
  - `test_old_saves_start_in_the_morning_without_homes`
  - `test_broken_time_and_homes_are_ignored`
- `tests/unit/test_block_library.gd` (+2):
  - `test_bed_is_a_half_height_block_with_matching_collision`
  - `test_a_bed_does_not_hide_the_face_next_to_it` (meshes a bed next to stone)
- `tests/unit/test_block_ids.gd` (+1): `test_bed_is_placeable_solid_and_breakable`.
  `test_placeable_blocks` now expects 23.
- `tests/integration/test_sky_cycle.gd` (5), on a real world:
  - `test_noon_is_the_worlds_day_look`
  - `test_midnight_is_dark_but_moonlit_and_keeps_the_fog_distances`
  - `test_the_realistic_sky_is_dimmed_at_night`
  - `test_a_style_switch_gets_the_night_look_at_once`
  - `test_the_clock_runs_and_can_stop`
- `tests/integration/test_sleep_director.gd` (9): a real world, two players (peers 2 and 3), and
  requests delivered through the same `Session` signals an RPC fires.
  - `test_one_sleeper_never_skips_the_night_for_everyone`
  - `test_when_everyone_sleeps_the_night_skips_to_sunrise_and_everyone_wakes`
  - `test_sleeping_by_day_skips_to_sunset`
  - `test_a_player_who_leaves_never_blocks_the_skip`
  - `test_a_sleeper_who_leaves_does_not_count_as_asleep`
  - `test_getting_up_cancels_the_skip`
  - `test_a_bed_too_far_away_or_taken_is_refused`
  - `test_breaking_a_bed_wakes_its_sleeper_and_clears_the_home`
  - `test_home_is_the_last_bed_slept_in`

  Replacing the all-asleep rule with "anyone asleep" makes two of them fail.
- `tests/integration/test_player_sleep.gd` (6):
  - `test_a_sleeper_lies_on_the_bed_with_the_head_on_the_pillow`
  - `test_a_sleeper_puffs_zzz_until_it_wakes`
  - `test_going_home_heads_for_the_bed`
  - `test_without_a_home_going_home_is_the_world_spawn`
  - `test_falling_out_of_the_world_goes_home`
  - `test_ghosts_below_the_world_still_pop_up_where_they_are`

**Headless end-to-end runs** (temporary scripts, not committed; a separate `user://` through a
temporary `override.cfg`):
- **Solo, in the real sandbox.** Spawn, place a bed, the SLEEP button shows, sleep (lying on the
  mattress, WAKE UP, the fade, Zs), skip to sunrise (0.151), wake, save
  (`homes={"SmokeKid": (14, 36, 0)}`), fall out of the world and come back to the bed, break the bed
  (the home is cleared, and the saved homes are empty).
- **LAN, two headless instances.**
  - The client got the host's clock.
  - The host asleep alone kept the night going (6 s later the time was still 0.006).
  - The client saw the host lying down with Zs.
  - A second sleeper was refused the host's bed ("taken").
  - Once the client slept in its own bed, both woke at 0.150 (sunrise) on both machines, and the
    client received its home over RPC.

**Costs (desktop):**
- `BedRules.find_bed`: 142 µs per scan, every 0.25 s, only while walking on the floor.
- `DayCycle.look`: 12 µs, once a second.
- Sky material writes happen only when a value changes.

## Rulings (decided on my own) and what each costs if wrong

1. **Clock layout.** t runs 0..1 like a clock face: midnight 0, noon 0.5.
   - Dawn 0.1–0.2, day 0.2–0.8, dusk 0.8–0.9, night 0.9–0.1.
   - Sunrise 0.15 and sunset 0.85 are the moments the sun is on the horizon, in the middle of dawn
     and dusk.
   - A new world starts at 0.3 (morning, 10 minutes of daylight).
   - *Cost if wrong:* none; these are constants.
2. **Wake rule at dusk.** Sleeping at dusk while the sun is still up wakes you at sunrise, not
   12 seconds later at sunset: "getting dark" counts as night for waking. After sunrise, you wake at
   sunset. `is_night` itself means "the sun is down" (for M2 monsters).
   - *Cost if wrong:* one line in `DayCycle.wake_time`.
3. **One light for the sun and the moon.** It is cheap (no second directional light or shadow map)
   and moonlight casts shadows.
   - *Cost if wrong:* a sun disc and the moon can't both be lit at twilight. A second light is a
     small change in SkyCycle.
4. **Night brightness was chosen without seeing it** (headless only): `DayCycle.MOON` 0.4,
   `NIGHT_AMBIENT` 0.8, blue `NIGHT_AMBIENT_COLOR`, and `NIGHT_SKY_ENERGY` 0.12 for the HDRI.
   - *Cost if wrong:* too dark or too bright. Tune these constants after the emulator check; the
     tests keep a "never pitch black" floor.
5. **Realistic sky.** The HDRI is only dimmed. Its baked-in sun stays where it is and does not
   follow our sun.
   - *Cost if wrong:* less realism. `Environment.sky_rotation` could turn the HDRI later.
6. **Stars are static** in the upper sky (elevation above about 3.4°, so never below the horizon),
   in one mesh. The moon is a billboard.
   - *Cost if wrong:* none for gameplay; real star motion could come later.
7. **The sky updates once a second**, not every frame. Radiance updates are `Sky.PROCESS_MODE_INCREMENTAL`,
   set in code; the procedural sky was already incremental.
   - *Cost if wrong:* sky lighting settles over a few frames after a change. If dusk or dawn costs
     FPS on phones, raise `SkyCycle.UPDATE_INTERVAL`.
8. **The bed is one block** with a fixed orientation: the pillow is always at +Z, because a block id
   has one orientation. A lying avatar (1.8 blocks long) keeps its head on the pillow, and its legs
   hang about 0.75 block over the foot end.
   - *Cost if wrong:* it looks a bit funny. A 2-block, rotatable bed needs rotation-aware blocks
     (M2).
9. **Pose** (the lead's instruction). `Player.set_sleeping` rotates the whole `avatar` node by
   (PI/2, 0, 0) and offsets it by `SLEEP_OFFSET` × size. It also calls `avatar.set_pose(&"sleep" /
   &"stand")` when the avatar has that method, so the realistic `AvatarModel` works too.
   - `Avatar:rotation` is already replicated.
   - The offset and the Zs are applied on every peer from the sleep state.
10. **Sleep rules.** You can sleep at any time of day (by day, you skip to sunset). Reach is
    3 blocks from the feet to the bed's top, with +1 host tolerance.
    - The host takes a remote body's "on the floor" on trust, because its owner simulates it.
    - *Cost if wrong:* a modified client could sleep mid-jump. That is harmless.
11. **The skip waits 2.5 s** (`SleepDirector.SKIP_DELAY`) after the last player lies down, so the
    lie-down, Zs and fade can play.
12. **B key.** B sleeps and wakes on a keyboard, through a raw keycode rather than a new input-map
    action, so `project.godot` and `tools/setup_input_map.gd` stay untouched.
    - *Cost if wrong:* B can't be rebound. Moving it into the input map is a small change.
13. **Homes are saved per player name, but only the host's own name is known.** LAN guests' homes
    last for the session only, keyed by peer id.
    - *Cost if wrong:* a guest who rejoins has lost their home. Once player names are replicated
      (chat task), `SleepDirector._homes` can be keyed by name.
14. **Falling out of the world.** In NORMAL mode you go home: the bed, or the world spawn column
    (the surface there). This replaces "the surface above where you fell". In FLY and GHOST mode the
    old rescue stays, because flying under bedrock is on purpose.
    - *Cost if wrong:* a normal-mode fall without a bed now teleports to the world spawn. The spec
      asks for that.
15. **The world spawn** is `world.spawn_column()` (the first-spawn column, on its surface) for
    everyone. It is the same on clients, which have the same seed.
16. **The wand can turn a bed into part of a buddy.** Beds are not "ground". That counts as the bed
    being gone: the home is cleared.
17. **Targeting.** The tap ray treats a bed's cell as a full block (`GridRay`), so the target
    highlight is a full cube around a bed.
    - *Cost if wrong:* cosmetic.
18. **The clock stops in the pause menu**, like everything else. On LAN, clients are corrected by
    the next sync.

## The lead must verify in the editor or on the emulator

- **Night brightness, in both styles** (the emulator shows Compatibility):
  - Moonlit and readable, never pitch black; caves at night still have the lantern.
  - Tune `DayCycle.MOON`, `NIGHT_AMBIENT`, `NIGHT_AMBIENT_COLOR` and `NIGHT_SKY_ENERGY` if needed.
- **Dusk and dawn**: an orange horizon, fog matching the horizon, a warm sun, and no visible jump
  when the light switches from sun to moon at the horizon.
- **Moon and stars**: size and glow of the moon; stars small, not fogged, hidden behind terrain,
  hidden by day. The realistic HDRI dims at night and gets its stars and moon.
- **Sun movement and shadows** over the day, including the 1 s update steps.
- **The bed block**, in both styles:
  - Top: the pillow at the +Z end. Side: blanket, mattress and frame. Bottom: planks.
  - Half-height collision: you can walk onto it (auto-step) and stand on it.
  - The hotbar and palette icon: a side-view bed with a headboard.
- **SLEEP / WAKE UP button**:
  - Centred just above the hotbar, never overlapping it.
  - Shows only near a bed while on the floor, and hides while jumping or flying.
  - The fade, "Z z z", and the "Good morning!" toast.
- **The lying avatar**: on its back on the mattress, head on the pillow, legs over the foot end, Zs
  rising. The other LAN player sees the same.
- **FPS at dusk and dawn** in both styles: the sky changes every second and radiance updates are
  incremental.
- **Falling out of the world** (normal mode, e.g. ghost under bedrock, then walk) brings you back
  to the bed.
- **Loading a save at night**: until the player spawns, Ambience does not apply the base, so the
  light is day-bright for that moment. It is only a loading moment.
  - *If it shows:* let Ambience apply once before spawn. That is the Task 7 file.

## Integration notes (public API)

**Chat commands (Task 12)**
- `sandbox.set_time_of_day(t: float)`: host only (ignored on clients). It jumps the clock for
  everyone.
- `sandbox.go_home(peer_id: int)`: host only. It sends that player to their bed, or to the world
  spawn.

`DayCycle` constants:

| Constant | Value |
|---|---|
| `MIDNIGHT` | 0.0 |
| `DAWN_START` | 0.1 |
| `SUNRISE` | 0.15 |
| `DAY_START` | 0.2 |
| `START` | 0.3 (a new world's morning) |
| `NOON` | 0.5 |
| `DUSK_START` | 0.8 |
| `SUNSET` | 0.85 |
| `NIGHT_START` | 0.9 |

Suggested `/time` mapping:

| Command | Constant |
|---|---|
| `/time day` | `START` |
| `/time noon` | `NOON` |
| `/time night` | `NIGHT_START` |
| `/time midnight` | `MIDNIGHT` |

Other helpers: `DayCycle.is_night(t)` (sun down), `DayCycle.phase(t)`, `DayCycle.wake_time(t)`.

**Sandbox**
- `sandbox.sky`: the `SkyCycle`, with `time` (0..1), `running`, `set_time(t)` and `refresh()`.
- `sandbox._sleep`: the `SleepDirector`.

**Session** (end section)

| Signal / function | Direction and use |
|---|---|
| `time_received(t)` | Clients |
| `broadcast_time(t)`, `send_time(peer, t)` | Host |
| `request_bed_sleep(bed)`, `request_bed_wake()` | Any peer |
| `bed_sleep_requested(peer, bed)`, `bed_wake_requested(peer)` | Host |
| `broadcast_sleep_state(peer, asleep, bed)`, `send_sleep_state(to, peer, asleep, bed)` | Host sends |
| `sleep_state_received(peer, asleep, bed)` | All peers receive |
| `send_home(peer, has, bed)` / `home_received(has, bed)` | Host sends / the owner receives |
| `send_go_home(peer)` / `go_home_received` | Host sends / the player receives |

**SleepDirector**
- `press_sleep()`, `restore_home(bed)`, `home_of(peer) -> Vector3i` (`BedRules.NO_BED` if none),
  `send_player_home(peer)`.
- `nearby_bed`, `SKIP_DELAY`.

**Player**
- `sleeping`, `sleep_bed`, `set_sleeping(asleep, bed)`.
- `has_home`, `home_bed`, `set_home(on, bed)`, `go_home()`.
- `SLEEP_OFFSET`, `ZZZ_RISE_TIME`.

**Hud**: `sleep_button`, `sleep_overlay`, `add_sleep_controls()`,
`show_sleep_button(on, text = "SLEEP")`, `set_sleeping(asleep)`.

**Realistic avatar (the other agent's `AvatarModel`)**
- The sleep pose assumes the model's feet are at its origin, it faces −Z with +Y up, and its head
  is at about `CameraRig.HEAD_HEIGHT` (1.55).
- `Player._sleep_tick` calls `avatar.animate(0.0, true, delta)` while asleep.
- `set_pose(&"sleep" | &"stand")` is optional.

**Merging**
- **Atlas row 4 tiles (0..2, 4) are the bed's.** The bed tiles use their own RNG in both tools, so
  after merging other tasks' tiles:
  1. Regenerate both atlases (`godot --headless --path . --script res://tools/make_atlas.gd` and
     `python3 tools/make_realistic_atlas.py`).
  2. The bed tiles stay the same whichever order the tile code lands in.
- `test_block_ids.test_placeable_blocks` expects 23; bump it for other new blocks.
- The palette (8 columns) still fits 23 blocks in 3 rows.

**Suggested `DEVELOPMENT.md` gotchas** (not added, to avoid conflicts):
- `wrap` is a global function: a static function called `wrap(x)` fails to parse ("expected 3
  arguments").
- Autoload names are unknown while a `--script` SceneTree main loop compiles, and so is any class
  that uses them. Add a Node driver at runtime with
  `root.add_child.call_deferred(load(...).new())`.
- A temporary `override.cfg` with `application/config/use_custom_user_dir=true` gives a headless run
  its own `user://`. That keeps shared saves and other worktrees safe.
- In a GUT test, a `Player` streams terrain around itself, making the test about 10× slower. Free
  `player.viewer` when the test needs no terrain.
