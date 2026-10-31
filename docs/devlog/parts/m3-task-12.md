# M3 Task 12: levels, the adventure board, achievements, presents during play (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `e5d3349`, after
M2 Task 17's HUD pass), without the editor or the emulator. Spec §14.11 (refined below), §5.8, §6, §16;
research R4 (adventure board instead of daily missions and a daily gift), R5 (play-style titles), C3
(trophy shelf), C5 (first-time badges), §1.8 (rewards); plan Task 12. M3 Tasks 7 (smart blocks and races)
and M4 data rights ran in parallel.

## What was built

| Piece | Where | What it does |
|---|---|---|
| The event bus | `autoloads/progress.gd` (autoload **`Progress`**) | One entry point, `Progress.event(kind, amount := 1)`. Kinds are families (`monster_defeated`, `secret_found`, `block_placed`, `wave_won`, `boss_beaten`, `buddy_woken`, `animal_tamed`, `photo_taken`, `race_finished`, `friend_played`, `area_explored`; `goal_done` is the board's own) or `family/detail` (`animal_tamed/dog`, `secret_found/geode`, `monster_defeated/goblin`, `boss_beaten/golem`) for goals and badges. It records into the profile's progress, finishes board goals (sticker, XP, Survivor gold from the host), unlocks badges and emits `leveled_up(level)`, `goal_done(goal_id, gold)`, `badge_unlocked(id)`, `present_ready`, `present_opened(gift_id)`, `changed`. **Counts only between `begin()` and `end()`** (the world's ProgressDirector calls them), so menus and tests never touch a child's progress. Also `pick_goal`, `choose_title`, `shown_title`, `tag`, `present_tick`, `open_present`. |
| XP, levels, titles | `core/progress/level_rules.gd` (`LevelRules`, pure) | XP per family (monster 10, secret 25, block 1, wave 40, boss 150, buddy 20, tame 30, photo 5, race 25, friend 15, new place 5, goal 50); one event gives XP for at most 5 blocks (a stamp is one event) or 10 of anything else. Curve `25 (L−1)(L+2)`: level 2 at 100 XP, 3 at 250, 5 at 700, 10 at 2,700, top level 99. `TYPICAL_XP_PER_MINUTE` 11 → level 2 in about 9 minutes, level 10 in about 4 hours. Ten play styles with a title each (Master Builder, Secret Hunter, Monster Buster, Boss Slayer, Animal Friend, Buddy Maker, Explorer, Photographer, Speedy Racer, Team Player), earned at 50 XP in the style; the tag shows the chosen one, else the style played most (by XP); "Adventurer" before any. |
| Progress data | `core/progress/progress_data.gd` (`ProgressData`) | XP, counts (a detail counts its family too), XP per style, the chosen title, the board, badges, stickers, the present clock. `to_dict` / `from_dict` field by field (unknown kinds, styles, goals, badges and stickers dropped; numbers finite and clamped; a string never a bool), `merge_from` for the server backup. **No dates anywhere.** In the profile as `ProfileData.progress` (JSON key `progress`). |
| The adventure board | `core/progress/board_rules.gd` (`BoardRules`, pure) | 23 picture goals of at most 4 words ("Tame 2 dogs", "Find a geode", "Beat the Stone Golem", "Place 100 blocks"…), each counting one kind from the moment it is picked. Three slots; a new board starts with three easy ones (Take a photo, Wake a buddy, Find 3 secrets) that the child can change. A goal done gives its sticker (the goal's picture in the sticker book) and in Survivor its fixed gold (40–150; creative goals — building, buddies, photos, friends — none); it stays on the board as "Done!" until the child picks a new one. `host_allows`: one paid goal per player per 20 s. |
| Badges | `core/progress/achievement_rules.gd` (`AchievementRules`, pure) | 24 badges (First buddy, First pet, Crystal geode, Golem beaten, 100 blocks, Say cheese, 20 new places, Played together, 5 goals done, Level 5, Level 10…), each unlocked once, in list order. None for logging in or time played (a test checks the words). |
| Presents during play | `core/progress/present_rules.gd` (`PresentRules`, pure) | The clock counts only seconds of active play with the child's pet within 24 blocks; a frame counts at most 1 s (a phone asleep for hours comes back as one frame); the wait is a fixed round of 15, 20, 25, 18, 22, 16, 24 minutes (no dice); a waiting present stops the clock. Gifts, the child picks one of three: Survivor 15 gold, 2 lanterns or 10 planks (from the host), Sandbox a flower, heart or star sticker. `host_allows`: one present per player per 10 minutes. |
| The world's glue | `world/progress_director.gd` (`ProgressDirector`, node `ProgressDirector` in the sandbox, every game) | Begins and ends counting. Once a second (decisions at 1 Hz; nothing per frame but a timer): active play (moved, turned or a key/touch in the last 60 s; not asleep, not knocked out; pausing stops it), the present clock with the pet from the sandbox, new places (128 × 128 areas; not the one the world started in; once per area per session), friends (each other player once per session; bot friends once, when one joins after the world loaded). Level-ups: confetti (`Celebration.confetti`), the ding and a banner "Level 3!", on this game only. Banners for goals ("Goal done: Tame a dog! +40 gold"), badges ("New badge: First pet!") and presents ("Rex brought you a present! Open it on your BOARD."). Keeps `Player.progress_tag`. A LAN guest's game saves its profile at those moments, every minute and on leaving (its world is never saved). Host: `watch_host(monsters, waves, boss)`. |
| Name tags | `entities/player/name_tag.gd` (`NameTag`, a `Label3D`), section in `entities/player/player.gd` | Other players wear a tag: their chat name and "Lv 5 Master Builder" from their synced `progress_tag` ("<level>:<style>", spawn + on change, ≤ 32 chars, parsed defensively). Checked twice a second; hidden while that player hides or is invisible. This game's own player has none. |
| Session | `autoloads/session.gd`, section `# --- M3 Task 12` | `progress_tell(peer, kind, amount)` (host → that player's game; its own at once, a guest by one reliable RPC `_rpc_progress` that checks the kind and clamps the amount), `progress_near(pos, kind)` (players within 24 blocks), `progress_everyone(kind)`, `progress_placed(peer, step, is_undo)` / `progress_placed_count(step)` (new blocks in an undo step: air or water → a block; undo never counts), `progress_goal_gold(goal)` → host `progress_host_goal_gold(peer, goal)` (known goal, fixed gold > 0, Survivor, not within 20 s), `progress_present(gift)` → host `progress_host_present(peer, gift)` (a Survivor gift: `gold_add` or `inventory_of(peer).add`, not within 10 min), `progress_reset()`. |
| Board page | `ui/progress/adventure_board.gd` (`AdventureBoard`) | The pause menu's BOARD page: the level star, "Level 3", the XP bar, the title button, three goal cards (picture, words, progress bar "1/3", "+60 gold" or "a sticker"; done cards green with "Tap: a new goal"), the pet's present (when one waits), TROPHIES and BACK. A card opens the goal list (8 columns of picture tiles: words, reward, ★ stickers already got); the title button the ten titles (earned ones to pick, the rest locked) and MOST PLAYED; the present three big gift buttons. |
| Trophy room | `ui/progress/trophy_room.gd` (`TrophyRoom`) | The 24 badges on three wooden shelves, the ones still to find as shadows with "???" ("2 of 24 badges"); STICKERS opens the sticker book (26: the goals' and the presents', counts, "?" gaps). The in-world trophy shelf is Task 21's. |
| Pictures | `ui/progress/progress_pictures.gd` (`ProgressPictures`), `progress_picture.gd` (`ProgressPicture`) | Every goal, badge and gift has a picture: the secrets' atlas (cat, geode, chest, hidden room, temple, island, golden animal, Wanderer, star, map, flower, heart, "?"), block and item icons (wand, brick, lantern, planks), the slime, the coin, the HUD's camera, and ten drawn in code (dog, goblin, Totem, Golem, race flag, two friends, the board, the level star, a present, a trophy, a lock). No new textures or materials. |
| Pause menu | `ui/menus/pause_menu.gd` (section at the end) | BOARD (green) shares its row with INVITE FRIENDS (M4 C), so every combination of rows still fits 720 px. |
| Smoke run | `tools/progress_smoke.gd`, `tools/progress_smoke_steps.gd` | A new Survivor world through the real systems (see below). |

## Hooks in shared files (one line each, for the lead)

| File | Line | What |
|---|---|---|
| `project.godot` | `Progress="*res://autoloads/progress.gd"` (after Feel) | the autoload |
| `autoloads/session.gd` | `_host_apply_batch`: `progress_placed(peer_id, step, is_undo)` before `_send_undo_step` | blocks placed (batches: stamps, mirror, tools) |
| `autoloads/session.gd` | `_host_apply`: `progress_placed(peer_id, [entry], is_undo)` before `_send_undo_step` | blocks placed (one) |
| `autoloads/session.gd` | section `# --- M3 Task 12` at the end | the RPCs and host checks |
| `scenes/sandbox.gd` | `_setup_local_player`: `_setup_progress()` after `_setup_team_chat()` | the director, secrets, photos, host hooks |
| `scenes/sandbox.gd` | `_on_spark`: `Session.progress_tell(peer_id, LevelRules.BUDDY)` after `_spawn_buddy` | buddies woken |
| `scenes/sandbox.gd` | `_on_pet`: `Session.progress_tell(peer_id, StringName("%s/%s" % [LevelRules.TAMED, a.species]))` in the tamed branch | animals tamed |
| `scenes/sandbox.gd` | section at the end (`_setup_progress`, `_pet_near`) | connects `_secrets.found_shown` (secrets found, on the finder's and nearby players' games), `photo.photo_saved` (photos), and on the host `watch_host(_monsters, _waves, _boss)` |
| `entities/player/player.gd` | `_enter_tree`: `_sync_progress_tag_property()`; `_ready`: `_setup_name_tag()`; section at the end | the synced tag code and name tags |
| `core/save/profile_data.gd` | the `progress` field, one line in `from_json`, the key in `to_json` | the profile |
| `core/save/profile_backup.gd` | `is_new` also needs `progress.is_empty()`; `merge`: `out.progress.merge_from(other.progress)` | the server backup keeps progress |
| `ui/menus/pause_menu.gd` | the INVITE row became `[BOARD]` or `[BOARD, INVITE]`; section at the end | the BOARD row |
| `tests/integration/test_online_menus.gd` | "INVITE … a full row" → "INVITE shares its row with BOARD" | the one test changed |

**For M3 Task 7 (races):** when a child finishes a race, call `Progress.event(&"race_finished")` on the
racer's own game, or on the host `Session.progress_tell(peer_id, &"race_finished")` for a finish the host
decides (a detail is welcome: `&"race_finished/gold"` for a medal). The goal "Finish a race", the badge
"First race!" and the "Speedy Racer" title count it.
**For the universe tasks (bosses 2–4):** the Stone Golem's win counts as `boss_beaten/golem` through
`BossDirector.fight_ended`; a new boss director should call `Session.progress_everyone(&"boss_beaten/<name>")`
on a win. New monster kinds count by themselves (`MonsterDirector.monster_defeated`).

## Rulings (decisions made on the owner's behalf, with the cost if wrong)

1. **An autoload with one method, not a signal bus.** `Progress.event(kind, amount)` (godot-prompter
   `event-bus`: a global autoload so unrelated code needs no references) with typed signals for the
   listeners; rejected: a signal per event kind on a bus (every new kind a new signal, and Task 7 would
   have to add one) and a class only Session calls (the local events, photos and secrets, don't pass
   Session). *Cost if wrong:* none known; one more autoload.
2. **Counting only while a world is played** (`begin`/`end` by the director). Without it every test that
   places a block or wakes a buddy would change the test machine's profile in memory and could pay board
   gold in the middle of another task's test. *Cost if wrong:* an event from a menu is lost (none exist).
3. **Host-decided events, the smallest correct way:** one host → player RPC (`_rpc_progress`) with the
   kind, checked against `LevelRules.is_kind` and clamped on the guest; the host's own player counts at
   once. Blocks placed are counted **on the host from the undo step it already builds** (the cells it
   really changed), so refused and skipped cells never count and an undo never does (a refused undo sends
   its cell back and would have looked like a placement: tested). *Cost if wrong:* one small reliable RPC
   per edit request of a guest (a few a second at most).
4. **A monster beaten counts for every player within 24 blocks of it** (the team that fought it), not
   only the one who landed the last hit: the combat code passes positions, not peers, and arrows,
   spears, spike traps and bot friends all finish monsters. Waves and bosses count for everyone in the
   game. *Cost if wrong:* a child standing near a friend's fight gets its count; the research's
   "Together" pillar makes that a feature.
5. **Presents in Survivor come through the host; LAN is trusted** like `gold_hello`: the host checks the
   gift or goal is a known one with a fixed reward and that the player wasn't paid one within 20 s
   (goals) or 10 minutes (presents). *Cost if wrong:* a modified LAN guest can claim at most 150 gold per
   20 s; M4's server wallet (`OnlineWallets`) can take the check over for online play.
6. **Creative goals give a sticker, never gold** (building, buddies, photos, friends), challenge and
   discovery goals a little fixed gold in Survivor (research §1.8: expected rewards for what children
   already love make them love it less). Every goal gives its sticker, in both modes, so the sticker book
   can be filled anywhere. *Cost if wrong:* change `gold` in `BoardRules.GOALS`.
7. **A new board starts with three easy goals** (Take a photo, Wake a buddy, Find 3 secrets) instead of
   three empty slots, so a child who never opens the board still has goals; any of them can be changed.
   *Cost if wrong:* set `STARTERS` empty-handed (`ensure_board` then leaves slots for the child).
8. **The child may change a goal any time** (a tap on a card opens the list), and a done goal stays on
   the board ("Done!") until the child picks a new one. Progress counts from the pick, so nothing is lost
   or gamed by swapping. *Cost if wrong:* none known.
9. **Titles:** earned at 50 XP in a style; the tag shows the child's choice (research R5: "the child
   picks") or, by default, the style played most **by XP**, so building's many small events and a boss's
   one big one compare fairly. *Cost if wrong:* tune `TITLE_XP` or the XP table.
10. **Name tags only over other players.** Players had no name tag before; a tag over this game's own
    player would sit above the crosshair in the default third-person view. The child sees their own level
    and title on the board. *Cost if wrong:* a solo child never sees their own tag in the world (photo
    mode could show it later).
11. **Explorer counts new 128 × 128 areas per session** (the start area never), kept only in memory: a
    world has no record of where a child has been, and a profile list of visited places would grow without
    end. *Cost if wrong:* walking between the same places in a new session counts them again (5 XP each).
12. **Friends:** each other player once per session; bot friends once per session, when one joins after
    the world loaded (friends saved with the world were friends already; BYE and add again is no XP farm).
    Bots count, so a child who plays alone can do "Play with a friend" (bots stay labelled as bots, §6).
    *Cost if wrong:* drop the bot line in `ProgressDirector._meet_friends`.
13. **The present needs a tamed pet within 24 blocks and active play** (moved or turned or touched in the
    last 60 s, not asleep, not knocked out, not paused); the wait is a fixed round of 15–25 minutes, not a
    random draw (spec §6), and the clock is saved in the profile so play spread over days still brings the
    present, while time away adds nothing. *Cost if wrong:* `PresentRules` constants.
14. **The profile is saved with the world** (every minute, on pause and quit, like Survivor gold). A LAN
    guest's world is never saved, so its game saves its profile itself (goals, badges, levels, presents,
    every minute and on leaving) — which also keeps the gold a guest earned on LAN. *Cost if wrong:* none
    known.
15. **Secrets count through the Secret Director's own find path** (`found_shown`, on the finder's and
    nearby players' games), so meeting the Wanderer (`secret_found/wanderer`), a shooting star and a golden
    animal count like buried treasure; no line in the secret director. *Cost if wrong:* none known.
16. **BOARD shares the INVITE row** instead of a new pair: every menu (Sandbox host online: MONSTERS,
    FRIENDS, INVITE) keeps the rows it had, and the fit tests stay green. *Cost if wrong:* INVITE is half
    as wide when hosting online.

## Tests (RED → GREEN)

New: `tests/unit/test_level_rules.gd` (11), `test_progress_data.gd` (13), `test_board_rules.gd` (11),
`test_achievement_rules.gd` (7), `test_present_rules.gd` (8); `tests/integration/test_progress_bus.gd` (21),
`test_progress_director.gd` (12), `test_name_tag.gd` (3), `test_adventure_board.gd` (7). 93 tests.
Changed: `tests/integration/test_online_menus.gd` (INVITE shares its row with BOARD; the fit check is as before).

- **Rules (proper RED).** The five unit scripts were written first and run against stub classes with the
  same API (`LevelRules`, `ProgressData`, `BoardRules`, `AchievementRules`, `PresentRules` returning
  nothing useful) and a bare `ProfileData.progress` field: **47 of 50 failed on their assertions** (XP 0,
  no goals or badges, the round trip empty, `interval_s` 0…). Then GREEN: 84/84 with the four profile
  scripts. Two real bugs on the way: `saved == true` is a runtime error when the saved value is a string
  (a hand-edited profile), and a new `ProgressData` had no board slots, so a profile's JSON changed on its
  round trip (M4 F's backup tests caught it).
- **The bus, Session, the director, the name tag, the board (written first, first run after the code, so
  each was mutation-checked):** removing the counting gate, counting undo steps, and dropping the host's
  20 s check failed `test_nothing_counts_unless_a_world_is_being_played`,
  `test_solo_the_hosts_own_placements_count` (a refused undo kept for later would have counted as a new
  block) and `test_the_host_pays_a_guests_goal_now_and_then`; making play always "active", counting the
  start area, counting bots already there, dropping the level-up banner, giving this game's own player a
  tag and always showing the present failed `test_no_present_while_the_child_is_away`,
  `test_no_present_while_asleep`, `test_a_new_place_counts_once_and_the_start_does_not`,
  `test_bot_friends_count_once_when_one_joins_later`, `test_a_level_up_is_celebrated_here_and_the_tag_follows`,
  `test_other_players_wear_a_tag_and_mine_has_none` and `test_a_waiting_present_opens_a_choice_of_three_gifts`.
  All restored and green. The bot-farm fix (bots count once a session) was proper RED first ("2 expected
  to equal 1").
- **Covered:** XP per event and the caps; the curve (level 2 at 100, 10 at 2,700, each level more than the
  last; about 9 minutes and 4 hours at the documented typical rate); titles by play style, ties, a chosen
  title only when earned, the tag line; the board's starters, picking (counts from the pick, refused
  picks), the list, done once and rewarded once, picking a new one, **never expiring** (no date, time,
  day, expire, deadline, streak or reset in the saved progress; a reload later changes nothing and the goal
  can still be finished); badges once, several at once, level badges, none for logging in or time;
  presents only during active play with a pet (idle, asleep, no pet: nothing; **ten hours away counts 1 s**,
  a clock turned back 0), never piling up, one gift of three, per mode; the host's checks (goal and
  present gaps, creative goals and Sandbox pay nothing, unknown gifts); host → guest RPCs go to that guest
  only, unknown kinds are never sent, a guest ignores bad kinds and clamps amounts; monsters count for
  players within 24 blocks; the profile round trip, old profiles (no `progress`), broken progress, the
  backup merge keeping the best of both, `is_new`; the pause menu still fits 720 px with BOARD; every
  board, list, title, present, trophy and sticker page fits 1280 × 720 (measured: board 988 × 574, with a
  present 988 × 678, goal list 1232 × 694, titles 908 × 608, present 868 × 501, trophy room 1128 × 691,
  sticker book 1164 × 619).
- **Full suite:** before 282 scripts, 2742 tests, all passing (exit 0, 441 s); after the first commit 291
  scripts, 2835 tests, all passing (exit 0, 456 s at load ~19); final (with the bot fix and the smoke run) 291
  scripts, 2835 tests, all passing, `tests/run_tests.sh` exit 0 (459 s), no `SCRIPT ERROR` / `Parse Error`.

### The smoke run (the real game, headless)

`XDG_DATA_HOME=<fresh folder with "smoke" and a profile.json> godot --headless --path . --script
res://tools/progress_smoke.gd`: a new Survivor world. **24 of 24 checks pass** (exit 0): the director is
there and counting, the tag code set ("1:"), the starter goals; two planks through `Session.request_set_block`
count 2; the wand wakes them ("Pubo is alive!") and a buddy counts; three summoned goblins beaten next to the
player count and finish the picked "Beat 3 goblins" with its 40 gold (25 → 65 through the host); a summoned
dog tamed with 3 taps counts; the present comes after 3 s of walking a circle with the dog near (the HUD's
queue: "New badge: First buddy!", "New badge: First monster!", "Goal done: Beat 3 goblins! +40 gold",
"Level 2!", "New badge: First pet!", "Sunny brought you a present! Open it on your BOARD."); the pause
menu's BOARD → the present → "2 lanterns" and the host adds them to the inventory; a new place; a geode
found through the Secret Director's own find path and a saved photo count; `profile.json` keeps it (XP 217,
level 2, six badges). An earlier run failed the present step while walking a straight line (the clock
counted one second in twelve; probably walking into a slope, not confirmed): the run now walks a small
circle and prints the pet, knocked-out and asleep state when a present doesn't come.

## What the lead should check on the emulator

1. Pause menu: BOARD (green) under the world row, above SAVE & QUIT; with INVITE (hosting online) the two
   share the row. Everything fits the 2400 × 1080 screen.
2. BOARD: the level star, "Level 1", the XP bar and "0 / 100", the title button ("Adventurer"); three cards
   with readable pictures (Take a photo, Wake a buddy, Find 3 secrets) and "a sticker" / "+60 gold". A card
   opens the goal list: 8 × 3 picture tiles, all readable at phone size (words at 17 px); pick one and it
   is on the board with 0/N.
3. Play a few minutes: place blocks, wake a buddy, take a photo (MORE → PHOTO), beat a monster at night:
   the banners ("Goal done: …", "New badge: …", "Level 2!") show one after another under the toasts; the
   level-up shows confetti over the player (check the first confetti costs no long frame: it uses the
   prewarmed `Fx` material).
4. Title: after ~50 XP in one style, the title button lists it enabled; pick it; MOST PLAYED goes back.
5. TROPHIES: 24 badges on three shelves, found ones in colour, the rest dark with "???", "N of 24 badges";
   STICKERS: 26 tiles. BACK, BACK, BACK returns to the menu.
6. Presents: tame a dog (tap it three times), keep playing about 15 minutes with the dog near (or set
   `Progress.data().present_s` from godot-mcp exec): the banner "<name> brought you a present! Open it on
   your BOARD."; on the board, the present row → three gifts; Survivor: 15 gold / 2 lanterns / 10 planks
   arrive in the HUD; Sandbox: the sticker is in the book. Standing still (a minute), sleeping or the pause
   menu stop the clock.
7. LAN (two instances): the other player's name tag over their head ("Name" and "Lv 1 Adventurer"), hidden
   while they hide in a barrel; a monster beaten near both counts for both (their BOARD's "Beat 5 monsters"
   moves); a Survivor goal done by the guest pays the guest's gold (HUD); the guest's progress is still
   there after leaving and joining again (its profile saves itself).
8. Performance: the director decides once a second and the tags twice a second; the autopilot bar should
   hold (nothing per frame was added but a timer each).
9. Many things at once (the first minutes) queue several banners, each 2.8 s. If that feels long, merge
   badge banners (a lead call).
