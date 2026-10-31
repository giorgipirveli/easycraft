# M2 Task 10: the Stone Golem and the portal

Spec §12.9 (boss), plan Task 10, research G3 "honest help" and D8 "portal peek"
(`docs/design/engagement-and-child-psychology.md`). Built in an isolated worktree on a branch cut from
`m2-survive-the-night` at `c86fd0f`, in parallel with Tasks 5, 8, 9 and 18. No editor, emulator or
godot-mcp use; engine glue checked with a new headless smoke run on real terrain and a two-instance
LAN run. Commits: `63f2192`, `724171c`, `077a758`, `99b55d6` and the last one (the boss music fix).

## What was built

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/boss_rules.gd` | Health by team size (tired: −25 %), the fixed attack order and wind-ups, the phase schedule, who the slam / rock / charge hit, "on the ground", dazed double damage, the rock's arc, the 300 gold split, honest help (percent reached, tired after 3 losses, reset after a win, cleaned when loaded), the loss rule, the universe unlock, where the Golem and the portal stand (`stand_y`) |
| The Golem | `entities/monsters/stone_golem.gd` | CharacterBody3D, group `monsters`, `take_hit` / `hit_center` / `hit_radius` like Task 4's monsters; the host simulates it (10 Hz decisions); every peer animates its synced phase (fists up, the rock over its head, pawing, leaning into the charge, dizzy stars) |
| Models | `entities/monsters/golem_models.gd` | Box meshes built once: body, arm (both arms), glowing eyes and chest rune, the rock, the stars, the portal frame; one shared unshaded glow material |
| The rock | `entities/monsters/golem_rock.gd` | What every peer sees fly (the same arc from the same numbers); the host's Golem decides the hit at the same moment |
| Director | `world/boss_director.gd` | Node `Boss` on every peer: Golem and portal spawners, the HUD bar, win/loss RPCs. Host: `start(totem_pos)`, one Golem at a time, the loss check, gold, the portal, the unlock, honest help, `link_waves` (Task 9), `save_into` / `restore` |
| Portal | `entities/portal/desert_portal.gd`, `shaders/desert_window.gdshader` | A stone frame around a moving window into the desert (one quad, one shared scrolling shader, nothing written per frame), sand blowing out and a wind loop while this device's player is within 24 blocks, the words over it and once as a toast when a child walks up |
| HUD | `ui/hud/boss_bar.gd`, `ui/hud/hud.gd` (section at the end) | Top-centre above the toasts: a golem face, the name ("STONE GOLEM" / "TIRED GOLEM"), a big bar with quarter notches, a steady "x2" chip while dazed; after a fight "You got it to 20%!" / "You beat the Stone Golem!" for 6 s |
| Session | `autoloads/session.gd` (section `# --- M2 Task 10: the boss`) | `boss_unlock(universe)` (host → every game raises its own profile, never lowers; guests save at once), `boss_apply_unlock`, signal `boss_universe_unlocked`; the Golem's avatar item through `AvatarUnlocks.earn` when M3 Task 9's code exists |
| World save | `world/world_meta.gd` | `boss_help` ({losses, best, wins}) and `portal_pos` (INF = none), in `"boss"` |
| Sandbox | `scenes/sandbox.gd` (one line each in `_ready`, `_start_host_or_solo`, `_setup_local_player`, `save_world`; section at the end) | `start_boss(totem_pos)` (Task 9's hook), `summon_boss(near)` (`/summon golem`), the bar, the shader prewarm at spawn, a save when a fight ends, `_link_totem` |
| Chat | `core/rules/chat_commands.gd`, `scenes/chat_command_runner.gd` | `/summon golem` (Sandbox only, like every `/summon`) → the sandbox's `summon_boss` hook |
| Sounds | `tools/make_boss_sounds.py`, `autoloads/audio.gd` | `golem_roar`, `golem_slam`, `golem_throw`, `golem_stomp`, `rock_crash`, `golem_crumble`, `portal_wind` (a seamless 4 s loop, imported with loop_mode forward); original work, credited |
| Smoke run | `tools/boss_smoke.gd` (+ `_steps`) | Headless end to end in a new world (Survivor, or `-- --smoke-sandbox`; `-- --smoke-seed=<n>` repeats a world) |
| LAN run | `tools/lan_test.gd` (`--boss` section) | Host starts and beats the Golem; both log what they see |

### The fight (numbers in `BossRules`)

- **Health:** 300 × (1 + 0.5 × (team − 1)), team = players + bot friends (`BotFriend.team_size`, knocked-out
  friends too), counted when the fight starts: 300 / 450 / 600 / 750 for 1–4. Tired (after 3 lost fights):
  × 0.75, rounded (225 for one player).
- **It rises** out of the ground for 2 s (no hits yet), 7 blocks from the Totem, facing it, on the ground
  nearest the Totem's height (`stand_y`: room for its 3-block body, never in water).
- **Then, in a fixed order, with a 2 s walk between attacks** (it walks at 2.2 m/s to 3 blocks from the
  nearest player or bot friend within 40 blocks of where it rose; slower than a walking child):
  1. **Slam:** both fists up for 1.2 s → a shockwave ring (dust, a boom, `Feel.slam` by distance on every
     screen): 4 HP to everyone standing on the ground within 7 blocks and 2 up or down; nobody in the
     air (jumping, flying, swimming). Then **dazed** for 2 s (stars): every hit counts double.
  2. **Rock:** a glowing rock held over its head for 1 s → thrown in an arc (0.5–1.6 s) at where its
     target stood: 3 HP to whoever is within 1.4 blocks when it lands, in the air too. Step away and it misses.
  3. **Charge:** it turns to its target and paws the ground for 1 s → runs straight 12 blocks at 10 m/s:
     5 HP (and a push aside) to everyone within 1.6 blocks of its path, once per charge. A wall, water or a
     cliff stops it (it never breaks a block).
- Players are hurt through `Session.hurt_player(peer, n, golem position)` (shields block from the front,
  knock-outs as usual), bot friends through their `hurt(n, from)`.
- **A win:** a crumble of stone, gold and confetti on every screen, `golem_crumble` + `coin`, the bar says
  "You beat the Stone Golem!", `Session.celebrate_all()` when the game has it (M3 Task 9), 300 gold split
  among the players (Survivor; `Session.gold_add`), the portal by the Totem, universe 2 in every
  player's profile (Survivor), the help resets, the world is saved.
- **A loss:** in Survivor when every player is knocked out at the same time; in both modes when no
  player who is up has been within 40 blocks for 10 s. It sinks back into the ground; the bar says "You
  got it to X%!". A Sandbox knock-out does not end the fight (players pop right back up).

## Hooks for Task 9 (the Totem) and the lead (agreed with the lead's message, 2026-09-24)

- **Task 9 → boss:** `WaveDirector.boss_requested(peer_id, totem_pos)` (a child taps the Totem's Stone
  Golem button; reach checked) is connected by `BossDirector.link_waves(waves)`, which the sandbox calls
  (deferred) with `sandbox.waves()` when that method exists: it calls `start(totem_pos)`; a refusal
  ("The Stone Golem is already here!") goes to that child (`Session.send_feedback`).
- **Boss → Task 9:** `waves.set_boss_running(true)` when a fight starts and `(false)` when it ends (won
  or lost), through the director's host signals **`fight_started(tired: bool)`** and
  **`fight_ended(won: bool, percent: int)`** (percent of health left; 0 = won). Task 9's `boss_offered`
  is not needed by the boss (the Totem shows the button); connect it to anything that should tell the child.
- **Other entry points:** the sandbox's **`start_boss(totem_pos: Vector3) -> String`** (host; "" = it
  comes) and **`summon_boss(near)`** (`/summon golem`, Sandbox tests and fun: it rises 7 blocks from the
  player). Both call `BossDirector.start`.
- **HUD:** the boss bar sits in the wave line's spot (top-centre above the toasts); the lead says the
  two never show together.
- **M3 Task 9 (avatar editor, merged separately):** `celebrate_all` is called through
  `Session.has_method(&"celebrate_all")`; the Golem's avatar item through
  `Session._boss_earn_avatar_item()`, which loads `res://core/avatar/avatar_unlocks.gd` when it exists and
  calls `earn(Profile.data, &"golem")` (`AvatarCatalog.EARN_GOLEM`). If the lead prefers the class names,
  replace that one function body with `AvatarUnlocks.earn(Profile.data, AvatarCatalog.EARN_GOLEM)` after the merge.

## Skills and patterns (godot-prompter)

- **state-machine:** an **enum state machine** (`BossRules.Phase`, an int synced to every peer) whose
  timings and next phase come from pure rules (`phase_time`, `next_phase`), so the schedule is unit-tested
  without a scene. Rejected: a node-based state machine (a node per state costs nodes, spawner and sync
  complexity for a linear schedule; the monsters use enums too) and a behaviour-tree addon (not in the project).
- **multiplayer-sync:** **state sync from the host** (`MultiplayerSynchronizer`: position and rotation
  always, hp and phase on change) plus **reliable RPCs for one-off events** (slam, rock, start, win, loss).
  Every peer derives the looks from the synced phase and a local clock. Rejected: input sync / client
  prediction and interpolation buffers (guests only watch the boss; the monsters don't interpolate either).
- **hud-system:** a **custom-drawn Control** (`_draw`, redrawn only when the health changes), fed by the
  director. Rejected: `ProgressBar`/`TextureProgressBar` with themes (more nodes and styleboxes; the HUD's
  hearts and chips are custom-drawn too) and a number (the task: "a bar, not a number").
- **shader-basics:** **one spatial shader, unshaded, procedural, animated by TIME** on one quad with one
  shared `ShaderMaterial`. Rejected: a StandardMaterial3D with a scrolling `uv1_offset` (a texture asset and
  a per-frame CPU write) and a stencil "real view" portal (needs a second world: far too costly for a phone).

## Tests (RED → GREEN)

Suite: **1321 → 1391 passing** (146 scripts), `tests/run_tests.sh` exit 0.

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_boss_rules.gd` | 28 | "Identifier BossRules not declared" |
| `tests/unit/test_world_meta_boss.gd` | 3 | "Invalid access to property or key 'boss_help'" |
| `tests/integration/test_boss_chat.gd` | 3 | `/summon golem` parsed as an unknown animal; no hook called |
| `tests/integration/test_stone_golem.gd` | 15 | written before `StoneGolem`; all passed at the first run, so checked by mutations (below). Later RED: a lost fight's Golem, still sinking, switched the boss music off for the next fight when it left (`test_the_boss_music_stays_until_the_last_golem_is_gone`; now a count of Golems in the tree) |
| `tests/integration/test_boss_director.gd` | 18 | written before `BossDirector`; all passed at the first run, so checked by mutations (below) |
| `tests/integration/test_boss_hud.gd` | 3 | "Invalid access to property or key 'boss_bar'"; later the LAN bug below ("STONE GOLEM" instead of the win) |

Covered: HP by team size 1–4 and with bot friends, tired −25 %; the order slam → rock → charge and each
wind-up (1.2 / 1.0 / 1.0 s) measured on the entity; the slam hits only grounded targets within 7 (not
flying, not at the top of a jump, not 8 away, not up a tower), bot friends too; dazed double damage for 2 s
and normal after; the rock hits who stays and misses who steps away; the charge paws in place then runs
about 12 blocks straight and hurts once; no hits while it rises, defeated once; weapons (a sword swing
through `CombatDirector`) and `hittables`; shared meshes and materials, small footprint; the boss music on
and off; the gold split (300 / 150 / 100 / 75, never loses or makes gold, rounding for 7), none in Sandbox;
the portal by the Totem, one per world, its words, shared shader and frame, sand and wind near it, the
toast when a child walks up; universe 2 once, never lowered, not in Sandbox; honest help (20 % shown,
tired after 3 losses and announced, reset after a win, cleaned when loaded, saved and restored); the
Sandbox loss rules; the bar (placement, a bar not a number, results, "x2"); Task 9's link (the button
starts the fight, "already here" to the child, the running switch on win and loss) and the celebration;
**never changes blocks** (a world that counts every edit through 30 s of fighting, and a source scan of
every boss file).

**Mutation checks** (each broken rule made the suite fail, then was put back): the slam ignoring "on the
ground"; no double damage when dazed; never tired; paying in Sandbox; knock-outs ending Sandbox fights; a
second portal per win; no celebration; no Totem link / running switch / refusal message.

## Headless smoke run and LAN run

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script res://tools/boss_smoke.gd [-- --smoke-sandbox] [-- --smoke-seed=<n>]`

- Survivor and Sandbox pass (`BOSS_SMOKE result fails=0`): the Golem rises on the ground by the stand-in
  Totem with the bar and the boss music; its slam lands at 3.2 s (2 s rise + 1.2 s wind-up) and hurts
  the player next to it (16 HP); dazed, a 10-damage hit takes 20; a win shows the message, opens the
  portal on the ground, pays 300 and unlocks universe 2 (Survivor) or nothing (Sandbox), and is saved;
  sand and wind near the portal; a second fight lost (knocked out / walked away) shows "You got it to 50%!"
  and is saved as help.
- One Survivor world (seed 2323666414) first failed twice, both **smoke-run placement** problems: it put
  the player on a tree top 3 blocks above the Golem (the slam correctly missed: "on the ground" means
  within 2 up or down), and next to the portal on a spot where they fell away and respawned. The run
  now stands the player on the same ground (`_ground_beside`) and prints where they stood on a failure.
- **LAN** (`--auto-host --lan-test --boss --survivor --new-world` + `--auto-join=127.0.0.1 --lan-test --boss`):
  the guest sees the Golem (450 HP: a team of 2), its phases, the bar and the boss music, then the portal;
  its gold went 25 → 175 and its profile to universe 2. The first run found a bug: the guest's bar kept
  "STONE GOLEM" at full health after the win (the host frees the Golem in the same frame as the last hit,
  so the guest's copy outlived the win message by a frame and its last health update restarted the bar).
  Fixed test-first (`test_a_result_stays_until_the_next_fight_starts`); the rerun shows "You beat the Stone
  Golem!" on the guest.

### Cost (desktop, this shared PC; a hint, not the emulator's numbers)

- A bench of the Golem's own physics step on a flat floor (a temporary tool, not committed; load ~25):
  walking 110 µs (of which `move_and_slide` ~65 µs), charging 142 µs, standing phases 38–65 µs, a decision
  ~40 µs. For comparison a Task 4 monster was 47 µs a step. The first version read the ground ahead
  (`MonsterRules.can_step`, several voxel reads) every walking step; it now plans at 10 Hz.
- In the real sandbox under load 45–77: the Golem's `_process` 60–120 µs a frame, the director's
  per-frame tick 40–80 µs after caching the fighting Golem (was 110–230 µs searching its list every frame);
  pose writes happen only when a value changes (the monsters' lesson). Whole-frame numbers from the smoke
  run swing with the load (quiet windows measured higher than fight windows in some runs) and are not
  usable. **To measure on the emulator.**
- No per-event materials or meshes: bodies, rock, stars and frame are shared meshes on BlockyAnimal's
  material or the one glow material; bursts use `Fx`; the portal's sand is one emitter using `Fx`'s
  material and runs only near a player; the window's shader and the glow material (and a Label3D like the
  portal's words) are drawn once in front of the camera when the world appears (`DesertPortal.prewarm`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **A fixed attack order, slam → rock → charge, with a 2 s walk between** (the task's "schedule"; a
   rhythm children can learn, no randomness). *Cost:* older children find it predictable; a distance-based
   choice is a few lines in `BossRules.attack_at`.
2. **"On the ground" for the slam** = standing on a block (feet within 0.3 above it), not moving up or
   down faster than 1.5 m/s, not flying; the ring reaches 7 blocks sideways and **2 up or down**, so a
   child on a tower or a tree is safe and a swimmer is "not on the ground". *Cost:* a child 3 blocks up a
   slope is not hit.
3. **The rock** flies at where its target stood when it was thrown and hits within 1.4 blocks when it
   lands, in the air too (1 s to see it coming plus 0.5–1.6 s of flight). *Cost:* tuning only.
4. **The charge** locks its direction when the run starts (it turns to its target while pawing), hits
   each target once, pushes them aside, and stops at walls, water and cliffs. *Cost:* none known.
5. **It can't be hurt while it rises (2 s); dazed (double damage) only after a slam.** *Cost:* none.
6. **Health is counted when the fight starts** (players and bot friends in the world then, knocked out
   too). *Cost:* a LAN friend who joins mid-fight doesn't make it stronger.
7. **The 300 gold go to every player in the world at the win** (knocked out too), paid straight into their
   gold (`gold_add`), the first players in peer order getting the odd coins; the "big burst" is gold and
   confetti bits, not coins to collect. *Cost:* a player far away also gets a share; no coin pickups.
8. **Sandbox:** `/summon golem` brings it 7 blocks from the player; nothing is paid or unlocked, the portal
   still opens (the peek is part of the fun); a knock-out doesn't end the fight. *Cost:* none known.
9. **A lost fight:** Survivor when every player is knocked out at the same time; any mode when no player
   who is up has been within 40 blocks for 10 s. The Golem never heals during a fight; each new fight
   starts at full health. *Cost:* a LAN team that is never all down at once can't lose (it has to win).
10. **Honest help:** the percent left is **rounded up to fives** ("You got it to 25%!" at 20.3 %: never more
    progress than made); the best try is saved too; tired after 3 losses since the last win, announced by
    a toast ("The Golem is tired today: it has less health!") and "TIRED GOLEM" on the bar; a tired Golem
    still pays 300. *Cost:* none known.
11. **The portal** is not made of blocks (a shared frame mesh), so it never changes the world; one per
    world, 3 blocks from the Totem, facing it; saved in `WorldMeta.portal_pos`. *Cost:* players walk through
    the frame.
12. **Universe 2 and the avatar item only in Survivor**, raised in every LAN player's own profile (the host
    decides; a guest saves at once, the host saves with its world right after the fight). *Cost:* a Sandbox
    win earns no hat.
13. **Players walk through the Golem** (the monsters' physics layer 8 with mask 1). *Cost:* a child can stand
    inside it; a solid body would need a layer the player collides with (and would push children around).
14. **Glow = one unshaded vertex-colour material** (eyes, rune, rock, stars) and the window one new shader;
    both compiled at world load. *Cost:* two small shader compiles during loading.
15. **The boss music plays from the moment the Golem appears until it is gone**, on every peer (its
    `_ready` / `_exit_tree`). *Cost:* none known.
16. **The boss bar** is 270 × 76 at the top centre (y 8–84), between the hearts (end x 501) and the
    username, sharing the wave line's spot. *Cost:* on a 1280-wide screen there is no room for a wider bar.

## What to check on the emulator (the lead)

1. **Sandbox:** `/summon golem` → it climbs out of the ground 7 blocks away with a roar and the boss
   music; the bar (golem face, STONE GOLEM, full) top-centre, clear of the hearts and the username.
2. Stand next to it: fists up (1.2 s) → shockwave ring, dust, a shake → 2 hearts gone; **jump** at the
   right moment → no damage. Stars over its head: hits count double ("x2" on the bar).
3. The glowing rock over its head (1 s) → it flies in an arc; step aside → it misses. Pawing (1 s) → the
   charge: sidestep it.
4. Beat it (sword, bow, spear; bot friends help): crumble, gold and confetti, everyone dances (after M3 Task
   9's merge), the bar says "You beat the Stone Golem!". **The portal**: stone frame, the moving desert
   window, sand blowing out, the wind, the words; walk up to it → the toast. Both graphics styles, day and
   night (the eyes, rock and window glow at night).
5. **Survivor via the Totem (after Task 9's merge):** win wave 5, tap the Stone Golem button → the fight;
   the Totem glows and refuses waves meanwhile; a win pays 300 gold and unlocks universe 2 (check
   `profile.json`); lose three times (get knocked out) → "You got it to X%!" each time, then "The Golem is
   tired today" and TIRED GOLEM with less health.
6. **First-contact frames:** the first Golem, rock and portal must not cost a shader compile (prewarmed at
   spawn): look for a spike when the Golem appears, throws, and when the portal opens.
7. **Performance:** a fight with bot friends around, in both styles (≥ 30 FPS, no frame over 100 ms).
8. LAN (host + guest): the guest sees the Golem, the wind-ups, the bar, the win message, the portal, and
   gets its share of the gold.

## Merge notes (what will conflict)

- End-of-file sections in `session.gd`, `hud.gd`, `sandbox.gd`, `world_meta.gd`: keep both.
- One-line calls: `hud.gd` `_ready` (`_add_boss_bar()`), `sandbox.gd` `_ready` (`_add_boss()`),
  `_start_host_or_solo` (`_start_boss()`), `_setup_local_player` (`_setup_boss_hud()`), `save_world`
  (`_boss.save_into(meta)`); `world_meta.gd` `from_json` (`_parse_boss`) and `to_json` (`d.boss`).
- `chat_commands.gd`: `BOSSES`, the `/summon` usage text and `choices`; `chat_command_runner.gd`: one branch
  in `_cmd_summon` and `_summon_boss`.
- `audio.gd` `SOUNDS`: six entries at the end.
- `tools/lan_test.gd`: one call in `_process` and a section at the end.
- Task 9: see "Hooks" above (`link_waves` needs `sandbox.waves()`; nothing else to wire).
- Not touched (the lead updates them at merge): the spec and the plan's Task 10 checkboxes, the dev log's
  status row, `docs/playtests/owner-feedback.md`.
