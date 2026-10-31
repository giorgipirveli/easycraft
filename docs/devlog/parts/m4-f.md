# M4 Wave 2, agent F: accounts, parents and the economy online (2026-09-24)

Spec §17.1, §17.2, §17.6 (with §5.6, §5.11, §5.14, §6, §7.3–7.4); plan M4 Tasks 2, 3 and 8, client
side, plus the lead's review finding on online gold (below). Built in a worktree from `9238c36`
while agents E (chat and co-op) and A2 (world sync part 2) worked in parallel. No editor or emulator
was used; server changes were tried on my own server (compose project `easycraft_f`, ports
7489–7491, removed at the end); the lead's development server was only read by the suite's usual
real-server tests.

## What was built

| Part | Where |
|---|---|
| **Profile backup** (§7.4, §17.1): the profile (`user://profile.json`'s JSON minus graphics, view distance and the FPS counter) in the player's private `profiles/profile` storage; uploaded at the first claim, at sign-in when the copies differ, 5 s after the profile stops changing (at most 30 s after the first change), and at once when the game quits or goes to the background; a new local profile (no progress: a reinstall on the same device) is restored at sign-in. Merge: the newer wins (`ProfileData.updated_at`, set by `Profile.save`), gold never goes backwards on this phone, and nothing earned is lost whichever wins (codes used, things owned, highest universe, Secret Book) | `core/save/profile_backup.gd` (`ProfileBackup`, pure), `net/profile_sync.gd` (`ProfileSync`, a child of `OnlineService`), `ProfileData.updated_at`, `Profile.saved` |
| **Codes by the server** (§5.11, §17.6): signed in, `redeem_code` decides (once per account; a code the server adds works without an app update); offline, the phone's `CodeRules` as before; a network failure falls back to the phone. Codes used offline are recorded on the server at the next sign-in (`redeem_code {"hashes"}`, 50 a call, never paid again) | `OnlineService.redeem_code`, `record_offline_codes`; `CodePanel` (the admin field) uses it when signed in |
| **Survivor gold online** (§7.3, §17.1, §17.6; the lead's review): in an online world the server keeps each player's balance. The host starts a guest's wallet from the server (`get_gold_of`), never from the guest's own word; it reports every change of every player in its match (`wallet_award` with `user_id` + `match_id`, batched 5 s per player, earned and spent netted; the server limits it per player); a guest's game adds each change to its own phone's gold (`_rpc_gold_moved`). The phone's gold is reconciled with the server's ledger when signed in (`sync_wallet`: changes off the server's watch — solo play, LAN, codes used offline, the menu's shop — go up from a per-account marker on the device; a first sync sends only what the server lacks and a server with more gives it to the phone; never backwards). LAN is unchanged (the guest's word, §12.11) | `core/economy/wallet_report.gd` (`WalletReport`), `core/economy/wallet_sync.gd` (`WalletSync`), `net/online_wallets.gd` (`OnlineWallets`), Session section "M4 F", `OnlineService.report_gold` / `gold_of` / `sync_wallet` |
| **The Gold Farm's clock** (§5.6, §17.6): `farm_start` / `farm_peek` / `farm_collect` on the server's clock, ready for M3 Task 10 | `OnlineService` |
| **Parent controls** (§5.14, §17.2): the grown-up area behind the parent gate, from SETTINGS (GROWN-UPS beside BACK, in the main menu and the pause menu) and from PLAY ONLINE's "Ask a grown-up" / GROWN-UPS: ONLINE PLAY (the consent state in plain words, START / CHECK, online ON / OFF, chat OFF / QUICK / TEXT for 13+, SAVE), FRIEND REQUESTS (an under-13 player's requests with YES / NO), PLAY TIME (today, counted on this device only), DONE. From SETTINGS it signs in by itself (TRY AGAIN, or "coming soon" in a build without a server); play time works offline | `ui/online/grown_ups_panel.gd` (extended from agent C's), `ui/menus/settings_panel.gd` |
| **A grown-up approves an under-13 player's friends** (§17.2): the AddFriends hook keeps an under-13 player's request (or "yes" to one that came in) in `parent/friend_requests` and answers `needs_grown_up` ("Ask a grown-up to say yes in GROWN-UPS."); `approve_friend` lists them and answers each: yes sends the request on or makes them friends (`nk.friendsAdd` as the child) with notification 103 `{"what": "friend"}`, no forgets it (and removes a request that came in) | `server/modules/src/rules/friend_approval_rules.ts`, `src/server/parents.ts`, `social.ts` (hook); `OnlineService.friend_approvals` / `approve_friend` |
| **Play time** (§5.14 parent corner): seconds per local day while the game is open and in front (menus count; the background does not; one step never counts more than 5 s), 7 days kept, `user://play_time.json`, never uploaded | `core/save/play_time.gd` (`PlayTime`), `ui/parents/play_clock.gd` (`PlayClock`, made by Session, never headless) |
| **Google Play Age Signals** (§17.2): an interface with a no-op on the desktop and in tests, and an Android adapter that uses a plugin singleton when the APK has one (not built: ruling 11); the store's range maps to our bands and only ever makes the phone's band stricter | `core/validation/age_signals_rules.gd` (`AgeSignalsRules`), `net/age_signals.gd` (`AgeSignals`), `net/android_age_signals.gd` (`AndroidAgeSignals`), `OnlineService._f_on_age_signal` |
| **Server module 0.2.2** (0.2.1 is agent E's): `approve_friend`, `get_gold_of`, `wallet_award` for a guest by its match's host, `redeem_code {"hashes"}`, the AddFriends hook | `server/modules/src/`, `server/README.md` |
| Storage in the backend | `OnlineBackend.read_storage` / `write_storage` (Nakama: private, owner read and write), the fakes in `tests/fakes/` |

Shared files, each in a marked section or a one-line call: `autoloads/session.gd` (section "M4 F",
`_f_ready()` in `_ready`, one line each in `gold_add`, `gold_spend`, `_store_gold`, `_rpc_gold_hello`,
`_rpc_gold`), `autoloads/profile.gd` (`saved`, `updated_at`), `net/online_service.gd` (section
"M4 Wave 2, agent F", one call each in `_ready`, `sign_in`, `claim_username`),
`net/online_backend.gd` / `net/nakama_online_backend.gd` (storage), `core/net/online_rules.gd` (two
messages, the account's `gold`), `core/codes/code_rules.gd` (`RECORD_CHUNK`),
`ui/menus/code_panel.gd`, `ui/menus/settings_panel.gd`, `tests/fakes/*` (a marked section).

## Patterns (GodotPrompter skills `save-load`, `godot-ui`, `mobile-development`)

- **Chosen:** JSON with the profile's own version field for the backup (the skill's "JSON for game
  saves, never Resources for data from outside": a backup comes from the network); pure rules for
  every decision (`ProfileBackup`, `WalletSync`, `WalletReport`, `PlayTime`, `AgeSignalsRules`) and
  thin nodes around them (`ProfileSync`, `PlayClock`), as `core/` works everywhere else; the backend
  interface extended (`read_storage` / `write_storage`) so tests keep the fake; one row of big toggle
  buttons for the grown-up area's pages, built in code with containers and `UiKit`'s theme, like every
  menu here; an adapter interface with a no-op for the platform API (`AgeSignals.for_platform()`).
- **Rejected:** `.tres` resources for the backup (they can run code: never for data from outside);
  `TabContainer` for the pages (small tabs; and Godot 4.7 wraps its tab bar in an internal node, the
  gotcha M2 Task 6 hit); `FoldableContainer` (small headers); a `ScrollContainer` for the whole area
  (touch scrolling is fiddly for a quick grown-up check); calling the Play library through
  `JavaClassWrapper` without a device to test on (a half plugin: ruling 11).

## Tests (RED → GREEN)

- Node (server): `test/parents.test.ts` (14: approvals rules, the hook, `approve_friend`, codes by
  hash) and `test/wallet_host.test.ts` (5: `get_gold_of`, `wallet_award` for a guest, who may, the
  version) were written first and failed for the right reasons (`Cannot read properties of undefined
  (reading 'needsApproval')`, `C.record is not a function`, `S[fn] is not a function`, "Missing
  expected exception"), then passed. `npm test`: **141 → 160**. Against a real server (my own,
  0.2.2): `test/integration/parents.server.ts` (4, new) and agent B's `nakama.server.ts` (14 → 15:
  host wallets added; its `befriend` helper now answers `needs_grown_up` through `approve_friend`, and
  it expects 0.2.2): **19/19**. The first real run failed once, rightly: the approval notification was
  not persistent, so it never showed in the list; it is persistent now (tested).
- GDScript: `test_profile_backup` (10), `test_wallet_report` (5), `test_wallet_sync` (6),
  `test_play_time` (6), `test_age_signals` (7), `test_profile_sync` (9), `test_online_economy` (14),
  `test_online_wallets` (15), `test_grown_up_area` (11), `test_nakama_profile_backup` (2, real
  server: skipped without one; `EASYCRAFT_TEST_SERVER=host:port` picks another server).
  RED seen for the grown-up area (parse errors: `PAGE_ONLINE` etc. missing), `WalletReport`'s spends
  (`[15] expected [8]`), the fake's approvals; the first rules (`ProfileBackup`, `PlayTime`,
  `AgeSignalsRules`, `WalletSync`) were written right after their tests without a RED run, so their
  key lines were **mutation-checked** instead (removed, the tests failed, restored): gold never
  backwards, the codes union, the debounce, codes recorded at sign-in, the batch wait, the marker
  moved by a code the server paid, the host seeding from the server.
- Suite: **2366 → 2451** tests (2365 → 2450 passing; 238 → 248 scripts), 0 failing, 1 pending as
  before. Agent C's online tests pass unchanged with the new area and the fake's approvals.

## Measurements

My server, this PC, load average 15 (16:15): a profile upload 13.2 ms median (max 13.7), a wallet
sync (the account's gold + one `wallet_award`) 21.7 ms median (max 35.2) — mostly the one frame each
call waits (`_settle`). A sign-in now adds a storage read, a write when the copies differ, one
`redeem_code {"hashes"}` when the phone used codes, and the wallet sync: about 50–70 ms on this PC.
The host's reports are one call per player every 5 s at most while gold changes (none while it
doesn't). Play time: one float add per frame and a small file write a minute.

## Rulings (decisions made on the owner's behalf)

1. **Only an account with a claimed name is backed up** (before the claim there is no name to restore
   to). *Cost if wrong:* a player who never went online has no backup (nothing to restore into).
2. **Graphics, view distance and the FPS counter stay on the phone**; every other setting travels.
   *Cost if wrong:* a restored phone takes the old volume or style; one list to change.
3. **The merge:** the newer profile wins by `updated_at` (the phone's clock at `Profile.save`); a
   profile with no progress counts as older than any backup; the gold is the winner's or this phone's,
   whichever is more (never backwards here, and no gold back for spending: spending makes the phone
   newer); codes, things owned, treasures and hints are joined; the universe and the Secret Book's
   counts take the higher. *Cost if wrong:* a phone with a wrong clock can lose to an older backup
   (earned things still merge); with account linking (two phones, one account) "the higher gold"
   needs revisiting.
4. **A reinstall restores only while `user://device_id.json` survives.** DeviceId lives in `user://`
   (agent C's ruling: no hardware id) and Android's app-data backup is off in the export presets, so
   a real uninstall makes a new account; the restore serves a lost or broken profile on the same
   install now and account linking later. *Cost if wrong:* if the owner expects a restore after a real
   reinstall: account linking, or turning on Android's data backup (a privacy decision for children).
5. **Uploads:** 5 s after the profile stops changing, at most 30 s after the first change, at once on
   quit or background (best effort; the next sign-in uploads anyway); a save that changed only the
   time (an autosave) writes nothing. *Cost if wrong:* a few more or fewer writes; two constants.
6. **Codes:** signed in, the server decides; a network failure falls back to the phone (then recorded
   at the next sign-in); codes used offline are recorded **without pay** (their gold reaches the server
   through the wallet sync, within its limits), and an unknown hash is never a wrong guess (hashes
   ship in the app anyway). *Cost if wrong:* a modified game can mark codes used on its own account
   (it only hurts itself).
7. **Online gold (the lead's review):** the server keeps each player's balance; the host reads a
   guest's starting gold from the server (`get_gold_of`, allowed only to the host of the guest's
   match) and reports every change of every player; a guest's phone adds each change to its own gold.
   When the server can't answer the host (not signed in, the network), the guest's own word is used, as
   on LAN. *Cost if wrong:* in that case online trust equals LAN trust for that session.
8. **Reconciling the phone with the ledger** by a per-account marker on the device (`user://
   wallet_sync.json`): changes off the server's watch go up as awards or spends; what the server's
   limits refuse stays on the phone and goes up later (meanwhile an online world may show a guest less
   than its HUD, and Tilly checks the server's view). A first sync on a device sends only what the
   server lacks; a server with more gives it to the phone. *Cost if wrong:* a modified game can still
   report "offline" gold up to the server's limits (20,000 × 2^(u−1) an hour) — the same trust as
   offline play, bounded; a server-only balance would need offline Survivor to stop earning.
9. **`wallet_award`'s reason is "other"** for every report (the host's `gold_add` reasons are not
   passed through yet) and the universe for the limits is the profile's highest. *Cost if wrong:* a less
   informative ledger; a looser limit for a player in a lower universe.
10. **Every under-13 friend request waits for a grown-up**, both ways, even with consent (§17.2 "approve
    friends"); at most 20 kept, 30 days; approving is behind the phone's parent gate (the same trust as
    `set_parent_settings`); notification 103 is persistent. *Cost if wrong:* a friend request takes a
    grown-up's tap; a switch "approve friends: off" would be one field in `parent/settings`.
11. **Age Signals: interface and a TODO, no half plugin.** The API is a Play library
    (`com.google.android.play:age-signals` 0.0.4, a Task-based call) that only a Gradle build can add,
    and the game's presets are not Gradle builds. `AndroidAgeSignals` uses a plugin singleton
    `EasyCraftAgeSignals` (`requestAgeSignals()`, signal `age_signals_result(json)`) when the APK has
    one; without it, nothing (never blocks play). A range with any age under 13 counts as under 13; the
    signal only ever makes the phone's band stricter (and so the first claim); an account already
    claimed as 13+ keeps the server's band until a grown-up changes it. *Cost if wrong:* the plugin
    (Kotlin, an EditorExportPlugin adding the Maven dependency) and one `set_parent_settings` call.
12. **Play time counts while the game is open and in front**, menus and the pause menu included, per
    local day, 7 days kept, never uploaded. *Cost if wrong:* "only in a world" is one check in PlayClock.
13. **The grown-up area** has three pages and DONE on one row; SETTINGS gets GROWN-UPS beside BACK (both
    menus). *Cost if wrong:* none.
14. **Module 0.2.2** (0.2.1 is agent E's chat). *Cost if wrong:* none; the merge takes 0.2.2.

## For the lead

**Merge notes.** Server: `main.ts` (version, two registrations), `social.ts` (the AddFriends hook),
`economy.ts` (`Economy.target`, `wallet_award`, `get_gold_of`, `recordOffline`), `tsconfig.json` (two
files), `test/fake_nakama.ts` (`friendsAdd`, `friendsDelete`), `test/integration/nakama.server.ts`
(`befriend`, the version, one test). Then `server/dev.sh reload`: the log should say `easycraft module
0.2.2 loaded`. Game: Session's M2 gold section has five one-line hooks (marked `M4 F`); agent C's
`test_online_*` pass unchanged; the fake server's `_add` now holds an under-13 request.

**Check with two games** (emulator + desktop, the development server with 0.2.2):
1. Desktop (private `XDG_DATA_HOME`): PLAY ONLINE → name → the console's Storage shows
   `profiles/profile` for the account; play a bit of Survivor solo, quit → the backup's
   `survivor_gold` follows (within ~5 s of the save, or at quit).
2. Delete only `profile.json` (+ `.bak`) in that data dir, keep `device_id.json` → start → the age gate
   and a name again → PLAY ONLINE (or just the autostart) → the old gold, universe and avatar items are back.
3. Admin panel code while signed in: +1,000; the console's wallet ledger has `source: code`; the same
   code again: "You already used that code." Offline on another fresh account: redeem, then sign in →
   `codes/redeemed` has the hash, the wallet has the phone's gold (award), not twice.
4. Desktop hosts a Survivor world online, the emulator joins: the emulator's HUD keeps its own gold;
   kill a monster / finish a wave → both players' ledgers show `source: award`, `by: <host id>`, within
   ~5 s; buy at Tilly's as the guest → a negative award. Nakama's log shows `get_gold_of` at the join.
5. Under-13 (with the fake consent) on the emulator: add the desktop's name → "Ask a grown-up to say yes
   in GROWN-UPS." → GROWN-UPS → the gate → FRIEND REQUESTS → YES → the desktop sees the request. The
   desktop asks the child → the child's YES → waits → the grown-up's YES → friends on both.
6. SETTINGS → GROWN-UPS (main menu and pause menu) → the gate → the area signs in by itself; PLAY TIME
   shows today's minutes after a few minutes of play; everything fits the emulator's screen.
