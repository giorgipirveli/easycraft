# M4 Wave 3, agent I — friends when they are not online together

Spec §17.5 (research additions), research `docs/design/long-term-roadmap-proposal.md` §5.2 ranks 5, 6
and 8 (T4 buddy playdates, D5 bottle mail, **T3 blueprint gifts and showcase visits — the signature
bet**), `engagement-and-child-psychology.md` T3, T4, D5 and their guards. Branch
`worktree-agent-ac91fdd9b34ab4c88`, cut from `m2-survive-the-night` at `5a9771a` (M3 Tasks 7 and 12 in).
No editor, emulator or godot-mcp was used; the lead checks with two games (below).

## What was built

| Piece | Where |
|---|---|
| Server module **0.2.4**: `send_gift` / `list_gifts` / `open_gift`, `publish_showcase` / `get_showcase`, `sign_guestbook` / `remove_sticker`, `send_bottle` / `list_bottles` / `open_bottle`, `report_build`; notes 104 (gift), 105 (bottle), 106 (sticker) | `server/modules/src/rules/build_rules.ts` (the build format, decoded and checked), `gift_rules.ts` (limits, stickers, guestbook, windows), `src/server/gifts.ts` (glue); `server/README.md` |
| Data rights for every new collection: `delete_account` removes the player's `gifts`, `bottles`, `showcases`, `guestbook`, the unopened gifts and bottles it sent (`gifts_sent`) and its stickers in friends' guestbooks (`stickers_left`); the retention job removes unopened gifts and bottles and stickers after 60 days and what console-deleted players left | `src/server/deletion.ts`, `retention.ts` (one line each), `gifts.ts` (`forgetSent`, `forgetStickers`, `retention`) |
| `BuildCodec`: the same format in the game (base64 of a version byte, the box's size, runs of (count, id) as LEB128; x, then z, then y); the server's limits read from its TS source by a test | `core/gifts/build_codec.gd` |
| **`BuildPicker`** (pure, M3 Task 8 reuses it): the connected non-natural blocks around a tap, at most 8 × 8 × 8 and 512, stopping as soon as it is too big | `core/building/build_picker.gd` |
| `BuildOutline`: the glow of a picked build (its open faces, lifted) or an area's frame, ONE shared unshaded material for every outline, one mesh | `ui/gifts/build_outline.gd` |
| `GiftStampBook`: friends' builds as stamps on this device (`user://gifts.json`, 20 slots = item ids **460–479**), placed by `Blueprints` like the M1 stamps (centred on the tap, away from the player; in Survivor paid with the blocks like every stamp); the child's own shelf of the last 8 picked builds | `core/gifts/gift_stamp_book.gd`; hooks in `data/items/item_ids.gd`, `data/blueprints/blueprints.gd`, `ui/hud/block_icons.gd` (a gift box drawn in code) |
| `GiftRules` (the game's side: stickers, plain words, careful reading of every answer), `ShowcaseArea` (the area, the snapshot, the waiting buddy), `BottleSpot` (water, beach, ground), `PlaydateRules` | `core/gifts/` |
| OnlineService section "M4 I" | `net/online_service.gd`: `send_gift`, `refresh_gifts`, `open_gift`, `discard_gift`, `delete_stamp`, `publish_showcase`, `remove_showcase`, `showcase_of`, `my_showcase`, `sign_guestbook`, `remove_sticker`, `send_bottle`, `refresh_bottles`, `open_bottle`, `discard_bottle`, `report_build`; signals `gifts_changed`, `sticker_received`; one line each in `sign_in`, `online_files`, `forget_online` |
| Friends page: **GIFT** and **VISIT** on a friend's row; **PRESENTS** and **MY SHOWCASE** beside ADD | `ui/online/online_friends_panel.gd` (section at the end; the list is 1100 wide, row buttons 135), `ui/gifts/gift_send_page.gd`, `bottle_page.gd`, `gifts_page.gd`, `guestbook_page.gd`, `sticker_picture.gd`; pictures `gift`, `bottle`, `visit` in `ui/online/online_icon.gd` |
| In a world: **SHARE** in the MORE panel (only in the child's own world, signed in with friends allowed): GIFT A BUILD (tap the build: it glows; SEND TO A FRIEND) and MY SHOWCASE (the golden frame; SHOW IT; the snapshot runs on a worker thread) | `ui/gifts/share_panel.gd`; `BlockInteractor.tap_override`; `HudIcons` picture `gift`; sandbox section "M4 I" |
| The palette's **GIFTS** tab (a gift box per stamp with who sent it; the small x deletes after SURE?; in Survivor the tabs are BLOCKS and GIFTS) | `ui/hud/block_palette.gd` (section at the end) |
| **The visit**: a small read-only world of its own (`VisitWorld`, `world/visit/visit.tscn`): a flat island in a calm sea (`VisitGenerator`, a per-cell rule on Voxel Tools' threads), the showcase in the middle, the friend's name on a sign, the friend's buddy waving, the visitor's player; the bar (`VisitPanel`): STICKER, REPORT, LEAVE | `world/visit/`, `ui/gifts/visit_panel.gd`, `WorldService.setup_visit`, Session section "M4 I" (`start_visit`, `leave_visit`) |
| **Bottles**: they float up near the child (`BottleShore`, this game only), a tap opens them (`GiftBottle` on the secret things' tap layer; one line in `SecretTaps.use`), `BottleCard` says who and what | `world/bottle_shore.gd`, `entities/gifts/gift_bottle.gd`, `ui/gifts/bottle_card.gd` |
| **Buddy playdates**: `PlaydateDirector` (node `Playdates` on every game; the host decides at most 10 times a second; the wave and the dance by one reliable RPC each); `Buddy.playdate_target`, `face`, `wave`, `dance`, `visiting` | `world/playdate_director.gd`, `entities/buddy/buddy.gd` (two lines in `_physics_process` and a section) |
| Smoke run in the real sandbox and the real visit scene; a reviewer's build viewer | `tools/gifts_smoke.gd` (+ `_steps`), `tools/show_build.gd` |
| Store drafts brought up to date (a shared build leaves the device) | `docs/store/privacy-policy.md`, `data-safety.md`, `data-retention-and-security.md`, `childrens-privacy-notice.md`; `docs/hosting.md` (reviewing a build report) |

## The guards (spec §17.2, the research's guard lines) and where each is enforced

| Guard | Server | Game |
|---|---|---|
| Friends only (mutual, state 0); no strangers, no public gallery | every RPC (`Gifts.friendOf`); `list_gifts` / `list_bottles` delete things from players who are no longer friends (or blocked) | the pages list friends only |
| Nothing for an under-13 player without verified consent | `AccountRules.canPlayOnline` for the caller; a child who may not be online is `not_found` as a target | `OnlineService.social_allowed` before every call; SHARE hidden |
| Sizes capped by the server | `BuildRules.decode` with `GiftRules.GIFT` (8³, 512), `BOTTLE` (4³, 64), `SHOWCASE` (32³, 48 KiB), `BUDDY` (17, 200); ids only blocks (1–99, 176–255; never an item or bedrock) | `BuildCodec` refuses the same before sending; builds read back only when whole |
| Preset stickers and phrases only | `GiftRules.STICKERS`, `ChatRules.isQuickPhrase` | the pages offer only those; `GiftRules.opened_bottle` drops anything else |
| REPORT on everything received | `report_build` (reasons bad_build / scary / other; shares report_user's 10-an-hour window; keeps the server's copy of a showcase, else the child's copy, marked) | GiftsPage (presents and stamps), BottleCard, VisitPanel; a sticker's REPORT is a `report_user` about the visitor; a report mutes the sender here and deletes the thing |
| Every received thing can be deleted by the child | `open_gift` / `open_bottle` with `discard`; `remove_sticker` | DELETE on presents, stamps (GiftsPage and the palette), stickers |
| Deleted with the account; retention | `Deletion.COLLECTIONS` + `forgetSent` / `forgetStickers`; `Gifts.retention` (60 days) | `online_files()` includes `user://gifts.json`: deleting the online account forgets friends' stamps |
| Visitors never change anything | — | the visit world never registers with Session: every edit request answers false; tested with place, break, a stamp, the wand, a door |

## Tests (RED → GREEN)

Tests were written first in each step; where they were green at their first run (the implementation
was written in the same step), each guard was **mutation-checked** instead: the check removed, the
test run red, the check put back.
- Node (`npm --prefix server/modules test`): **205 → 231**. New: `test/gift_rules.test.ts` (8: base64,
  the format, ids, decode refusals, limits, stickers, the guestbook, windows and keys),
  `test/gifts_rpcs.test.ts` (18: every RPC with its guards and caps (taking a showcase down always works), deletion and retention of the new
  collections, the module's version and registrations). Mutation checks: the friends-only check (4 tests
  red), the per-friend caps (2), `forgetSent` in the deletion (1), the retention hook (1), the consent
  check (2).
- Integration against a real server (`test/integration/gifts.server.ts`, 7 tests, on my own server
  `easycraft_i`): gifts, a 33 KB showcase visited by a friend, stickers, bottles to an under-13 friend
  with consent, a build report, deletion and retention **SQL on PostgreSQL 16** (the fake only knows
  it by its text). All integration files on `easycraft_i`: **34/34** (the two version assertions of G's
  and B's files moved to 0.2.4).
- GUT: **3087 → 3171** (3136 after the core and service commit; the final full run: 336 scripts,
  3171/3171 passing, 473 s under `nice` at load average ≈ 40, exit 0). New files: unit `test_build_codec.gd`, `test_build_picker.gd`,
  `test_gift_stamp_book.gd`, `test_showcase_area.gd`, `test_bottle_spot.gd`, `test_playdate_rules.gd`,
  `test_gift_rules.gd`, `test_visit_generator.gd`; integration `test_online_gifts.gd`,
  `test_visit_world.gd`, `test_share_panel.gd`, `test_gift_pages.gd`, `test_bottle_shore.gd`,
  `test_playdates.gd`, `test_palette_gifts.gd`. Mutation checks: codec ids, the picker's size cap.
- Smoke `tools/gifts_smoke.gd` (a new Sandbox world, the fake server): **22 checks, 0 failed**.
  Found by its first run: a tower standing lower than the child's feet lost its bottom block to the
  showcase (the area started under the feet) → the area now takes 8 layers under the feet
  (ruling 10); the fake server kept notifying a signed-out player's freed backend (the smoke signs
  Hopper out before Mia visits).

## Measurements (this PC, shared; load average given)

| What | Result |
|---|---|
| `send_gift` round trip, real server | 11–14 ms (load ≈ 40) |
| `publish_showcase` of a worst-kind area (32,780 characters: a new run nearly every cell) | 180 ms on the server (load ≈ 40); `get_showcase` 8 ms |
| A real showcase (a Sandbox spawn with a tower), 32 × 32 × 32 | 2.4–3.7 KB of text, 4,600–5,800 blocks |
| Reading a 32³ area cell by cell (the snapshot) | 85–128 ms on the main thread (load 25–41): now read from the copy's bytes on a **worker thread** (`ShowcaseArea.snapshot_async`); the main thread only makes the copy |
| Picking a 3-block build in the real sandbox (the pick, its glow, the panel) | 5–17 ms (load 25–41) |
| A playdate step (the host, 2 buddies) | 0.33–0.51 ms, at most 10 a second (≈ 0.05 ms a frame) |
| The visit: VISIT to standing on the island | 0.86–1.10 s (headless, load 25–41) |
| The visit's frames, 3 s after arriving | average 7.4–8.7 ms, worst 136–142 ms (the first streaming frames; headless at load 25–41: **check on the emulator**) |

## Rulings (decided on the owner's behalf; each with its cost if wrong)

1. **Storage**: one server-only object per unopened gift or bottle, owned by the friend it is for; the
   lists are the mailbox and the notes 104/105/106 are **not persistent** (only a nudge to an open game).
   *Cost:* none known; a friend offline sees the present at the next sign-in anyway.
2. **The build format** (base64: version, size, LEB128 runs) and ids 0–99 and 176–255 only; the server
   decodes every build. *Cost:* a block page above 255 needs format version 2.
3. **Limits**: gift 8³ / 512 (the BuildPicker's), bottle 4³ / 64, showcase 32³ and 48 KiB of text
   (publish_showcase's payload up to 56 KiB; every other RPC keeps 4 KiB), a waiting buddy 17 wide /
   200 blocks (the wand's cap); 10 gifts and 5 bottles unopened per friend, inboxes 50 and 30, 30 sends an
   hour each, 12 showcase changes an hour; the guestbook keeps 30 stickers, one per visitor per 10
   minutes. *Cost:* too strict shows a kind "wait" message; too loose costs storage.
4. **Retention**: unopened gifts and bottles, and stickers, **60 days**; the showcase stays while the
   account does (it is the child's own, and 13 quiet months delete the account). *Cost:* a child away
   two months misses a present (the sender can send again).
5. An opened gift is deleted on the server; on the device the stamp stays until the child deletes it,
   in `user://gifts.json`, **not in the profile backup**; deleting the online account forgets it.
   *Cost:* a reinstall loses friends' stamps.
6. **Item ids 460–479** for the 20 gift stamp slots (outside M3's 400–450); not catalogue items (never
   given, sold or in the MAGIC row). *Cost:* the lead adds them to the M3 allocation table.
7. **SHARE in the MORE panel** is the way in, in a world; any tap picks while SHARE picks (the wand's
   sparkle plays): the wand need not be in the hand (Survivor's starter hotbar has none). *Cost:* M3
   Task 8 may want the wand in hand; BuildPicker is agnostic.
8. **Only from the child's own world** (solo or host), never as a guest. *Cost:* a guest can't send a
   copy of a friend's build.
9. **GIFT on a friend's row** sends one of the builds picked earlier (the shelf, the last 8) or a
   bottle; picking needs a world. *Cost:* one extra step before the first present.
10. **The showcase area**: 32 × 32 × 32 around the child, from 8 layers under the feet (a build a little
    downhill comes too); the visit lays the layer the child stood on on its grass, and at or under it
    the showcase's air keeps the island's ground. *Cost:* a basement or a dug pool below the ground is
    hidden from visitors.
11. **The visit world is a scene of its own**, never registered with Session (read-only by
    construction), reusing the HUD with building hidden and the wand as the only item; no monsters,
    animals or saves; PAUSE, LEAVE and Back go to the menu. *Cost:* smart blocks don't work in a visit
    (no host logic there).
12. **"A buddy sent for a visit inside a showcase"** is read as the owner's buddy: the owner's buddy
    standing in the area when SHOW IT is pressed waits there, waving; no name travels (the game names
    it from its blocks). *Cost:* if the owner meant a visitor's buddy visiting, VISIT gets a "bring my
    buddy" later.
13. **Bottles float up at the start of play and when one arrives while playing**, for this player only
    (local nodes, never over the network; also when the child is a guest). *Cost:* none known.
14. A bottle's tiny build becomes a **gift stamp** (placed and paid like every stamp), never free blocks
    in the world. *Cost:* none; it keeps Survivor fair.
15. **Playdates** for any two buddies of different owners in one world (LAN too), host-decided, a
    pair rests 60 s. *Cost:* none known.
16. **REPORT** shares report_user's limit (10 an hour); it mutes the sender on this device and deletes
    the thing; a sticker's REPORT is a report_user about the visitor (a sticker is a preset picture).
    The reviewer reads a reported build with `tools/show_build.gd`. *Cost:* none known.
17. Muted and blocked players' things are **hidden** on the device (unmuting shows them again); the
    server deletes gifts and bottles from players who are no longer friends when the list is read.
18. The friends list widened from 780 to 1100 px (row buttons 135: TALK, GIFT, VISIT, MORE and JOIN
    fit). *Cost:* none; the page still fits the menu's panel (tested).
19. The Georgian line added to the children's privacy notice needs a native check (marked).

## Patterns (godot-prompter skills read: save-load, multiplayer-sync, godot-ui, multithreading)

- **save-load**: JSON through `JsonStore.write_atomic` with a version and a careful `from_json` (every
  stamp checked: slot, username, a gift-sized build) — rejected: Resources (untrusted data runs code),
  the profile backup (friends' names and builds would go to our server again).
- **multiplayer-sync**: the playdates ride the buddies' existing position sync; the two moments (wave,
  dance) are one reliable RPC each on the director — rejected: a synced "mood" property on every buddy
  (a field in every sync for a rare event).
- **godot-ui**: pages built from containers with the online screens' helpers (`OnlineUi`), the friends
  page's own page swapping and BACK (a page steps back inside itself first) — rejected: TabContainer
  (its internal nodes, M2 Task 6's gotcha). HUD overlays are anchored by presets and tested against
  every HUD button's rectangle.
- **multithreading**: the 32³ snapshot runs as one `WorkerThreadPool` task on the area's own copy,
  polled each frame and waited on — rejected: `Thread` (a long-lived worker for one job).
- The outline: one `StandardMaterial3D` shared by every outline (a static), one `ArrayMesh` of lifted
  open faces — rejected: a mesh per block, or a next-pass outline shader (a material per build).
- The visit's terrain: a `VoxelGeneratorScript` whose rule is a pure function of the cell (like
  `EditedGenerator`) — rejected: placing the showcase as edits into a Meadows world (terrain generation
  for nothing, and edits to undo).

## What the lead should check with two games (emulator + desktop, both signed in, friends)

1. **Desktop hosts a Sandbox world**: MORE shows **SHARE**; GIFT A BUILD → tap a small build: it
   glows gold; SEND TO A FRIEND → the emulator's name → toast. A build bigger than 8 × 8 × 8 says so.
2. **Emulator**: PLAY ONLINE → FRIENDS shows **PRESENTS (1)**; open it → "It's a stamp now"; in a
   world, palette → **GIFTS** tab → the gift box with the friend's name → tap it into the hotbar and
   place it (Sandbox: free; Survivor: pays the blocks, or says which are missing). Delete it with the x.
3. **Desktop**: MORE → SHARE → MY SHOWCASE: the golden frame around the player → SHOW IT (no hitch:
   the snapshot is on a worker thread).
4. **Emulator**: the friend's row → **VISIT** (with the desktop closed or not): the island, the build,
   the sign with the name, the buddy waving if one stood in the area; walk, fly, look; taps change
   nothing; **frame times on the emulator** (the headless worst frame was 136 ms while the island
   streamed); STICKER → a star; REPORT works; LEAVE → the menu.
5. **Desktop**: PLAY ONLINE → FRIENDS → MY SHOWCASE lists the star (DELETE works); TAKE IT DOWN; the
   emulator's VISIT then says "no showcase yet".
6. **Emulator** → the desktop's row → GIFT → A BOTTLE → "Hi!" and a tiny build → SEND. The desktop's
   next world (or at once if playing): a bottle bobs on the nearest water (or the beach, or the ground)
   → tap → the card; the tiny build is on the GIFTS tab.
7. **Both in one online match**, each with a buddy (wand): within 16 blocks they wave, walk together,
   dance, one follows the other, then back to their owners; a minute later again.
8. An **under-13** account without consent: no SHARE, no PRESENTS or MY SHOWCASE actions (the server
   refuses as well); with consent everything works.
9. The console: `reports` has the build reports with `build`; `tools/show_build.gd -- --file=<the
   copied text>` prints the layers.
10. The server: build the module in the main checkout (`docs/DEVELOPMENT.md` §8, "the lead's development
    Nakama"), `docker restart easycraft-nakama`, the log says `module 0.2.4 loaded`.
