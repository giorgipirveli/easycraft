# M4 Task 8b, agent G: data rights and retention (2026-09-24)

Spec §5.14, §17.2 (and §16's data-policy must-have); plan M4 Task 8b; the store drafts `docs/store/`
(`data-safety.md`, `privacy-policy.md`, `data-retention-and-security.md`), whose promises this makes
true. Built in a worktree from `0660a6f` (M2, M4 Waves 1 and 2 merged; module 0.2.2) while other
agents worked on M3 and the M2 HUD. No editor or emulator was used. Server work was tried on my own
server (compose project `easycraft_g`, ports 7589–7591, removed at the end); the lead's development
server was only used by the GUT suite's usual real-server tests.

## What was built

| Part | Where |
|---|---|
| **Delete my online account, server** (module **0.2.3**): `delete_account` in two calls (the first hands out a confirmation that lasts 10 min, kept server-only in `limits/delete_account`; the second deletes). It removes every friend edge both ways, the player from other children's requests waiting for a grown-up, notifications the player sent (invites, Nakama's friend notes), every DM with the player (both sides), the player's name from reports they made (re-keyed: the old key named them; reports **about** them stay for the reviewer), every storage object in `profiles`, `parent`, `codes`, `farm`, `invites`, `limits`, `activity`, then `nk.accountDeleteId(id, true)` (the database cascade takes devices, wallet and ledger, notifications to them, messages they sent; their sessions are logged out, so they leave every match and channel). The owner runs the same RPC without a session (the runtime HTTP key, or the console's API Explorer with an empty User ID) naming the account. Nakama's own `DELETE /v2/account` is refused (`use_delete_account`) | `src/rules/deletion_rules.ts` (`DeletionRules`), `src/server/deletion.ts` (`Deletion`, `rpcDeleteAccount`, `beforeDeleteAccount`), `Server.rpcOrAdmin` (`common.ts`) |
| **Retention clean-up**: every device sign-in records itself (`activity/signed_in`, server only); the first sign-in after 24 h (1 h when the last run stopped at a limit) runs the job, claimed by a versioned write of the system-owned guard `activity/retention` so two sign-ins never both run it; `retention_run` runs it for the owner only. One run: accounts without a sign-in for 13 calendar months (else their last account change) deleted as above (≤ 50), chat messages older than 30 days (≤ 5,000), what a console deletion leaves (notifications from and DMs with players who no longer exist, their names on reports), reports: the review time written in once (`reviewed_ms`), deleted 12 months after it (≤ 1,000 changes). A failing run is logged, recorded and not retried at every sign-in | `src/rules/retention_rules.ts` (`RetentionRules`: calendar months, cutoffs, the report step, the once-a-day guard), `src/server/retention.ts` (`Retention`, `afterAuthenticateDevice`, `rpcRetentionRun`) |
| **A snapshot of the reported message**: `report_user` with a `message_id` stores `message` (`text` or `emote`, `at_ms`, `source`): the server's own copy (`"server"`: an after-ChannelMessageSend hook keeps each passed-on message an hour in Nakama's in-memory cache; a kept DM is looked up in its history, only by one of its two players), else the copy the reporter's game sends (`"reporter"`, "as shown by the reporter"), else `null`; a copy from another sender or channel is not the message. Part of the report, so it goes when the report goes | `ReportRules.shownMessage` / `snapshot` (`report_rules.ts`), `src/server/snapshots.ts` (`Snapshots`, `rtAfterChannelMessageSend`), `social.ts` (`rpcReportUser`, 4 lines) |
| **DELETE MY ONLINE ACCOUNT, game**: a button on the grown-up area's ONLINE PLAY page (under-13 consent view and settings view) opens `DeleteAccountPage`: what goes (on our server) and what stays (on this device) in adult words, BACK and a red **HOLD TO DELETE** (`HoldButton`, 3 s, a fill grows; letting go, hiding or disabling starts over). The page asks for the confirmation when it opens and deletes when the hold ends; a late hold gets a new confirmation ("That took too long..."); in an online world it says "Leave the online world first". After it: "The online account is deleted..." and OK | `ui/parents/delete_account_page.gd`, `ui/parents/hold_button.gd`, `ui/online/grown_ups_panel.gd` (`PAGE_DELETE`, `in_online_world`, a marked section) |
| **The game forgets its online link**: `OnlineService.delete_account_start` / `delete_account`, then `forget_online`: signs out, deletes `online_files()` (the device id, `online.json` with the stay-safe card time and mutes, `wallet_sync.json`; each with JsonStore's `.bak` and `.tmp`: `DeviceId` would read a `.bak` back), clears the cached account, friends, invites, chats and wallet reports. The grown-up area signs in by itself only when `has_online_link()` (a device id is kept), so it never makes a new account. `Session.online_autostart` stays off (no card seen). Profile, worlds, gold, play time stay | `net/online_service.gd` (section "M4 Task 8b, agent G"), `core/net/online_rules.gd` (two messages, one alias) |
| **PLAY ONLINE after a deletion**: while its grown-up area is open, the screen no longer turns "signed out" into "Can't reach the game" (the area speaks for itself); when the area closes after a deletion, PLAY ONLINE closes too (its pages were the deleted account's, and TRY AGAIN would make a new one); after a real network drop it shows the failure then | `ui/online/play_online_screen.gd` (a G section, two lines) |
| **The game sends the message it showed with a report** (`shown_message`: `{"text"}` or `{"emote"}`, `at_ms`) | `OnlineService.report_message` (one line) |
| **Log rotation**: every service's Docker log `json-file` 10 MB × 5 (size only: Docker has no age limit, so no addresses go there); Caddy's access log in its own file on the `caddy_logs` volume, `roll_at 00:00`, `roll_keep_for 288h`, `roll_keep 30`, `roll_size 50MiB`: no line older than 14 days; its format drops headers and cuts `token` / `http_key` out of the address; Caddy's own (Docker) log drops `remote_ip`, `client_ip`, headers and those query keys. `./kit.sh access [lines]` shows it | `server/deploy/caddy/Caddyfile`, `docker-compose.yml`, `kit.sh` |
| Docs | `server/README.md` (RPCs, hooks, storage, "Deleting an account", "Retention", tests), `docs/hosting.md` (what the logs keep, reviewing reports, a parent's deletion request step by step, the clean-up), `docs/store/*` ("(enforced)"), `DEVELOPMENT.md` (architecture, kit, 5 gotchas), spec §17.2 |

## Patterns (GodotPrompter skills `godot-ui`, `save-load`)

- **Chosen:** the delete page as a code-built `VBoxContainer` of containers with UiKit's theme inside the
  grown-up area's content (like F's pages), shown from a button on ONLINE PLAY; a small `Button`
  subclass for hold-to-confirm whose fill is drawn in `_draw` and advanced by an explicit `step(delta)`
  (testable without real time), letting go on `button_up`, visibility change and `NOTIFICATION_PAUSED`
  (DEVELOPMENT.md's paused-touch gotcha). For the files: one list of what the device keeps about the
  online account (`online_files()`) and delete each with JsonStore's `.bak` and `.tmp`, checking the
  result (the skill's "check return codes").
- **Rejected:** a 4th tab (the tab row is 1,022 of 1,224 px already); a `ConfirmationDialog` popup
  (small buttons, a stray tap on OK is exactly what must not delete); a Tween for the fill (the hold's
  time must be the logic, not an animation); typing "DELETE" (a keyboard for a quick grown-up action;
  the parent gate is already in front); overwriting the files with empty JSON instead of deleting them
  (a file would stay, and `DeviceId` would keep reading a `.bak`).

## Tests (RED → GREEN)

- **Node (server)**, written first, RED for the right reasons: `retention_rules.test.ts` (10: "Cannot
  read properties of undefined (reading 'monthsBefore')" ...), `account_deletion.test.ts` (10:
  `S.rpcDeleteAccount is not a function`, `DeletionRules` missing), `retention.test.ts` (11:
  `rpcRetentionRun` / `afterAuthenticateDevice` missing; the registration test stayed RED until the
  snapshot hook existed), `report_snapshot.test.ts` (10: `shownMessage`, `rtAfterChannelMessageSend`
  missing), then GREEN. The fake Nakama learned account deletion with the database's cascade (and a
  switch to turn the cascade off, to prove the module removes things itself), `storageList`,
  `uuidv4`, the local cache, storage times in seconds on a test clock, and the new SQL.
  **`npm test`: 164 → 205**, all passing.
- **Mutation checks** (a line removed, the tests failed, restored; `scratchpad` scripts): each of
  the six deletion steps (1 failing each), the confirmation check (3), the guard's version write (2),
  orphan notifications (2), the review stamp (2), the sign-in record (3), the daily wait (3), `more`
  (2), the snapshot's sender, channel and DM-membership checks (1 each), the after hook (1), the
  server-copy branch (3), the reporter's time bound (1); GUT: forgetting the files (3), the no-link
  check (the run broke off), the hold's reset (2), the report's message (1), the prefs reset (2),
  PLAY ONLINE's close after a deletion (1) and its "network" page while the area is open (1).
- **Against a real Nakama 3.41** (my server, 0.2.3): `test/integration/data_rights.server.ts` (7,
  new: the player's two calls with every trace checked through the console and the friend's API; the
  owner's by name through the HTTP key and the console's API Explorer; `DELETE /v2/account` refused;
  the sign-in record and the day's guard; `retention_run` owner-only deleting an account whose last
  sign-in was set 14 months back; a team-room message's snapshot `source: "server"`, cleaned). It failed
  once, rightly: Nakama's own friend notes carry the player as sender (4 notifications, not 1). All
  real-server tests: **20 → 27, 27/27**.
- **By hand on my server** (psql, the console): after deletions no orphan storage, ledger rows,
  devices, friend edges or notifications; 8 tombstones for 8 deletions; the same device id signs in as
  a new account; a kept DM message reported **after a restart** (cache empty) came from the history
  (`source: "server"`); a DM message aged 40 days in the database was removed by `retention_run`
  (the fresh one stayed); a report set to "reviewed" in the console got `reviewed_ms` = the console
  save's time, one with `reviewed_ms` 13 months back was deleted; a reporter deleted with the
  console's Delete lost their name from the report at the next run.
- **Caddy 2.11.4** (the kit's image, a throwaway container): `caddy validate` passes; a request with
  `?token=SECRET-TOKEN` and one with `?http_key=SECRET-KEY` wrote `remote_ip` and a path without them
  to `/var/log/caddy/access.log`, and Docker's log got the upstream error without any address or key.
- **GUT**: `tests/unit/test_hold_button.gd` (4), `tests/integration/test_delete_account.gd` (10: the page
  from ONLINE PLAY for both bands, fits the menu's panel with ≥ 135 × 64 buttons, what goes and stays;
  a tap or a 2 s hold deletes nothing; 3 s deletes, every online file and its `.bak` gone, the profile
  and gold stay; afterwards the area makes no new account and play time still shows; a late hold asks
  again; in an online world "leave first"; the server's refusal in plain words; **the offline game
  after deletion**: Survivor gold on the host, codes on the phone, LAN hosting, no autostart, and PLAY
  ONLINE later makes a fresh account from the stay-safe card; from PLAY ONLINE's grown-up area the
  screen closes after deleting and makes no new account; a report sends the message as shown),
  `tests/unit/test_hosting_kit.gd` (+4: every service's Docker log, the access log rolled at midnight
  and gone within 14 days, no tokens/headers/addresses where they must not be, Nakama at INFO). The UI
  tests were written before the page but first run after it: the key lines were mutation-checked
  instead (above). The hosting-kit tests were RED first (the Caddy ones), then GREEN. Agent F's
  `test_grown_up_area.gd` (11), E's `test_online_chat.gd` and C's `test_online_screens.gd` pass
  unchanged with the new button.
- Full suite: see "Suite" below.

## Measurements

My server, this PC, load average 10.6–11.0 (18:50): a device sign-in (the after hook: one storage
write, one read of the daily guard) **6.7 ms median** (max 9.8, n 30); `retention_run` with nothing to
do **8.3 ms**; with 50 inactive accounts **317 ms** (≈ 6 ms an account); `delete_account`'s second call
(one friend, one report) **20.7 ms median** (max 21.9). The day's run happens inside one sign-in: with
nothing to delete it adds ~8 ms to that one; a backlog is capped per run (50 accounts ≈ 0.3 s here,
phones never wait on it: the server does).

## Rulings (decisions made on the owner's behalf)

1. **Two calls with a confirmation (10 minutes, server-only)**; the game asks for it when the page
   opens and deletes when the hold ends. *Cost if wrong:* a grown-up who leaves the page open for more
   than 10 minutes holds twice (the page says so).
2. **Hold 3 seconds** (behind the parent gate), not a typed word. *Cost if wrong:* a typed "DELETE"
   is one field on the page.
3. **The button is on ONLINE PLAY, not a 4th tab** (the tab row has no room). *Cost:* one more tap.
4. **Not while this game plays in an online world** (that world runs on the account's connection):
   "Leave the online world first". *Cost:* a parent leaves the world first.
5. **The device forgets its online link completely**: device id, `online.json` (the stay-safe card and
   the **mutes**), `wallet_sync.json`; the profile, worlds, gold, codes used and play time stay. *Cost
   if wrong:* a child's mutes are forgotten (their friends are gone too); keeping them is one path less.
6. **The grown-up area signs in by itself only on a device with an online account** (changes agent
   F's area: on a device that never went online it says "This device has no online account" instead of
   making an empty account). *Cost if wrong:* none known: before the child's name claim there was
   nothing a grown-up could set.
7. **Reports the deleted player made:** re-keyed, `reporter_id` and `reporter_username` blank,
   `reporter_deleted_ms`; **reports about them** stay (with their name) until 12 months after review, as
   the task says. *Cost if wrong:* a lawyer may want the reported name removed too: one field.
8. **Every DM with a deleted player goes, both sides**, and the notifications they sent (invites and
   Nakama's own friend notes, which name them). *Cost:* the friend loses messages they could no longer
   open anyway.
9. **Nakama's own client deletion is refused**; the console's Delete button still works (Nakama's
   cascade), and the next daily run removes what it leaves (names on reports, notes they sent, DMs with
   them). The owner's steps use `delete_account`. *Cost:* none.
10. **Nakama's deletion is recorded** (`recorded = true`: a tombstone of the id, nothing else); the same
    device id then signs in as a new account (checked). *Cost:* none.
11. **The clean-up runs from sign-ins** (after every device sign-in, at most once a day, claimed by a
    versioned write so only one sign-in runs it; an hour later while a backlog lasts) and from
    `retention_run` for the owner. Rejected: a cron container calling `retention_run` with the HTTP key
    (one more service holding a secret). *Cost if wrong:* a server nobody signs in to cleans up only
    when someone does or the owner runs it; a one-line `curl` loop service in the kit would add a clock.
12. **"Last sign-in" is our own record** (Nakama keeps none): `activity/signed_in` at every device
    sign-in; an account without one counts from its last account change (`users.update_time`). *Cost if
    wrong:* only accounts made before 0.2.3 (the development server's) can be deleted earlier than 13
    months after their real last sign-in.
13. **Months are calendar months in UTC**, a missing day (31 February) the month's last; "13 months"
    is strict (exactly 13 months is not yet). *Cost:* none.
14. **A report's review is `"status": "reviewed"` set in the console**; the clean-up writes that save's
    time into `reviewed_ms` at its next run and deletes 12 months later; **a report nobody reviewed is
    kept**. *Cost if wrong:* an owner who never reviews keeps reports forever (a cap for unreviewed
    reports is one rule).
15. **Per-run limits: 50 accounts, 5,000 messages, 1,000 report changes.** *Cost:* a big backlog takes
    several runs an hour apart.
16. **Old chat goes by SQL on Nakama's `message` table** (every channel: only DMs are kept anyway),
    because the runtime can't list channels; notifications, held requests and a player's DMs likewise.
    *Cost if wrong:* a Nakama upgrade that changes those tables breaks the job (logged, recorded in the
    guard; `data_rights.server.ts` checks the job's result has no error).
17. **The snapshot is the server's own copy when it has one** (1 hour in memory for any message it
    passed on; a kept DM's history), else the reporter's copy marked `"reporter"`; only with a
    `message_id`, only that message; the server's copy wins when both exist. *Cost if wrong:* after an
    hour or a server restart, a team-room report carries the child's word only (marked so); several
    Nakama nodes would need a shared store.
18. **Logs:** Docker's `json-file` limits size only, so the 14-day promise is kept by Caddy's access
    log in its own file (rolled at midnight UTC, rolled files kept 12 days: nothing older than 14 days;
    no headers, no tokens or HTTP key) and by keeping addresses out of Docker's logs (Caddy's own log
    filtered; Nakama at INFO logs none: 2,539 lines of the development server's log checked). This
    replaces agent D's ruling 11 ("no access log"), as the task and the store drafts ask for a 14-day
    security log. *Cost if wrong:* to keep no address log at all, delete the site's `log` block.
19. **Backups**: a deleted account stays in the kit's 7 daily backups up to 8 days; the store draft's
    "35 days" now covers only the provider's backups. *Cost:* the lawyer's wording.
20. **Module 0.2.3.** *Cost:* none.
21. **PLAY ONLINE closes after a deletion made from its grown-up area**, and while that area is open a
    sign-out is not shown as a network failure (a real drop shows when the area closes). *Cost if
    wrong:* the child lands on the main menu instead of PLAY ONLINE's first page; one line.

## Suite

GUT: **2,614 → 2,632 tests** (268 → 270 scripts), 2,631 passing, 1 pending as before, 0 failing
(`tests/run_tests.sh` exit 0, 19:15, load average ~30 from other agents). An earlier full run had one
failure outside this work, `test_hiding_in_world.gd` `test_breaking_the_barrel_brings_the_player_out`
(load 26); it passed alone and in the final run: a load flake for the lead to watch. Node **164 →
205**. Real server **20 → 27**.

## For the lead

**Merge notes.** Server: `main.ts` (version 0.2.3, five registrations), `tsconfig.json` (five files),
`common.ts` (`rpcOrAdmin`), `store.ts` (`ACTIVITY`), `social.ts` (`rpcReportUser`: the value built
first, `message` added), `report_rules.ts` (appended), `test/fake_nakama.ts` (clock, notification ids
and senders, SQL dispatch, a G section), `nakama.server.ts` and `wallet_host.test.ts` expect 0.2.3.
Then build and copy `build/index.js` into the main checkout and restart `easycraft-nakama` (log: `module
0.2.3 loaded`). Game: `OnlineService` (a G section at the end; one line in `report_message`),
`OnlineRules` (two messages, one alias), `GrownUpsPanel` (a const, a var, three lines in `show_page` and
`_online_ready`, a G section), `PlayOnlineScreen` (one connect, one line in `_show_grownups`, two in
`_on_status_changed`, a G section), the fake server (`report_user` keeps `message`; a G section). New
`class_name`s: `HoldButton`, `DeleteAccountPage` (`--import`). Kit: `Caddyfile`, compose (`caddy_logs`),
`kit.sh access`. A server already running the kit needs `./kit.sh update` for the new Caddyfile and
volume.

**Check with two games** (emulator + desktop, the development server with 0.2.3):
1. Desktop (private `XDG_DATA_HOME`), a claimed 13+ player friends with the emulator's: SETTINGS →
   GROWN-UPS → the gate → ONLINE PLAY → DELETE MY ONLINE ACCOUNT: the words fit the screen; a tap on
   HOLD TO DELETE does nothing; hold 3 s (mouse held) → "The online account is deleted..." → OK →
   "This device has no online account". The emulator's friends list loses the player; the console's
   Accounts page no longer finds the name; `device_id.json`, `online.json`, `wallet_sync.json` are gone
   from the data dir, `profile.json` and `worlds/` are not.
2. The same desktop: Sandbox, Survivor (gold), bot friends and HOST ON LAN still work; PLAY ONLINE shows
   the stay-safe card and a name claim (a new account).
3. On the emulator (under-13 with the fake consent): the page from the consent view and from the
   settings view fits the 1280 × 720 screen; the red button is easy to hold.
4. In an online world (pause → SETTINGS → GROWN-UPS → the gate → ONLINE PLAY → DELETE...): "Leave the
   online world first".
5. Team room: the emulator's player sends a quick phrase, the desktop reports it (tap the line →
   REPORT) → the console's `reports` object has `message.source: "server"` and the phrase.
6. Console → API Explorer → `retention_run`, User ID empty, body `{}` → an answer with counts; Storage
   → `activity` → `retention` shows the run. `delete_account` by `{"username": ...}` then with
   `"confirm"` deletes a test account (the owner's steps in `docs/hosting.md`).
