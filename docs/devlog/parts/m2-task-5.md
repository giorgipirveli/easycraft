# M2 Task 5: Stealth

Spec §12.5 (stealth), plan Task 5, research G5 ("hiding feels safe") and A3 ("danger arrow"), and the
Task 4 hand-off (replace `Monster.perceive()` and `MonsterRules.can_see`'s sight). Built in an
isolated worktree on a branch cut from `m2-survive-the-night` at `c86fd0f` (Tasks 1, 2, 3, 4, 6, 7,
11, 14, 15 and M3 Tasks 13, 16 merged), in parallel with Tasks 8, 9, 10 and 18. No editor or
emulator use (house rule for agents); engine glue was checked with headless tests on a real world,
a headless developer run and the monster smoke run.

Commits: `5352a3a` (rules), `c7571c4` (blocks and tiles), `b8c163c` (crouching and hiding on the
player), `0695b19` (monsters, StealthDirector, taps, HUD, sandbox), `759a7c4` (searching monsters
stop to look; a test made deterministic) and this notes commit (docs only; the suite ran green on
the same code for `759a7c4`: 1422 passing).

## What was built

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/stealth_rules.gd` | `StealthRules`: light (daylight 1.0, night 0.45, dark cave 0.3, a lantern or light block within 6 → 1.0), visibility (× 0.5 crouching, 0 hidden or invisible), sight (16 × visibility, 120° view, a grid ray; up to 1.5× is "half-seen"), what blocks a look, noise radii and moving noise, landing, hiding spots, the search spot next to a hiding block, the HUD eye and bars, the danger arrow; `StealthRules.Mind`, the monster's mind (wander → ? → ! → search 6 s → wander) |
| Monsters | `entities/monsters/monster.gd` | Perceives players **and bot friends** at every look (`perceive()`: the nearest one it sees; on the way the nearest one it hears or half-sees is the clue), keeps a `mind`, chases what it sees, walks to a noise, searches the last known spot, attacks only what it sees (players through `Session.hurt_player`, bots through `hurt(n, from)`), syncs `alert` (? / !) and `alert_peer` (whose danger arrow) on change, shows the mark over its head on every peer; `saw_hide(who, spot)`; `bots_now()` (one lookup per physics frame, like players); a far archer's hit makes it come to see |
| Marks | `entities/monsters/alert_marks.gd` | `AlertMarks`: "?" (yellow) and "!" (red-orange), 5 × 7 pixel letters of little boxes with a dark back, one mesh each, BlockyAnimal's vertex-colour material (no new shader) |
| Director | `world/stealth_director.gd` | `StealthDirector`, node `Stealth` on every peer: five times a second the light around every player and bot (the sky's daylight, `AmbienceRules.underground_target`, lanterns by one bulk box copy) and a player's bush; the host's noise log (landings, broken blocks, attacks and spear throws; `add_noise`, `heard_at`, `last_attack_near`); host checks of every hide request and the broadcast; a broken hiding block or a knock-out brings the player out; monsters that were after the player search next to the spot; late joiners hear who is hiding; this game's noise for the HUD (`local_noise`) |
| Player | `entities/player/player.gd` (section at the end + 4 one-liners) | `crouching` (synced on change), `set_crouching`, the C toggle, half speed, a lower body (`CROUCH_BODY`), camera (`rig.height_factor`) and eyes (`stealth_eye()`); `hidden_in`, `set_hidden` (the body goes into the block, stops colliding, holds still; out on the side it went in), `stealth_visibility()`, `stealth_light`, `stealth_in_bush`; moving or JUMP asks to come out |
| Camera | `entities/player/camera_rig.gd` | `height_factor` (crouch) and `peek_from` / `set_peek` (inside a hiding spot: no spring arm, looking out from the block) |
| Taps | `entities/player/block_interactor.gd` | Inside a hiding spot any tap or hold asks to come out; a tap on a barrel or closet asks to hide, whatever is in the hand (like bags and Tilly) |
| Session | `autoloads/session.gd`, section `# --- M2 Task 5: stealth` | `stealth_request_hide/unhide`, `stealth_broadcast_hidden`, `stealth_send_hidden`, signals `stealth_hide_requested`, `stealth_unhide_requested`, `stealth_hidden_changed` |
| HUD | `ui/hud/hud.gd` (section + 3 one-liners), `stealth_meter.gd`, `hide_overlay.gd`, `danger_arrows.gd` | CROUCH where DOWN sits when walking (presses the `crouch` action; lights up while crouching); `StealthMeter` under the hearts at (194, 62): an eye (open / half / closed) and 0-3 noise bars; `HideOverlay`: a warm dark vignette (one gradient texture), a closed eye, "They can't see me!", "Tap or move to come out", sounds muffled (Audio's low-pass); `DangerArrows` at the screen edge |
| Blocks | `data/blocks/block_ids.gd`, `world/block_library.gd`, `tools/make_atlas.gd`, `tools/make_realistic_atlas.py`, both atlases | BUSH (1,6)/(0,6), BARREL (3,6)/(2,6), CLOSET (5,6)/(4,6) in both styles, drawn with their own RNG (every other tile byte-identical, checked with a pixel diff); the three join `PLACEABLE` |
| Palette | `ui/hud/block_palette.gd` | 11 columns (three rows hold 33 blocks; with 26 the 8-wide palette grew a 4th row and covered the hotbar: `test_palette_fits_a_1280x720_screen_above_the_hotbar`) |
| Sandbox | `scenes/sandbox.gd` (section + 2 one-liners) | Adds `Stealth` on every peer; wires it once the world and player exist; the host starts it |
| Input | `project.godot`, `tools/setup_input_map.gd` | Action `crouch` on C |

How the numbers play out (sight = 16 × visibility; half-seen up to 1.5×):

| Situation | Visibility | Seen within | "?" within |
|---|---|---|---|
| Standing in daylight | 1.0 | 16 | 24 |
| Crouching in daylight | 0.5 | 8 | 12 |
| Standing at night | 0.45 | 7.2 | 10.8 |
| Crouching at night | 0.225 | 3.6 | 5.4 |
| Crouching in a dark cave | 0.15 | 2.4 | 3.6 |
| By a lantern (any time) | 1.0 / 0.5 crouching | 16 / 8 | 24 / 12 |
| In a bush crouching, in a barrel or closet, invisible | 0 | never | never |

Heard within: running 12, walking 6, crouching 1.5 (at any speed), landing a jump 8, breaking a
block 7, attacking 6; standing still is silent.

## Patterns chosen (godot-prompter skills)

- **state-machine:** an enum FSM in a pure `RefCounted` (`StealthRules.Mind`) that runs in parallel
  with Task 4's motion enum (`Monster.State`, now WANDER, CHASE, WINDUP, SUSPICIOUS, SEARCH, derived
  from the mind at every decision). Rejected: node-based states (5 nodes × 20 monsters, per-frame
  dispatch, not testable without the tree) and resource-based states (no designer tuning needed).
- **ai-navigation:** direct steering to a spot (Task 4's, with its water and cliff checks), and a search
  made of short random walks within 3 blocks of the spot. Rejected: `NavigationAgent3D` and navmesh
  baking (a navmesh over an endlessly streamed voxel world would need runtime bakes per chunk: too
  costly on phones; monsters hop 1-block steps anyway).
- **multiplayer-sync:** crouching is the owner's state on the player's existing synchronizer, sent on
  change (like `held_item`); hiding is a host-checked request plus a reliable broadcast (a change that
  must arrive and must be checked); a monster's mark is two on-change synced ints. Rejected: an RPC per
  crouch toggle (duplicates the sync) and syncing the mind (guests only need the mark).
- **hud-system:** custom-drawn `Control`s that look ten times a second and redraw only on a change
  (like `HeartsBar`); world-to-screen through the camera's transform for the arrow. Rejected:
  `TextureProgressBar` and sprite icons (no art assets; would need an icon atlas row).
- **godot-optimization:** shared per-physics-frame lists (players and now bots), the eye, facing and
  position read once per look, at most one grid ray per candidate (only in range, in view, visible, and
  nearer than the best so far), the mark synced only when the mind changes, lanterns by one bulk copy.
  Measured below.

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_stealth_rules.gd` | 39 | "Could not find type StealthRules" (rules file moved aside); then one real failure: `lerpf(1.0, 0.3, 1.0)` is 0.30000000000000004, so the blends are written exactly |
| `tests/unit/test_block_ids.gd` (+1, size 23 → 26), `tests/unit/test_block_library.gd` (+2) | 3 | PLACEABLE had 23, the tiles were the placeholders (0,1), (6,0)… |
| `tests/integration/test_player_stealth.gd` | 12 | parse error: `stealth_eye` missing; one test fixed on the way (a local avatar's visibility depends on the spring arm's hit length, which never updates headless) |
| `tests/integration/test_monster_stealth.gd` | 16 | run against Task 4's `monster.gd`: "Cannot find member SUSPICIOUS in Monster.State" |
| `tests/integration/test_monster.gd` (Task 4) | changed | the mesh count per monster excludes the new `AlertMark` |
| `tests/integration/test_stealth_director.gd` | 14 | "Could not find script for class StealthDirector" (checked by moving the file aside: the director was drafted before this test, not after); a test fix on the way (a stand-in bot at y = 0 stood "under ground" in the stub) |
| `tests/integration/test_hud_stealth.gd` | 11 | "Could not find script for class StealthMeter / HideOverlay / DangerArrows"; a test fix (setting `size` on a full-rect control warns) |
| `tests/integration/test_hiding_in_world.gd` | 5 | written before the taps; its RED was not run separately (green on its first run after the `BlockInteractor` change) |

Covered: every visibility factor and their product; sight range × visibility; the 120° cone; a wall
blocks the line (a low wall doesn't); glass, bushes, water and open doors don't block; noise radii and
moving noise; landing; the full mind with timings (? walks to the noise, search 6 s, ! chases, lost
chase searches the last known spot, a noise during a search, a lost chase following a sound); hidden
players are never seen (bush, barrel) nor hurt (also mid-swing); invisible players never seen; a
crouching player at night is not seen 8 blocks away (review focus 5); a walking player behind is
heard, then seen; crouching past is not heard; breaking and landing noises, old noises fade; the far
archer; a monster that saw you hide searches next to the spot and gives up, one that saw nothing is
not sent; knocked-out players ignored (Task 4's test kept); bots perceived, clubbed and touched through
`hurt()`, knocked-out bots left alone; the marks on every screen (shared meshes, BlockyAnimal's
material) and synced on change; crouching halves speed, toggles with C, lowers body/camera/eyes, is
synced, stands up when flying; hiding puts the body and camera inside, holds still, moving asks once,
remote hidden players are not drawn, coming out on the side it went in; the host's checks (reach, not
a hiding block, taken, knocked out), a broken barrel or a knock-out brings the player out; light by
day / night / cave / lantern for players and bots, five times a second; the HUD's CROUCH spot, eye,
bars, the hiding view (muffled), the danger arrow (behind → edge, on-screen or another player's
monster → none, fades, never nags); end to end on a real world: tap a barrel → inside (no plank placed),
tap → out beside it, with a sword too, too far says so, breaking it brings you out, a bush.

Suite: **1321 → 1422** passing (`tests/run_tests.sh` exit 0 before every commit: 1360 after the
rules, 1363 after the blocks, 1375 after the player, 1422 after the monsters and HUD). Each suite ran
on an export of the git index (`git checkout-index`) with the worktree's `.godot` copied in, so the
commit held exactly what was tested.

Headless checks besides the suite: a developer run of a new Survivor world (no script errors) and
the monster smoke run (see "Found, not from this task").

## Cost

Measured with temporary timers (never committed: `patch_cost.py` / a benchmark script in the agent's
scratch folder), on this desktop shared with other agents' suites (load average 25-130, so single
numbers swing by 2×). Task 4's tree (`c86fd0f`) and this task's tree were run **alternately** in the
same conditions.

| Measure | Task 4 (`c86fd0f`) | Task 5 |
|---|---|---|
| Flat-world bench: 20 monsters (both kinds, levels 1-5) around one player walking a slow circle, 600 steps after a warm-up, ms per physics step for all 20 (16 alternating rounds) | 0.68-1.09, medians 0.79 / 0.94 | 0.83-1.11 (one 2.06 at a load spike), medians 0.91 / 0.95 |
| `perceive()` alone, µs per call | 14-64 | 17-43 |
| A decision without a look, µs per call | 19-74 | 23-52 |
| Smoke run's 20-monster window on real terrain (all chasing one player, who was kept from being knocked out), per `_physics_process` call / per step | 48 µs / 0.97 ms (another run: 275 µs / 5.5 ms at a load spike) | 51-64 µs / 1.02-1.28 ms (before the look was trimmed) |

Perception and decisions cost the same as Task 4's within this PC's noise, and the whole step is at
Task 4's figure (0.94 ms). What costs a little more is behaviour, not overhead: monsters that hear
a walking player walk to the noise instead of standing (Task 4's wanderers stood still 40% of the
time), so there are more physics moves; searching monsters stop to look 40% of the time
(`Monster.SEARCH_STOPS`) to keep that down. Trimmed during the task: the eye, facing and position
are read once per look (not per candidate), and the mark is synced only when the mind changes (not
at every decision). Per candidate a look is at most one grid ray (only when in range, in view,
visible, and nearer than the best seen so far); the noise log is at most 24 entries; lanterns are one
13³ bulk copy per body five times a second (`StealthDirector.light_around`, ~0.02 ms like the bots'
box search). **Must be measured again on the emulator** (the autopilot at night with monsters).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Light:** daylight blends by `DayCycle.daylight` (dusk and dawn in between); "dark cave" is the
   cave mood's own measure (`AmbienceRules.underground_target`: deeper than 3 blocks under the generated
   ground and under a ceiling); "near a lantern" is a LANTERN or LIGHT block within 6 blocks (the
   lantern radius of Task 8's "keeps weak monsters 6 blocks away"). The player's own cave lantern
   (Ambience, a mood on one screen) does not count. *Cost if wrong:* glowing crystals don't light you
   up; one list (`StealthRules.LIGHT_BLOCKS`) and one radius to change.
2. **Half-seen** = inside the view with a clear line, beyond the sight range but within 1.5× it: "?",
   it comes to look (never an attack). *Cost if wrong:* monsters react a little further than 16 × vis.
3. **No "noticed from any side within 3 blocks" for sight** (Task 4's placeholder rule): a monster has
   no eyes in the back of its head; close players are *heard* instead (walking 6). A player standing
   still or crouching right behind a monster is not noticed — sneaking up is the point of stealth.
   *Cost if wrong:* stealth attacks from behind are easy.
4. **Marks:** "?" while suspicious *and* while searching, "!" while chasing (also on the way to the last
   known spot). *Cost if wrong:* none known.
5. **Timings:** a lost chase searches once it reaches the last known spot (1.5 blocks) or after 5 s
   (Task 4's memory); walking to a noise gives up after 10 s; the search lasts 6 s within 3 blocks,
   stopping to look 40% of the time; walking to a noise and searching at 0.6 × the chase speed.
   *Cost if wrong:* tune the constants.
6. **Monsters attack only what they see** (the club mid-swing misses a player who hides; a slime never
   touches a hidden player). *Cost if wrong:* none known (review focus 5: "hiding really hides").
7. **Sight passes through glass, bushes, water and open doors; leaves block it.** *Cost if wrong:*
   one function (`StealthRules.blocks_sight`).
8. **Noise:** there is no sprint button, so "running" is moving faster than 7 m/s (the Speed potion,
   flying); walking is any speed from 0.5 m/s; crouching is 1.5 at any speed; standing still is silent.
   A landing thuds when the fall was faster than 8 m/s (a jump from the ground lands at 9; stepping
   down one block, 6.9, is quiet). Breaking = any solid block becoming air (tool powers and wand
   captures too). Attacks = accepted attacks and spear throws, heard around the attacker. Event noises
   last 0.5 s (monsters look every 0.3 s), at most 24, merged within 1.5 blocks; the log lives on the
   host. *Cost if wrong:* a sprint button later needs one speed threshold.
9. **The far archer** (Task 4's hand-off): a monster hit with nobody within 4 blocks of where the hit
   came from turns "?" towards the newest attack noise within 40 blocks (where the shot came from),
   else towards where the hit came from. A melee attacker it cannot see (invisible, hidden) is heard,
   not seen. *Cost if wrong:* archers are found a little easily; it is "?", not "!", so a hidden or
   crouching archer in the dark is still safe.
10. **Crouching is a toggle** (button and C): young children can't hold a button while steering. The
    button presses the same action, so held while swimming it would still dive (the button is hidden
    then; DOWN shows). Crouching stands up when taking off, swimming, sleeping, knocked out or hiding.
    It does not shrink the collision capsule. The eyes drop to 0.6 × head height, so a 1-block wall
    hides a crouching player. *Cost if wrong:* a hold-to-crouch option later is one setting.
11. **Hiding needs to be close:** within 4 blocks, eye to the block's centre (the host allows +1 for
    latency), otherwise "Get closer to hide inside!". A tap on a barrel or closet always means "hide",
    whatever is in the hand (like bags and Tilly), so a block is never placed *on* a barrel by tapping
    its face (tap the ground next to it; breaking by holding still works). One player per spot
    ("Someone is hiding in there already!"); not while knocked out or asleep. *Cost if wrong:* stacking
    barrels needs a tap on a neighbour block.
12. **Inside:** the body moves into the block (collision off, still), the camera looks out from 0.6
    above the block's floor with no spring arm (the block's own faces are culled from inside, so the
    child peeks out), the avatar vanishes for everyone, taking off switches to walking. Out: any tap, a
    hold, moving or JUMP, on the side it went in (or the nearest free side). Breaking the block or a
    knock-out brings the player out first. *Cost if wrong:* none known; the view from inside must be
    checked on the emulator.
13. **Who searches the spot:** only monsters that were chasing that player ("!") are sent next to the
    spot (the side the player went in); they search 6 s and never find a hidden player. A bush needs no
    special rule: a monster that loses you there searches the last known spot anyway. *Cost if wrong:*
    none known.
14. **Bots:** perceived like players (no crouching or hiding; the director measures their light), hurt
    through `hurt(n, from)`, never a danger arrow; knocked-out bots are left alone (they leave `bots`).
    No change to `bot_friend.gd` (Task 18 edits it in parallel); a bot's light is its `stealth_light`
    meta. *Cost if wrong:* none known.
15. **Danger arrow:** only on the edge into "!" for this player, for a monster behind the camera or
    off the screen; at most 3 at once; the same monster at most every 8 s; 2.2 s from glow to gone;
    pulsing only without Reduce motion. *Cost if wrong:* tune the constants.
16. **HUD:** the eye is open from visibility 0.7, half below it, closed at 0 (night, a cave and
    crouching in daylight all show "half"); bars: 1 crouching, 2 walking/landing/breaking/attacking, 3
    running. The HUD shows a guest's own movement, landing and breaking noise (a guest's attack noise
    is known on the host only). *Cost if wrong:* a guest's bars stay low while it attacks.
17. **Muffled while hidden** uses Audio's underwater low-pass (Task 14); coming out switches it off
    (Ambience switches it on again on its next underwater change). *Cost if wrong:* none known.
18. **Standing in a bush gives no cover** (the spec lists only crouching in it). *Cost if wrong:* a
    cover factor is one constant.
19. **Sandbox too:** crouching, hiding and the HUD work the same with gentle monsters. *Cost if wrong:*
    none known.
20. **Palette 11 columns** (three rows for up to 33 blocks, with Tasks 8 and 16's blocks). *Cost if
    wrong:* a wider panel (1084 of 1280 px).

## What to check on the emulator (the lead)

1. **Crouch:** walking, the CROUCH button sits where DOWN sits (DOWN comes back when flying or
   swimming); a tap: lower body and camera, half speed, the button lights up; tap again stands up.
   Other players (LAN) see the crouch.
2. **Night, a goblin:** walk up behind it: "?" pops up, it turns; seen: "!" and it chases. Crouch into a
   bush: it comes to the last spot, "?", searches about 6 s and wanders off. The marks readable in
   moonlight in both styles (they use the animals' shaded material, like the health bar).
3. **Barrel / closet:** tap one within 4 blocks: the view goes inside (a warm dark ring, muffled
   sounds, a closed eye, "They can't see me!"); tap or move: out beside it. A goblin that saw you go
   in searches next to it and leaves. From 6 blocks away: "Get closer to hide inside!". Check the view
   from inside (the block's faces culled, neighbours drawn).
4. **The eye and bars** top-left under the hearts: open by day, half at night / in a cave / crouching,
   closed in a bush crouching, in a barrel, or with the Invisibility potion; bars while walking,
   running (Speed potion), crouching, landing.
5. **The danger arrow:** let a monster come from behind at night: an arrow glows at the edge on its
   side and fades; with Reduce motion on it doesn't pulse; never twice in a row for the same monster.
6. **Tiles** in both styles (bush cutout, barrel, closet); the palette at 11 columns fits above the
   hotbar.
7. **Performance:** the autopilot at night with monsters, both styles; the first "?" / "!" (shared
   material: no shader compile expected, but look for a first-contact spike).
8. **LAN:** a guest sees ? / !, crouching bodies, a hidden player vanishes; the host sees a guest hide;
   the guest's own eye and bars.

## Merge notes (what will conflict)

- `data/blocks/block_ids.gd` `PLACEABLE` (Task 8 adds its blocks: `test_block_ids` size 26 → 29),
  `world/block_library.gd` `TILES`, `tools/make_atlas.gd` `_init` (Tasks 8 and 16 append there too),
  `tools/make_realistic_atlas.py`, and the three atlas PNGs: after merging Tasks 5, 8 and 16, run
  `tools/make_atlas.gd` and `tools/make_realistic_atlas.py` again (each task's tiles use their own RNG).
- `entities/monsters/monster.gd`: Task 8 (doors, traps, lanterns) and Task 18 part 2 (minds) build on
  it; perception is `perceive()` / `_consider()`, the mind is `mind`, targets are `Node3D`.
- End-of-file sections: `session.gd`, `hud.gd`, `sandbox.gd`, `player.gd`, `block_interactor.gd`.
  One-liners: `hud.gd` (`_ready`, `_process`, `_show_up_down`), `sandbox.gd` (`_ready`,
  `_setup_local_player`), `player.gd` (`_enter_tree`, `_process`, `_physics_process`, `_move_normal`),
  `block_interactor.gd` (`place_at_screen`, `break_at_screen`), `camera_rig.gd`.
- `ui/hud/block_palette.gd` `COLUMNS`, `project.godot` (the `crouch` action), `DEVELOPMENT.md` rows.

## Found, not from this task

- **A knock-out can make every monster vanish (Task 4 × Task 2; matters for Task 9's waves).** When
  the only player (or every player) is knocked out, the respawn (`Player.go_home` → `spawn_at` →
  `_begin_spawn`) sets `_spawned = false` for a moment; if `MonsterDirector.tick()` (once a second)
  runs then, `player_positions()` is empty and `MonsterRules.should_despawn(pos, [])` is true for every
  monster, summoned and wave monsters included. The monster smoke run's 20-monster window shows it: its
  20 summoned monsters knock the player out (traced: 20 HP → 0 within about 1 s in both trees), and in
  2 of 8 runs of this tree and 0 of 5 runs of `c86fd0f` the window ended with 0 monsters ("FAIL 20
  monsters (0)"; a race with the once-a-second tick, so a few runs don't tell the trees apart); with
  the player protected, 20 of 20 stayed every time. Suggested fix (not made here, to
  keep off Task 4's file): skip the far-away despawn in `tick()` while there are no player positions,
  and in the smoke run protect the player during the cost window (`p.health.protect(600)`).
- The monster smoke run also failed once on "coins are lying there" on `c86fd0f` (a timing flake, not
  looked into).
- `test_stealth_director.gd` once failed (light 1.0 instead of 0.45) under a load average of ~100:
  the director was also run by the engine between the test's own steps. The test now steps it by
  itself (`set_physics_process(false)`); 3 of 3 runs green since.
