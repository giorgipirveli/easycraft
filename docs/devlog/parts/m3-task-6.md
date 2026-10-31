# M3 Task 6: Physics Lab (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `4f9cd4d`),
without the editor or the emulator. Spec §5.4 and §14.3 (refined here), plan Task 6. Commits `ea2e602`
(rules), `a6be563` (pads), `933f87e` (player, HUD, save). M2 Task 7 (a gold
cost for flying in Survivor) and M2 Task 16 (block ids 32–35) ran in parallel.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Lab rules | `core/rules/lab_rules.gd` (`LabRules`) | Modes NORMAL, MOON, ZERO_G, FLY, GHOST, SLOW; the LAB cycle, skipping what the game mode forbids (`allowed`, `next`: Survivor keeps Normal and Fly); each mode's `physics_mode` (Moon and Slow walk, Zero-G floats as FLY with collision) and back (`from_physics`); `gravity_factor` (Moon 0.35), `time_factor` (Slow 0.4), `jump_height`/`air_time`; zero-G `wish`, `zero_g_velocity` (damping, gentle thrust, cap), `wants_push_off`/`push_off_velocity`; labels and toasts. |
| Mode rule | `core/rules/mode_rules.gd` | `ModeRules.PHYSICS_LAB`, Sandbox only. |
| Pad rules | `core/rules/pad_rules.gd` (`PadRules`, one per body) | `pad_under` (centre, then the footprint's corners), `touch` (fires unless cooling down), `apply` (a jump pad's throw, a speed pad's burst), `tick`, `reset`; `launch_velocity`, `travel_dir`, `boost_floor`, `boosted`. |
| Pad blocks | `data/blocks/block_ids.gd`, `world/block_library.gd` | `JUMP_PAD` 36 and `SPEED_PAD` 37 (`COUNT` 38), placeable, solid, breakable, in the palette's last block row. Placeholder looks from the existing atlas (see ruling 9). `BlockIds.is_valid` now also needs a name, so an id no block owns yet (32–35 here) is refused by the host; the library fills such gaps with empty models. |
| Player | `entities/player/player.gd` (section at the end + hooks) | `lab_mode` (synced ON_CHANGE with spawn, like `physics_mode`), `lab_mode_changed`, `set_lab_mode`, `cycle_lab_mode` (Sandbox only), `_follow_physics_mode` (hook at the end of `set_physics_mode`), `_move_zero_g`, `_lab_move_and_slide` (pads, then `move_and_slide` in the body's own time), `_rpc_pad_fx`. Hooks: `_physics_process` runs on `body_delta` and dispatches Zero-G; `_move_normal` multiplies gravity by `gravity_factor`; `_update_remote` checks the synced `lab_mode` and animates in the body's time. |
| Animals | `entities/animal/animal.gd` (section at the end + 2 hook lines) | The host fires pads under animals (lookup on landing and with decisions) and sends the boing and puff to the other games (`_rpc_pad_fx`). |
| Effects | `entities/fx/pad_fx.gd` (`PadFx`) | Boing + green puff (jump), whoosh + yellow spray (speed), one burst each with the shared `Fx` material; `speed_scale` follows the body's time. |
| Sounds | `tools/make_pad_sfx.py` → `assets/audio/sfx/boing.wav`, `whoosh.wav`; `Audio` keys `&"boing"`, `&"whoosh"` | Original procedural sounds, credited in `assets/CREDITS.md`. |
| HUD | `ui/hud/hud.gd` (section at the end + 2 hook lines) | LAB button at (-226, 204) 90 × 90 from the top-right corner (under the camera button, left of SIZE), touch screens, Sandbox only; `lab_pressed()` cycles and toasts; lit (`selected`) on Moon, Zero-G and Slow, whose names show on the WALK button. |
| Sandbox | `scenes/sandbox.gd` | Saves `meta.lab_mode`; restores Moon, Zero-G and Slow on load; L key → `hud.lab_pressed()`. |
| Save | `world/world_meta.gd` | `lab_mode` (bad or missing → NORMAL; worlds saved before keep working). |
| Input map | `project.godot`, `tools/setup_input_map.gd` | `lab_mode` = L (added by hand to `project.godot`, same format as the tool writes). |

## Rulings (decisions made on the owner's behalf)

1. **LAB is a second button; the WALK/FLY/GHOST button stays.** Children switch to Fly all the time
   while building; with one six-mode button Fly would be three taps away. M2 Task 7 hooks paid Fly onto
   the WALK button in Survivor, and Survivor has no LAB. The WALK button shows the lab mode's name
   (MOON, ZERO-G, SLOW) and LAB lights up while one is on. *Cost if wrong:* one button to remove, or
   LAB merged into WALK.
2. **Lab modes sit on top of the physics switch.** `lab_mode` is new; `physics_mode` keeps its meaning:
   Moon and Slow motion walk (NORMAL), Zero-G floats (FLY, with collision). Everything that asks "is
   this player walking?" (beds, swimming, spawning, unstuck, falling out of the world) keeps working
   unchanged, and the WALK/FLY/GHOST button, `/walk`, `/fly`, `/ghost`, a bed or the autopilot set the
   plain lab mode. *Cost if wrong:* Zero-G counts as flying for beds (no sleeping while floating) and
   water (no swim pose).
3. **Slow motion reaches the player's own body and its own pad puffs, nothing else.** Slowed: movement,
   gravity, jumps, pad launches and bursts, swimming and climbing, knockback, the avatar's animation,
   the footstep rhythm and the swim effects' timing, and the puffs of pads it fires (in every game).
   Not slowed: other players, animals, monsters, projectiles, the day, sounds, the air-jump flip and
   weapon swing (tweens), the camera. The world's time is shared on LAN: slowing things near you would
   slow them for your friends too, and give an edge in fights. Other games see a slow-motion player
   walk and animate slowly (the synced `lab_mode`). *Cost if wrong:* if the owner wants nearby things
   slowed, the host needs a radius check in the animal and monster ticks.
4. **Moon gravity is the player's own:** gravity × 0.35 with the same jump speed, so a jump goes 2.9 ×
   as high (4.8 blocks) and hangs 2.9 × as long; a triple jump reaches about 12 blocks. Air control,
   swimming and animals are unchanged. *Cost if wrong:* retuning constants.
5. **Zero-G numbers:** drift damping 0.3 per second (a drift loses about a quarter of its speed each
   second), thrust 4 m/s² up to 3 m/s from the stick, JUMP (up) and DOWN, a kick of 7 m/s straight away
   from the surface you move into (walls, floor, ceiling; one kick per 0.3 s, the slide along it kept),
   top speed 18 m/s. The stick thrusts too, so a child is never stuck floating in mid-air (pure drift
   with damping would strand them). Drifting into a wall without pushing slides along it (no bounce).
   Size Magic scales thrust and kicks like walking speed. *Cost if wrong:* retuning constants.
6. **Pads have no facing**: voxel blocks carry no rotation. A speed pad sends a body the way it was
   going, or the way it faces when standing still (players: the camera's forward; animals: their
   forward). *Cost if wrong:* four directional speed pads (four ids, fits Task 1's 128–135) or block
   metadata.
7. **Pad numbers:** launch 16 m/s up (about 5.3 blocks in normal gravity, 15 on the Moon, the same in
   slow motion, only slower), burst 14 m/s (walking is 6) held for 1 s and easing back over 0.5 s,
   and a body's pads rest for 0.5 s after any pad fires under it. Launches and bursts set a speed, never add one, so a
   chain of pads can't grow, and two pads can't bounce a body back and forth faster than the cooldown.
   The same for every body and size (a pad is a spring). *Cost if wrong:* retuning constants.
8. **Pads fire when the feet touch them**: on the floor in Normal, Moon, Slow, Zero-G and Fly; a Ghost
   touches nothing. Players check the footprint's corners (a foot on the edge counts, up to 5 block
   lookups per grounded frame); animals check only the centre, when they land and with their
   decisions (walking animals hop, so a lookup per decision alone missed pads; found by
   `test_animal_pads`). *Cost if wrong:* an animal passing over a pad's very edge doesn't bounce.
9. **Placeholder looks until M3 Task 1's pages**: both pads glow (the LIGHT/CRYSTAL material) with a
   different top and side from the existing atlas: Jump Pad green top on purple sides, Speed Pad
   yellow top on blue sides, stone underneath. The palette shows the side tile, so their icons look
   like the purple and blue toy blocks until then. *Cost if wrong:* children may mix them up with toy
   blocks in the palette until Task 1 draws a spring top and an arrow top (and moves them to 128–135).
10. **Ids 32–35 belong to M2 Task 16**: here they are empty models, and `BlockIds.is_valid` refuses an id
    without a name, so a LAN client can't place a gap id. After the merge they are Task 16's blocks (no
    change in behaviour). `test_m2_blocks_are_allocated` now checks `COUNT >= 32` and the M2 range only.
11. **Pads work in both modes, but Survivor can't get them yet**: the palette is Sandbox's; M2 Task 7's
    trader can sell them (a suggestion: a few gold each, like other building blocks). They are ordinary
    blocks for the host's edit checks (`PlacementRules`), undo, capture and saving.
12. **Survivor safety:** `Player.cycle_lab_mode` does nothing outside the Sandbox, `set_lab_mode` ignores
    modes the game mode forbids and falls back when the physics switch refuses (Fly without gold), the
    sandbox restores only Moon, Zero-G and Slow from a save (plain Fly still goes through
    `physics_mode`, where Task 7's payment hooks in), and the HUD shows no LAB in Survivor.
13. **Effects in every game:** a pad firing plays its boing and puff where it fired, and the body's
    owner (a player's own game, the host for animals) sends it to the other games with an unreliable
    RPC on the body (`_rpc_pad_fx`). A lost packet loses one puff; nonsense ids do nothing.
14. **Not included:** living buddies are not launched by pads (they move by their own rules; later if
    wanted). **Monsters** (M2): call `PadRules` in their host tick exactly like `Animal._touch_pads`
    (one `PadRules` per monster, `tick` each simulated step, `touch` + `apply` before `move_and_slide`,
    `_rpc_pad_fx` for the others).

## Tests (RED → GREEN)

Written first. RED run: `test_lab_rules.gd`, `test_pad_rules.gd` and the new cases in
`test_world_meta.gd`, `test_block_ids.gd`, `test_mode_rules.gd` failed to parse on the missing
`LabRules`, `PadRules` and `ModeRules.PHYSICS_LAB`. GREEN: the unit tests passed first time. The
integration tests then showed one real bug, animals never bounced: they looked for pads only with
their decisions, and walking animals are in the air (hopping) on most of them (ruling 8).

- `tests/unit/test_lab_rules.gd` (23): the LAB cycle in Sandbox; Survivor keeps Normal and Fly (and
  leaving a forbidden mode lands on an allowed one); bad values; labels and toasts; physics modes both
  ways; gravity factors; Moon jumps 2.9 × higher and longer; slow motion 0.4 time, same jump height,
  2.5 × air time; no gravity, no coming down; zero-G: still stays still, drift fades slightly, gentle
  thrust capped at THRUST_SPEED, JUMP/DOWN thrust, thrust never brakes a push-off, speed cap, push off
  a wall (and not when moving away or along it), DOWN on the floor kicks up, size scaling, the wish.
- `tests/unit/test_pad_rules.gd` (15): ids; the pad under the feet, a foot on the edge; a strong
  launch that keeps the run; launches never add up; cooldown; two pads touched every frame for 3 s
  fire at most every COOLDOWN; only pads fire; the burst along the way of travel, full for 1 s, easing,
  over after 1.5 s; the facing when standing; level; sideways steering kept; bursts never add up; never
  slows a faster body; reset.
- `tests/unit/test_world_meta.gd` (+2): the lab mode round trip; broken or missing values are Normal.
- `tests/unit/test_block_ids.gd` (+2, 2 changed), `test_block_library.gd` (+1, 1 changed),
  `test_mode_rules.gd` (+1).
- `tests/integration/test_player_lab.gd` (19), a real Player with real physics: a lab mode sets the
  physics switch and the switch sets it back; the LAB cycle; Survivor refuses; `lab_mode` synced with
  spawn, on change; Moon jumps ≈ 2.9 × a normal jump; slow motion walks 0.4 as far at its own walking
  speed; a slow jump is as high and the avatar's walk cycle runs at 0.4; zero-G floats still, JUMP
  thrusts up gently and the drift goes on, a kick off a wall it moves into, DOWN on the floor kicks up;
  a jump pad launches over 4 blocks with a puff, a Moon pad over 10; a speed pad bursts to 14 m/s the
  way it walked and is over after 1.5 s; a Ghost floats through pads; a remote slow-motion player
  animates at 0.4; a tampered remote lab mode is Normal; other games see and hear a pad fire (and
  ignore nonsense); a slow-motion puff is slow.
- `tests/integration/test_hud_lab_button.gd` (3): placement clear of every control, the username and the
  gold line, under the palette; only in Sandbox on touch screens (a tap on it never builds);
  tapping cycles, toasts, lights LAB and names the mode on the WALK button (and shows UP/DOWN in zero-G).
- `tests/integration/test_animal_pads.gd` (3): a jump pad throws an animal up with a puff; a speed pad
  sends it running; an animal away from pads only hops.

Full suite after the change: **106 scripts, 930 tests, 930 passing, `tests/run_tests.sh` exit 0** (279 s;
load average about 24–39 on the PC at the time).

## What the lead should check on the emulator (not verifiable headless)

1. The LAB button sits under the camera button, left of SIZE, clear of the gold counter's real size;
   it is missing in Survivor and on a LAN client of a Survivor host.
2. Tapping LAB: a toast each time; the WALK button reads MOON, ZERO-G, FLY, GHOST, SLOW, WALK; LAB is
   lit on Moon, Zero-G and Slow. The WALK button still toggles Walk/Fly/Ghost and resets the lab.
3. Moon: floaty high jumps and triple jumps, the camera keeps up; no frame over 100 ms.
4. Zero-G: floating still, the stick drifts gently, UP/DOWN thrust, moving into a wall kicks off
   (a soft step sound), DOWN on the floor kicks up; a child can always get somewhere.
5. Slow motion: the body, its animation and its steps are slow; animals, monsters, the sky and other
   players are not; the camera follows smoothly.
6. Pads: Jump Pad and Speed Pad are in the palette's last block row, glow and look two-tone in both
   graphics styles; placing, breaking and undo work; boing + green puff and a big launch; whoosh +
   yellow spray and a 1.5 s burst; animals bounce and run too; nothing loops faster than every half
   second under a low ceiling.
7. LAN (two instances): the other game sees a slow-motion player walk slowly, sees and hears its pads;
   a player who joins later sees the mode (spawn sync).
8. Save and reload in Moon, Zero-G and Slow: the mode comes back.
9. Performance: the play phase and flight hold the budget (pads add at most 5 block lookups per grounded
   player frame and 1 per animal landing or decision).

## For other tasks and the merge

- **Block ids:** `COUNT` is 38 here; M2 Task 16 takes 32–35 in parallel. Merging both: keep Task 16's
  names, tiles and `PLACEABLE` entries for 32–35 and these for 36–37; `COUNT` stays 38 (or more).
  `test_placeable_blocks` expects 25 placeable blocks here (23 + the two pads): add whatever the other
  tasks make placeable. With the pads the palette has 4 block rows (`test_palette_fits_a_1280x720_screen_above_the_hotbar`
  passes); more placeable blocks will need a scrolling or paged palette.
- **M3 Task 1 (pages):** move the pads to 128–135 with a spring-top and an arrow-top tile, and keep a
  save migration (36 → the new jump pad id, 37 → the new speed pad id) for worlds built before.
- **M3 Task 7 (smart blocks)** lists a "jump pad" and a BOUNCE game block, and **Task 14** "launch and
  bounce pads": reuse `BlockIds.JUMP_PAD`/`PadRules` (a BOUNCE block can be a `PadRules` launch with its
  own number) instead of a second pad system.
- **M2 Task 7 (paid Fly):** nothing to do for the lab; Survivor never reaches `LabRules`' lab-only modes.
  If Fly is refused for lack of gold inside `set_physics_mode`, `set_lab_mode` already falls back.
  Pads can join the trader's stock.
- **The plan's HUD allocation** says "LAB button (right column, Sandbox, Task 5)": it is Task 6's, and it
  sits beside the column (left of SIZE, under the camera button) because the column itself is full down
  to the JUMP button.
