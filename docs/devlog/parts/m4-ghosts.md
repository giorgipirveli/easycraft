# M4: ghost races on friends' courses (notes)

Brief `docs/superpowers/briefs/prompt-m4-ghosts.md` (plan M4 Wave 3: "Ghost races on friends' courses follow M3 Task
7"); research T2 ("my friend races my ghost and gets bronze; I have gold"), spec §17.5. Built by a background agent in
its own worktree (branch `worktree-agent-a69776d00b15cf159`, cut from `m2-survive-the-night`, `lead-merge` merged in
at the start and again before the final suite), without the editor, the emulator or godot-mcp. Stopped once by the
API's usage limit and resumed. Server module **0.2.6** (0.2.5 was owner #45b's `BLOCK_MAX`).

## What was built

| Piece | Where | What it does |
|---|---|---|
| Server rules | `server/modules/src/rules/ghost_rules.ts` (`GhostRules`) | A ghost's format (START and FINISH cells in its course's box, the time, the path as int16 little-endian decimetres from START's top in base64, the look code) and the checks: the shape (1–180 s, samples 5 a second ±1, a look is a JSON object ≤ 2,048), `not_on_course` (START and FINISH where it says), `impossible_run` (first sample within 3 blocks of START's top, last within 1 of FINISH's, inside the box + 4 blocks aside / 24 up / 16 down, every step ≤ 40 m/s + a block, a bigger step only onto a START, CHECKPOINT or TELEPORT_PAD's top (≤ 3 blocks), ≤ 64 of them) |
| Server glue | `server/modules/src/server/ghosts.ts` (`Ghosts`), `main.ts` (0.2.6, two registrations), `gifts.ts` (5 hooks), `deletion.ts` (1 line) | `share_ghost` (`to: "showcase"`: checked against the showcase's build, one per course, ≤ 3, 12 shares an hour; `to: "gift"`: a present like `send_gift` with its ghost checked against the gift's build; `remove`), `list_ghosts` (a friend's, or your own); a new showcase (or none) takes the ghosts down; `list_gifts` says `ghost: true`, `open_gift` gives the ghost; `report_build` with `what: "ghost"` (the server's copy, else the reporter's) and a showcase's report keeps its ghosts; `ghosts` in `Deletion.COLLECTIONS` |
| Game rules | `core/ghosts/race_ghost.gd` (`RaceGhost`), `ghost_race_rules.gd` (`GhostRaceRules`), `ghost_share.gd` (`GhostShare`), `ghost_book.gd` (`GhostBook`) | A course's recording sampled 5 times a second (a jump — a fall back to the checkpoint, a teleport pad — stays one sharp step), the wire both ways, the server's checks on this side, playback (a jump blinks), turned like a stamp; medals against the ghost's time (×1, ×1.3, ×1.6), names only for 13+ or with verified consent, kind words; the owner's courses in a showcase area or a picked build, a stamped gift's START, a new best's replacement; friends' ghosts on the device (`user://ghosts.json`: showcase ghosts with the showcase's build, gifts' ghosts by stamp slot and where they were stamped, the child's best against each, this player's own showcase; ≤ 12 ghosts, ≤ 6 showcases) |
| The owner's own best | `core/rules/course_book.gd` (`finished(..., own)`, `mine`, `mine_ms`, saved as `mine_ms` + `mine` or `mine_is_best`), `world/course_director.gd` (the host's own run is `own`; `mine_best` and `start` in the state) | "A player's best run on a course they built": the world owner's own best, apart from the course's best of anyone (a LAN friend's or a bot's may be faster) |
| The runner | `entities/ghosts/ghost_runner.gd` (`GhostRunner`), `ghost_look.gd` (`GhostLook`) | A blocky body in the racer's look (`AvatarLook.from_code`), see-through (a shared see-through twin of each material, no shadow), the name tag ("Mia's ghost" / "A friend's ghost"); waits on START, runs at the run's pace, a puff where it blinks, back on START 2 s after FINISH. **No collision object of any kind**, not in the players' group, never over the network |
| The races | `world/ghost_races.gd` (`GhostRaces`) | This game only: links ghosts to STARTs, a runner waits on each START within 64 blocks (and only while that START is there); this player's run (M3 Task 7: START arms, stepping off starts) starts the ghost; at FINISH `CourseDirector.state_filter` gives the medal against the ghost's time, `ghost_line` for the toast, the child's best kept |
| Director hooks | `world/course_director.gd` (section at the end) | `touch_sink` / `player_of` / `setup_own_world` (a visit is its own world and its own host), `state_filter` |
| Visits | `world/visit/visit_world.gd` (section), `ui/hud/hud.gd` (`push_top`, one line in `_place_toast`, one in `show_race_state`) | The friend's courses work in the visit (the visitor's game times them; nothing is saved), their ghosts wait on their STARTs, the race clock and toasts sit under the visit's bar |
| Online | `net/online_service.gd` (section "M4 ghost races" + 7 hook lines), `core/gifts/gift_rules.gd` (`ghost` in a list and an opened gift) | `share_showcase_ghosts`, `share_ghost`, `ghosts_of`, `send_gift(..., ghost)`, `showcase_of` brings the ghosts and keeps them (offline races), `kept_showcases` / `kept_showcase`, `note_ghost_result`, `ghost_names_shown` (offline: the last known), `ghost_race_in_slot`; a stamp's ghost goes with the stamp; a report carries a gift's ghost and forgets that player's ghosts here; `online_files` + `forget_online` forget the book |
| SHARE | `ui/gifts/share_panel.gd` (section + 4 hook lines), `ui/gifts/gifts_page.gd` (2 lines) | SHOW IT takes the owner's courses inside the frame along ("Friends can visit it and race your course."); GIFT A BUILD of a whole course: "Your race comes too! (0:01.3)" and the present carries it; PRESENTS says "… and a race!", OPEN says "Stamp it and step on START to race!" |
| The world | `scenes/sandbox.gd` (section "M4 ghost races" + 1 line), `entities/player/block_interactor.gd` (signal `stamped` + 1 line) | A gift's race waits where its stamp is stamped in the child's own world (host or solo), kept per world (slot and seed) and linked again when the world opens; a new own best on a course inside the child's showcase replaces its ghost ("Your new best is on your showcase: friends can race it!") |
| Offline | `ui/online/play_online_screen.gd` (section + 1 line) | PLAY ONLINE's can't-connect page offers FRIENDS' RACES (when some are kept): the kept showcases by name (or "A FRIEND"), a tap visits one from the device's copy |
| Fakes | `tests/fakes/fake_online_server.gd` (section + 6 lines) | `share_ghost`, `list_ghosts`, gifts with ghosts, reports, deletion as module 0.2.6 answers them |
| Tools | `tools/ghosts_smoke.gd` (+ `_steps`), `tools/ghost_net_test.sh` (+ `.gd`, `_steps.gd`), `server/modules/test/integration/ghosts.server.ts` | Below |
| Docs | `server/README.md`, `docs/DEVELOPMENT.md` (architecture, commands), spec §17.5 "as built", `docs/store/` (privacy policy, data safety, retention: a shared race) | |

## Skills and patterns (godot-prompter)

- **save-load:** JSON through `JsonStore.write_atomic` with a version and a careful `from_json` (every ghost
  re-checked with `RaceGhost.from_wire`, a showcase ghost only with its showcase's build, a gift's only in a stamp
  slot, places only of kept ghosts). Rejected: Resources (untrusted data), the profile backup (friends' runs and
  names would go back to our server).
- **3d-essentials (materials):** see-through by a material twin per source material (alpha blending, no shadow),
  cached for the game. Rejected: `GeometryInstance3D.transparency` (a per-instance fade that not every renderer
  draws; the emulator falls back to Compatibility) and one flat pale material (the friend's look would be lost).
- **multiplayer-basics:** the ghost is local presentation, never replicated; the race itself stays M3 Task 7's
  host-checked run, and a visit is its own host (`setup_own_world`: a touch counts only where the block really is).
  Rejected: syncing ghosts to guests (a friend's downloaded ghost is this child's; guests have their own device
  books) and a new host RPC for ghost results (the medal is presentation of the host's time).

## Tests (RED → GREEN)

- **Node** (`npm --prefix server/modules test`): **231 → 252**. New `test/ghost_rules.test.ts` (9) and
  `test/ghosts_rpcs.test.ts` (12); the version tests moved to 0.2.6 (`gifts_rpcs`, `wallet_host` and the three
  integration files). RED: `ghost_rules` "Cannot read properties of undefined (reading 'sampleCount')" (no
  `GhostRules` yet); `ghosts_rpcs` was written before the glue and first run with it (2 failures fixed: `list_gifts`'s
  answer kept its old shape, a look test's text was under the cap). Mutation checks (the guard removed, the tests
  run, put back; each went red): landing only onto START/CHECKPOINT/TELEPORT_PAD (2 red), the box's margins (2),
  `list_ghosts` friends only (1), `share_ghost` consent (1), 3 per showcase (1), a new showcase takes them down (1),
  deletion (1), the share window (1), a gift's ghost checked (1), reports cover ghosts (1).
- **Real Nakama 3.41** (my own server, below): `test/integration/ghosts.server.ts` 4/4 (the module in Nakama's own
  JavaScript runtime; a gift's biggest build with a 3-minute ghost in one call; deletion on PostgreSQL); every
  integration file **38/38** (34 before + 4).
- **GUT:** new unit `test_race_ghost.gd` (9), `test_ghost_race_rules.gd` (5), `test_ghost_book.gd` (7),
  `test_ghost_share.gd` (6), `test_course_book_mine.gd` (4); integration `test_ghost_races.gd` (9),
  `test_online_ghosts.gd` (11), `test_visit_ghosts.gd` (5), `test_share_ghosts.gd` (4), `test_play_online_ghosts.gd`
  (3): **63 tests**; changed `test_gift_rules.gd` (a gift's list entry has `ghost`). Seen RED: `test_course_book_mine`
  (Too many arguments for "finished()"), `test_race_ghost` / `test_ghost_race_rules` / `test_ghost_book` (the classes
  did not exist: parse errors), `test_play_online_ghosts` (no `VIEW_RACES`), `test_ghost_races` (a typed-cast parse
  error first, then green). Written first but first run with their code, then mutation-checked: sampling snaps across
  a jump (1 red), jumps land on a landing block (1), playback blinks (1), margins (1), a new gift in a slot forgets
  the old places (1), names only with consent (1), the medal against the ghost (1), names in the runner's tag (1),
  translucent (1), a report forgets that player's ghosts (1), the report carries the gift's ghost (1), deletion
  forgets the file (1), the gift carries the race (1), SHOW IT shares the races (1), only a faster run replaces (1),
  the stamped START centred like the stamp (1).
- **Full suite** after merging `lead-merge`: see "Suite" at the end.

## Smoke run and the two-game net test

- `tools/ghosts_smoke.gd` (real sandbox and visit scenes, the fake server): **36 checks, 0 failed**. Found by its
  first run: my own course lane was 9 blocks wide, too big for a gift (8 at most) — the tool's fault; the lane is 7
  wide now.
- `tools/ghost_net_test.sh --server=127.0.0.1:7790` (two headless games, the real Nakama client, my private server
  with module 0.2.6): **GHOSTNET PASS** — Hopper asks, Mia says yes, Hopper's showcase and race go up, Mia's
  `list_ghosts` sees it, she visits (the real visit scene), his ghost waits on his START in his look with no
  collision, she beats it ("You beat GhH…'s ghost!  GOLD!"), leaves a trophy he reads, finds the showcase kept for
  offline races; both test accounts are deleted. Found by its first runs: a GDScript lambda captured the friend's id
  by value (the known gotcha; an array carries it out now), and Mia deleting her account right after her sticker
  took the sticker away before Hopper looked (she now waits until he is done).
- **My own server**: compose project `easycraft_ghosts` (containers `easycraft_ghosts-postgres` /
  `-nakama`, an override file for the names), ports 127.0.0.1:7789–7791, this worktree's module build; removed with
  `docker compose -p easycraft_ghosts down -v` when done. The lead's `easycraft` server was never touched.

## Measurements (this PC, shared; load average given; phones are 3–5× slower)

| What | Result |
|---|---|
| A ghost's frame (`GhostRunner.step`, a 3-minute path) | 7.5 µs (GUT, load ≈ 25) |
| The visit while racing a ghost (smoke, headless) | online: 561 frames, avg 7.1 ms, worst 49.6 ms (load 28.8); offline: 567 frames, avg 7.0 ms, worst 29.0 ms (load 29.2) |
| VISIT to standing on the island (smoke) | 0.88–1.0 s |
| `share_ghost` on the showcase (real server) | 17 ms; `showcase_of` with its ghosts (two calls) 34 ms |
| The biggest `share_ghost` (a gift's 8³ build + a 3-minute ghost wandering) | 7,577 characters, 45–49 ms (real server) |
| A 3-minute ghost's path | 901 samples, 7,208 characters of base64 (the 10 Hz recording is ~14 KB) |

## Rulings (decided on the owner's behalf; each with its cost if wrong)

1. **Whose run:** only the world owner's own best (host or solo; `CourseBook.mine`), not the course's best of
   anyone. *Cost:* a LAN friend who helped build can't share their run from the host's world.
2. **5 samples a second** (half the recording's 10), a jump kept as one sharp step. *Cost:* wiggles shorter than
   0.2 s are smoothed in the ghost.
3. **The showcase takes the courses in its frame along** at SHOW IT (the most lately raced, one per course, at most
   3); a new showcase (or none) takes them down on the server. *Cost:* a 4th course isn't shared; after moving the
   showcase the child must race again or SHOW IT again with the courses inside.
4. **A new own best replaces its ghost by itself** (only when faster than the one there, signed in, friends
   allowed; a refusal is silent). *Cost:* a course changed since SHOW IT is refused by the server (its copy of the
   showcase is older); SHOW IT again fixes it.
5. **A gift carries a race only when the picked build holds the whole course** (START and FINISH) and the run stays
   within the build's box and 4 blocks. *Cost:* a course bigger than 8³ goes only on the showcase.
6. **The server's plausibility limits:** ≤ 40 m/s (the game's fastest move is a launch pad's 30; `test_race_ghost`
   checks every speed constant against it), a block of slack a step, jumps only onto a START, CHECKPOINT or
   TELEPORT_PAD top (≤ 3 blocks), ≤ 64 jumps, the box + 4 aside / 24 up / 16 down. *Cost:* a future faster move
   needs the limit raised in both `ghost_rules.ts` and `race_ghost.gd` (the tests compare them).
7. **Medals against a ghost:** its time is gold (as fast counts), ×1.3 silver, ×1.6 bronze, like a course's first
   goals; slower is "finished" (a star, "got there first. Race again!"). The builder's own goals are not used for a
   ghost race. *Cost:* a builder's custom goals don't apply when racing a ghost.
8. **Names:** "Mia's ghost" for 13+ and for under-13 with verified consent; "A friend's ghost" otherwise (offline:
   the last answer this device knew). *Cost:* none known; visiting needs consent anyway.
9. **Ghosts race on this game only** (never synced): a guest in a host's world doesn't see the host's downloaded
   ghosts, and a guest's stamp brings no race (the world is the host's). *Cost:* friends playing together can't race
   one ghost side by side.
10. **A gift's race waits where its stamp was stamped** in the child's own world, kept per world (slot and seed), only
    while its START is there. *Cost:* a mirrored copy of the stamp has no ghost.
11. **The ghost is blocky in both graphics styles** (the look's own shape; cheaper than a skeleton on a phone).
    *Cost:* in REALISTIC style ghosts look blocky.
12. **Visits: the friend's courses work there**, timed by the visitor's own game (a visit is its own world; nothing
    is saved); the race clock and toasts sit 60 px lower in a visit (under its bar). *Cost:* none known.
13. **On the device:** ≤ 12 ghosts and ≤ 6 friends' showcases (the least lately raced go first), kept until the
    online account is deleted or that friend is reported; never in the profile backup. *Cost:* a 7th friend's
    showcase pushes the oldest out.
14. **Offline way in:** FRIENDS' RACES on PLAY ONLINE's can't-connect page (no new HUD button, as allocated).
    *Cost:* a child offline has to open PLAY ONLINE to find it.
15. **Reports:** no new button — the visit's REPORT (the showcase report keeps its ghosts) and PRESENTS' REPORT
    (the gift's ghost goes with it) cover ghosts; `report_build` also takes `what: "ghost"` (the server's copy by
    `ghost_id`) for later use. A report forgets that player's ghosts on this device. *Cost:* a single ghost can't be
    reported apart from its showcase.
16. **Limits:** 12 shares an hour (`limits/ghosts`), gifts with a race use the gift window (30 an hour), the call may
    be 16 KiB. *Cost:* a child beating their time more than 12 times an hour stops replacing until the hour passes.
17. **Keeping and deleting:** showcase ghosts live as long as the showcase (no separate expiry); a gift's ghost lives
    in its gift object (60 days unopened, gone with the sender's account); `ghosts` goes with the account. *Cost:*
    none known.
18. **Compatibility:** the module only adds (two RPCs, a `ghost` field when present, `what: "ghost"`). A new game on a
    0.2.5 server: SHOW IT still works (no race shared, the plain toast), a visit has no ghosts; an old game on 0.2.6:
    unchanged. *Cost:* none known.
19. **My own server** for the real-runtime checks (the brief allocated none): compose project `easycraft_ghosts`, ports
    7789–7791, removed afterwards. *Cost:* none; the lead's `easycraft` server was not touched.

## Deploy (the lead)

1. After merging: `npm --prefix server/modules ci && npm --prefix server/modules test` → 252/252.
2. Development server: in `lead-merge`, `npm --prefix server/modules run build`, copy
   `server/modules/build/index.js` into the main checkout's `server/modules/build/`, `docker restart easycraft-nakama`,
   `docker logs easycraft-nakama 2>&1 | grep "module 0.2.6 loaded"`; then
   `EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server` (38/38) and
   `tools/ghost_net_test.sh --server=127.0.0.1:7350` (GHOSTNET PASS).
3. Live server: `server/deploy/kit.sh pack`; `scp -i ~/.ssh/easycraft_hetzner build/server/easycraft-server-<date>.tar.gz
   easycraft@178.104.20.64:`; on the server `tar -xzf easycraft-server-<date>.tar.gz -C ~/easycraft && cd
   ~/easycraft/server/deploy && ./kit.sh update`; `./kit.sh logs nakama` shows `easycraft module 0.2.6 loaded
   (production)`; `./kit.sh check`. Optional from the PC: `tools/ghost_net_test.sh --server=https://178-104-20-64.sslip.io`
   (two throwaway 13+ accounts, deleted at the end).

## What to check on the emulator (the lead; desktop + emulator, both signed in, friends)

1. **Desktop, a Sandbox world:** build a small course (START, a lane, FINISH), race it (the race clock, a gold
   medal). MORE → SHARE → MY SHOWCASE with the course inside the golden frame → SHOW IT → "Friends can visit it and
   race your course." Race again faster → "Your new best is on your showcase: friends can race it!"
2. **Emulator:** PLAY ONLINE → FRIENDS → the desktop's row → VISIT: a see-through runner in the desktop player's look
   (both graphics styles: it is blocky) stands on the START with "<name>'s ghost" (13+) over it; step on START (the
   clock reads 0:00.0), step off: the ghost runs; its steps look smooth, it never blocks you (walk into it) and a
   sword or blaster passes through it; at FINISH the medal against its time and "You beat …'s ghost!" or "… got there
   first. Race again!"; the race clock and the toasts sit **under** the visit's STICKER / REPORT / LEAVE bar.
   **Frame times** while the ghost runs (headless worst was 50 ms at load 29).
3. **Emulator offline** (airplane mode): PLAY ONLINE → "Can't reach the game" → FRIENDS' RACES → the friend's name →
   the same visit and race, no server.
4. **Desktop:** SHARE → GIFT A BUILD → tap the course (≤ 8 blocks long): "Your race comes too!" → the emulator's
   name. **Emulator:** PRESENTS "… and a race!" → OPEN ("Stamp it and step on START to race!") → in a world, the
   GIFTS tab → stamp it → "<name>'s ghost came with it! Step on START to race." → race it; leave and reopen the world:
   the ghost waits there again; break the START: it is gone.
5. **An under-13 account with consent** sees names; switch consent off in the grown-up area (or use a child without
   consent) and FRIENDS' RACES shows "A FRIEND" and the ghost says "A friend's ghost".
6. **REPORT** in the visit: the console's `reports` object has `ghosts`; PRESENTS' REPORT on a stamp with a race:
   `ghost` with `source: "reporter"`; the emulator forgets that friend's ghosts.
7. **Delete my online account** (grown-up area): `user://ghosts.json` is gone; the server's `ghosts` too.

## Merge notes (what may conflict)

- `server/modules/src/main.ts` (version, two registrations), `tsconfig.json` (two files), `src/server/gifts.ts`
  (WHAT, `list_gifts`, `giftOut`, `publish_showcase` ×2, `report_build`, `reportGhosts`), `deletion.ts` (one line);
  version assertions in `gifts_rpcs`, `wallet_host` and three integration files.
- `net/online_service.gd` (7 hook lines + a section at the end), `core/gifts/gift_rules.gd` (2 places),
  `ui/gifts/share_panel.gd` (4 lines + a section), `ui/gifts/gifts_page.gd` (2 lines), `ui/online/play_online_screen.gd`
  (1 line + a section), `world/visit/visit_world.gd` (1 line + a section), `ui/hud/hud.gd` (2 lines + a section),
  `world/course_director.gd` (4 changed lines, `_state`'s `start`, `info_of`'s `mine_ms`, `_on_state`'s filter, a
  section), `core/rules/course_book.gd` (the `own` argument and a section), `scenes/sandbox.gd` (1 line + a section),
  `entities/player/block_interactor.gd` (1 line + a signal), `tests/fakes/fake_online_server.gd` (6 lines + a
  section), `tests/unit/test_gift_rules.gd` (1 assertion).
- No block or item ids, no HUD button, no Session section (none was needed).

## Suite

After merging `lead-merge` (#41 more animals, Nell, fixes) and `--import`: `tests/run_tests.sh` exit 0, **536 scripts,
5155 tests, 5153 passing, 0 failing**, 2 risky (owner #45b's `test_the_column_cache_changes_nothing` and
`test_chunks_meet_without_seams` did not assert: not this task's), 869 s at load ≈ 25–33. This task adds 63 tests
(the same tree without them: 5092). Node: **252/252** (231 before). After the merge also: the smoke run 36/36 (the
visit's worst frame 31.5–34.6 ms at load 33) and `tools/ghost_net_test.sh` GHOSTNET PASS on the private server, which
was then removed (`docker compose -p easycraft_ghosts down -v`).
