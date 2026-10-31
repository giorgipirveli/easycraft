# Owner feedback #39, part: the Sky Dragon (the Dragon Realm's boss)

Worker branch `worktree-agent-aeb8e3d2df0e92608`, cut from the #39 lead's branch `worktree-agent-a317d3c66e402be33`
(its spec commit `b2b2308`, merged first). The lead merges this into the #39 integration; two other workers build the
realm's world and its monsters. Spec: §14.2a ("The Sky Dragon as built"), §12.9 (the Golem's honest help and team
scaling), §12.20 (Monster Wave's raid boss at wave 10), §6 (fair fun). Plan: M3 Task 26.

## What was built

### Rules (`core/rules/sky_dragon_rules.gd`, `SkyDragonRules`, pure)

| | |
|---|---|
| Health | 480 × (1 + 0.5 per extra player or bot friend), 75 % when tired (the Golem's `TEAM_SHARE`, `TIRED_SHARE`); more than the Cake Monster's 420 (the last boss is the biggest) |
| Schedule | RISE (2.5 s, no hits) → CIRCLE (3 s; tired 4) → DIVE_WARN (1.4 s; tired 1.5) → DIVE (as long as its line takes at 13 m/s; tired × 0.8) → GLIDE (2.5 s; tired 3.2) → CLIMB (1.5 s) → CIRCLE …; after every second dive GLIDE → LAND (1 s) → REST (3.5 s; tired 4.5; double damage) → TAKE_OFF (1.2 s) → CIRCLE |
| Circle | 12 blocks round the Totem, 8 blocks over the ground under it, 6 m/s |
| The dive's line | from under the dragon, through the child's feet and 7 blocks on, at least 10 long, cut at the arena circle (30 blocks from the middle) |
| The swoop | from where it hovered down to 0.4 over the ground before it reaches the child (`dive_height`: descent over 0.8 × the distance to the child, 2–9 m), low from there on |
| Who it hits | feet within 1.3 (flat) of this step's path and within its height band (1.6 under its feet to 2 over them): 4 HP, once per dive; the line drawn is 2 × 1.4 wide, so off the drawn line is always safe |
| The push | 7 m/s sideways off the line on the child's side (a little along, a hop up); beyond 20 blocks from the middle it pushes back inwards, never out |
| Ground | `column_floor` (from the ground it knew: 2 cells on flat ground; up over cover, down a slope; water counts as ground; over the void it keeps the height it knew), `floor_under_body` (a 3 × 3 grid `reach` apart; reach 0: its feet only), `smooth_floors` (along a dive: the highest within 1.5 m, then 1 m down per metre) |
| Towers | 4 (tired 3) at 10 blocks round the middle, a quarter turn apart; the second rise turned half a step (new places); 4 hits break one; each standing tower heals 0.5 % of its health every second (480: 2 HP; a team of three's 960: 5 HP); never above its max; rises: when it has arrived, and once more at a third of its health (`stage`, `towers_due`), never a third time |

### The dragon (`entities/monsters/sky_dragon.gd`, `SkyDragon extends StoneGolem`)

- To the BossDirector it is a StoneGolem: the fight, bar, honest help, gold, win, loss, the Dance Orb and the
  director's "near" check work unchanged. The director passes the Totem as `center` in the spawn data (the other
  bosses ignore it).
- The host **moves** it (it is never pushed: `collision_mask` 0, a 1.8 × 1.6 × 1.8 box on the monsters' layer for taps,
  off while it arrives or leaves). It never leaves the arena circle (`keep_in` on every move).
- **Ground:** ten times a second it reads the ground under it (its feet only while high; while low, a 3 × 3 grid as
  wide as its body plus how far it moves before it looks again) and 2 blocks or more ahead; when the ground under it
  rises it climbs at 12 m/s. During the wind-up it reads the ground along the dive's line, two samples a step (every
  0.5 m, on the line and 0.9 to each side), so no step reads it all; the swoop follows the smoothed profile. Every
  read goes through a 10-second cell memory (`_read`): circling, it flies over the same ground again and again.
- **Synced** (on change): `phase`, `hp`, `dive_from`, `dive_to`, `tower_spots`, `tower_hits` (plus position and
  rotation). Every screen draws the dive line (`_show_line`: a striped strip on the ground, breathing 0–10 % wider,
  never narrower than it hits), builds the towers at `tower_spots` and breaks them from `tower_hits`. One RPC,
  `_rpc_towers` (the crystal hum and the line "Break the crystal towers — they heal the Sky Dragon!", or "New crystal
  towers! …" for the second rise).
- **Looks:** wings beat (fast while it climbs, big beats in the wind-up, folded back in the dive, spread in the
  glide, folded down at rest), the tail sways, the head lifts in the wind-up and droops at rest, the body pitches with
  its climb or dive and banks into turns; the wind-up lights its eyes (a glow in its mouth) and violet stripes on its
  belly; stars circle its head while it rests. A wing-beat sound on every downstroke; a roar at the wind-up; a whoosh
  as it dives.
- **A lost fight:** it flies up and away (2.2 s) and is gone with its towers.

### Crystal towers (`entities/monsters/sky_dragon_tower.gd`, `SkyDragonTower extends StaticBody3D`)

Children of the dragon (`top_level`), never blocks: in the group "monsters" with `take_hit` / `hit_center` /
`hit_radius` / `size` while standing (swords, arrows, spears, blasters, orbs, bot friends' swings, taps), out of it
once broken. The host's dragon counts the hits (`hit_tower`). Each rises out of the ground (0.8 s), sends a beam with a
spark running up it to the dragon, wobbles and sheds shards on a hit (its crystal shrinks), and shatters on the last.
It never hurts anyone (a source scan in the test).

### Looks, sounds, HUD, glue

- `SkyDragonModels`: body, neck and head (horns, frills, teeth), eyes (and a lit pair), chest gem, the wind-up's glow,
  wing, tail; tower base and crystal, beam, spark; the dive line. All shared, built once; the animals' material and
  the Golem's glow material (`DesertPortal.prewarm` compiles it as the world appears): nothing new to compile.
- `tools/make_sky_dragon_sounds.py` (original, synthesised; credited in `assets/CREDITS.md`): `sky_dragon_roar`,
  `sky_dragon_wings`, `sky_dragon_dive`, `sky_crystal_hum`, `sky_crystal_shatter` (Audio keys of the same names;
  prefixed so the realm's other workers' sounds cannot collide).
- `BossBar._draw_dragon_face` (teal scales, ivory horns, violet frills, golden eyes with slits, a pale jaw).
- `BossDirector`: `_new_boss` (SKY_DRAGON → `SkyDragon`), `center` in the spawn data, `_win_look` (teal scales and
  violet crystal bits, the shatter), `_rpc_won(at, kind, portal)`: when no portal opens (Monster Wave's raid boss)
  the win says "Every universe is yours!" in the last universe and nothing about a portal elsewhere.
- `BossRules.SKY_DRAGON`, `words`, `max_hp_of`; `ChatCommands.BOSSES` + `BOSS_KINDS` (`/summon skydragon` →
  `&"sky_dragon"`).
- **No reward is wired here** (the lead adds the baby dragon pet and the Dragon Crystal in `_earn_boss_items`).
- **Monster Wave:** nothing to change: the ArenaDirector starts `boss.start(totem_pos)` at wave 10 and the
  BossDirector uses the world's `boss_kind` (tested with a real ArenaDirector, WaveDirector, MonsterDirector and
  BossDirector: `test_the_arena_starts_the_sky_dragon_at_wave_ten`).

## Chosen and rejected patterns (the godot-prompter skills)

- **state-machine:** an enum FSM with a pure transition table (`SkyDragonRules.next_phase`), one synced int like every
  boss — chosen (a linear cycle; guests animate from the int). Node-based states — rejected (the phase must be one
  replicated int; state nodes don't replicate and the StoneGolem API is the director's). A hierarchical machine
  (airborne / grounded) — rejected: ten states in one cycle, splitting them would sync two ints for nothing. The
  towers run as a **parallel** machine (rises and hits, `tower_spots` / `tower_hits`) that touches the flight only
  through the heal, on the host.
- Movement: kinematic flight (positions set by the host, a tap box only) — chosen; a CharacterBody3D with
  `move_and_slide` in the air — rejected (Jolt cost for no use; nothing may push a boss, and it must never scrape
  blocks). Ground: incremental column reads through a short memory — chosen; a downward scan from above every
  decision — rejected after measuring its reads (and it missed its body's sides, see the tests).

## Tests (RED → GREEN)

Suite (`tests/suite_slots.sh tests/run_tests.sh`, on a snapshot of the worktree): **4502 of 4502** after merging the
lead's branch → **4540 of 4540** with the Sky Dragon (exit 0).

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_sky_dragon_rules.gd` | 20 | `SkyDragonRules` not declared, `BossRules.SKY_DRAGON` not found (parse errors: written before the code) |
| `tests/integration/test_sky_dragon.gd` | 18 | `SkyDragon`, `SkyDragonTower`, `SkyDragonModels` not declared. Then, with the code: `test_it_never_flies_through_cover_or_ground` failed for real (lowest −0.80 under the cover's top): gliding past a ring of cover, the dragon's side grazed it between two looks (it read the ground under its feet and 2 blocks ahead only). Fixed by reading under its whole body as far round as it moves before it looks again, and the dive's line with its sides |

Mutation checks (each removed, run, restored; every one caught):

| Mutation | Caught by |
|---|---|
| the dive hits within 3 × its reach | `test_a_child_who_steps_off_the_line_is_missed` (both sides), `test_who_the_dive_hits` |
| no dive hits | `test_a_dive_hits_a_child_on_the_line_after_the_line_showed`, `test_nothing_hurts_without_a_warning` |
| no tower healing | `test_crystal_towers_rise_heal_it_and_break` |
| no second rise at a third | `test_towers_rise_again_at_a_third_of_its_health` |
| no dive line drawn | `test_guests_see_the_dive_line_and_the_towers` |
| no inward push near the edge | `test_the_push_never_throws_a_child_out_of_the_arena` |
| the win ignores "no portal" | `test_as_the_raid_boss_its_win_promises_no_portal` |
| no body footprint while low | `test_it_never_flies_through_cover_or_ground` |
| the dive's ground without its sides and smoothing | `test_it_never_flies_through_cover_or_ground` |

Not caught, on purpose: removing the look-ahead (the body-wide reads keep it out of cover; the look-ahead only makes
it rise early instead of hopping up at 12 m/s — a looks matter).

## Cost (the brief: the host step against the Cake Monster's)

`godot --headless --path . --script res://tools/sky_dragon_bench.gd`, 60 s each at 60 Hz in alternating 5 s blocks,
the arena's ground, a child near the middle, load 32 on the shared PC:

| | avg µs | p99 µs | max µs |
|---|---|---|---|
| Sky Dragon host step (flight, dives, towers' heal) | 32.8 | 162 | 2157 |
| Cake Monster host step | 21.9 | 106 | 1329 |
| Sky Dragon looks (pose, line, four beams) | 33.2 | 101 | 1064 |
| Cake Monster looks | 8.5 | 30 | 2023 |
| four towers' own `_process` | 9.3 | 21 | 65 |

World reads: the dragon **34 a second** (the Cake Monster 4): at 15–35 µs a real voxel read, about 0.5–1.2 ms a second
of reading, spread (a decision reads 2–4 cells high up, up to ~36 low; the dive's line ~480 cells over its 84 wind-up
steps, most of them remembered). The maxima are the busy PC's (one-off spikes in both). Shared meshes and materials
only; no per-event material.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **"Once more at a third of its health" = when it is down to a third** (`stage` 1), not when it has lost a third.
   Cost if wrong: one constant (`towers_due`: stage 2).
2. **It dives at the nearest child** (like every boss's target), not in turns. Cost: a turn counter in `_plan_dive`.
3. **Heal 0.5 % of its health a second per tower** (2 HP for one child's dragon; about 150 HP heals while a child
   breaks four towers one by one). Cost: `HEAL_SHARE`.
4. **Four hits of anything break a tower** (hits, not damage: every weapon is fair, a wooden sword too). Cost:
   `TOWER_HITS`, or count damage in `hit_tower`.
5. **Gliding low is normal damage; resting is double** (the brief's "dazed-style" rest). Cost: `hit_taken`.
6. **A hit on the dive line is 4 HP** (the Golem's slam), whatever the universe (bosses are not scaled; the arena's
   kit is). Cost: `DIVE_DAMAGE`.
7. **It is hittable in the air** (arrows, thrown spears; `hit_radius` 2 — it is big). Cost: `hittable`.
8. **The win's words follow whether a portal opened** (`_rpc_won`'s new `portal` argument, a default keeps old
   callers): Monster Wave's win no longer says "A portal opened by the Totem!" for any boss (it opened none); in the
   last universe it says "Every universe is yours!". Cost: the argument and one line in `_win_look`.
9. **The line is drawn at the child's ground height** (dive_from/dive_to's y): on a hilly Sandbox world (`/summon`)
   parts of it can sink into a slope; the arena is flat. Cost: a per-segment line (more meshes).
10. **A tower rise is an RPC for its line and hum only**; the towers themselves come from the synced state (a late
    joiner sees them). Cost: none known.
11. **Over the void it flies at the height it knew** (`column_floor` keeps its guess). Cost: a void-aware rule.

## What the lead should check on the emulator

1. Monster Wave in the Dragon Realm to wave 10 (or `/summon skydragon` in Sandbox): the dragon arrives, circles, the
   striped line on the ground (readable on a phone? wide enough?), the swoop along it, a step off dodges it; it
   glides low (a sword reaches it), lands after the second dive (stars, "x2" on the bar), takes off.
2. The towers: rise with the line, beams and sparks to the dragon, the bar creeping back up, 4 sword hits break one
   (shards, shatter sound), the second rise at a third.
3. LAN: a guest sees the line, the towers, the breaks and the win; the win's words in Monster Wave ("Every universe is
   yours!", no portal promised).
4. Frame times during a dive and at a tower rise (both styles); the arena's cover pillars: it never flies through one.
5. The sounds' volume (the wing beats every ~0.9 s may be too present: `Audio.play(..., -8.0)` in `_pose_dragon`).

## Merge notes (what will conflict)

Shared files, each a small edit: `core/rules/boss_rules.gd` (the constant after CAKE, `words`, `max_hp_of`),
`core/rules/chat_commands.gd` (`BOSSES`, `BOSS_KINDS`, `_parse_summon`), `world/boss_director.gd` (`start`'s spawn
data, `_on_defeated`, `_rpc_won`, `_new_boss`, `_win_look`, `GRAND_WIN_NO_PORTAL`), `ui/hud/boss_bar.gd` (`_draw`,
`use_boss`, the face at the end), `autoloads/audio.gd` (five keys after `fanfare`), `assets/CREDITS.md` (a section
before "Realistic avatar"), `docs/DEVELOPMENT.md` (§4 a section before "Autopilot", §5 a paragraph after the Candy
Kingdom's, §8 a row after the boss-without-a-floor one), the spec §14.2a (a sub-bullet), the M3 plan (Task 26, a line).
The lead wires `world/universes/dragon.gd`'s `boss_kind = BossRules.SKY_DRAGON` and the rewards in
`_earn_boss_items`. `test_candy_boss.gd` assumes universe 4 is the last: it changes when the world worker's ladder
entry merges (not touched here).
