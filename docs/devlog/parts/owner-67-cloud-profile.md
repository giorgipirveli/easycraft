# Owner feedback #67 (2): the account on every device ("when user is logged it feels loaded")

**Owner, 2026-09-28:** "remember username database info shouldnot get lost, it should be saved somewhere, simple
data, like resources and other important info so when user is loged it feels like username was loaded".

Branch `worktree-agent-a29fc59c6503f0a7d` (from `lead-merge` 9187c8b). Server module **0.2.12**. Spec §5.13 (Login),
§7.4, §17.1 (the new bullet "The account on every device"). The lead's part (1) of #67, 100,000 gold for sasa192974,
was done on the live server before this.

## What was there, and what was missing

M4 F already backed the profile up (`ProfileSync`, `profiles/profile`) and kept Survivor gold in the wallet ledger.
Reading it against the owner's words found six gaps:

| # | Gap | Effect for a child |
|---|---|---|
| G1 | **No way to sign in to an existing account on another device.** Nakama device auth only; a new phone or a browser whose storage was wiped (Safari after 7 days away, "clear data") made a new, empty account, and the old name was "taken" | Nothing came back anywhere. The backup restored only when `profile.json` was lost but `device_id.json` survived (spec: "until account linking [later]") |
| G2 | **A device that had synced once never took the server's gold** (`WalletSync.plan` with a marker kept the phone's number) | The owner's 100,000 gold for sasa192974 never reaches their game with the old client; gold earned on another device never arrives; gold spent on another device could be spent twice |
| G3 | The backup carried `survivor_gold` (written by the client), and the server stored any JSON under any `profiles/*` key | A modified game could park data or a gold number there; the restore took the higher gold |
| G4 | Last writer wins: a device uploaded without knowing what another device wrote | Two devices of one account wrote over each other's progress on the server |
| G5 | One device's things travelled: the browser's install-card answers (M7), the thumb buttons moved for one screen, the farm's phone note | A tablet's button places on a phone, a browser's install answers on Android |
| G6 | Uploads only 5-30 s after a save; a child who leaves a world and closes the game at once could leave the last change on the device | Rare lost progress until the next sign-in |

## What was built

**Server (module 0.2.12; `src/rules/key_rules.ts`, `profile_rules.ts`, `src/server/keys.ts`, `guards.ts`):**
- `account_key {action: state | new | sign_out_others}`: a claimed account makes a **sign-in key**: 8 Crockford
  base32 symbols (40 random bits from `nk.uuidv4()`), shown once as `XXXX-XXXX`, stored only as
  `sha256(salt + ":" + key)` with a random salt in `account/sign_in_key` (permission read 0: the game can't read it
  back); a new key replaces the old; 5 new keys an hour. `sign_out_others` unlinks every other device id, logs the
  account out (no refresh) and closes every socket on its notifications stream. Without a session (the owner: HTTP
  key or console) `state` and `new` name the account (`docs/hosting.md`: a family whose every device is gone).
- `sign_in_with_key {username, key, device_id}`: the asking game (signed in on its own, usually brand-new account)
  sends a **new** random device id; with the right name and key the server links that id to the account
  (`nk.linkDevice`) and deletes the asking account if it never claimed a name (`Deletion.run`). Wrong key, unknown
  name, a name without a key and a never-claimed name all answer `wrong_key`; 5 wrong for a name (known or not)
  in 15 min lock it 15 min, 10 wrong from one asking account in an hour lock it for the hour; the counts live in
  the node's local cache only.
- The storage write hook now allows only `profiles/profile` and **cleans the value in place** (`ProfileRules.clean`):
  a JSON object with `version` 1-99, sane shape (depth 8, lists 2,000, 1,000 keys, texts 1,024, finite numbers,
  64 fields, 64 KiB), no `survivor_gold`, no one-device fields or settings, no avatar `base`, known fields of the
  wrong kind dropped, `username` and `age_band` the account's. Unknown fields of a newer game pass (an app update
  never waits for the server).
- Deleting an account deletes `account` too; Nakama's cascade unlinks every device.

**Game:**
- `OnlineService` section "Owner #67": `sign_in_with_key`, `make_account_key`, `account_key_state`,
  `sign_out_other_devices`; at every sign-in a claimed account's name becomes the profile's.
- `ProfileBackup` layout 2 (`BACKUP_VERSION`, `"backup": 2`): no gold, `DEVICE_ONLY_FIELDS` and the longer
  `DEVICE_ONLY_SETTINGS` stay; per-group choice merge with `ProfileData.stamps` (stamped by `Profile.save` through
  `ProfileBackup.stamp_changes`); a new device takes all of the account's choices.
- `ProfileSync` writes by version and merges again on a clash; stops retrying a refused profile; the menu opening
  after a world flushes (`Session.online_autostart`).
- `WalletSync`: the phone ends a sync with the server's balance plus its own unreported change; `account.gold`
  follows the sync's own report; no sync inside an online world; the gold counter hears it.
- UI: PLAY ONLINE's name claim → **I HAVE AN ACCOUNT** → the parent gate → `KeySignInPage` (name, key, SIGN IN);
  GROWN-UPS → ONLINE PLAY → **OTHER DEVICES** → `AccountKeyPage` (MAKE A KEY / MAKE A NEW KEY, the name and key big,
  devices signed in, HOLD: SIGN OUT OTHER DEVICES 2 s). The delete page names the key among what goes.

## What the account keeps, and what stays on the device

| Kept with the account (on every device it signs in to) | Stays on the device | Why it stays |
|---|---|---|
| Online name (the account's), age band (the stricter of the two) | Worlds: blocks, buildings, the **Survivor bag**, buddies and pets in the world, homes, farms, portals | Too big (a world's `voxels.sqlite` is 100 KB to MBs; the backup is one ≤ 64 KiB object), and a bag belongs to its world: its items were mined there and are used there |
| Settings: volume, music volume and style, sound effects, song names, style (blocky/realistic), SIMPLE/CLASSIC controls, read-aloud, button size, left hand, text size, captions, reduce motion, vibration, jumps, block music, the first-launch card's answer | Graphics preset, view distance, the FPS counter | Depend on the device's power |
| The look (hair, face, clothes, hat, cape, wings, trail, outfit, dance wheel) and every costume owned | Boy / girl / just me | Owner #48: personal data; the look itself travels |
| Purchases (entitlements), the wish list, codes used (hashes) | Moved thumb buttons (`hud_moves`) | Placed and checked for one screen |
| Highest universe, crystals given and to give, the Secret Book and its treasures, stickers | The browser's install card answers | One browser's own question |
| Levels, XP, badges, presents, quests, keepsakes, titles (`progress`) | The farm's phone note and when it last rang | A notification on one phone |
| Pip and the baby dragon (names, collars), the Animal Book, saving list, pages rewarded, universes explored, buddy magic (shapes, album, minis, tricks), the tutorial, hints seen | Play time, the Memory Book, photos | M3 21b and M5 rulings: the device's own |
| The grown-up switches: Shorts Theater, photo sharing | Friends' gift stamps and ghost races, online prefs (mutes, the stay-safe card) | Kept for offline play; forgotten with the account (M4 G) |
| **Gold: the wallet ledger only** (never in the backup) | The wallet marker (`wallet_sync.json`), the device id | Per device and account |

## The merge (ProfileBackup.merge)
- **Earned things are never lost**, whichever copy is newer: unions (codes, cosmetics, purchases, wishes,
  treasures, hints), the larger count (Secret Book, stickers, crystals given), the higher universe, the data
  classes' own `merge_from` (progress, books, buddy magic, tutorial); Pip and the dragon never go.
- **The child's choices, per group, the newest**: look, settings, switches, pets (`ProfileBackup.GROUPS`). A group's
  stamp is set when a save sees its travelling JSON change; a group taken from another copy keeps that copy's stamp
  (so an older choice never looks new); a profile from before #67 has every group stamped with its `updated_at`.
- **The rest from the newer copy** (`updated_at`); a device with no progress yet takes everything from the account
  (a new phone "feels loaded" even if its starting look was picked a minute ago).
- **One device's things** from the local copy whichever wins; **gold** always the local number, then the wallet
  sync makes it the account's.
- Every write names the version it was merged with; another device wrote in between → read, merge, write again.

## When it saves
5 s after the profile goes quiet (at most 30 s after the first change), at once when the menu opens after a world,
when the game quits or goes to the background, at every sign-in (merge, then upload if different), and after the
first name claim. A save that changes only the time or the gold writes nothing. Offline, the profile on the device
is the queue: every menu visit tries to sign in (`online_autostart`), and the sign-in merges and uploads.

## Rulings (decisions made on the owner's behalf)
1. **A sign-in key, not a password or an e-mail.** The account stays "no password" (§5.13): a grown-up makes a
   key behind the parent gate, it is shown once, and the name plus the key sign a new device in. *Cost if wrong:*
   a family that loses the key and every device needs the owner (console steps in `docs/hosting.md`); if the owner
   wants Google/Apple linking, that is still [later] and needs a privacy review.
2. **The key is 40 bits, typed forgivingly, locked after 5 wrong tries per name for 15 min (and 10 per asking
   account per hour).** 480 guesses a day at most per name against 10^12 keys. *Cost if wrong:* someone could lock
   a child's name for 15 minutes by guessing (the key still works afterwards); the counts reset with a server
   restart (in-memory by design: nothing about a name nobody owns is written).
3. **I HAVE AN ACCOUNT is behind the parent gate** and only on a device with no claimed name. *Cost if wrong:* a
   child who claimed a new name on the new device by mistake can't switch; the family deletes that new account
   (GROWN-UPS → DELETE) and then signs in with the key. A "switch account" button would be a later step.
4. **The asking device's own account is deleted when it never claimed a name** (a new device's empty account).
   *Cost if wrong:* an unclaimed account with code gold in its wallet loses it on the server (the phone keeps it and
   the wallet sync sends what the account lacks).
5. **Gold is never in the backup; the device follows the wallet.** A sync ends with the server's balance plus the
   device's change the server has not taken yet. Gold can go down on a device when it was spent on another device
   of the account. *Cost if wrong:* if the server's wallet were ever wrong (a bad deploy), every device would follow
   it at the next sign-in; the ledger keeps every entry, so the owner can repair it.
6. **No wallet sync inside an online world** (the host's reports are batched 5 s). *Cost if wrong:* gold given on
   the server arrives when the child leaves the online world, not during it.
7. **Worlds stay on each device** (the lead's own instruction) and with them the Survivor bag, buddies and pets of
   that world; nothing player-level called "resources" exists outside the profile. *Cost if wrong:* if the owner
   means the Survivor bag must travel, the bag would have to become the account's (a game-design change), or
   `world.json` could be backed up per slot without its blocks (a world that comes back as it was generated, without
   what was built): both are possible next steps.
8. **Per-group "newest choice" with four groups** (look, settings, switches, pets), not per setting. *Cost if
   wrong:* two devices changing two different settings at once: the later device's whole settings group wins.
9. **The server cleans instead of refusing** (drops gold, one-device fields, wrong kinds; forces the name and band),
   and refuses only what is not a profile. Old clients (1.0.1, today's web build) keep working against 0.2.12.
   *Cost if wrong:* a modified game could still store up to 64 KiB of odd but well-shaped extra fields in its own
   private backup (only its own devices read it back, and each reads it through `ProfileData.from_json`).
10. **Sign out other devices** unlinks, logs out (no refresh) and closes sockets; a session token already handed
    out still answers plain HTTP calls until it expires (2 h, `token_expiry_sec`). *Cost if wrong:* a lost phone
    that is open in the game can make HTTP calls (not chat, not play) for up to 2 hours; a shorter expiry or
    Nakama's session cache would close that.
11. **The menu opening flushes the backup** (leaving a world), on top of the debounce. *Cost if wrong:* one more
    small write per world visit.

## Tests
- Node (`npm --prefix server/modules test`): **319 pass** (280 before): `key_rules.test.ts` (11), `profile_rules.test.ts`
  (10), `keys_rpcs.test.ts` (18: keys, the owner path, linking, locks, sign-out, deletion, the write hook), and the
  storage guard test updated (one key only; cleaned).
- Real server (a private Nakama 3.41 + PostgreSQL 16, compose project `easycraft_o67`, ports 7469-7471; the lead's
  `easycraft-nakama` untouched): `keys.server.ts` **6/6** and every integration script together **45/45** with module 0.2.12
  (they expect 0.2.12 now).
- GUT: `test_wallet_sync.gd` (11), `test_profile_backup.gd` (+8), `test_profile_stamps.gd` (2), `test_profile_sync.gd`
  (14: layout 2, two devices by version, the account's name, a refused profile, the menu flush),
  `test_account_key.gd` (8), `test_account_key_pages.gd` (8: the pages fit 1280 x 720, big buttons, the hold, the
  gate), `test_online_wallets.gd` (+3: the owner's gift reaches a synced phone, spent elsewhere not twice, no sync in
  an online world), `test_nakama_account_key.gd` (the game's real client end to end; pending on a module < 0.2.12),
  `test_nakama_profile_backup.gd` (gold moved to the ledger check).
- **Full suite** (`tests/run_tests.sh`, a PC-wide slot, niced; on base 9187c8b): **6437 passing, 1 failing, 3
  risky/pending**. The failure is `test_realistic_before_the_pack.gd`'s "still fits a 1280 x 720 screen" (1590 px:
  owner #66's SIMPLE/CLASSIC beside the style), already in the base and fixed by the lead in `lead-merge` a2e07dd;
  after rebasing onto `lead-merge` 0a5d20e it passes with this work's files (130/130 in that run). Pending: the
  real-client test on the lead's 0.2.11 server, and two benches that assert nothing (as before).
- Smoke runs on the fake server: `tools/smoke_all.sh gifts ghosts`: both PASS (15 s, 28 s).

## Measurements (this PC, the private server)
- Key sign-in on a new device to a loaded account (sign-in, key, re-sign-in, merge, wallet): **214 ms**.
- A profile upload: median **13 ms** (max 21); a wallet sync: median **28 ms** (max 35).
- The backup is a few KB (the 64 KiB cap is far).

## Deploy steps for the lead
1. Merge this branch into `lead-merge` (no conflicts expected outside `net/online_service.gd`'s end and the fake
   server if another agent touched them).
2. The lead's dev Nakama: in `lead-merge`, `npm --prefix server/modules run build`, copy
   `server/modules/build/index.js` into the main checkout's `server/modules/build/`, `docker restart
   easycraft-nakama`, and check the log says `module 0.2.12 loaded`. Then `EASYCRAFT_SERVER=http://127.0.0.1:7350 node
   --test server/modules/test/integration/keys.server.ts` (6/6) and `tests/run_tests.sh
   -gtest=res://tests/integration/test_nakama_account_key.gd` (no longer pending).
3. The live server (0.2.12 is backward compatible: 1.0.1 and today's web build keep working; their backups are
   cleaned of gold, which they never read back as more than they have): `server/deploy/kit.sh pack`, copy, unpack
   over the old folder, `./kit.sh update`, `./kit.sh check https://178-104-20-64.sslip.io` (as `docs/hosting.md`),
   and the log's `module 0.2.12 loaded`.
4. The game: a new web build (`tools/export_web.sh`, `tools/deploy_web.sh`, `tools/deploy_web_github.sh`) and an
   Android release. **sasa192974's 100,000 gold shows in their game only with this client** (the old client never
   takes server-side gold once it has synced): after the update, the next sign-in brings it.
5. On the emulator (the lead's check): PLAY ONLINE on a claimed account → GROWN-UPS → ONLINE PLAY → OTHER DEVICES →
   MAKE A KEY; then a fresh browser (or another emulator user) → PLAY ONLINE → I HAVE AN ACCOUNT → gate → name + key →
   the account's name, look, universe and gold show.

## Open
- A switch-account button for a device that already claimed another name (ruling 3).
- The Survivor bag or `world.json` in the account (ruling 7), if the owner wants worlds' things to travel.
- Nakama's `authenticate/email` and `custom` are allowed with the username filter (as before); the game never uses
  them. Refusing them (and `link/email` etc.) in the module would close a way to put an e-mail on an account.
- A lost phone's HTTP session token lives up to 2 h after SIGN OUT OTHER DEVICES (ruling 10).
