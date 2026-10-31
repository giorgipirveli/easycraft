# M4 Wave 3, agent H — co-op games (hide-and-seek, the team photo, Storm Run)

Spec §17.5 "Co-op games" (written before the build), §13.7 (Storm Run), §16 (research T5, T6; roadmap
proposal §5.2 ranks 1–2). Branch: this agent's worktree, cut from `m2-survive-the-night` at `13b77f4`.

## What was built

| Part | Where |
|---|---|
| Pure rules | `core/games/`: `GameRules` (kinds, participant keys `p<peer>` / `b<bot name>`, when a round may start, the stickers), `HideSeekRound` (the round: counting 30 s, seeking 3 min, found joins the seekers, hints, `can_see`, `in_spot`, the play area), `StormRun` (the circle's schedule, waypoints, stars, the push, the best), `TeamPhoto` (the offer, the line-up, the camera), `BotGamePlans` (hiding spots, open places out of sight, the seek route, star targets), `GameWords` (every word a child reads) |
| The host's director, every game's view | `world/games/games_director.gd` (`GamesDirector`, node `Games` in the sandbox, group `games_director`), `game_ring.gd` (`GameRing`, one open cylinder, `shaders/game_ring.gdshader`), `star_pool.gd` (`StarPool`, 10 pooled star meshes, `shaders/game_star.gdshader`), `game_taps.gd` (`GameTaps`: a seeker's tap on a barrel, closet or bush looks inside) |
| Requests | `autoloads/session.gd` section `# --- M4 H: co-op games` (`games_request_start / _stop / _find / _spot / _star / _photo`, host-only signals, `any_peer` RPCs with length checks) |
| UI | `ui/games/games_panel.gd` (the GAMES page), `game_line.gd` (the HUD's round line), `game_overlay.gd` (the counting screen, the end card with the sticker); `FriendsPanel` got GAMES beside BACK (the page opens in the panel's place); HUD section "M4 H" (`game_line`, `team_photo_button`), `HudLayout` spots `game_line` and `team_photo` |
| Hooks in shared files (small, marked "M4 H") | `BotFriend`: `game_brain` asked first in `_decide`, `game_pose` synced (crouch / inside), `game_hidden_in`, `game_go / game_hold / game_set_pose / game_eye`; `WaveDirector.game_on` (refusal `&"game"`, `WaveRules.REFUSALS`); `StealthDirector._taken` counts a bot in a barrel; `BlockInteractor` asks `GameTaps` before hiding; `PhotoMode.take_team_photo(view)` (a fixed camera until the child steers); `ProfileData.stickers` (+ `ProfileBackup` merge by max); `WorldMeta.storm_best`; sandbox section "M4 H" (`_add_games`, `_start_games`, `_setup_games_hud`) |
| Tools | `tools/games_smoke.gd` (+ steps): the three games in a new Sandbox world on real terrain; `tools/lan_test.gd --games`: the same over two LAN instances |

How a round goes: the host's child opens pause → FRIENDS → GAMES and taps PLAY (hide-and-seek: choose the
seeker or RANDOM). `Session.games_request_start` → the host's `GamesDirector` checks it (`GameRules.start_refusal`:
no round, wave or boss on; hide-and-seek needs two) → the round starts: wild monsters puff, no night spawns
(`monsters_allowed` wraps `MonsterDirector.enabled`), the Totem refuses waves and the boss. Every game gets
the round's state by RPC (on each change and every 5 s) and runs the same clock; it shows the HUD's line,
the glowing ring (hide-and-seek: the 40-block play area, green; Storm Run: the shrinking circle, blue) and
the stars, and moves only its own player. At the end everyone who played gets the game's sticker (their
own game adds it to the profile and saves), bots are friends again, and after 6 s the world is back to
normal.

## Tests (RED → GREEN)

Before: suite **2881/2881** (300 scripts) at `13b77f4` (load ~15).
- `tests/unit/test_hide_seek_round.gd` (11): RED "Preload file res://core/games/hide_seek_round.gd does not
  exist" → GREEN. Seeker picking, two needed, counting 30 s, find only by a seeker of an unfound hider, found
  joins the seekers, all found / time up / the only seeker leaving end it, hints at 120, 140, 160 s, joining
  and leaving, the state round trip, `can_see` (3 blocks, the host's slack, behind, a wall, hidden, a crouch
  in a dark cave), `in_spot`, the reach into a spot, the play area's push.
- `tests/unit/test_storm_run.gd` (9): RED (missing script; then "Function waypoints has the same name as a
  variable" → `make_waypoints`) → GREEN. Radius 40 → 8, always shrinking slowly; the centre drifts under 1.5
  blocks/s and within 16 blocks, the same roll the same path, only on good ground; the push (inside nothing,
  flat, stronger than walking, capped); stars inside; the round (spawns, the pool, taken once, gone outside
  the circle, the end and the best); the state round trip.
- `tests/unit/test_team_photo.gd` (7), `tests/unit/test_bot_game_plans.gd` (4), `tests/unit/test_game_rules.gd`
  (4, with stickers in the profile and the backup merge): RED (missing scripts) → GREEN.
- `tests/integration/test_co_op_games.gd` (20): through Session requests on a flat stand-in world with real
  physics and bot friends: alone refused, the chosen seeker, monsters and the Totem wait (a real
  `WaveDirector`), the counting holds the child still, finds by sight (not at 5 blocks, not through a wall,
  not in a barrel), a tapped spot (too far, empty, found and out), the end with a sticker and bots released,
  time up after hints, a bot hides in a barrel within 30 blocks (not the one at 40), without spots it crouches
  6–30 blocks away, a seeking bot finds the child in a barrel by looking into it and never walks faster than
  4 m/s, Storm Run stars inside the circle / taken for the team / too far / the best saved / the sticker, a bot
  fetches a star, the push back in (no damage, never lifted) and a hop against a ledge (RED without it), a guest's requests checked (start, find from 30
  blocks, a hider, an unknown peer), a guest's copy shows the same stars, circle and line and is never wiped by
  the last round's end card (RED first: found by the LAN check), the team photo
  (offer, 24 blocks, the line-up, facing, cheer, the shot while cheering, once), the 20 s offer, the saved best.
  Mutation checks: with the wall check off, the push off, or the bot's look into a spot off, the matching
  tests fail (then restored).
- `tests/integration/test_games_ui.gd` (5): GAMES beside BACK, the page in the panel's place and back, it fits
  720 px; PLAY with a chosen bot seeker asks the host and closes the pause menu, one round at a time, END GAME;
  the best and the stickers; the HUD's line and TEAM PHOTO follow the director (a tap asks, it goes); the
  counting screen for the seeker only, the end card with the sticker.
- `tests/integration/test_hud_layout.gd`: the round line joins the wave/boss labels (never shown together) and
  TEAM PHOTO is checked with every other button on both screens (first run: the line overlapped the hearts by
  2 px on the 16:9 phone → 316 px wide, font 20).

After: suite **2941/2941** (307 scripts; +60 tests, +7 scripts), load ~40.

## Rulings (decisions made on the owner's behalf; cost if wrong)

1. **Only the host's pause menu has GAMES** (it is in the FRIENDS panel, which a guest's menu doesn't have, and
   the pause menu's rows are not mine to change). The host still takes a start request from any player (tested
   with a guest's request), so a guest entry is one line in the pause menu later. *Cost:* a guest asks the
   host's child to start a round.
2. **Found by sight = the monsters' FULL sight within 3 blocks** (eyes to eyes, 120° view, a clear grid ray,
   16 × visibility). A seeker's own game checks the view from its camera and asks; the host re-checks the
   distance (+0.75), the visibility with the real light and the clear line, not the view cone (it doesn't know
   a guest's camera). *Cost:* a changed client could "see" behind itself within 3 blocks — nothing to gain.
3. **A play area of 40 blocks around the counting spot** (the same gentle push as Storm Run, shown by the green
   ring); bots hide within 30. *Cost:* less room for children who like to hide far away.
4. **A player joining mid-round plays:** hides while counting, else seeks (nobody sits out); they get the sticker.
5. **Hints after 2 minutes of seeking, then every 20 s:** a sparkle within 2.5 blocks of a random hider for
   everyone, with a toast (research T6's guard "nobody waits forever"); seeking bots go there too.
6. **Monsters:** every monster puffs at a round's start (`MonsterDirector.puff_all`: also summoned ones), no
   night spawns during a round; the Totem refuses a wave and the boss with "A game is on! The Totem waits for
   it."; a round can't start during a wave or a boss fight. *Cost:* a `/summon`ed monster goes too.
7. **Stickers are a count per game in the profile** (`ProfileData.stickers`, merged by the larger count in the
   backup), the same for everyone who played (bots get none: they are not players); shown on the end card and
   the GAMES page. No sticker book yet. *Cost:* the Memory Book (M3) may want to show them.
8. **Storm Run's numbers:** radius 40 → 8 linearly; 6 legs of 30 s, each ≤ 12 blocks, the centre ≤ 16 blocks
   from the start and only over good ground (standing ground within 8 blocks of the start's height, not water);
   a star every 1.5 s up to 10, within 85% of the radius, 1 block over the ground (skipped where there is none);
   stars left outside the shrinking circle go; the push is 5 m/s + 1.5 per block outside (at most 12), flat,
   through the child's own body on its own game (`move_and_slide`: it slides along walls). Bots never need it
   (their brain goes back to the centre).
9. **The team photo:** offered to every game for 20 s after a won boss (`BossDirector.fight_ended(true)`); the
   first tap wins; everyone within 24 blocks of the one who tapped (players and bots) lines up 1.4 blocks apart
   across the way that child faces, the child in the middle, each on its own ground, facing a camera in front,
   far enough for a 16:9 picture at the player's field of view (never inside a block, at least 2.5 blocks
   away); they cheer at 1.6 s, the shot is at 2.4 s. Every game with its player in the line opens photo mode
   from that camera with the stars frame, takes the photo (saved like any photo) and stays open (more shots,
   SHARE through the child's own share button, or close). *Cost:* children further away aren't in it.
10. **Fair bot seekers:** they know the hiding blocks in the area (like a child looking around) and a few open
    places, never who is where; they walk at 4 m/s (a child 6), look 1.2 s into each spot, see with the same
    rules from their body's facing. **Bots hiding in the open** pick, of 10 places, one the counting spot can't
    see (a grid ray from the counting eyes to the crouched eyes), and crouch.
11. **The counting seeker's own game holds its player in place** and covers the 3D view with the counting
    screen under the HUD's buttons (PAUSE still works; nothing flashes).
12. **The state travels as reliable RPCs** (on each change and every 5 s for the clock); stars as (id, position)
    RPCs into a pool of 10 meshes — nothing is spawned per star. Hiding spots are searched 3 boxes of 16³ a
    frame on the host (never one big copy), nearest first.
13. **HUD:** the round line shares the wave line's place (a round never runs with a wave or the boss); TEAM
    PHOTO is a context button right of HELP UP (only for the 20 s offer).
14. **A bot in a barrel** is a synced pose (`BotFriend.game_pose`), its body and name tag hidden on every game;
    a player can't climb into a barrel a bot is in.
15. **END GAME** on the host's GAMES page ends a round early with the usual end (stickers too).
16. **The push hops a ledge:** a pushed child against a wall gets the auto-step's upward speed (its own physics
    hops a 1-block step, as walking into it does); a cliff stops it (the circle shrinks slowly; the child can
    walk round). *Cost:* none known.
17. **A star's ground:** standing ground within 8 blocks of the run's starting height, else the surface there if
    within 12 blocks of it; six spots tried per star (water, holes and unloaded ground skipped). *Cost:* a run
    started deep in a cave gets few stars.
18. **One 16³ box a frame for the hiding-spot search** (about 1.2 s per round, while the seeker counts). *Cost:*
    bots start running to hide about a second after the round begins.

## Measurements (desktop, headless; the PC was busy: load average 25–53 from other agents)

**Smoke run** (`tools/games_smoke.gd`, a new Sandbox world on real terrain, the child and two bot friends;
32 checks pass; last run at load 25.7 / 38.2 / 40.4). The director's own steps (its `_process` or
`_physics_process`, timed by the smoke run; bots are timed by their own physics as before):

| Part | director avg | director worst | the whole frame avg / worst (headless) |
|---|---|---|---|
| quiet (before any round) | 238 µs | 1.5 ms | 26.9 / 131 ms (the world still streaming) |
| hide-and-seek, counting (bots run and hide; the spot search) | 59 µs | 0.28 ms | 6.9 / 34 ms |
| hide-and-seek, seeking | 35 µs | 2.9 ms | 7.6 / 67 ms |
| Storm Run (stars, the ring, bots fetching) | 71 µs | 3.7 ms | 7.6 / 80 ms |
| the team photo | 20 µs | 0.9 ms | 6.9 / 6.9 ms |

Earlier runs at load 38–53 had director worsts of 4–8 ms (a star's spawn: up to 6 spots × two ground
searches) and frame worsts of 55–88 ms in every part including "quiet": the frame spikes are the PC's.
Searching one 16³ box for hiding spots: 0.03–0.05 ms on a settled world, 0.44–0.9 ms average and up to 2.6–8.3
ms at load 40 while the world still streamed (the gotcha of DEVELOPMENT.md §8), hence **one box a frame**
(about 72 boxes, 1.2 s at 60 FPS; bots start running to hide once it is done). The pushed child: 6.4 → −0.1
blocks outside in 1.5 s; against a 1-block ledge it hops like walking into it (a run where it didn't hop
stayed 5.4 blocks out: fixed, `test_a_ledge_in_the_way_gets_a_hop_like_walking_into_it`).

**LAN** (`tools/lan_test.gd --games`, two headless instances on this PC, load 30–40): the guest sees the
counting screen ("Counting... 29"), its find of the host is checked by the host (2.24 blocks, clear line,
visibility 1.0) and ends the round; both get the Hide & Seek sticker; the guest sees the same stars as the host
(3–5), a star the guest stands at counts for the team on both games, the best (1) and the Storm Run sticker
reach both; TEAM PHOTO shows on the guest, its tap lines both up and both photos are saved the same second.
Found on the way (both fixed): (1) the tool put the guest "2 blocks from the host" inside a slope and it fell
through the terrain to y −57 (the tool now uses `find_standing_y`; a gotcha row in DEVELOPMENT.md §8); (2) a
guest still showing the last round's end card wiped the host's next round when its end timer ran out (the
guest then missed Storm Run's first 6 s): a running round's state now ends any end display
(`test_a_guests_copy_of_the_round_shows_the_same`, RED first).

Not measured here (needs the emulator): the ring's see-through wall (fill rate) and the stars on the GL
renderer, and the prewarm of both shaders (`GameRing.prewarm`, on spawn).

## What the lead should check with two games (emulator + desktop)

- Host (desktop): pause → FRIENDS → GAMES → SEEKER: the guest → PLAY. The guest (emulator) sees the counting
  screen for 30 s; both HUDs show the round line; bot friends run off and hide (one into a barrel: it
  disappears with its name); the guest finds them by walking close or tapping the barrel; "X found Y!" toasts
  on both; the end card and the sticker on both.
- Storm Run: the blue ring shrinks the same on both; the stars sit at the same places; a star the guest takes
  goes on the host; walking out of the ring pushes you back gently; FPS on the emulator with the ring on
  screen (a see-through wall: fill rate) and 10 stars, in both graphics styles.
- The team photo: beat a boss (Sandbox: `/summon golem`, then defeat it) → TEAM PHOTO on both for 20 s → the
  line-up faces the camera, cheers, and the photo is saved on both (Pictures/EasyCraft on Android); SHARE only
  through the child's own button.
- Under-13 profiles: nothing here is online-only; the games work solo with bots and on LAN too.
