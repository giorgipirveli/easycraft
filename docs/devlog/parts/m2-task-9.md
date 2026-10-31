# M2 Task 9: the Monster Totem and waves

Spec §12.8 (and §12.15 for Sandbox, §12.11 for LAN), plan Task 9, research G6 ("easier or again?",
`docs/design/engagement-and-child-psychology.md`). Built in an isolated worktree cut from
`m2-survive-the-night` at `c86fd0f`, in parallel with Tasks 5, 8, 10 and 18. No editor, emulator or
godot-mcp use; engine glue was checked with a new headless smoke run on real terrain and a two-instance
LAN run.

## What was built

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/wave_rules.gd` (`WaveRules`) | Wave sizes and levels, the fixed roster per wave, rewards, how a wave ends, N after a wave, try again / easier, the boss offer, spawn columns on the 25-block circle, the Totem's spot (flat, dry, clear of trees and of Tilly), its tap box and reach, every on-screen line |
| The Totem | `entities/interactables/totem.gd` (`Totem`) | A carved pole of three monster heads (goblin, slime, horned with glowing eyes) on a stone plinth; group `totems`; `find()` for taps; `show_state()` drives the glow (eight standing stones and a floating crystal) and the line over it ("Wave 3", "5", "7 left", "Try again?", "Wave 6 or the Golem!") |
| Director | `world/wave_director.gd` (`WaveDirector`) | Node `Waves` on every peer with the TotemSpawner and two RPCs (state, effects). Host: places the Totem, checks requests, counts down, spawns, calls stuck monsters closer, counts, ends, pays; boss hooks for Task 10 |
| Wave monsters | `entities/monsters/monster.gd` (section at the end, 2 one-line hooks) | `wave` (the wave it belongs to) and `goal` (the Totem); with nobody to chase it walks to its goal, near it (4 blocks) it wanders like any monster |
| Monster director | `world/monster_director.gd` (2 lines) | Wave monsters are never sent away for distance; a split wave slime's small ones join its wave |
| Session | `autoloads/session.gd`, section `# --- M2 Task 9: waves` | `wave_request_start(wave)`, `wave_request_boss()`, host signals `wave_start_requested(peer, wave)`, `wave_boss_requested(peer)` |
| Taps | `entities/player/block_interactor.gd` (1 line + section) | A tap on the Totem within reach emits `totem_tapped` whatever is in the hand (after Tilly's check); never while its wave runs |
| HUD | `ui/hud/wave_line.gd`, `ui/hud/totem_panel.gd`, `ui/hud/monster_icon.gd`, `ui/hud/hud.gd` (2 lines + section) | The wave line (top-centre above the toasts) and the Totem's centred picture panel; a slime drawn in code for both |
| World save | `world/world_meta.gd` | `totem_pos`, `totem_yaw`, `wave_next` (JSON `"totem": {pos, yaw, wave}`), validated |
| Sandbox | `scenes/sandbox.gd` (3 lines, one Back-button branch, section) | Adds the director on every peer; host places the Totem after Tilly and the monsters, wraps the night spawns, saves N; the HUD follows the state; `waves()` for Task 10 |
| Smoke run | `tools/wave_smoke.gd` (+ `_steps`) | Headless end to end in a new world (below) |
| LAN run | `tools/lan_test.gd` (`--wave`) | Two instances: a guest starts a wave, both see it (below) |

No new assets: the Totem, the slime icon and the glow are drawn in code; the sounds are the existing
`ui_click`, `ding`, `poof` and `coin`.

**Waves** (`WaveRules`, spec §12.8): wave N = 3 + 2N monsters, at most 20 (5, 7, 9 … 19, then 20 from
wave 9); levels ⌈N/2⌉ and ⌈N/2⌉+1, at most 5 (wave 1: 1–2, wave 5: 3–4, wave 9 on: 5); every second monster
is the higher level, three in five are slimes. Sandbox: at most 8, level at most 2, no gold.

**A wave, host side** (`WaveDirector`, five ticks a second while a wave is on):
1. A tap on START asks the host, which checks: no boss fight, no wave on, Sandbox MONSTERS ON, the wave is
   the Totem's N (or, after a wave not won, that wave or one easier), the player's eye within 8 blocks
   of the pole (and up, not knocked out).
2. 5 s countdown ("Wave N starts in 5…", a tick each second on every game, the Totem glows).
3. The monsters appear two per tick, each at its own place on the edge of the 25-block circle (spread
   evenly from a random start). A column with water or tree tops is nudged, then moved in or out, and the
   last choices come closer (8–14 blocks), so a Totem on a small island still gets its wave. The director
   waits while the ground there is not loaded. Each appears with a purple puff; the start is a ding at the
   Totem.
4. They head for the Totem at walking pace while they see nobody. The Task 4 sight rules (and later Task
   5's stealth) still decide when they chase. One that chases nobody and got no closer for 15 s (behind a
   river, resting far from everyone) is called to 9 blocks from the Totem, with a puff at both spots.
5. The wave is **won** when every monster is defeated, the small slimes of a split big one included:
   10 × N gold to every player not knocked out during it, a confetti burst at the crystal, N rises
   (saved), and "Wave N won! +10N gold". A player who was knocked out hears "Wave N won! Stay on your
   feet to earn gold."
6. It ends without a win after 3 minutes, or once every player has been knocked out during it. The
   monsters puff away (no coins), N stays, and "Time's up! The monsters went home. Try again at the
   Totem!" (or "Ouch! …"). The Totem then offers TRY AGAIN and TRY AN EASIER WAVE.
7. Night monsters stop while a wave (or the boss) is on: the wild ones puff away and none come, so the
   budget of 20 monsters holds.

**Everyone sees it (LAN):** the host sends one small state (`WaveDirector.state()`: phase, N, the wave on,
monsters left, countdown seconds, time left, the wave not won, the boss offer, gentle) to every game when
something visible changes, and to a guest when it joins. The time bar counts down locally between
messages. Each game's Totem, wave line and panel follow it. Monsters come through Task 4's
MonsterSpawner with their `wave` in the spawn data.

## Tests (RED → GREEN)

Suite: **1321 → 1401 passing, exit 0** (140 → 146 scripts; the run times are in the commit messages).

| File | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_wave_rules.gd` | 29 | `WaveRules` not declared. Then a test bug: the no-shame word list flagged "closer" for "loser"; single words are now matched whole |
| `tests/unit/test_world_meta_totem.gd` | 3 | no `totem_pos` / `wave_next` / `has_totem` on WorldMeta |
| `tests/integration/test_waves.gd` | 24 | `WaveDirector` not declared; later `STUCK_TIME` / `CALL_RADIUS` missing (the stuck-monster rule, added after the smoke run); one test bug (asked for wave 3 without the Totem offering it) |
| `tests/integration/test_totem.gd` | 9 | `Totem` not declared, then `totem_tapped` missing on BlockInteractor |
| `tests/integration/test_wave_monster.gd` | 3 | `wave` / `goal` / `GOAL_NEAR` missing on Monster |
| `tests/integration/test_wave_hud.gd` | 12 | `WaveLine` / `TotemPanel` not declared; then "Wave 99 starts in 5…" was 208 px in a 204 px room at 21 px (now 20 px) |

The director, Totem and monster tests were written before those scripts but first run after the
implementation, so I checked them with **mutations**: each change below was applied, the tests run, and
the file restored (`mutate.py` in the scratchpad). Every one made a test fail:
- no goal walk;
- wave monsters sent away for distance;
- split slimes left out of the wave;
- everyone paid, knocked out or not;
- a busy Totem still taking taps;
- no Totem tap in the interactor;
- night monsters during a wave;
- no monsters sent home after a loss;
- the countdown ending early;
- unlimited spawns per tick;
- no stuck-call;
- a chasing monster being called.

The first goal-walk test survived its mutation (the seeded wander happened to lead towards the Totem). It
now uses two monsters with the same luck on opposite sides.

One mutation survives on purpose: dropping the RUNNING check in the knock-out handler. `_begin` clears
the list anyway, so the check is only defensive, and the behaviour stays covered by
`test_a_knock_out_during_the_countdown_does_not_count`.

Covered: sizes and levels for N = 1..12, caps, the fixed roster, bad numbers; rewards only to players
not knocked out (before-the-wave and countdown knock-outs don't count); all defeated, 3 minutes, every
player knocked out, win beats a same-tick knock-out; N rises on a win only, an easier win keeps N; try again
and the easier wave (normal gold, normal roster, none below wave 1, equal buttons); the boss offered after
wave 5 (not 4), its request checked (reach, busy, asleep when nobody listens) and emitted; boss running
blocks waves and glows; Sandbox gentle and unpaid, MONSTERS: OFF refuses and ends a wave; state to a
guest's director and Totem; the Totem's placement (20 blocks, flat, dry, no trees, clear of Tilly,
deterministic, fallback, four real seeds) and save; shared meshes and one glow material, nothing made on
glow; taps (reach, walls, busy, through the camera, with a sword); wave line (text, time bar running down,
longest lines fit, top-centre above the toasts and clear of the hearts, gold, pause, potion chips and camera
button, never taking taps); the panel (START, try again / easier, boss, Sandbox counts and no gold, closes
on a wave start, walking away, X; centred).

## Headless runs

**Developer run**, private `XDG_DATA_HOME` with a copy of `profile.json`, `-- --survivor --new-world`:
- `TRADER at (16.5, 38.0, -11.5)`, `TOTEM at (26.5, 39.0, -16.5)`: 11.2 blocks apart.
- `world.json` holds `"totem": {"pos": [26.5, 39.0, -16.5], "wave": 1, "yaw": 2.61}`.
- No errors.

**Wave smoke run** (`tools/wave_smoke.gd`, new world, real terrain), four runs, load average 27–39 (other
agents' suites):
- Survivor: run 1 failed one check of the script itself. It looked at the ground under a goblin a second
  after it had appeared, when it was mid-step, and found air. The script now records every monster
  where it appears.
- Survivor runs 2 and 4 and Sandbox run 3: `WAVE_SMOKE result fails=0`.
- The Totem is 19.8–20.2 blocks from the spawn on grass.
- A real tap through the camera opens the panel; START; the HUD says "Wave 1 starts in 5…"; the Totem
  glows.
- Five monsters appear 24.4–25.6 blocks from the Totem on grass or sand. It took about 5 s after the
  countdown, because the smoke run had just moved the player there and the ring was still loading.
- They walk in (average 24.8 → 20.0–20.6 blocks in 8 s; slimes hop slowly).
- Survivor +10 gold, Sandbox 0; `world.json` keeps wave 2.
- A knock-out ends wave 2 (lost 2, its monsters gone); the panel offers both choices.

**Cost window** (desktop, headless, wave 9 = 20 monsters all active, 12 s; load 27–31, so only a hint):

| | physics avg / worst ms | process avg / worst ms |
|---|---|---|
| quiet (after the knock-out teleport, streaming) | 6.8–15.6 / 12–31 | 10.9–13.8 / 22–37 |
| wave 9, 20 monsters | 7.7–11.2 / 11.7–31.5 | 4.3–5.8 / 7.0–12.2 |

The monsters' own cost is Task 4's (47 µs a monster a step). The director adds a 5 Hz tick over at most
20 monsters; the wave line redraws at 5 Hz, and only while a wave runs.

**LAN** (`--auto-host --survivor --new-world --lan-test --wave` + `--auto-join=127.0.0.1 --lan-test
--wave`, private folders; port 24565 checked free), 2 runs, both clean:
- The guest receives the Totem at the host's spot.
- It asks for wave 1 over the network and hears the same states as the host: countdown 5…1 with its
  Totem glowing and its line "Wave 1 starts in N…", then "Wave 1 — 5 left".
- The wave monsters reach it with their wave (`monsters here=5`).
- The win: "Wave 1 won! +10 gold" and its gold goes 25 → 35. The Totem shows "Wave 2", the glow and the
  line are gone.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Gold only for a won wave.** A wave that times out pays nothing, because otherwise hiding for 3
   minutes would pay 10 × N again and again. *Cost:* a child who survives the whole time without
   clearing gets only the coins of the monsters they defeated.
2. **"Everyone knocked out" = every player was knocked out at least once during the wave** (nobody could
   still earn the gold); solo, the first knock-out ends it. *Cost:* in LAN a wave goes on while one player
   has not been knocked out. "All down at the same moment" would almost never happen with 1.6 s knock-outs.
3. **The last monster falling as the last player falls is a win** (N rises; no gold for the knocked out).
4. **Every player in the world takes part**, near the Totem or not (a co-op game for children).
   *Cost:* a LAN sibling building far away also gets the gold.
5. **Knock-outs before the monsters come (the countdown) don't count.**
6. **Each wave always brings the same monsters**: every second one is the higher level; three in five are
   slimes (like the night's 60 %). Children can learn a wave. *Cost:* less variety between tries.
7. **Where they appear:** each at its own place on the circle's edge, spread evenly from a random start;
   water or tree tops move it a little, then in or out, then closer in (an island Totem). Two per 0.2 s
   tick; it waits while the ground there is loading.
8. **Wave monsters** are not wild (the sun never takes them), are never sent away for distance (running
   away never wins a wave), and head for the Totem at walking pace while they see nobody.
   *Cost:* they need about 15–20 s to reach the Totem; faster would be one constant (use the chase speed
   while heading for the goal).
9. **A stuck wave monster is called closer**: one that chases nobody and got no closer to the Totem for
   15 s is put 9 blocks from it, with a puff. Otherwise a slime behind a river makes a wave impossible to
   win. *Cost:* a monster may pop nearer in view.
10. **No night monsters while a wave or the boss is on**: the director's switch is wrapped
    (`WaveDirector.night_allowed`), so the wild ones puff away everywhere and none come. This keeps the
    budget of 20. *Cost:* a LAN guest far away loses its night monsters during someone else's wave.
11. **Totems in every world.** Sandbox waves are gentle and unpaid.
    - With MONSTERS: OFF the Totem refuses ("Monsters are OFF in this world."), and switching OFF ends a
      running wave. That end is `STOPPED`: no win, no loss, N and the offer stay.
    - The world setting (a parent's control) wins over the `/summon` precedent.
    - *Cost:* a child in a Sandbox world with monsters OFF can't use the Totem until someone switches
      them on.
12. **N is saved per world** (`WorldMeta.wave_next`); nothing lowers it; winning an easier wave keeps it.
    The try-again offer lives in the session only. *Cost:* after a reload the easier choice is gone (START
    on wave N is there).
13. **After a wave that was not won** the panel shows only TRY AGAIN (that wave) and TRY AN EASIER WAVE
    (one lower; not after wave 1), as equal buttons (research G6). The host also still accepts wave N.
    *Cost:* after losing an easier wave, START on N comes back only with a win or a reload.
14. **The boss offer** (Task 10):
    - It comes in both modes.
    - Every won wave from 5 on emits `boss_offered`.
    - The panel shows the Stone Golem button while N > 5.
    - With nothing listening, the child hears "The Stone Golem is still asleep. Soon!".
15. **Quitting mid-wave** ends it: wave monsters are not saved, and N doesn't change.
16. **The Totem is a node, not blocks** (like Tilly, Task 7 ruling 9): it can't be mined or stamped over.
    While a wave runs, a tap on it is a swing, not the panel. *Cost:* digging under it leaves it floating.
17. **Taps:** within 6 blocks of the pole, not through blocks; the host accepts within 8.
18. **The wave line** sits at x 508–772, y 16–80 on the 1280 × 720 screen: right of the hearts, above the
    toasts. Its text is 20 px, so "Wave 99 starts in 5…" fits. Task 10's boss bar has the same spot;
    they never show together.
19. **The Totem's spot:**
    - Rings of 20 blocks first, then 19, 21, 18, 22, 17, 23, 16 and 24, from a seed-derived angle.
    - 3 × 3 flat, dry ground (no beach, river, sea or cave mouth), no trunk within 3 columns, at least 8
      blocks from Tilly's stall, facing the spawn.
    - Fallback: the 20-block ring clear of Tilly.
    - Worlds made before this task get their Totem on the next load.
20. **Sounds and effects reuse what exists:**
    - The countdown tick is `ui_click`, on every game's HUD. The start is a `ding` at the Totem.
    - Each monster appears with a purple puff (`Fx`, the shared material) and a quiet `poof`.
    - A win is confetti with a `ding` and a `coin`.
21. **Bot friends** fight wave monsters like any monsters (Task 15). They are never paid, because they
    are not in `players`.

Not built (follow-up for the lead): the one-time hint arrow over the Totem (research O5, "an arrow shows
the Totem the first time"). Tilly's `Trader` has the pattern: a bobbing arrow, a label and a
`*_visited` flag in WorldMeta.

## Godot skills used (pattern chosen / rejected)

- **state-machine:** an enum (`WaveDirector.Phase`: IDLE, COUNTDOWN, RUNNING, BOSS) switched in `advance`
  and `tick`. Rejected: node-based states. Four phases, host-only, with no per-state input or animation,
  so state nodes would be ceremony.
- **hud-system / godot-ui:**
  - Chosen: a signal-driven HUD (`state_changed` → `Hud.show_wave_state`; nothing polls) and a
    `Control` that draws its own panel and time bar, redrawn at most 5 Hz and only while running.
    Taps are ignored.
  - The panel reuses the shop's pattern: a centred overlay, `UiKit` buttons with an icon over a short
    word, the dim area and Back closing it.
  - Rejected: a `ProgressBar` / `TextureProgressBar` for the time bar. It needs a theme or textures for
    one thin bar that a single `draw_rect` does.
- **multiplayer-sync:**
  - Chosen: a MultiplayerSpawner for the Totem (spawn data only, like Tilly), and a reliable RPC of one
    small state dictionary on change, plus to a guest when it joins. The time left is extrapolated
    locally.
  - Rejected: a MultiplayerSynchronizer for the wave state. It would send every interval for data that
    changes a few times a minute, and still needs the join case.
  - Requests are guest → host RPCs in Session, like every other task.

## Hook for Task 10 (the Stone Golem): names agreed here

Everything is on the host's `WaveDirector` (`sandbox.waves()`, node `Waves`):
- `signal boss_offered(totem_pos: Vector3)`: a wave from 5 on was won; the Totem now offers the boss
  (`boss_available()` is true while N > 5).
- `signal boss_requested(peer_id: int, totem_pos: Vector3)`: a player tapped the Stone Golem button. The
  host has checked that the boss is offered, no wave is on, no boss fight is on, and the player is within
  8 blocks. **Task 10 connects here and summons the Golem at `totem_pos`.** With nothing connected, the
  player hears "The Stone Golem is still asleep. Soon!".
- `func set_boss_running(on: bool)`: call `true` when the Golem appears and `false` when the fight ends.
  Meanwhile the Totem glows and says "The Stone Golem!", waves are refused ("The Stone Golem is here!"),
  night monsters stay away, and every game hears the phase `BOSS`.
- `func totem_position() -> Vector3`, `func boss_available() -> bool`, `var gentle` (Sandbox).
- Guests' taps arrive through `Session.wave_request_boss()` → `Session.wave_boss_requested` →
  `WaveDirector.request_boss`.
- The boss bar can take the wave line's spot (see ruling 18).

## What to check on the emulator (the lead)

1. A new Survivor world: the Totem is visible about 20 blocks from the spawn, with "Wave 1" over it, in
   BLOCKY and REALISTIC; its heads, horns and glowing eyes read well by day and at night.
2. Tap it with anything in the hand: the panel is centred (Wave 1, slime × 5, coin 10, START).
3. START: the ticks, "Wave 1 starts in 5…" top-centre, the countdown over the Totem, the stones and
   crystal glowing. **No hitch when it lights up** (the eyes keep the glow shader compiled), none at the
   first purple puff (`Fx` is prewarmed).
4. Monsters pop up about 25 blocks away and walk in; "Wave 1 — k left" and the time bar; bot friends
   help. Does the line sit well next to the hearts, the potion chips and Task 5's stealth eye?
5. Win: confetti, "Wave 1 won! +10 gold" and the counter, "Wave 2" over the Totem.
6. Lose (a knock-out, or let the 3 minutes run): the toast; tap: TRY AGAIN and TRY AN EASIER WAVE, equal
   and readable.
7. Boss button: set N from godot-mcp exec (`get_tree().current_scene.waves().next_wave = 6`), then tap.
   Task 10 wires the Golem.
8. **Performance:** wave 9 or later (20 monsters) near the Totem, in both styles, against the ≥ 30 FPS,
   ≤ 100 ms bar.
9. Sandbox: gentle waves, no gold; MONSTERS: OFF refuses the Totem and ends a running wave.
10. LAN: the guest sees the Totem, the countdown, the glow and the line, and gets its gold.

## Merge notes (what will conflict)

- End-of-file sections: `session.gd`, `hud.gd`, `sandbox.gd`, `block_interactor.gd`, `world_meta.gd`,
  `monster.gd`, `lan_test.gd`. Keep both sides.
- `monster.gd`:
  - `_setup_wave(data)` is one line in `setup`, and `_head_for_goal()` one line in `_decide`'s wander
    branch.
  - Tasks 5 (stealth) and 18 (minds) rewrite `perceive` / `_decide`. Keep the goal walk in whatever
    replaces the wander choice; Task 18's mind can treat the goal as a place to go.
- `monster_director.gd`: two lines (`m.wave == 0 and` in the despawn check; `"wave"` / `"goal"` in the split
  data). Task 8 may touch the same file.
- `sandbox.gd`: `_add_waves()` after the monsters in `_ready`, `_start_waves()` after `_start_monsters()`,
  `_setup_waves_hud()` in `_setup_local_player`, one Back-button branch.
- `hud.gd`: `_add_waves()` in `_ready`, `_setup_waves()` in `setup`.
- `block_interactor.gd`: the Totem tap comes right after Tilly's.
- `world_meta.gd`: the fields after `bots`, `_parse_totem` at the end of `from_json`, `totem` in `to_json`.
- Task 10: the boss bar's spot, and connecting `boss_requested` / `set_boss_running` (above).
