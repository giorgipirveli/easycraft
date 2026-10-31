# RESUME HERE — state of the whole roadmap (saved 2026-09-24 20:05; updated 21:42)

**2026-10-18 08:05 — RUNNING.** Live: **1.0.7** (`bb6dd646`: web, VR, Pages; Android files in `~/Downloads`; the Play
upload waits for the owner's yes): learning in the world (W1, DISCOVER = Hoot's pick), the voice on by default, the Glow
Caves, the play place's garden and five dressed rooms, **the Android updater's first bases** (phone and Quest
`bb6dd646`, backed up in `~/.local/share/easycraft/android-bases/`). **1.0.8** (`7e22f131`) in its full suite: the unit
page as pictures and voice, the animals' winding fix, Inside a Leaf B1; then **the first patch deploy**
(`tools/export_android_update.sh --dry-run`, then for real, `tools/deploy_android_update.sh` after the web; the emulator's
steps 3-6 of `docs/devlog/parts/same-version.md` §9). Running (3): **Inside a Leaf B2** (the voyage plays; the registry
for every deep game's host; branch from `lead-w1b`), **the rooms' look** (the remaining rooms), **Word Magic phase A**
(English). Approved designs waiting: **Balance Altar B** (after the leaf's B2), **Fraction Bakery B** (after the altar's
B). Owner pages: the leaf https://claude.ai/artifact/UrJscQu53EtVwcCvwehb8n, the altar
https://claude.ai/artifact/DRoDygURZvmxE23znLfgr8, the bakery https://claude.ai/artifact/TbSAPiZBrHzgva4vk98R5D.

**2026-10-18 02:15 — RUNNING. Released 1.0.6** (code 16) from `d258cd72`: the web game, the VR web page, GitHub Pages
(02:03, checked from outside); `~/Downloads/EasyCraft-1.0.6.apk`, `EasyCraft-1.0.6-play.aab` (upload key, verified),
`EasyCraft-quest-1.0.6.apk` (installs on the Quest by itself the next time it is on the cable with the game closed:
a background wait). The suite: 11,732 of 11,736 (one test-order failure fixed in `d258cd72`). The Play upload still
waits for the owner's yes. Merged since: **Play G0** (`670824f5`: the foundation for games that need no reading).
**The plan is `docs/design/future-lessons.md`** (owner #133, #134): depth before breadth, one deep game per agent in
gated phases. Running (3): **Inside a Leaf, phase A** (research and design, highest effort; the lead reviews it and shows
the owner its one-page summary before any code), **Play W1** (integrating G0, then the Academy; its stages 1-2 merge
after an emulator check), **the Android updater** (#123; its second full suite). Paused: the Glow Caves (`c489e01e`),
the rooms' look (`c64838b1`). Next deep games: Balance Altar, Fraction Bakery.

**2026-10-17 23:35 — RUNNING.** The owner tested on the Quest 3 and their child played 30+ minutes: "where is educational
content? nowhere in the game" (#132). Running (3): **Play W1** (learning inside the world: DISCOVER in MORE and the
pause menu + Hoot's first-visit invitation as stage 1, which the lead merges and ships tonight; then discovery crystals,
then the Discovery Academy; brief `2026-10-17-play-w1-world-brief.md`), **Play G0** (every unit a game), **the Android
updater** (#123; in its final suite). **Paused** (resume in this order when a slot frees): **the Glow Caves** (done but
docs, merge, suite: `c489e01e`), **the rooms' look** (5 of 21 rooms: WIP `c64838b1`). Lead tonight (all on lead-merge,
not deployed yet): #123 the build label, the online version check, the web page waits for an update while it
downloads (`72a5ccaa`; its browser check `tools/web_update_slow_check.mjs` not run yet), release 1.0.6 code 16; the
Quest fixes #124 weapons aim along the laser and shots leave the weapon, #126 hands in the rocket, #127 the HUD on a
raised forearm (a shield), #128 a held sword hits by swinging (Quest APK 1.0.6 installed 23:22); #130 13 games removed
from the Quest at the owner's word. **Next:** merge W1's stage 1; a full suite on lead-merge; deploy everything (web, VR,
Pages, Quest, phone APK/AAB 1.0.6) from one commit; then the updater, G0, the Glow Caves, the rooms' look. The Quest's
live log streams to the scratchpad's `quest_live.log` while it is on the cable.

**2026-10-17 21:25 — RUNNING.** Merged since 20:25: **grades 7 and 8 core** (grades 3-8 complete, 818 units), **Success
S3** (the shop, the Market Square; its follow-ups done: How to earn, MY MAP). The lead's emulator check passed (titles,
S2's cards, rooms 54-60 FPS) and fixed Life's lesson-first unit page (owner #122: TRY IT first, the BOOK last), the
Experiences' pictures, the cards' titles under stars. Running (3): **Play G0**, **the Glow Caves**, **the rooms' look**
(brief `2026-10-17-rooms-look-brief.md`). Next: merge them; the deploy after a full suite on the merged tree (it carries
the read-aloud fix, grades 7-8, S3, Life's play-first page); G1 maths' signature games and grade 9 play-first after
G0; after G0 merges, Life's School-linked units open G0's play instead of PRACTICE; the Quest frame rates when the owner
plays.

**2026-10-17 20:45 — RUNNING.** Merged: **grade 8's last 14 core units** (`911738eb`: grade 8 has all 136 units;
**grades 3-8 complete, 818 units**; the 14 School files 137/137 on the merged tree). Running (3): **Play G0** (owner
#122), **Success S3**, **the Glow Caves** (universe 6; brief `2026-10-01-glow-caves-brief.md` with its 2026-10-17
section: page 45, ids 768-783, learning by doing in the caves). Next: merge S3, G0 and the caves; the deploy (with the
read-aloud fix) after a full suite on the merged tree; G1 maths' signature games after G0; grade 9 play-first after G0;
grade 8's 39 older maths/science/English units score 51-73 on the audit (their play-first pass after G0); the Quest
frame rates when the owner plays.

**2026-10-17 20:25 — RUNNING.** Merged: **grade 7's last 14 core units** (`dab483c3`: grade 7 has all 136 units;
804 unit files; the 13 School files 132/132 on the merged tree). Running (3): **Play G0** (owner #122: every unit played,
DISCOVER, the Book; brief `2026-10-17-play-g0-brief.md`), **grade 8's 14 core units** (`g8k`, its final suite), **Success
S3**. Next: merge g8k and S3; the deploy (with the read-aloud fix) after a full suite on the merged tree; G1 maths'
signature games after G0; the Quest frame rates when the owner plays.

**2026-10-17 19:35 — RUNNING. Owner #122 changes how we teach: every lesson is a game** (`docs/design/learning-is-play.md`,
spec §22.0). Deployed 18:03 (L3b, L3c, grade 8). The Quest 3 is on the PC's USB in Developer Mode: the APK installed
(18:48, with the read-aloud fix `71e6322c`); a watcher records frame rates when EasyCraft runs on a worn headset (it
needs the controllers awake: no hand tracking). The owner paused (18:44) and unpaused (18:47) the agents. Running (3):
**grade 7's** and **grade 8's 14 core units** (their final suites; the last card-only content), **Success S3**. Next,
in the first free slot: **Play G0** (brief `2026-10-17-play-g0-brief.md`: every unit playable, DISCOVER, the Book);
then G1 maths' signature games; Success S3's merge; the deploy (with the read-aloud fix) after the next full suite.

**2026-10-17 17:50 — RUNNING.** Merged: **Life L3c** (Online City, Find Your Way, Home Helper; Life Town's third row,
now full: 6 of 8 meadows). Its suite on lead-merge 802d299b + L3c (the merged tree's code exactly): 11,502 passing, 0
failing; **deploying** everything since 09:05. Running (3 agents): **grade 7's 14 core units** (`g7k`), **grade 8's 14
core units** (`g8k`), **Success S3** (the shop, the Market Square as a second plaza). Next: grade 9's outline, L4, VR
round 5, E0; the emulator check (L3a-L3c rooms, S2's cards, the grown-ups' titles, FPS).

**2026-10-17 15:40 — RUNNING.** Merged since 14:20: **grade 8 health/D&T/projects** (`d648b8f6`; grade 8 has all
twelve subjects; the 20 shared School files 331/331 on the merged tree). Still **not deployed** (waiting for a full suite
on the merged tree). Running (3 agents): **Life L3c** (in its final suite), **grade 7's 14 core units** (`g7k`), **grade
8's 14 core units** (`g8k`). Next: Success S3 (brief `2026-10-17-success-s3-brief.md`, after L3c merges), grade 9's
outline, L4, VR round 5, E0.

**2026-10-17 14:20 — RUNNING.** Merged since 09:00: **grade 8 humanities** (`3a9c7347`), **Life L3b** (`1b26c38f`:
electricity, animals, medical emergencies, fire and heat; Life Town's second row with Success's four places), **grade 8
computing, art, music**. On the merged tree the 15 shared files pass 260/260; **not deployed yet** (the deploy waits for
a full suite on the merged tree: the agents' own, which take lead-merge in). Running (3 agents): **grade 8 health/D&T/
projects** (`g8l`, in its final suite), **Life L3c** (Online City, Find Your Way, Home Helper; brief
`2026-10-17-life-l3c-brief.md`), **grade 7's 14 missing core units** (`g7k`). Next: grade 8's 14 missing core units,
grade 9's outline, Success S3 (the shop, the Market Square), L4, VR round 5, E0; the Quest install when the owner's
headset is in Developer Mode and on the cable.

**2026-10-17 09:00 — RUNNING.** Merged since 04:40: **Life L3a** (safe mistakes, the time scale, intensity, the
debrief; Water Safety, the Poisons Cupboard, Earth and Weather). The lead fixed one merge seam (`5348fe1f`). Running (3
agents): **grade 8 humanities** (`g8h`), **grade 8 computing, art, music** (`g8c`), **Life L3b** (electricity, animals,
medical, fire and heat; Life Town's second row with Success's places). Deploying S2 + grade 7 + L3a. Next: grade 8
health/D&T/projects (`g8l`), Life L3c (Online City, Find Your Way, Home Helper), grade 7's remaining core units, Success S3,
VR round 5, E0.

**2026-10-17 04:40 — RUNNING.** Merged since 22:00: **Success S2** (Goals & Habits, Talk & Deal, the Connections Book,
Success Stories) and **the School's grade 7 D&T, Health and PE, Projects** (grade 7 has all twelve subjects). Running (3
agents): **Life L3a** (safe mistakes, water, poisons, earth and weather; told to merge S2's test counts in), **grade 8
humanities** (`g8h`), **grade 8 computing, art, music** (`g8c`). The lead's full suite on S2 + grade 7 runs. Next: grade 8
health/D&T/projects (`g8l`), Life L3b (brief written; after L3a), Life L3c (Online City, Find Your Way, Home Helper), the
Tool Book's calendar and jar (S2's; after L3a), grade 7's remaining maths/science/English units, VR round 5, E0.

**2026-10-16 22:00 — RUNNING again** (the owner, 21:41: "continue work"). Merged Life L2, Tools (round 4b) and VR-WONDER;
the lead wired Real Builder into Life (its building site in Life Town, the Tool Book). Running (3 agents): **the School**
(grade 7: D&T, health and PE, projects), **Life L3a** (safe mistakes, water, poisons, earth and weather), **Success S2**
(goals and habits, Talk & Deal, connections, stories). The lead's full suite on everything merged: **11,037 passing, 0
failing**; deployed 23:10-23:21 (`/vr/`, `/play/`, Pages, the Quest APK). 23:12 the session limit stopped the agents;
02:41 all three resumed. Briefed next: Life L3b (after L3a); grade 8 in three agents (`g8h`, `g8c`, `g8l`).
Next: grade 8's nine missing subjects, Life L3b (electricity, animals, medical, people and places), VR round 5, E0.

**2026-10-16 21:34 — PAUSED (owner #119: "pause all agents").** All three agents stopped; nothing runs. Each had
finished its work and was in its final full suite; every branch is committed and clean:
- **Life L2** `worktree-agent-life-l2` @ `85062446` (18 commits ahead: Safe Streets, The Kitchen, Calm Corner, Life Town,
  the follow-ups, the flaky room test hardened); its notes `docs/devlog/parts/life-l2.md`.
- **VR-WONDER** `worktree-agent-a31292368d2c108aa` @ `f8119f4d` (7 ahead: hold a planet, the telescope and magnifier, the
  Lab bench; items 500-501); notes `docs/devlog/parts/vr-r4-wonder.md`.
- **Tools (round 4b)** `worktree-agent-a090e57ad7626a49c` @ `ee39bec9` (14 ahead: the ten motion recognisers, the device
  run, the Tool Book, Real Builder, its review sheet); notes `docs/devlog/parts/tools-r4b.md`.
**On resume:** the lead reads each branch's notes, merges them one by one (expect docs conflicts: keep both; Tools
adds one Life catalogue entry beside L2's), runs one full suite on the merged tree, deploys. Live now (20:30-20:42):
Life L1, VR-SOUND, VR-HANDS on `/play/`, `/vr/`, GitHub Pages and the Quest APK. Then the queue: the School's next grades
(#111), Success S2, Life L3 (with #118's safe mistakes), VR round 5, the ease audit (E0).

**2026-10-16 19:25 — the state.** Merged today: accounts (#104/#105, live), the Moon landing (#106, live), VR rounds
1-4 (hands, the keyboard, P5 72 Hz and vr_plus, VR-HANDS' grab and building by hand #116, VR-SOUND's instruments and
cockpit), the cars (#109), Life L1 + Success S1 (#112-#115). Live: `/play/` and `/vr/` 16:29-16:38 (P5 + the cars); the
Quest 3 APK in `~/Downloads`. Running (3 agents): **Life L2** (Safe Streets, The Kitchen, Calm Corner, Life Town),
**VR-WONDER** (round 4), **Tools** (round 4b: the ten motions, the device run, the Tool Book, Real Builder). The lead's
full suite on everything runs; then the deploy (Life, the instruments, building by hand). Next in the queue: the
School's next grades (#111), Success S2, VR round 5, the ease audit (E0). The headset run waits for the owner's
Developer Mode (then P5's two levers). Designs: `docs/design/life-skills.md`, `success-skills.md`.

**2026-10-16 08:57 — VR RESUMED (owner #108: "i have quest 3. download and make it rady" / "continue and finish vr").**
The owner said yes to the downloads; the headset is a Quest 3. Running: VR-RIG round 3 (P4, `worktree-agent-af972211a2b1e38dd`)
and VR-UI round 2 (P2, `worktree-agent-a7347d9754abec8dd`), resumed from their WIP with the latest lead-merge; the lead installs
the OpenXR Vendors plugin and Monado, builds the Quest 3 APK and opens `/vr/` (the merged Caddyfile and compose, Caddy
recreated). Then P5 (72 Hz, `vr_plus` for Quest 3). **09:20 `/vr/` live; the Quest 3 APK in `~/Downloads/EasyCraft-quest-1.0.5.apk`
(waits for the owner's Developer Mode + USB-C). 09:45 running (3 agents): VR-RIG round 3 and VR-UI round 2 (their full
suites), the P5 agent (brief `2026-10-16-vr-p5-brief.md`).** 11:30 VR-UI round 2 and VR-RIG round 3 merged; running: P5, the cars agent (#109, brief
`2026-10-16-cars-brief.md`), the VR ideas research (#110: `docs/devlog/parts/vr-ideas-research.md`). **After VR and the cars:
the School to the full programme (#111).** 11:50 **Life skills designed (#112, #113)**: `docs/design/life-skills.md`,
spec §27, roadmap §7; **Life L1's brief ready** (`2026-10-16-life-l1-brief.md`): it starts in the first free agent slot
(the VR ideas research is the next to finish). The Classroom is the future, not now (#114). 12:00 **Success designed (#115)** (`docs/design/success-skills.md`); the
VR ideas research done (#110, `docs/devlog/parts/vr-ideas-research.md`); **running: VR P5, the cars (#109), Life L1 +
Success S1**; **VR round 4 planned** (`2026-10-16-vr-round4.md`: the frozen grab contract, VR-HANDS next free slot, then
VR-WONDER, VR-SOUND). The lead's full suite on the merged VR: 10,226 passing, 0 failing; the contract's stubs `9fb0c96e`; `/vr/`, `/play/`,
the Quest APK updated 12:56-13:09. 14:50 **merged VR P5** (draws 155-179 → 69-103; vr_plus for the Quest 3) and **the cars
(#109, eight kinds)**; running: **Life L1 + Success S1**, **VR-HANDS**, **VR-SOUND** (round 4); the lead's full suite on
P5 + the cars. Waiting for the first headset run: P5's lever `voxel/threads/main/time_budget_ms.quest=3` (measure
first), the cars' VR checks. This PC's network intercepts HTTPS (a FortiGate): live checks from here fail; the owner told. Next: the lead's full suite, a new
Web VR build (`tools/export_web_vr.sh`, `tools/deploy_web_vr.sh`: no Caddy restart) and a new Quest APK. Other work (reels 3, visuals 2, the Glow Caves) after VR ("when this is
done we continue other remaining works", #101).

**2026-10-16 07:27 — HOLDING (owner #102/#103), the owner's direct orders done and live.** Nothing runs; no cron.
After the stop the owner gave three orders, now all live: **#104** LOG OUT with no gate and a DELETE that deletes,
**#105** a password with the name, LOG IN with name + password, one device at a time, **#106** the Moon landing flown by
the child and a crash's cost (live 03:41). #104/#105 (and #99's ask on a taken name): merged `890e3443`, server module
**0.2.20 live 07:20**, the web game deployed 07:27 (`5dcf9fd0`; the live LOG IN test PASS); **Android 1.0.5 (code 15)** built 07:40 with all of it
(`~/Downloads/EasyCraft-1.0.5.apk`, `EasyCraft-1.0.5-play.aab`; checked on the emulator: LOG OUT with no gate, LOG IN back); **the Play
upload waits for the owner's yes**. The server's integration tests: 13 old failures that expect the age
rules 0.2.13 turned off (debt to clean up some day). **Do not start new work until the owner says so.** Then, in order:
(1) VR-RIG round 3 (P4, WIP `56bf7ea3` on `worktree-agent-af972211a2b1e38dd`: docs, two tests, a mutation check, the full
suite) and VR-UI round 2 (P2, WIP `2c3324a9` on `worktree-agent-a7347d9754abec8dd`: merge lead-merge, the full suite);
(2) `/vr/` (the owner's go: the kit with the merged Caddyfile and compose, which recreates Caddy); (3) reels round 3,
visuals round 2, the Glow Caves, the forever roadmap. **Waiting on the owner:** the go for `/vr/`; half the hearts in the
Sandbox too (now Survivor only, one line); which Quest, Developer Mode, yes to the 3 downloads (OpenXR Vendors plugin 5.1.0,
Monado, the Khronos OpenXR loader AAR); a parent e-mail for forgotten passwords (none is kept now).

**2026-10-15 22:26 — STOPPED (owner #103: "stop all works").** Nothing runs. On resume: (1) the lead's full suite on
lead-merge (VR P1 + P3 merged, the focus pause `313abc17`; the 22:00 run was killed half-way), then deploy the web and `/vr/`
(the Caddy change); (2) VR-RIG round 3 (P4) and VR-UI round 2 (P2) from their WIP commits; (3) #99's fix round from
`docs/devlog/parts/accounts-99-review.md`, a second review, then the merge and module 0.2.20; (4) the queue below.

**2026-10-15 22:05 — HOLDING (owner #102: "dont start new works untill i tell you").** The cron is deleted; nothing new
starts. Finishing only what runs: VR-RIG round 3 (P4: hands, `vr_pose`), VR-UI round 2 (P2: readability, keyboard, wrist HUD,
break card, dashboard), the adversarial review of #99 (branch `worktree-agent-a45831f837d05a838`, module 0.2.20, not
merged), the lead's full suite on the merged VR P1+P3 (`313abc17`). Their results get merged and tested; **no deploys**
(the web, `/vr/` with its Caddy change, the module 0.2.20) until the owner says to continue.
- 22:24 **#99's adversarial review: NOT mergeable** (`docs/devlog/parts/accounts-99-review.md`): HIGH, the move's parent gate
  is a no-op in shipped builds (`AgeBand.restrictions` false) and chat lets a 6-digit code through, so a stranger can
  talk a child into typing a code, take the account and sign her phone out; MEDIUM, ask-flooding blocks a family's move,
  LOG OUT never removes a player from a shared tablet, a switch during a reconnect can mix players' profiles and gold, a
  failed write mid-switch; LOW, retention and deletion leftovers, the store drafts. **On resume:** send the accounts agent
  the fix round (the review's fixes, test-first, with its 9 reproducing tests), then a second review, then merge.

**2026-10-15 17:30 — RESUMED (owner #101): "continue work we stopped … start in parallel working on VR mode, I have meta
quest … this is now N1 priority".** The keep-going cron is back (:17 and :47). **Priority 1: VR on the Meta Quest** (2 of the
3 agent slots): research and design (`vr-research` workflow: the platform, the game's adaptation, the budget) → spec §3b + a
plan (`docs/superpowers/plans/2026-10-15-vr-*.md`) → build. **Slot 3, in order:** #98 the rocket easier (brief
`2026-10-15-rocket-easier-brief.md`), #99 log in/out and the device switch, reels 3 and visuals 2, the Glow Caves. The lead
merges Ganymede (its suite passed) and keeps the docs.
- 18:02 Ganymede merged, censused and deployed. 18:07 running: **VR-RIG** and **VR-UI** (P0-P1, brief
  `2026-10-15-vr-agents-brief.md`, plan `2026-10-15-vr-quest.md`) and **the rocket** (#98). Waiting on the owner: which Quest,
  developer mode, yes/no to downloading the Godot OpenXR Vendors plugin 5.1.0 and Monado.

**2026-10-14 22:49 — PAUSING again (owner #100: "please pause works after finished running tasks"). The keep-going cron is
deleted. Running until they end, nothing new after: the #98 understanding workflow and Ganymede's full suite; their results go
below. Resume from the queue under 22:31 when the owner says to continue.**
- 22:52 the #98 understanding workflow finished: findings and the proposed design in `docs/devlog/parts/rocket-easier.md`
  (next: settle the design, build it test-first, review, merge).
- 23:34 Ganymede's full suite: 9771/9773, 0 failing: **ready to merge** (then the census, the smokes, the deploy).
- **23:35 paused: nothing runs.**

**2026-10-14 22:31 — RESUMED, non-stop (the owner: "continue non stop work to finish full plan, set goals and everything
for that"). A keep-going cron fires at :17 and :47 (session-only; re-create it if the session restarts; it expires after 7
days). At most 3 agents at once (workflow agents count). The queue, in order:**
1. **#98 the rocket easier** (owner 22:13): workflow `rocket-easier-understand` running (the child flow, the cheapest passing
   rockets per mission and crew, placing parts on the pad), then design → implement (TDD) → adversarial review → merge:
   Mission Control's ready plan per mission (BUILD IT FOR ME, built layer by layer with a line per stage), buying on the MY
   ROCKET page in one tap, the gold still needed said plainly.
2. **#99 log in, log out, the same name on a new device** (owner 22:22, 22:27): typing a claimed name asks "Is this you? Move
   your game here?"; proof by a YES on the other device or the key (never the name alone); LOG OUT after the account is
   saved on the server; LOG IN.
3. **The paused branches:** Ganymede (full suite, merge, census), reels round 3 (full suite, merge), visuals round 2 (notes,
   bench, the mixed-order failures, full suite, merge, census).
4. **The Glow Caves** (brief `2026-10-01-glow-caves-brief.md`), then the forever roadmap (cosmos: Callisto…; universes 7-8;
   School quality up to grade 7; visuals; the emulator's Moon flight on a quiet GPU).

**2026-10-01 21:05 — PAUSED by the owner (#97: "please pause for the moment the works"). Do not resume agents until
the owner says so. Branches waiting: `worktree-agent-a1926aaadcc0732ee` (Ganymede, done; re-run its full suite, then
merge), `worktree-agent-a6dba18cfb42ddc4e` (learning reels round 3: all 16 reels done, its full suite to run), `worktree-agent-a5b99f014331139d2` (visuals
round 2: all five items built, notes and the full suite to do). Details: the devlog's 21:12 entry. Next after them: the Glow Caves (brief `2026-10-01-glow-caves-brief.md`).**

**2026-10-01 20:10 — after the weekly limit: everything up to MAKE MY SHORT and module 0.2.19 is live (13:36);
1.0.4 (code 14) APK and Play bundle in `~/Downloads` (the Play upload waits for the owner's yes and the Theater forms
decision). Agents (3, resumed 20:02): Ganymede (world 28, page 43, ids 736-751), learning reels round 3 (16 reels for
maths, English, history, geography, computing, music, art), visuals round 2 (the Vulkan leaf cost, clouds, caves and
night, REALISTIC's materials, particles). Lead's queue: re-measure the Moon's and world 41's flights on a quiet GPU (20:05
looked bad under agents' window renders), the census after the visuals/Ganymede merges, the next APK with MAKE MY SHORT.**

**2026-09-30 23:35 — owner #95 built (sign in again by itself; an update downloads the whole game before it takes
over; suite 35 running, then deploy with grade 7 humanities). Owner #96: "reels high quality; implement visuals, video,
animation tools and use them"**: the Shorts agent was told (style guide, quality checker, `tools/reel_preview.gd` frame
sheets, pluggable actors); **next agent when a slot frees: the Reel Studio** (brief `2026-09-30-reel-studio-brief.md`:
`scene3d` actor, Movie Maker → ffmpeg Theora `.ogv`, cinematic reels, a reels pack). ffmpeg with libtheora is on this PC.

**2026-09-30 22:15 — OWNER #94: "pause lessons on grade 7; game improvement, lessons quality up to grade 7, more
animations, TikTok-like educational Shorts in the TV shows room".** Grade 7 paused: the health/D&T/projects and the
maths/science/english-gaps agents stopped, their work in WIP commits on their branches (`worktree-agent-abf2fe0060bd47d21`,
`worktree-agent-acc7de6fbcff02718`) for later; grade 7 humanities had finished (merged after suite 34, a ruling).
Agents (3): **EasyCraft Shorts** (spec §5.12b, brief `2026-09-30-shorts-brief.md`), **lesson quality** grades 3-6 + 7's
written (brief `2026-09-30-lesson-quality-brief.md`), **animations** (brief `2026-09-30-animations-brief.md`). Merged,
live after suite 34: Triton (27). Queue after these: nature's wonders, grade 8 (when the owner resumes lessons), the
emulator re-measure of the frame-spike fixes.

**2026-09-30 18:20 — live 18:17: grades 3-6 complete (546 units, every subject); Saturn's rings (25); crew flights; the
Moon's and Mars's riches; Venus (24); the New Seven Wonders; offline play (#93); the frame-spike fixes.** Agents (3): Pluto
(world 26, page 41, ids 704-719), grade 7 history/geography/citizenship, grade 7 computing/art/music. Queue: grade 7
maths/science/english gaps + health/D&T/projects, grade 8 (97 units), Triton 27, nature's wonders, the emulator check
of the frame-spike fixes (the brief's steps in `docs/devlog/parts/frame-spikes.md`) and the Voxel 4 ms budget trial.

**2026-09-30 12:15 — merged: Venus (24), grade 6 computing/art/music, the New Seven Wonders (world 41's second tour);
smokes 0 fails; suite 29 + web export running, then deploy.** Agents (3): crew flights, mining on the Moon and Mars
(page 39, 672-687), grade 6 health/PE + design/tech + projects (23 units). Queue: grade 6's missing maths 1/science
6/english 6 units, grades 7-8, Saturn's rings 25, Pluto 26, Triton 27, world 41's frame rate + the census, the Moon
re-measure on a quiet PC.

**2026-09-30 11:55 — merged: Venus's cloud city (world 24) and grade 6 computing + art + music; suite 29 running, then
the web.** Agents (3): the New Seven Wonders (world 41, pages 36-37, finishing its suite), crew flights (the brief
`2026-09-30-crew-flights-brief.md`), mining on the Moon and Mars (the prospecting brief, page 39, ids 672-687). Queue:
grade 6 health/D&T/projects and grades 7-8, Saturn's rings 25, Pluto 26, Triton 27, world 41's frame rate (after the
New Seven), the census, the Moon re-measure on a quiet PC.

**2026-09-30 11:10 — emulator re-measure (devlog table): Mars realistic in budget; world 41 the heaviest (39-43 FPS,
slow frames at spawn: after the New Seven merge, blame them with `tools/frame_probe.gd` in world 41 (the big wonders' meshing, or first-seen materials), and run the warm-up census again with a phase for the space and Earth worlds: `data/shader_warmup.json` last ran with the flight, before colonies, aliens and wonders); one rare native crash on Mars (1 in 14, not reproduced; watch).**
Re-measure the Moon on a quiet PC. Crew flights brief written (`2026-09-30-crew-flights-brief.md`); the space
prospecting prompt: the prospecting brief with PART = the Moon's and Mars's riches, IDS = page 39 (672-687).

**2026-09-30 10:15 — owner #93: offline play (`c5f1ef5`).** The browser game now opens without the internet after one
visit (the worker's offline page; `tools/web_offline_check.mjs`: offline reload → menu 7.9 s → SANDBOX spawned); the
no-internet cards say what works alone (`OnlineRules.PLAY_ALONE`). #92 re-tested live: net test PASS. Export running,
then web deploy after suite 28 (server stays 0.2.18). The Android app in airplane mode checked on the emulator
(10:08: menu, the play-alone card, SANDBOX). Agents (3) as below.

**2026-09-30 09:15 — the owner: "limits are reset, so continue full work".** Agents (3): the New Seven Wonders (world
41's second tour, pages 36-37, ids 624-655), Venus's cloud city (world 24, page 38, ids 656-671, a Venus mission row),
grade 6 computing + art + music (`g6c`). Suite 28 (colonies, the ancient wonders, invent flight) running, then the web.
Queue: prospecting on the Moon and Mars, crew flights, grade 6 health/D&T/projects and grades 7-8, the rings 25, Pluto
26, Triton 27, the emulator. Owner decision pending: the Play AAB's Theater.

**2026-09-30 09:45 — AGENTS PAUSED: the account's weekly limit (resets 2026-10-04 02:00 Tbilisi).** The lead finished
and merged the last three agents' work (colony domes #77, the ancient wonders #78 world 41, invent flight §21e; each
smoke 0 fails); suite 28 running, then the web (server stays 0.2.18). Live 06:22 (`cc8defe`): the core loop, robots and
aliens, the Daily Mission and friends, prospecting, controllers, TV shows. After the reset, the queue: the New Seven
Wonders and nature's (the wonders brief), prospecting on the Moon and Mars, crew flights, grade 6's other subjects and
grades 7-8 (the school-subjects brief), Venus's cloud city 24, the rings 25, Pluto 26, Triton 27 (the planet brief),
the emulator (the full loop, the new worlds' frame rates). Owner decision pending: the Play AAB's Theater.

**2026-09-30 04:50 — live 04:37 (`6aa41cf`): the core loop end to end (learn/invite → gold → buy → build → fly the
rocket → land), controllers, prospecting on Earth.** Server 0.2.17. On lead-merge (suite 26 running, then deploy):
robots and aliens (#86). Agents (3): the Daily Mission + postcards + gifts + friendship + crews (module 0.2.18), the
colony domes (#77, page 31), the ancient seven wonders (#78, world 41, pages 33-34, MAX_UNIVERSE 60). Owner decision
pending: the Play AAB's Theater (forms or off). Next briefs: the new seven wonders and nature's, invent it (§21e: the
kite to the rocket in Survivor), crew flights, prospecting on the Moon and Mars, grade 6's other subjects and grades
7-8, more planets (Venus's cloud city 24, the rings 25, Pluto 26, Triton 27), the emulator (the full loop, the new
worlds, frame rates).

**2026-09-30 03:45 — THE CORE LOOP FLIES END TO END on lead-merge** (the mission smoke: build → buy 1040 gold → LAUNCH
→ the rocket flight → "Mission complete!" on the Moon → HOME; 0 fails). Live 02:36 (`f6d0cfa`, server 0.2.17): invites,
gold, the Gold Shop, missions, the TV shows. On lead-merge, suite 24 running: the rocket flight + the real landing
(#87) + the wiring, the grown-ups' hard-history note. Waiting to merge after suite 24: **game controllers**
(`worktree-agent-a42149d931c2cc0d2`, rebased on a2979233; then give the flight its pad bindings: steering and boost as
input actions in `GamepadRules.BINDINGS` + `tools/setup_input_map.gd`, `PadFocus.take` on the flight's cards) and
**prospecting on Earth** (page 35, when its suite ends). Agents: prospecting (finishing), the Daily Mission + friends
(module 0.2.18), robots and aliens (#86). Next briefs: colonies (#77, page 31), wonders (#78, pages 33-34), invent it
(§21e), crew flights, grade 6's other subjects; the emulator re-measure and the full loop on the emulator.

**2026-09-30 01:55 — live 01:42 (`0f04230`): the core loop's first half: earning gold by learning, the invite program
(server module 0.2.16 live), the Gold Shop, the rocket missions; also #92's online fix, the planet guide, the moving
Star Map.** On lead-merge (suite 23 running): the TV shows (77 real videos; module **0.2.17** to deploy: `kit.sh pack`
→ scp **the printed path** → untar → `server/deploy/kit.sh update` → `docker compose … up -d --force-recreate caddy`
(the Caddyfile's `/tv/` without COEP) → `kit.sh check` shows 0.2.17; `curl -sI https://178-104-20-64.sslip.io/tv/` 200
without Cross-Origin-Embedder-Policy). **Owner decision** before the next Play AAB: the Theater now plays (Data safety
and Families answers, or `"enabled": false` for that build). Agents: the rocket flight (+ the Star Map's real
landing), game controllers, prospecting on Earth (page 35). Next briefs: robots and aliens (#86), colonies (#77, page
31), wonders (#78, pages 33-34), invent it (§21e), crew flights, the Daily Mission card and friendship levels (#85),
grade 6's other subjects; the emulator re-measure (Mars, Europa, Io, Titan, Mercury; the autopilot ghosts now).

**2026-09-30 00:10 — owner #92 (online broke when a friend joined) fixed on lead-merge (`13cd980`): a guest's own
freeze never counts as the host's silence (15 s), a host streams round a friend no further than round itself; net
tests --big, --freeze, --drop, live: PASS.** Suite 21 running, then deploy. Waiting to merge: earn + invite + Gold
Shop (`worktree-agent-a5ab0068a22292a64`, clean trial merge; then deploy server module 0.2.16 with `kit.sh pack` → scp →
untar → `server/deploy/kit.sh update` → `kit.sh check`, then the web). Agents: rocket missions, rocket flight (+ the
real landing for the Star Map's LAND, #87), TV shows (module 0.2.17). Also on lead-merge since the 22:21 deploy: the
planet guide (#88), the moving Star Map (#91), PC mode polish. Queue: controllers (#90), robots and aliens (#86),
prospecting (#80), colonies (#77), wonders (#78), grade 6's other subjects, the emulator re-measure.

**2026-09-29 22:30 — live 22:21 (`ece9d07`): Mercury, the PC game (#84), label the diagram, grade 5 complete.** On
lead-merge (suite 19 running, then deploy): grade 6 history + geography + citizenship. Agents (3, the core loop first,
#79): earn + invite + the Gold Shop (server module 0.2.16 to deploy with it), rocket missions (page 32, ids 560-575),
the rocket flight (`RocketFlight.start(rocket, from)`, movie-style moments #86). Wire at merge: the Mission Board's
LAUNCH → `fly` → `RocketFlight`; the Gold Shop's rocket shelf ← the missions' price table. Next briefs: robots and
aliens (#86), prospecting (#80, page 35), colonies (#77, page 31), wonders (#78, world 41, pages 33-34), grade 6's
other subjects, the emulator re-measure (the autopilot now ghosts in Survivor).

**2026-09-29 21:10 — THE CORE LOOP IS FIRST (owner #79, "very important"; the roadmap §0, spec §25).** Earn gold by
learning, puzzles and inviting new players → buy the rocket's parts → build it (the real check) → sit at the controls
and fly to the Moon (real animations and visuals). Agent order as slots free: (1) earning + invites
(`2026-09-29-earn-invite-brief.md`, server module bump), (2) missions (`2026-09-29-missions-brief.md`, page 32, ids
560-575, parts cost gold), (3) the flight (`2026-09-29-rocket-flight-brief.md`, `RocketFlight.start(rocket, from)`);
then prospecting and mining (#80, spec §26, `2026-09-29-prospecting-brief.md`: Earth first; give it page 35, ids
608-623), colonies (#77, page 31), wonders (#78, world 41, pages 33-34), invent it (§21e), crew flights.

**2026-09-29 21:05 — the owner's #77 and #78 come first.** #77: domes for living creatures on the Moon and Mars
(spec §21c); #78: missions: build a rocket (alone or with friends) to reach a planet, no portals (spec §21d); invent
flight in history's order (§21e); the world's wonders, all of them (§24). Briefs: `2026-09-29-missions-brief.md`
(page 32, ids 560-575), `2026-09-29-colony-domes-brief.md` (page 31, ids 544-559), `2026-09-29-world-wonders-brief.md`
(world 41, Earth's range 41-60, pages 33-34, ids 576-607; TOUR = the ancient seven first). Start them in that order as
the running agents finish (Mercury → missions, grade 5 core → domes, grade 6 humanities → wonders). On lead-merge, not
live: "label the diagram" (`LabelAnswer`). Live 20:43 (`1a2ff5b`).

**2026-09-29 20:45 — live 20:43 (`1a2ff5b`): grade 5 in nine more subjects (124 of 136 units), Titan (world 22),
server module 0.2.15 (builds carry block ids 512-1023).** The School: 515 of 817 units written. Agents (3): grade 5's
last 12 maths/science/English units (`g5c`), Mercury (world 23, page 30, ids 528-543), grade 6 history + geography +
citizenship (`g6h`). The emulator is off while agents run; when the PC is quiet: rebuild the APK and rerun the
autopilot (now a real ghost flight in Survivor worlds) on Mars, Europa, Io, Titan in both styles plus Green Meadows
realistic as the baseline; feel Titan's dolphin leap and the frame rate by its sea. Queue: grade 6 computing/art/music,
grade 6 health/D&T/projects, grade 6-8 core additions, grades 7-8 subjects; Venus's cloud city 24, the rings 25,
Pluto 26, Triton 27 (pages 31+ = ids 544+); labs, crafts, visuals.

**2026-09-29 19:25 — live 18:47 (`0bb8424`): Io (world 21), every grade 4 unit, the `lab_circuit` fix.** On
lead-merge (not live; next full suite, then deploy): grade 5 history + geography + citizenship, the block id space
(ids 400-511 are the items'; next block page 29 = ids 512-527), years shown "1850" (`"year": true`), and the
autopilot's flight ghosting in Survivor worlds (it was a walk that stuck at cliffs; dev log 19:00). Agents (3): grade 5
computing + art + music (`a3d0dff08250ebdef`), grade 5 health + D&T + projects (`a7203bfe69a60a71e`), Titan world 22
on page 29 (`a351cd697758f9e2f`). To do when the PC is quiet (load < 7): rebuild `build/android/game.apk`, rerun the
autopilot on Mars, Europa and Io in both styles plus Green Meadows realistic as the baseline for the realistic style's
1-2 frames over 100 ms (dev log table 19:00). Queue: grade 5's new core units (maths, science, English research
additions), grades 6-8 subject groups (`2026-09-29-school-subjects-brief.md`), Mercury 23, Venus 24, the rings 25,
Pluto 26, Triton 27 (`2026-09-29-cosmos-planet-brief.md`; pages 30+ = ids 528+), more labs and crafts, visuals.

**2026-09-29 16:45 — live 16:30: Europa, grade 4 history + geography + citizenship, the space looks.** On
lead-merge (not live; next suite): grade 4 computing + art + music, the autopilot's WORLD reaching the space worlds,
release 1.0.3 (code 13; `docs/playtests/whats-new-1.0.3.md`; build the APK and AAB after the next suite, steps in
`docs/store/play-console.md`). Agents: grade 4 health + D&T + projects, grade 4's new core units, Io (world 21).
To do when the PC is quiet (load < 6): the emulator autopilot on Mars (19) and Europa (20) in both styles
(`build/android/game.apk` built 16:43; developer menu → WORLD → AUTOPILOT), and feel Europa's step hop and geysers.

**2026-09-29 15:25 — USAGE LIMIT REACHED. Resume here.** Live 15:14 (`43290ab`): grade 3 in all 12 subjects,
Mars, the Star Map, the Space Book, the Science Lab. On lead-merge, NOT yet live (needs the full suite, then ff main
and the web deploy): the space worlds' looks (Boing and Rainbow keep their own skies, Rainbow's terrace rainbows,
Mars's haze) and grade 4 history + geography + citizenship (merged `3e572af`, School tests 446/446). Europa (world 20) FINISHED
(`worktree-agent-a8b2783ab02e2fec4`, suite 7126/7128 on its branch, smoke 0 fails; merge note: keep BlockIds.COUNT 384,
the Lab's id 352 stays; check the low-gravity step hop and the geyser pad on the emulator; notes
`docs/devlog/parts/cosmos-europa.md`). Still running: grade 4 computing + art + music (`worktree-agent-a5f97cfdca2271e3e`),
grade 4 health + D&T + projects (`worktree-agent-a7caa1e0a9680cb8d`). Merge conflicts are "both appended" (SOURCES, picture hooks,
DEVELOPMENT.md): keep both, and keep a `return` after each picture hook's draw. Queue: grade 4's new core units, then
grades 5-8 (`2026-09-29-school-subjects-brief.md`), Io/Titan… (`2026-09-29-cosmos-planet-brief.md`), visuals.

**2026-09-29 13:55 — grade 3 written in all 12 subjects; Mars live.** Live 13:51 (`e74c9cd`): Mars (world 19), the
Star Map, the Space Book, grade 3's first six subjects, sort, match, robot, rhythm, mix, sounds. On lead-merge (suite12
running, then deploy): grade 3's computing, art, music, health and PE, D&T, projects. The School: 338 of 817 units
written. Agents (3): the Science Lab (spec §23), grade 4 history + geography + citizenship, grade 4 computing + art +
music (the reusable brief `2026-09-29-school-subjects-brief.md`). Queue: grade 4 health/D&T/projects, grade 4's new core
units, grades 5-8 the same way; Europa and the next planets; visuals.

**2026-09-29 11:30 — live 11:22: #75 (jump taps fly up), #76 (iPhone screen), the School's 12 subjects.** On
lead-merge since (not yet live): the cosmos (spec §21b): the Star Map (`StarMap`, `SpacePanel`, `StarBody`; every
planet, moon and universe with three real facts; LAND/HOME/honest words), the Space Book (the book's SPACE tab), world
numbers 19-40 for real planets; the School's sort and match exercises. Agents (3): grade 3 maths (committed
`5822978`: 97 generators, 13 picture kinds), grade 3 science + English (`6642412`, converting to sort/match), grade 3
history + geography + citizenship (`01ca5f3`). Waiting: their reports → merge → full suite → deploy. Next agent: Mars
(world 19; brief: `docs/superpowers/plans/2026-09-29-cosmos-mars-brief.md`). Note: grade 3 is live
with every unit Coming soon until this merge.

**2026-09-29 11:00 — the School's whole programme is in the outline; grade 3 is being written.** The research
(`docs/design/school-curriculum-research.md`, owner #73): 12 subjects (maths, science, English, history, geography,
citizenship, computing, art, music, health and PE, D&T, projects), 817 units for grades 3-8. In the outline now
(`cb55e33`, `tools/school_from_research.py`); 201 written; tabs show only subjects with a written unit. Agents (3):
grade 3 maths (`g3m` generators), grade 3 science + English, grade 3 history + geography + citizenship. Server
**0.2.14** live (profiles to 1 MiB, 5000 keys; Nakama 4 MiB requests; verified with a 491 KB, 4000-unit profile).
#75 (jump taps fly and go up) and #76 (iPhone screen size) fixed on lead-merge, suite 6783/6785; deploy after suite9.
Next queue: grade 3 computing/art/music, health and PE/D&T/projects; then grades 4-8's new subjects and new core units;
the cosmos (roadmap §2); new exercise types (research §5.3: sort, match, label, timeline, listen, rhythm, mix colour,
code the robot).

**2026-09-29 10:10 — THE GAME NEVER ENDS (#71). Now: the School, grade 3 and every subject (#70).** The owner:
"this game never ends … we never stop developing new worlds, new universes, new lessons, new contents"; and (#70) the
School was NOT complete: only maths, science and English, grades 4-8, short units. The roadmap with no end:
`docs/superpowers/plans/2026-09-29-forever-roadmap.md` (§1 the School: grade 3 first, then history, geography,
citizenship, computing, art, music, health and PE for grades 3-8, then depth; §2 the cosmos: every universe a planet on
a star map; §3 universes 6-8; §4 worth paying for later; §5 visuals). Online re-tested live 10:05: PASS.

**2026-09-29 06:15 — the warm-up's first part is off (the menu comes ~5 s sooner).** Live `01ac320`:
`ShaderWarmup.menu_first = false` (the menu's own draws join the world part the loading card waits for); emulator MENU
ready ~11 s (16 s with the first part, 8.5 s before the rework), no 11 s world freeze. Everything else as at 05:40.

**2026-09-29 05:40 — all caught up; live everywhere.** Web live 05:30 (`b0cb1e3`: the whole School, the shader
warm-up); server 0.2.13; Android 1.0.2 (code 12) rebuilt 05:35 in `~/Downloads` with the whole School, waiting for the
owner's upload (steps in `docs/store/play-console.md`). All three stopped agents' branches salvaged. Open: the owner's
phone checks (#59, #62, #65); before a Play review, the Families / Data safety / target-age answers (they assumed the
age question, removed in #69). Ideas next: warm during calm moments in play; consolidate near-duplicate materials
(shorter warm-up); School polish (lesson pictures for grades 6-8).

**2026-09-29 05:00 — the School is live; the shader warm-up rework merged (#64).** Web deployed 04:01 with all 201
School units (`d6089e6`). The stopped agent's warm-up rework was measured on the emulator with a child's taps
(`tools/web_emu_flow.py`): the 11 s freeze when a first world appears is gone (worst 1.3 s) for a menu 7 s later; merged
`308f6d7`, its suite running, then the web deploy. All three stopped agents' branches are now salvaged. The grade 4
agent's uncommitted `test_g4_english_more_gen.gd` (tests for English generators it never wrote) is not merged: the
English units are complete as hand-written practice.

**2026-09-29 03:40 — the School is complete (#68): all 201 units of grades 4–8.** The lead wrote it alone (the agents
stopped on the usage limit): grade 4 English, grade 5 science, English and maths 13-16, grades 6-8 in every subject,
with generators g5m, g6n, g6a, g7n, g7g, g8n, g8g (each answer recomputed in `tests/unit/test_g*_maths_gen.gd`). The
agents' grade 4 science and grade 5 maths work is merged. Suite green on `0b7c29a` (6730/6732); this commit's suite and
the web deploy follow. Left from the agents: the shader warm-up rework branch (`worktree-agent-ada1c6430da943609`),
to measure on the emulator before merging.

**2026-09-29 01:45 — the browser version checked on nine devices; the parity list written.** The live build
(web `…1790630932`, server 0.2.13, #69 no age rules) ran in Chromium, Firefox and WebKit as a PC, a Mac, Android
phones and a tablet, iPhones and an iPad (`tools/web_device_matrix.mjs`): all nine reach the game, no page errors.
Every browser-vs-app difference and why: `docs/web/parity.md`. No agents can run until Oct 3, 06:00 (usage limit);
their branches wait to be salvaged: grade 4 science (`worktree-agent-ac02a9d5cef656382`), grade 5 maths units 1–7
(+ 8–12 uncommitted, `worktree-agent-a2c962ee2548e7955`), the shader warm-up rework (`worktree-agent-ada1c6430da943609`;
measure on the emulator before merging). Android 1.0.2 in `~/Downloads` waits for the owner's upload.

**2026-09-28 11:50 — the browser version is live; the School (#68) is being written grade by grade (spec §20, §22;
logs `docs/devlog/2026-09-27-m7-web.md`).** Links: https://178-104-20-64.sslip.io/play/ and
https://giorgipirveli.github.io/easycraft/ (iPhones are sent on to the server). Build `tools/export_web.sh`; deploy
`tools/deploy_web.sh` + `tools/deploy_web_github.sh`; checks `tools/web_check.py`, `tools/web_iphone_check.mjs`,
emulator-5554 Chrome (`-no-snapshot`), `tools/frame_trip.gd`, `tools/frame_probe.gd`, `tools/web_shader_probe.py`,
`tools/web_update_check.py`. Live: web since 11:13 (first download ~20 MB, updates ~2.8 MB, music + realistic in the
background, #54, #55 space, #65 Samsung → Chrome install, #66 SIMPLE/CLASSIC on SETTINGS' first page, the game-logic
freeze fixes, #67 the account on every device); the server module **0.2.12** since 11:08 (`kit.sh update`; sign-in
keys as bcrypt). sasa192974 has 100,915 gold (live). **Android 1.0.2 (code 12)** is in `~/Downloads`
(`EasyCraft-1.0.2.apk`, `EasyCraft-1.0.2-play.aab`, upload key): the owner uploads it to Play (steps in
`docs/store/play-console.md`). On `lead-merge` (suite running 11:40): the School (#68; `6b96628`) and its progress in
the account (`91d3df5`); the shader warm-up merged but OFF (`PlatformRules.shader_warmup`). Agents (3 max): School grade
4 science + English (ac02a9d5cef656382), School grade 5 maths (a2c962ee2548e7955), the shader warm-up rework
(ada1c6430da943609). School queue: grade 5 science + English, grades 6, 7, 8 (plan `docs/superpowers/plans/2026-09-28-school.md`).
Owner feedback #54–#68 in `docs/playtests/owner-feedback.md` (#59, #62, #65 wait for the owner's phones). Merge routine:
`--import` and grep Parse Error before every suite. The owner's standing words: "dont stop untill everything fixed,
tested, fixed again and made app full"; "make sure it loads fast … saved in iphone and in android browser so after
refresh i dont need to redownload"; "while playing download full data needed for full game run in background";
"at the end we should have full school 4-5-6-7-8 grade programs in the game".

**2026-09-27 19:45 — testers can now join without a list.** The closed test's testers are the Google Group
easycraft-testers@googlegroups.com (anyone can join; submission 6 in review). Share https://groups.google.com/g/easycraft-testers/about
and https://play.google.com/apps/testing/com.giorgi.easycraft. The store pictures are live. Open testing stays locked until
production (12 testers × 14 days).

**2026-09-27 03:05 — the Play store page is complete.** The texts, the buddy icon, Data safety and the sign-in details
were approved (live); the 8 new screenshots and the feature graphic (made by `tools/store_shots.gd`, merged from the
store-shots agent) are in review (`docs/store/play-console.md`). No agents run. What moves Play forward now is only the
owner's: 12 testers for 14 days (1 opted in), then Apply for production.

**2026-09-27 01:30 — Play pushed forward (the owner: "if there is something we can do, do all of them").** Done in the
console: the new listing texts, the buddy icon, Sign-in details for reviewers, the Data safety changes; sent for review
01:25 (`docs/store/play-console.md`). Running: one agent makes the 8 store screenshots and the feature graphic with a new
`tools/store_shots.gd` (desktop, windowed); when it reports, check every picture, merge, upload them (Default store
listing → Graphics; the old 0.3.2 pictures removed) and send them for review. Open testing and pre-registration are
locked until production access: the owner's 12 testers for 14 days is the gate (1 opted in).

**2026-09-27 01:00 — NEXT: M6 "iPhone" on the owner's Mac.** The owner: "our next job is to produce app version for
iphone". Spec §19, plan `docs/superpowers/plans/2026-09-27-m6-iphone.md`, setup `docs/IOS-START-HERE.md`. The folder to
copy: `~/Downloads/EasyCraft-for-Mac/` (and `EasyCraft-for-Mac.zip`, 273 MB, sha256 `9718c2a1…`, refreshed 2026-09-27 22:20): the repository with its
history (commit `8821fc9`), Claude's memory notes and a README; no keys. Play: **1.0.1 is published** on the closed test (27 Sept
00:20); 1 of the 12 testers needed has opted in (`docs/store/play-console.md`).

**2026-09-26 03:00 — THE ROADMAP IS COMPLETE (M2–M5, everything but the iOS build). Release 1.0.1 (code 11) delivered.**
`~/Downloads/EasyCraft-1.0.1.apk` and `~/Downloads/EasyCraft-1.0.1-play.aab` (upload key) from `b49eb8b`; suite 6016/6018,
every smoke run passes, live server module 0.2.11, the emulator acceptance in `docs/devlog/2026-09-26-release-1.0.0.md`.
No agents run; the keep-going job was deleted. **What's left is the owner's** (`docs/HANDOFF.md`): upload 1.0.1 to Play,
the store listing and forms (`docs/store/pre-launch-checklist.md`), 12 testers for 14 days, the lawyer, a real-phone
check, children's playtests, later the iOS build on the Mac. When the owner reports anything, log it in
`docs/playtests/owner-feedback.md`, fix it test-first, and build the next version (1.0.2, code 12) the same way.

**2026-09-26 01:20 — RELEASE CANDIDATE 1.0.0 DELIVERED.** `~/Downloads/EasyCraft-1.0.0.apk` (100.3 MB, sha256 `e73842e4…`)
and `~/Downloads/EasyCraft-1.0.0-play.aab` (71.6 MB, upload key, sha256 `d3859b9e…`) from `93edc27`; main = `75549fc`+docs.
Suite 6005/6007, Node 280, every smoke run passes, live server module **0.2.11** (net_test PASS), emulator acceptance in
`docs/devlog/2026-09-26-release-1.0.0.md`, the owner's list in `docs/HANDOFF.md`. **Last step running:** M5 Task 6, the
whole-game review (an agent); if it finds real bugs they are fixed test-first and a 1.0.1 (code 11) follows the same way.
Then the keep-going job is deleted.

**2026-09-25 23:50 — everything is merged on lead-merge but one agent.** Merged since 23:10: the M4 leftovers (server
**0.2.10 live**, with the regenerated public pages), M5 T4 store readiness, M5 T2 art and audio polish, and the lead's
fixes from the acceptance smoke runs (the wild meadows' generator with any box, the bubble's pop, seven smoke tools).
Main = `3c4c402`. Running: the full suite on `a7baf78`+ then `tools/smoke_all.sh` (SMOKE_ALL_DIR=/tmp/easycraft-smoke-final),
and the agent `aa0d24bfb86da3d1b` (F1 photo SHARE's grown-up switch, B the host's `match_players`, module 0.2.11).
**Then the RC:** merge that agent → deploy 0.2.11 → version 1.0.0 (code 10: `test_release_version.gd`, both presets,
`project.godot`) → full suite → the phone APK (Android Phone, debug keystore env) and the Play AAB (Android Play,
upload key) → emulator acceptance of the RC (the agents' checklists; autopilot per universe on a quiet PC) → copy to
~/Downloads with sha256, `docs/store/play-console.md`, `docs/playtests/whats-new-1.0.0.md` final, `docs/HANDOFF.md` final.

**2026-09-25 23:10 — main = `65530da`** (suite 5873/5875): tutorial, M4 review, accessibility, performance, safety in the
world; **server 0.2.9 live** (the live removal test PASS). `tools/smoke_all.sh` runs on main's tree in the
`lead-moderation` worktree (log in the scratchpad). Agents: store docs and the M4 leftovers (0.2.10) are on their final
suites; polish still working. Then: merge them, deploy 0.2.10, the emulator acceptance on a quiet PC, RC 1.0.0.

**2026-09-25 22:35 — after the usage limit (19:50–22:00).** lead-merge `3a1da90` = M3 T15 tutorial + M4 T10 review
(server **0.2.8 deployed live**) + M5 T1 accessibility + M5 T3 performance (phone APK 193 → 96 MB) + the lead's **safety in
the world** (spec §17.3: the name tag's card in every world with REPORT, BLOCK and the host's REMOVE; server **0.2.9**
`remove_guest`, not deployed yet) — full suite running. main = `5de1890` (green 5778/5780). **Running (3):**
`a036af39c6e6f9d6a` M5 T2 polish, `a2379db1050627c76` M5 T4 store docs, `ac2eb31f9717abec9` the M4 review's leftovers
C/D/E/G/I (server 0.2.10). No stopped agents left. **Next for the lead:** suite → ff main → deploy 0.2.9 → live
`net_test --invite --remove`; merge the three agents as they report; the emulator acceptance (checklists in the agents'
notes: m3-task-15, m3-task-19-review, m4-task-10-review, m5-task-1, m5-task-3), autopilot per universe and style on a
quiet PC, then RC 1.0.0 (code 10) APK + AAB in ~/Downloads and `docs/HANDOFF.md`.

**2026-09-25 19:20 — the lead's work since 18:55 (on lead-merge, suite running on `8a88223`):** the SETTINGS page
buttons, `Lang.blocks`, a cap of 2 building-tool edits per player, `Player.position_or_none`, `tools/smoke_all.sh` (every
smoke run), `tools/net_test.sh --invite --delete-accounts` and **M4 acceptance part 2 PASS on the live server** (two games,
invited, rejoin 2.6 s, test accounts deleted), `docs/HANDOFF.md` (draft). **M3 T15 tutorial done** (`ae4b671f45ccf8dd9`,
branch `worktree-agent-ae4b671f45ccf8dd9`, its suite 5745/5747): merge after the running suite; its emulator checklist is
in `docs/devlog/parts/m3-task-15.md`. **Running (3):** `a6865f57bc2197409` M5 T3 performance, `a548748399ecf9644` M4 T10
review (final suite), `aedeca7a7c45126d0` M5 T1 accessibility (resumed 19:18). **Still stopped:** `a036af39c6e6f9d6a` M5 T2
polish, `a2379db1050627c76` M5 T4 store docs. Known: `test_monster_defenses.gd`'s doorway test fails alone, passes in the
suite (old; DEVELOPMENT.md gotchas).

**2026-09-25 18:55 — M3 T19 review merged into lead-merge (`0cac6f0`, suite running).** Six fixes (two-byte block ids in
the lantern/bot searches, a guest's error flood, an ownerless buddy, "an owl", singular plurals, a mimic whose child left);
open items in `docs/devlog/parts/m3-task-19-review.md`. **Running (3):** `ae4b671f45ccf8dd9` T15 tutorial,
`a6865f57bc2197409` M5 T3 performance, `a548748399ecf9644` M4 T10 review (resumed 18:51). **Still stopped, in order:**
`aedeca7a7c45126d0` M5 T1 accessibility, `a036af39c6e6f9d6a` M5 T2 polish, `a2379db1050627c76` M5 T4 store docs.
Emulator checks from the M3 review for the acceptance run: monsters come near village roofs at night; the stealth eye
stays low crouching beside a house; a LAN guest's buddy stays when the guest leaves; no error flood on a guest when the
host quits; "called an owl!" and "Copied 1 block!".

**2026-09-25 18:30 — owner #51, #52, #53 built on lead-merge** (not yet on main: the full suite runs first).
`80edf2d` #51 MOBS tab in the Sandbox palette; `8445d17` #52 **English only** (Georgian removed everywhere: never add a
language again, `test_english_only.gd`); `94d3368` #53 **strength follows rarity** (`WeaponStrength`, spec §13.4b:
blasters 3/9/12/22/50, rocket 3 a magazine and 500 gold, spear 5, mace 8, boomerang 21). The 3 running agents were
told about both (18:25). Next: the full suite on `94d3368`, fast-forward main, restart emulator-5554 (it died ~17:30)
and check MOBS, the English settings and a blaster fight on the device; then the agents' merges.

**2026-09-25 17:44 — the owner: "dont run more then 3 agents same time".** Keep-going cron now **`5cb03570`**. Running
(3): `ae4b671f45ccf8dd9` M3 T15 tutorial, `a6865f57bc2197409` M5 T3 performance and size, `acb41057fb7614571` M3 T19
review. **Stopped at 17:44 with their work uncommitted in their worktrees; resume one at a time with SendMessage as a
running one finishes, in this order:** `a548748399ecf9644` M4 T10 review (was adding "a restored backup never lifts
the phone's under-13 band"), `aedeca7a7c45126d0` M5 T1 accessibility (RED tests written, the HUD next),
`a036af39c6e6f9d6a` M5 T2 polish (the universe backdrops next), `a2379db1050627c76` M5 T4 store docs (a pointer in
play-console.md, then the web pages). 0.4.0 is built; the owner uploads the bundle (the extension can't send 90 MB;
serving it locally to the page was refused by the permission check).

## 2026-09-25 17:01 — CONTINUE WITH FULL POWER ("continue with full power", "give me apk for final version")
- Keep-going cron re-created: **`23b4fb80`** (at :07, :27, :47).
- **Release 0.4.0 (code 9)** built and delivered: `~/Downloads/EasyCraft-0.4.0.apk` and `~/Downloads/EasyCraft-0.4.0-play.aab`
  (`docs/store/play-console.md`). The boot splash export bug fixed (`15bfae0`).
- **Agents launched 17:03** (each merges lead-merge first and last, translates its words, runs the full suite):
  `ae4b671f45ccf8dd9` M3 T15 tutorial; `aedeca7a7c45126d0` M5 T1 accessibility; `a6865f57bc2197409` M5 T3 performance and
  size; `a036af39c6e6f9d6a` M5 T2 art and audio polish; `a2379db1050627c76` M5 T4 store readiness (docs); `acb41057fb7614571`
  M3 T19 review and fixes; `a548748399ecf9644` M4 T10 review and fixes (module 0.2.8 if the server changes; the lead
  deploys).
- **Then:** the acceptance runs (M3 T18, M4 T9: two instances online) on emulator-5554, new store screenshots, RC 1.0.0
  (code 10), the hand-off list.

## PAUSED 2026-09-25 13:40 — everything that was running is merged; nothing is running
- **main = `bac5ef3`** (= lead-merge). Last full suites: 5558/5560 on `ebe692e`; M3 Task 21b's agent ran 5655/5657 on the
  exact tree that became `bac5ef3` (the 2 are #45b's tests that never assert). No agents run; the keep-going cron is
  deleted (09:38).
- **Built since the M2 release:** M3 Tasks 1–14, 16, 17, 20a/b, 21a/b/c, 22 (Survivor games, crafting, Monster Wave),
  23 (#42 treasures), 24 (#45a quests, #45b bigger world), 25 (#48 girl avatars), 26 (#39 portals + Dragon Realm, #41
  animals), 27 (#36 costumes), 28 (#37 trade); M4 Waves 1–3 + 8b + ghost races; M5's #43 identity. Live server:
  https://178-104-20-64.sslip.io, module **0.2.7**. Play: closed test live with 0.3.2; `~/Downloads/EasyCraft-0.3.3-play.aab`
  (hotfix) waits for the owner's upload.
- **When the owner says continue** (re-create the keep-going cron; allocations: next block page 15 = 288–303 is free,
  page 21 is the tests'; items 452–459, 485–489 kept for crystals, 412–414 free):
  1. M5 Task 3 performance and APK size (`prompt-m5t3.md`: the dev APK is ~181 MB, the realistic pages 144 MB of it;
     the docs' images; the flaky `test_visit_world` under load).
  2. M5 Task 1 accessibility (`prompt-m5t1.md`).
  3. M3 Task 15 tutorial with Pip (`prompt-m3t15.md`, last feature).
  4. Acceptance on emulator-5554: M3 Task 18 and M4 Task 9 (the agents' emulator checklists in their notes files;
     the Dragon Realm and Georgian were checked on 2026-09-25), the autopilot in every universe, both styles.
  5. Release **0.4.0 (code 9)**: APK to `~/Downloads`, the Play bundle for the owner to upload; new store screenshots
     (#43's list in `docs/devlog/parts/owner-43-identity.md`) and the new icon `docs/store/graphics/next/icon-512.png`.
  6. The whole-branch reviews (M3 Task 19, M4 Task 10), then M5 Task 4 store readiness, RC 1.0.0, hand-off.
- **Owner's to-dos:** testers must tap "Become a tester" on https://play.google.com/apps/testing/com.giorgi.easycraft
  (0 opted in; 12 needed for 14 days); upload 0.3.3 or wait for 0.4.0; (no Georgian check: the game is English only, #52); the
  lawyer's checks (#36 costume names: Sherlock Holmes, Aladdin, Pinocchio, Hercules; #43's "EasyCraft" trademark search,
  `docs/store/listing.md`).

**2026-09-25 09:38 — the owner paused again: "please dont start new works, just finish ongoing".** The keep-going cron
`185780ea` was deleted at 09:38. No new agents start. Finishing only: the running suite on lead-merge (#36), then the
finished T20b buddy magic and T21c Tiny world merged (in that order: both change `sandbox._on_spark`; both took spec
§14.23), and the three agents still running (T21b books `ac1e64514dd88f0de`, #37 trade `aab08e0612da580f3`, #43
identity `a2a9dc352027fc8de`) merged as they report; main fast-forwarded after each green suite. **13:20:** everything that was running is merged but T21b (books, `ac1e64514dd88f0de`, resumed at 13:01 after the
second limit, 10:43–13:00; it finishes its last merge and suite). main = `ebe692e` (suite 5558/5560). Live server module
0.2.7. **Not started (the
queue for when the owner says to continue):** M5 T3 performance and APK size, M5 T1 accessibility, T15 tutorial (last),
M3 T18 / M4 T9 acceptance runs, release 0.4.0 (code 9), the whole-branch reviews, M5 T4 store readiness, RC 1.0.0.

**21:41 — the owner paused again:** "please finish ongoing tasks and then pause, dont run new agents, save and
pause". No new agents start. The 7 running agents finish, the lead merges their branches, and this file is
updated. Then work stops until the owner says to continue. The keep-going cron `9210da38` was deleted at 21:42.

The owner stopped new work at 20:04 ("please save everything, we are out of limits, dont start new works.
just finish ongoing and save everything into plan"). This file is the single place to pick up from.
Read it together with `CLAUDE.md`, `docs/DEVELOPMENT.md` and `docs/playtests/owner-feedback.md`.

## 2026-09-25 00:xx — the night shift (the owner: "you have full night ahead, dont stop, make the game real … the very very final edition")
- **Online works live** (owner 23:37, two phones through https://178-104-20-64.sslip.io, build 0.3.2).
- **Google Play:** the app exists (EasyCraft, `com.giorgi.easycraft`, developer name "API Studio" waiting for
  approval). Internal test live with 2 testers. Closed test "Closed testing - Alpha" with 0.3.2, plus every
  declaration and the store listing, **sent for Google review** at 23:47. See `docs/store/play-console.md`
  (steps, state, the advisory warnings) and `docs/store/reviewers-and-testers.md` (12 real testers × 14 days;
  Expert Approved, Common Sense Media).
- **APK 0.3.2** `~/Downloads/EasyCraft-0.3.2.apk` (dev package `com.giorgi.game`); bundle
  `~/Downloads/EasyCraft-0.3.2-play.aab`.
- **Merged into lead-merge tonight:** the audio pass, Survivor games + crafting + Monster Wave, T14b blasters,
  #42 treasures, #40 commands (+ `/music` wired to the audio pass), the Play preset 0.3.2, T14a gadgets, T11
  pets, T20a rides, T10 Gold Farm, #35 shop. Plus fixes: Plus universes stay open while a build has no store;
  the settings' Farm note in the last row; the Monster Wave clock clear of RIDE; the Candy Kingdom's own
  treasure places; `test_no_inner_class_takes_the_name_of_a_global_class`. The full suite on all of it was
  running at 00:xx (`scratchpad/suite-lm4.log`; if lost, run `tests/run_tests.sh` in lead-merge). When it's
  green, fast-forward main.
- **Agents running** (branches `worktree-agent-<id>`):
  - `a46ece032a1aae7bb` #49 chat on phones;
  - `adb097634f397613d` #50 chicken sounds;
  - `a317d3c66e402be33` #39 portals + Dragon Realm;
  - `a956136f34c56efcc` #48 girl avatars;
  - `a6bb046066c594cc8` M3 T8 building tools;
  - `a2d3d68b7911f3c97` #45a quests.

  The first two start from 0.3.2 (`4d3198d`); the other four from lead-merge.
- **00:20:** the suite passed 4500/4502; the 2 failures were the pets' voices, fixed in `cfd9a51`. **main = lead-merge = `e1ebb29`.** Google approved the submission; **the closed test is live**, with join link https://play.google.com/apps/testing/com.giorgi.easycraft. New agent: `a4b05011a7fe365bc` #45b bigger world (from main).
- **00:45:** #50 (animal chorus) and #49 (readable chat) merged into lead-merge (`cb967eb`). **Hotfix 0.3.3 (code 8)** = 0.3.2 + #49 + #50 on branch `hotfix-0.3.3` (worktree `.claude/worktrees/hotfix-033`), with its suite running. Next: build the APK and AAB into `~/Downloads`, check on the emulator, then upload to the closed test. The AAB is ~70 MB; the Chrome extension only uploads files under 10 MB, so the owner drags the AAB into Play Console (Test and release → Closed testing → Create new release → Upload) and the lead fills the rest. New agent: `a7fd6389f0586832e` #41 animals.
- **03:01–03:25 (after the usage-limit reset):** all six agents resumed (SendMessage). Hotfix 0.3.3 built
  (`~/Downloads/EasyCraft-0.3.3.apk`, `EasyCraft-0.3.3-play.aab`) and checked on emulator-5554 (chat readable;
  see `docs/store/play-console.md`). **The owner uploads the 0.3.3 bundle** (70 MB > the extension's 10 MB), then
  the lead fills the notes and reads the first pre-launch report. Console: no policy issues; 0 testers opted in
  (each must tap Become a tester on the join link). Full suite on lead-merge queued for a slot
  (`scratchpad/suite-lead-0310.log`); when green, fast-forward main. M3 Tasks 6, 9, 10, 11, 12, 16, 20a were
  already merged (plan text fixed).
- **03:53–04:07:** merged into lead-merge: **#48 girl avatars** (`b228aed`, agent suite 4563/4563), **hotfix-0.3.3**
  (`549ff6a`: lead-merge is now 0.3.3/code 8, so a dev build never downgrades the emulator: Android wiped the
  profile on the 8 → 7 downgrade, an upgrade keeps it, checked), **#45a quests** (agent suite 4605/4605), **M3 Task 8
  building tools** (`c8baeb4`; conflicts in `avatar_look.gd` and `sandbox.gd`, kept both). Full suite on the
  combined tree queued (`scratchpad/suite-lead-0410.log`). On emulator-5554: the first launch's "Pick your look"
  (BOY / GIRL / JUST ME) fits and works. New agent: `a56613018f44fb05f` #36 costumes. Next release is 0.4.0 =
  code 9.
- **04:10–04:40:** merged **#39 portals + the Dragon Realm** (`186d2f6`) and **#45b a bigger world** (`be8a5af`), with
  lead fixes: #45b's `GLOW_CAP` renamed `GLOW_MUSHROOM` (both branches named a block so), `test_block_pages` uses page
  21 (13 is the meadows'), **Build Rewind stores 16-bit ids** (`3e4519b`, RED→GREEN), the realistic cheeks softer
  (`eeffd5e`, checked on the emulator). **Live server updated to module 0.2.5** (04:39, `kit.sh check` all ok; Node
  231/231). #41 animals finished (to merge after the running suite `scratchpad/suite-lead-0450.log`). New agents:
  `af915ba815ebace13` T20b buddy magic, `ad0a987ca5b9165b3` T21a words and voices, `ac1e64514dd88f0de` T21b books,
  `a2c7cb49dafb1088b` T21c Tiny world, `a69776d00b15cf159` M4 ghost races (module **0.2.6**), plus
  `a56613018f44fb05f` #36 costumes. Id allocations given: T21c page 14 (272–287) + items 412–414, T20b page 15
  (288–303) + items 495–499, T21b 217–218; test page 21 (384–399).
- **04:50–05:12:** merged **#41 more animals** (`e08c4a2`; conflicts with #39's pet dragon in the animal, pet and voice
  tables) and fixed the seams: the dragon's sound `dragon_chirp` (`33abe7f`), Nell the dragon keeper for universe 5
  (`39cd6cb`), the dragon's food, home check and measured chorus level, the keepsakes shelf (`1e1d6d6`). **05:12 the
  usage limit stopped all 8 agents** (reset 08:00). **08:01 all 8 resumed** with SendMessage (each had uncommitted work;
  each merges lead-merge before its final suite): `a56613018f44fb05f` #36, `af915ba815ebace13` T20b,
  `ad0a987ca5b9165b3` T21a, `ac1e64514dd88f0de` T21b, `a2c7cb49dafb1088b` T21c, `a69776d00b15cf159` ghosts (module
  0.2.6), `aab08e0612da580f3` #37, `a2a9dc352027fc8de` #43. Full suite on lead-merge `1e1d6d6`: running
  (`scratchpad/suite-lead-0810.log`); when green, fast-forward main.
- **08:10–08:55:** suite 5091/5092 then green (the chorus test's "dragon" example); main = `5ae37e2`. Emulator: the
  night's features toured, the Dragon Realm and Nell checked (debug build, `run-as` test profile; DEVELOPMENT.md has the
  techniques). `/universe` in Sandbox now points to portals (`fbf8cb3`). **M4 ghost races merged** (agent suite
  5153/5155, Node 252/252) and **the live server runs module 0.2.6** (08:50, `kit.sh check` ok). The APK size finding
  went into `prompt-m5t3.md` (the realistic pages are 144 of 181 MB). 7 agents running (#36, T20b, T21a, T21b, T21c,
  #37, #43). Full suite on lead-merge queued (`scratchpad/suite-lead-0855.log`).
- **09:00–09:27:** merged **M3 Task 21a words and voices** (Georgian + English, read-aloud, babble, Simple controls;
  the lead translated the ghost races' 23 new lines) and **#36 the Storybook costume pack** (21 costumes, earned only;
  legal-check list in `docs/devlog/parts/owner-36-costumes.md` for the owner's lawyer: Sherlock Holmes, Aladdin,
  Pinocchio, Hercules trademarks). Suite 5231/5233 before #36; main = `88c880f`. Georgian checked on the emulator.
  **Live server module 0.2.7** (09:22: the costume code). Every agent translates its own new words
  (`tools/i18n/words.gd -- --missing`). Running: T20b, T21b, T21c, #37, #43. Queue after them: M5 T3 performance and
  size, M5 T1 accessibility, T15 tutorial (last), the acceptance runs, 0.4.0.
- **Next:**
  1. Merge the agents as they report.
  2. Start the queue with ≤ 6 agents running (the suite slot gate is 3):
     - #41 animals (after #50);
     - #45b bigger world;
     - #36 costumes (after #48);
     - T20b buddy magic;
     - T21a/b/c;
     - M4 ghost races;
     - T15 tutorial (last).
  3. M3 T18 and M4 T9 acceptance on the emulator (`emulator-5554` only).
  4. Release 0.4.0 (code 8) as APK and bundle, uploaded to the closed test.
  5. The whole-branch reviews, then M5.

## 22:05 — work resumed ("continue work", then "continue full work")
- Keep-going cron re-created: **`185780ea`** (at :07, :27, :47).
- All 7 stopped agents were resumed with their context (SendMessage). **Done:** audio pass (`a633b61ec8e79c4c9`,
  3 commits, suite 3198, APK +15.9 MB) and Survivor games + crafting + MONSTER WAVE (`abd3fb335e007a32c`, `8aad5c6`,
  suite 3390). Both go to lead-merge next. **Still running:** T14b, #42, #40, T14a, #35.
- **New agents (22:07):** M3 Task 11 pets `a0eadce05ac1734f9`, Task 10 Gold Farm `a64e6dd702b879693`, Task 20a
  rideable buddies `abe53a255574addf7`. Each merges `lead-merge` first and uses its brief.
- lead-merge `ca51c26`: the 3-branch merge's one failure was fixed. M4 H's inner class `StickerPicture` hid M4 I's
  global class, so `game_overlay.gd` failed to compile. It is renamed `StarPicture` and guarded by the new
  `test_no_inner_class_takes_the_name_of_a_global_class`. The full suite is re-running.
- **Merge note:** the Survivor-games agent named its plan task "M3 Task 22" (Monster Wave), and main's quests +
  bigger-world task (#45) is also Task 22. When merging, renumber the #45 task to **Task 23** (plan heading,
  `prompt-own45.md`, owner-feedback row #45, the queue line below).

## 21:53 — final state before the owner's usage limit ("we are out of limits so please finish all ongoing tasks to not lost a work")
- **The game server is live:** `https://178-104-20-64.sslip.io`. Hosting-guide steps 1–7 are done. Root login is off
  and SSH is key-only (`/etc/ssh/sshd_config.d/00-easycraft.conf`). The kit is in `~/easycraft/server/deploy`
  (project `easycraft_live`: nakama, postgres, caddy, backup, all healthy). `./kit.sh check` prints all ok:
  a real HTTPS certificate, sign-in, RPC healthcheck module **0.2.4**, wss ping 38 ms, big message, and relay SKIP
  (uninvited players are refused, as they should be). The secrets live in the server's `.env` and nowhere else.
  **Owner:** copy them to your password manager with
  `ssh -i ~/.ssh/easycraft_hetzner easycraft@178.104.20.64 cat easycraft/server/deploy/.env`.
- **Still to do for online play:** (a) the Hetzner Cloud firewall, TCP 22/80/443 (ufw already allows only
  these); (b) `RELEASE_SERVER := "https://178-104-20-64.sslip.io"` in `core/net/online_config.gd`, run its test and
  the suite, and `tools/net_test.sh --server=https://178-104-20-64.sslip.io`; (c) release APK versionCode 7, then
  PLAY ONLINE on the emulator. Update the server later with a new `kit.sh pack` → scp → `./kit.sh update`.
- **Agents' unfinished work is safe:** at 21:52 each running agent's worktree was snapshotted, including untracked
  files, to **`refs/wip/agent-<id>`**, and the agents were not disturbed (their HEAD, index and files were untouched).
  To continue one: `git worktree add .claude/worktrees/resume-<id> -b resume-<id> refs/wip/agent-<id>`, or just
  use its worktree if the files are still there. Its brief (in the table below) and notes file say what is left.
  Changed files at 21:52: audio 6, Survivor games 59, 14b 26, #42 76, #40 7, 14a 2, #35 5.
- **lead-merge:** the three 21:42 merges and the dev-log entry are committed there (`419ad2e`); its full suite was
  still running at 21:53. Next session: run `tests/run_tests.sh` in `.claude/worktrees/lead-merge`; if it passes,
  replace `SUITE_PENDING` in `docs/devlog/2026-09-24-m3.md` with the count, then `git merge --ff-only lead-merge`
  on main (main has docs commits since, so merge main into lead-merge first).
- Owner feedback #45 (quests, a bigger world) is planned: M3 Task 22, `prompt-own45.md`.

## 21:50 snapshot (saved on the owner's "please save locally everything needed from this conversation")
**The internet server exists (the owner bought it at 21:45).**
| What | Value |
|---|---|
| Hetzner project | `easycraft` (id 16150153); the other project `learnquest` is not ours — never touch it |
| Server | `easycraft-1` (id 167304119), CPX12 (1 vCPU, 2 GB, 40 GB), Nuremberg (eu-central), Ubuntu 24.04.4 |
| Address | IPv4 **178.104.20.64** (console: https://console.hetzner.com/projects/16150153/servers/167304119/overview) |
| SSH | `ssh -i ~/.ssh/easycraft_hetzner root@178.104.20.64` (the key's public half is the Hetzner key `easycraft-pc`); user `easycraft` has the same key |
**Done on it (21:47, hosting guide step 2):** security updates, user `easycraft` (sudo without password,
group docker), Docker 29.8.1 + Compose v5.5.1 (Docker's installer), ufw on (SSH, 80, 443 only).
**Next, in order:**
1. `sudo reboot` (the updates asked for it); then check `ssh -i ~/.ssh/easycraft_hetzner easycraft@178.104.20.64`
   works, and only then close root: `sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo systemctl restart ssh`.
2. Hetzner Cloud firewall (console → Firewalls, free): inbound TCP 22, 80, 443 only; apply to `easycraft-1`.
   SSH stays open to all addresses because the owner's home address can change; logins are key-only.
3. A name (step 3): **ruling** — use `178-104-20-64.sslip.io` (it points at the IP with no account). Cost if
   wrong: if the owner later buys a domain, the game needs one new APK with the new address. Check that
   `getent hosts 178-104-20-64.sslip.io` prints the IP.
4. `server/deploy/kit.sh pack` → `scp build/server/easycraft-server-*.tar.gz easycraft@178.104.20.64:` → on
   the server: `mkdir -p ~/easycraft && tar -xzf easycraft-server-*.tar.gz -C ~/easycraft && cd ~/easycraft/server/deploy && ./kit.sh keys 178-104-20-64.sslip.io && ./kit.sh up && ./kit.sh check`.
   The `.env` it writes holds the secrets. Tell the owner to copy it into their password manager. Never commit it.
5. `core/net/online_config.gd`: `RELEASE_SERVER := "https://178-104-20-64.sslip.io"`; run
   `test_the_release_server_in_the_game_is_empty_or_secure`, the suite, `tools/net_test.sh --server=https://178-104-20-64.sslip.io`;
   then the next release APK (versionCode **7**) and PLAY ONLINE from the emulator.

**Merges at 21:50:** `lead-merge` holds three new merges on top of main (`d668a72`): owner #38 bot chat
(`4012af1`), M4 Wave 3 I (`9e73ad7`, module 0.2.4), M3 Task 4 Candy Kingdom (`edc432d`), and a dev-log entry
(`docs/devlog/2026-09-24-m3.md`, "19:57–21:50", its suite cell `SUITE_PENDING`). Import check clean; `npm test`
231/231; `tools/net_test.sh` PASS; the dev server already runs module 0.2.4. **The full suite was running.** If the
session ended, run `tests/run_tests.sh` in `.claude/worktrees/lead-merge`. If it passes: put the count in place of
`SUITE_PENDING`, commit, and run `git merge --ff-only lead-merge` in the main checkout.

**Agents still running at 21:50** (their branches `worktree-agent-<id>` and worktrees `.claude/worktrees/agent-<id>`):
audio `a633b61ec8e79c4c9`, Survivor games + crafting + Monster Wave `abd3fb335e007a32c`, T14b blasters
`acfd0f8291cc58f47`, #42 treasures `a4074b887d6ba3088`, #40 chat commands `a4333df0961994b27`, T14a gadgets
`aee33dfde6eb1a424`, #35 honest shop `a5625d128091bc35d`. If the session ended before they reported: in each
worktree, `git status`, then commit any unfinished work as a WIP commit on its branch. Continue each one later
the same way as the 20:08 stop (below). **The owner's order at 21:41 still holds: no new agents until they say to continue.**

## Where the milestones stand
| Milestone | State |
|---|---|
| M1, M1b | Done (0.2.0) |
| **M2 "Survive the Night"** | **Done.** `~/Downloads/EasyCraft-0.3.0.apk` delivered 19:28 (versionCode 5); acceptance `docs/superpowers/notes/m2-acceptance.md` (15 rows) |
| M3 "Worlds of Wonder" | Done and merged: Tasks 1 (block pages), 2 (Sandstorm Desert), 5 (universe ladder, portals), 6 (Physics Lab), 9 (avatar, emotes), 13 (codes), 16 (photo), 17 (Theater). **Also merged (20:10):** 7 (smart blocks, courses, races) and 12 (levels, adventure board, badges, presents). **Stopped mid-way, saved on branches:** 3 (Frostpeak), 4 (Candy Kingdom). **Queued:** 8, 10, 11, 14a, 14b, 20a, 20b, 21a, 21b, 21c, then 15 (tutorial, last), 18 (acceptance + 0.4.0), 19 (review) |
| M4 "Better Together" (online) | Done and merged: Waves 1–2 (world sync, Nakama server module, online client and screens, hosting kit, chat by age, co-op, accounts/parents/economy) and Task 8b (account deletion, retention, report snapshots, log rotation; module **0.2.3**). **Stopped/not started, saved:** Wave 3 H (co-op games, WIP branch), I (gifts, showcase visits, bottle mail, playdates; module 0.2.4; not started). **Queued:** ghost races (after M3 Task 7 — now merged), Task 9 acceptance + 0.5.0, Task 10 review. **Owner step:** the internet server (below) |
| M5 "Launch" | Store/privacy drafts written early (`docs/store/`). Everything else queued (plan `2026-09-24-m5-launch.md`) |

## Branches and how to merge (the lead's routine)
- Main checkout `~/Documents/game` on `m2-survive-the-night`; merges happen in `.claude/worktrees/lead-merge`
  (branch `lead-merge`): `git merge -q --ff-only m2-survive-the-night` first (merge it if main has its own
  commits), `git merge --no-ff worktree-agent-<id>`, resolve (`scratchpad` helpers are gone: "both added"
  conflicts keep ours then theirs; real overlaps by hand), `godot --headless --path . --import` and grep
  `Parse Error`, `tests/run_tests.sh` (+ `npm --prefix server/modules test` and `tools/net_test.sh` for
  server changes; build the module and copy `server/modules/build/index.js` into the main checkout, then
  `docker restart easycraft-nakama`), commit, then `git merge --ff-only lead-merge` in the main checkout.
- **20:10: M3 Tasks 12 and 7 are on main** (the merge suite passed **3087/3087**; the race → progress hook in `world/course_director.gd`). `lead-merge` = main.

## Agents (stopped at 20:08 with WIP commits; **resumed 20:18** on the owner's "continue work please"; keep-going cron `9210da38`)
Every agent was stopped and its unfinished changes committed as a **WIP** commit on its own branch
(`worktree-agent-<id>`, worktree `.claude/worktrees/agent-<id>`). To continue one: start a new agent in a
fresh worktree **from that branch** (or check it out), tell it to read its brief in `docs/superpowers/briefs/`,
its notes file, and `git log`/`git diff m2-survive-the-night...HEAD`, then finish the task. WIP commits were
not tested: the agent must run the full suite before its final commit.
| Branch `worktree-agent-…` | Task | Brief | Saved state at 20:08 |
|---|---|---|---|
| a2ab14876422d983a | M3 Task 3 Frostpeak | `prompt-m3t3.md` | **done, on main 21:01 (suite 3193/3193)** |
| a45860bf088056076 | M3 Task 4 Candy Kingdom | `prompt-m3t4.md` | **done 21:39** (its suite 3338/3338, Frostpeak merged in); to merge next with #38 and M4 I |
| a633b61ec8e79c4c9 | Audio pass + classical music (owner #27, #31) | `prompt-audio.md` | WIP only (1 file): was writing the classical-music source tool |
| aaf8e150c1f4dc3e2 | Owner bugs #26, #29, #30 — **done, on main 21:13 (suite 3235/3235)** | `prompt-owner-bugs.md` | WIP only (1 file): reading code |
| abd3fb335e007a32c | Survivor games + crafting (owner #33, #34) **+ the new MONSTER WAVE mode and Survivor without waves (owner #44, given 21:08; Monster Hunter folded in)** | `prompt-survivor-games-crafting.md` | 1 commit: spec §12.18 Survivor games, §12.19 crafting, the M3 plan task |
| a692df4b8ed3a0751 | M4 H co-op games | `prompt-m4h.md` | **done 21:29** (its suite 2941/2941); merged in `lead-merge` 21:31 (10 conflicts resolved), suite running |
| a4074b887d6ba3088 | Owner #42 more secrets, chests and treasures | `prompt-own42.md` | started 20:55 |
| a4333df0961994b27 | Owner #40 more chat commands | `prompt-own40.md` | started 21:31 |
| acfd0f8291cc58f47 | M3 Task 14b blasters, piñatas, goblin archers (the owner's "modern weapons", 20:39) | `prompt-m3t14b.md` | started 20:53 |
| a5717cbf234550c86 | Owner #38 bot chat | `prompt-own38.md` | done; to merge |
| ac91fdd9b34ab4c88 | M4 I friends apart | `prompt-m4i.md` | done (module 0.2.4); to merge |
| aee33dfde6eb1a424 | M3 Task 14a gadgets (items 400–414) | `prompt-m3t14a.md` | started |
| a5625d128091bc35d | Owner #35 honest parent-facing shop | `prompt-own35.md` | started 21:36 |

## Queue (briefs saved in `docs/superpowers/briefs/`, start them in this order)
1. `prompt-own35.md` — honest, parent-facing monetization (EasyCraft Plus, cosmetic packs, wish list → grown-up area, billing adapter + fake backend). The lead's ruling in owner feedback #35: no manipulation of children.
2. `prompt-own37.md` — lower priority now (the owner found Tilly's shop, #37): find Tilly (MORE → SHOP arrow), traders per universe, market day, trading between players.
2b. `prompt-own39.md` — universe portals you build and the Dragon Realm (owner #39, 20:35), after M3 Tasks 3–4 merge.
2c. `prompt-own40.md` — more chat commands (owner #40, 20:40).
2d. `prompt-own41.md` — more animals (owner #41, 20:42), after M3 Tasks 3–4 and the audio pass.
2e. `prompt-own42.md` — more secrets, chests and treasures (owner #42, 20:43).
2f. `prompt-own43.md` — a distinct visual identity (owner #43: Google Play and Minecraft-likeness), part of M5 Task 2, can run early.
2g. `prompt-own45.md` — **more quests and a bigger world** (owner #45, 21:49: "we should continue implementing new quests and also we should extend the world"); M3 Task 24 (24a quests, 24b world); after Candy, #41 and #42.
3. `prompt-own36.md` — Storybook costume pack (public-domain heroes drawn from the books, our own genre costumes; no Marvel/Harry Potter — ruling #36).
4. M3: `prompt-m3t11.md` (pets), `prompt-m3t14a.md` (gadgets), `prompt-m3t14b.md` (blasters, piñatas, archers), `prompt-m3t8.md` (building tools; uses M4 I's BuildPicker), `prompt-m3t10.md` (Gold Farm), `prompt-m3t20a.md` (rideable buddies), `prompt-m3t20b.md` (buddy magic), `prompt-m3t21a.md` (read-aloud, babble, Georgian), `prompt-m3t21b.md` (books), `prompt-m3t21c.md` (Tiny world), then Task 15 (tutorial with Pip; brief to write: spec §14.9).
5. M4: ghost races on friends' courses (reuse M3 Task 7's recorded runs), then Task 9 acceptance (two games: consent gates, chat by age, revive, reports) and release 0.5.0 (versionCode 6: `tests/unit/test_release_version.gd`).
6. M3 Task 18 acceptance (the autopilot in every universe with the developer menu's WORLD toggle and NIGHT RUN, both styles) and release 0.4.0 — or fold 0.4.0 and 0.5.0 into one release; then the whole-branch reviews (M3 Task 19, M4 Task 10), then M5.
Parallelism: up to 8 agents while > 6 GB memory is free (owner, 19:54). Give each fixed allocations (see
the M3 plan's Allocations, page 10 detail, and each brief).

## Owner feedback still open (see `docs/playtests/owner-feedback.md`)
- #26, #29, #30 → bug agent running. #32 (PAUSE) **fixed** in main (`d29213b`, test `test_a_tap_on_pause_asks_for_the_pause_menu`); not yet in an APK. #28 works as designed (paid flying).
- #27, #31 → audio agent. #33, #34 → Survivor games + crafting agent. #38 → bot chat agent.
- #35, #36, #37 → queued (briefs above). #25 online → the server step below.

## The owner's next step for online play: the internet server (Hetzner)
The owner asked (20:03) for the lead to **use the browser (Claude in Chrome), open Hetzner, create and
configure the server and use it**. **21:25: logged in (Playwright window); project `easycraft` (id 16150153) created, SSH key `easycraft-pc` added, the order form filled (cpx12, 1 vCPU/2 GB/40 GB, Ubuntu 24.04, Nuremberg, $14.09/mo incl. IPv4 — CX23 sold out in every EU location) and waiting for the owner's "yes" before Create & Buy.** 20:20: the Claude-in-Chrome extension was not connected (it must be signed in to the same claude.ai account as Claude Code; restart Chrome) — the owner was offered the browser way or the hcloud CLI with a token they enter themselves (`hcloud context create easycraft`); a dedicated SSH key exists: `~/.ssh/easycraft_hetzner` (public half only goes to Hetzner). When resuming:
1. Load the Chrome tools, open the Hetzner Cloud Console in a new tab (the owner logs in; never type their
   password), create a project and a server as `docs/hosting.md` says (location, type, Ubuntu, SSH key;
   the cost estimate is in the guide), add a firewall (22 from the owner's IP, 80/443 open).
2. Point a domain (or the owner's subdomain) at the server's IP; on the server run the hosting kit
   (`server/deploy/kit.sh`: Docker, Nakama with our module, PostgreSQL, Caddy with automatic HTTPS, daily
   backups, 14-day logs); set the server and console secrets in its `.env` (never committed).
3. Set `OnlineConfig.RELEASE_SERVER` (and `RELEASE_SERVER_KEY` = the server's socket key) in
   `core/net/online_config.gd`, run the online tests against it, build a release APK, and check PLAY ONLINE
   from the emulator and a desktop game through the real server.
4. For under-13 online play: the owner registers a parental-consent provider (e.g. Kids Web Services);
   until then children under 13 stay on solo, LAN and bots in release builds.

## Keep-going loop
**Deleted at 21:42** (cron `9210da38`) because the owner paused work. To resume the non-stop roadmap when the
owner says so, create it again with the same prompt (`claude-hist search "Keep-going loop"`), at :07, :27 and :47.
Delete it only when M2–M5 are built, accepted and documented, and a release APK is in `~/Downloads`.
