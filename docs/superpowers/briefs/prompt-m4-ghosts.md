# M4 — ghost races on friends' courses (M4 plan: "Ghost races on friends' courses follow M3 Task 7")
(House rules: `docs/superpowers/briefs/m4-common.md`. Start from main after the night's merges.)
Read `docs/devlog/parts/m3-task-7.md` (Game Blocks, courses, races, recorded runs), `docs/devlog/parts/m4-i.md`
(showcases, gifts: how a friend's build reaches another friend, and the server module's storage rules), M4
Waves 1–2 notes (accounts, friends, consent by age), `server/modules/` and its Node tests.
Build, test-first:
1. A player's **best run** on a course they built (the recorded path, M3 Task 7) can be shared with friends as a
   **ghost** in the showcase (M4 I: a friend visits the showcase and races the ghost there) or sent with a
   blueprint gift. The server keeps a ghost small (sampled path, a size cap), friends only, the same consent and
   age rules as showcases, and reports cover ghosts too.
2. **Racing a ghost:** a translucent avatar (the friend's look, no name for under-13 viewers without consent)
   runs the path; START/FINISH as in Task 7; medals against the ghost's time; your own best can replace
   your ghost on your showcase. Works offline against ghosts already downloaded.
3. Server module bump (0.2.5): `share_ghost`, `list_ghosts`, validation (path length, time plausible: no
   teleports, speed ≤ the game's max), rate limits, deletion with the account. Node tests first.
4. Everything fair: ghosts never block, can't be collided with, no leaderboard strangers see.
Tests: GDScript (sampling, playback, medals, UI), Node (validation, friends-only, caps, deletion), a two-instance
net test. Notes: `docs/devlog/parts/m4-ghosts.md`. The lead deploys the module to the dev server and the live
server (`server/deploy/kit.sh pack` → scp → `./kit.sh update`). Suites through the slot gate.
