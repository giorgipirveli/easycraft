# M2 Task 4: Monsters of Green Meadows, and gentle Sandbox monsters

Spec §12.4 (monsters), §12.15 (Sandbox monsters, owner feedback #19: "even in sandbox mode we should
face some monsters"), plan Task 4. Lead additions during the task (child-psychology notes in
`docs/design/`): monsters never break player builds; hits feel good (a tiny hit-stop, a squash,
confetti). Built in an isolated worktree from `2430164` (branch `m2-survive-the-night`), no editor or
emulator use. Commits `ff67199`, `a4ae3ca`, `b43720a` (+ this notes commit).

## What was built

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/monster_rules.gd` | Stats, scaling, level looks, night spawns, levels, the sunrise puff, coins, sight, safe steps, the summon spot |
| Monster | `entities/monsters/monster.gd` | CharacterBody3D, group `monsters`, `take_hit(damage, from, knockback)`, goblin chaser and slime jumper, looks on every peer |
| Models | `entities/monsters/monster_models.gd` | One box-built mesh per kind and level (built once), the goblin's club arm, the coin, the health bar |
| Director | `world/monster_director.gd` | Node `Monsters` on every peer (spawners, confetti RPC); the host ticks night spawns, puffs, defeats, coins, /summon |
| Coins | `entities/pickups/coin.gd` | No physics body, one shared mesh; flies to the nearest player within 2 blocks; the host pays once |
| Weapons | `world/combat_director.gd` | Group `monsters` in `hittables`; hits go to `take_hit` with the weapon's damage and push |
| Taps | `entities/player/block_interactor.gd` | A weapon tap on a monster aims at it |
| Sandbox | `scenes/sandbox.gd` | Wires the director (host), `summon_monster` hook, MONSTERS: ON / OFF |
| Pause menu | `ui/menus/pause_menu.gd` | `show_monsters_setting(on)`, signal `monsters_toggled(on)` (Sandbox worlds, host only) |
| World save | `world/world_meta.gd` | `monsters_on` (default true; anything but a bool reads as true) |
| Chat | `core/rules/chat_commands.gd`, `scenes/chat_command_runner.gd` | `/summon slime 3`, `/summon goblin` (level 1); Sandbox-only like every `/summon` |
| Home beds | `world/sleep_director.gd` | `home_beds()` for the spawn rule |
| Sounds | `tools/make_monster_sounds.py` | `squish`, `growl`, `pop`, `poof`, `coin` (original, credited in `assets/CREDITS.md`) |
| Smoke run | `tools/monster_smoke.gd` (+ `_steps`) | Headless end-to-end check in a new world (see below) |

**Stats (§12.4)**, level l = 1..5, universe u (×2^(u−1) on HP, hits and gold):

| | HP | Hit | Gold | Behaviour |
|---|---|---|---|---|
| Slime | 4, 7, 10, 13, 16 | 1, 2, 2, 3, 3 | 2, 4, 6, 8, 10 | jumper; level ≥ 3 splits into 2 level-1 slimes |
| Goblin | 6, 10, 14, 18, 22 | 2, 3, 4, 5, 6 | 3, 6, 9, 12, 15 | chaser; 0.8 s club wind-up |

**Level looks**: size ×0.8, 0.95, 1.1, 1.25, 1.4; colours are the Okabe-Ito set (green `009e73`, sky
blue `56b4e9`, yellow `f0e442`, orange `e69f00`, vermillion `d55e00`), told apart with every common
colour blindness; and l bone-white spikes (slime) or horns (goblin). Colour is never the only cue.

**Night spawns (host, once a second)**: only at night (`DayCycle.is_night`), on the generated surface
(first 2-high gap from the surface up, on solid ground that is not leaves, never in water), 18–40
blocks (horizontal) from a player and never closer than 18 to any player, never within 8 blocks of a
LANTERN or LIGHT block or of any player's home bed, caps 20 in all and 10 per player (monsters within
48 blocks count as that player's), at most 3 a tick and 8 spots looked at a tick. Level
1 + ⌊distance from the world spawn / 150⌋ (max 5), ±1 at random. 60% slimes. Sandbox: at most 8,
levels 1–2, and only while MONSTERS is ON.

**Cost rules (the animals' lessons)**: rest beyond 32 blocks from every player; decisions at 10 Hz,
staggered; looks (grid rays) every 0.3 s; one player lookup per physics frame shared by all monsters
and coins; no physics move while standing on the ground; a goblin level with its target stops 1.1
blocks short and stands; moving monsters keep 0.9 apart (a static list, no group queries);
`_process` returns at once when there is nothing to show; shared meshes and BlockyAnimal's material
(no new shader anywhere: bodies, arms, coins and health bars are vertex-coloured boxes).

## Tests (RED → GREEN)

Suite: **637 → 723** passing (`tests/run_tests.sh` exit 0).

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_monster_rules.gd` | 28 | `MonsterRules` not declared |
| `tests/unit/test_chat_commands.gd` (+1) | summon monsters | `ChatCommands.MONSTERS` missing |
| `tests/unit/test_world_meta.gd` (+1) | monsters setting | `monsters_on` missing |
| `tests/integration/test_monster.gd` | 21 | `Monster` not declared; later: sounds not registered, then the cost changes (see below) |
| `tests/integration/test_monster_director.gd` | 23 | written right after the first director draft; checked by breaking rules on purpose (below) |
| `tests/integration/test_monster_combat.gd` | 8 | hittables had no monsters (7 of 8 failed), then the weapon tap found no monster |
| `tests/integration/test_monster_chat_and_menu.gd` | 4 | no `summon_monster` hook, no `show_monsters_setting` |

Mutation checks on the director (each broken rule made the suite fail): lights ignored, coins in
Sandbox, no sunrise puff, splits for every slime, no summon cap, no far despawn, 30 spawns per tick
(this one first slipped through: the test compared against the constant it checked; it now asserts
the spec's 3).

Test bug found on the way: a GDScript lambda captures locals **by value** (`got = peer` inside a
signal lambda never reaches the test); collect into an Array instead.

## Smoke run (headless, real terrain) and cost

`XDG_DATA_HOME=<private dir with "smoke"> godot --headless --path . --script res://tools/monster_smoke.gd`
(`-- --smoke-sandbox` for Sandbox). Both modes pass (`MONSTER_SMOKE result fails=0`): night monsters
appear 22–36 blocks away on grass, levels 1–2 near the world spawn; a summoned level 2 goblin sees the
player, winds up and hurts them (17 HP); a defeat gives 5 coins for 6 gold and the coins fly to a
player standing on them and pay (Survivor) or confetti only (Sandbox); MONSTERS: OFF sends every
monster away and the world remembers OFF; at sunrise the wild ones puff away.

Cost, 20 active monsters (all levels) around one player, measured with a temporary per-call timer
in `Monster._physics_process` (not committed), desktop under heavy load (load average ~40 on 24 cores):

| | µs per monster per physics step | 20 monsters, ms per step | move_and_slide | decision |
|---|---|---|---|---|
| First version | 170 | 3.4 | 96 µs, 75% of steps | 248 µs |
| After `b43720a` | **47** | **0.94** | 38 µs, 72% of steps | 47 µs (a look: 34 µs, every 3rd) |

Whole-frame times from the smoke run are not usable on this shared PC (the quiet window without
monsters measured 1.7–31 ms between runs). The smoke run also caught a bug in the first draft of the
cost change: a goblin summoned on a 2-block ledge stopped short above the player and never reached
them; it now keeps going when it is not level with its target (tested:
`test_a_goblin_on_a_ledge_above_the_player_comes_down`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Small slimes are level 1 and never split again**, and splits ignore the spawn caps (the big one
   leaves, so +1). *Cost if wrong:* less chain-splitting fun at level 5.
2. **"In the dark" = night, and no LANTERN or LIGHT block within 8 blocks** (a 17³ box scanned in one
   bulk copy). *Cost if wrong:* fewer spawns near glowing builds; one list to change
   (`MonsterRules.LIGHT_BLOCKS`).
3. **"A bed with someone home" = any player's home bed** (the bed they last slept in), not only a bed
   someone is sleeping in. *Cost if wrong:* slightly fewer spawns near homes.
4. **Summoned monsters are not wild**: the sun does not puff them away and they are never saved; they
   leave when defeated or 64 blocks from every player. `/summon` works with MONSTERS: OFF (an explicit
   request). *Cost if wrong:* a summoned goblin can outlive the night.
5. **MONSTERS: OFF puffs every monster away at once** (summoned ones too); ON brings night monsters
   back at the next tick. *Cost if wrong:* none known.
6. **Coins**: at most 5 per defeat, near-equal values that add up; they pop out for 0.35 s before they
   can fly, lie there 60 s, then vanish (their gold with them); at most 40 lie around (the oldest
   goes). *Cost if wrong:* a child who walks away loses a few coins.
7. **Monsters use the animals' physics layer** (value 8) with mask 1: players, animals and other
   monsters pass through them (cheap), and weapon taps already look at that layer. *Cost if wrong:*
   a separate layer later means one constant and `BlockInteractor.HITTABLE_LAYERS`.
8. **Sight until Task 5**: 16 blocks, a 120° view, a clear grid ray; any player within 3 blocks is
   noticed; a look every 0.3 s (a new monster looks at its first decision); it chases a lost player
   for 5 s and gives up beyond 28 blocks. `Monster.perceive()` is the one seam Task 5 replaces.
9. **Goblin**: starts its wind-up within 1.6 blocks; the club lands if the player is still within 2.4
   blocks (and 2 up or down); 1.4 s between swings; it pushes the player back a little. **A hit
   during the wind-up stops the swing** (brave play is rewarded). Chases at 3.4 + 0.2 per level m/s,
   always slower than a walking player (6 m/s). *Cost if wrong:* goblins are too easy; tune the numbers.
10. **Slime**: hops about a block high every 0.7 s when chasing (1.4 s wandering), hurts on touch (half
    its width + 0.7 blocks), then waits 1.2 s and bounces back.
11. **Health bar** from vertex-coloured boxes turned to the camera in code while shown (no billboard
    or unshaded material: either would compile a new shader on the first hurt monster).
12. **Hit sphere is generous**: radius max(width, 0.8 × height) / 2 + 0.1 (0.35–0.9), so an arrow at a
    tall goblin's head hits (children aim loosely).
13. **The director lives on every peer** (node `Monsters`, holding the spawners and the confetti RPC,
    like CombatDirector); only the host ticks. The plan said "host only, like AnimalDirector".
    *Cost if wrong:* none; the host logic is the same and tested with stubs.
14. **Sounds play on the host** (like animals), except the club swing (every peer, from the synced
    wind-up) and the defeat, puff and coin sounds (every peer).
15. **Night spawn mix 60% slimes, 40% goblins**; monsters that appear 32–40 blocks away rest until a
    player comes within 32 (the animals' activity distance).
16. **Lead rulings** (child-psychology notes): *monsters never change blocks* (they only read the world
    through `block_at`; tested by a full scenario against a world that counts every edit, and by a
    source scan of every monster file); *hit feel*: a 50 ms hit-stop, a squash on every screen,
    confetti from the shared Fx material on a defeat.

## What to check on the emulator (the lead)

- **Quick look** (Sandbox): `/time night`, then wait a few seconds: slimes and goblins appear 18–40
  blocks away. `/summon goblin 3`: a yellow-tunic goblin with 3 horns appears 4 blocks away, raises
  its club (0.8 s) and swings; step back during the wind-up to dodge; hit it with the sword (health
  bar, squash, push); it bursts into confetti. `/summon slime 3`, then defeat it: two small green slimes.
- **Survivor** (no cheats there: wait for night, about 8 minutes of play from a new world's morning, or
  run the headless smoke run): coins pop out and fly to you within 2 blocks; each one reaches
  Survivor gold.
- **Pause menu** (Sandbox, host): MONSTERS: ON / OFF under SETTINGS; OFF makes them puff away.
- **Performance bar**: the autopilot at night with monsters around, in both styles (≥ 30 FPS, no
  frame over 100 ms). No new shader compiles with the first monster, coin or health bar (all share
  BlockyAnimal's material), so look for a first-contact spike anyway.
- **Readability at night**: level colours and spikes in moonlight, the health bar, coins.

## Hand-offs to other tasks

- Task 2 (knock-out): monsters keep attacking a player at 0 HP (`Health.damage` ignores it) until the
  respawn exists.
- Task 5 (stealth): replace `Monster.perceive()` (and `MonsterRules.can_see`'s `sight` argument). A hit
  makes a monster chase the player nearest to where the hit came from (within 4 blocks): melee
  attackers, yes; an archer far away, no (an arrow's hit starts next to the monster). Noise (§12.5)
  could tell it where the archer stands.
- Task 8 (defenses): `MonsterDirector.lights_around(tool, pos)` finds lanterns near a spot with one bulk
  copy; spike traps can call `take_hit(2, trap_pos, Vector3.ZERO)`.
- Task 9 (waves): `MonsterDirector.spawn_monster({kind, level, id, pos, yaw, wild: false, universe})` and
  the signal `monster_defeated(kind, level, pos)`.
- Task 7 (gold counter): every coin is its own `Session.gold_changed`.
- Task 14 (water): monsters do not splash yet.
- Task 15 (bots): bots can hit monsters through the CombatDirector like players.

## Found, not from this task

- `tests/integration/test_hud_attack_button.gd` and `test_touch_pause.gd` leak about 50 objects at exit
  (Controls, Labels, `sleep_overlay.gd`), also when run alone; the full suite shows it as "ObjectDB
  instances were leaked at exit" (warnings only, exit 0).
- `tests/integration/test_main_menu_modes.gd.uid` and `test_survivor_session.gd.uid` (Task 1's) are not
  committed; left for the lead (uids differ per worktree).
