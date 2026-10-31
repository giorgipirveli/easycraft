# Owner feedback #99, #104, #105: LOG IN with a password, LOG OUT, one device at a time

**Owner, 2026-10-14 22:22 (#99):** "when player plays on mobile and with the same username wants to start playing on pc
and enters username it should ask to switch into new device or not and continue accordingly". **22:27:** "also do we
have logout and login?" **2026-10-15 23:06 (#104):** "fix logout, still cant logout, why i need to go to grow up to
logout? … also when i delete my account it is not deleting, fix all this quick!!!!!!" **23:14 (#105):** "and when
starting playing create a password. so when logging in another device you can use password and username again to login,
but if you login another device you should logout automatically from old device".

Branch `worktree-agent-a45831f837d05a838` (from `lead-merge` 664ebdb; the accounts brief
`docs/superpowers/plans/2026-10-15-accounts-brief.md`; merged with `lead-merge` at 6fe352d4). Server module **0.2.20**.
Spec §5.13 "As built (owner #99)" and "As built (owner #99, #105)".

## Before
Sign-in was automatic by this device's id; a taken name only said "Someone already has that name. Try another one!".
Another device needed a grown-up's key (#67: GROWN-UPS → OTHER DEVICES → MAKE A KEY, then PLAY ONLINE → I HAVE AN
ACCOUNT → the parent gate → name + key). There was no LOG OUT of this device and no LOG IN (the live game's only "sign
out" is SIGN OUT OTHER DEVICES behind the grown-ups' gate: #104's "why i need to go to grow up"), one device had one
player, and DELETE MY ONLINE ACCOUNT deleted the server's account but kept the player on the device: its profile kept the
invite program's code, so the next start signed in again by itself (a new account) and the name claim offered the same
name and sent the gold up again (#104's "it is not deleting").

## The flows, as a child sees them (the final review's simple model, 2026-10-16: one player on a device)

**1. Starting.** The start screen: PLAY (a new player: the age, then the name) or **LOG IN** (an account from another
device). Online for the first time: PLAY ONLINE → the stay-safe card → "Your online name": Anna_7, OK → **Make a
password** ("Make it two words and a number that only you would think of."; PASSWORD and AGAIN, typed in secret, each
with SHOW; "Never tell anyone your password. Not even a friend."; MAKE IT; no LATER). Wrong ones say why: "The two
passwords are not the same.", "That password is too easy to guess. …", "No runs like 123456 or qwerty. …", "Your password
can't be your name, even with numbers.", "Use at least 6 letters, numbers or signs.", "That password is too long.". Then
"Your password is made. Keep it secret!" → PLAY ONLINE's home: "You are Anna_7" with PASSWORD and LOG OUT. An account from
before #105 is asked once: "Make a password so you can play on your other devices." with LATER.

**2. LOG IN** (the start screen; PLAY ONLINE's I HAVE AN ACCOUNT; a taken name's "Is it you, from another phone, tablet or
computer?" YES, IT'S ME; the main menu's LOG IN; the logged-out card). "Log in" / "Type your online name and your
password." with NAME, PASSWORD (SHOW), BACK, LOG IN, FORGOT PASSWORD? and USE A KEY (a grown-up's way: the parent gate,
then the key page); "Your game moves here: your other devices are logged out." A wrong name or password: "That name and
password don't match." Too many: "Too many tries: wait 15 minutes." (the same device after 5 wrong), or "Too many tries
for this name. Try again in 10 minutes, or ask a grown-up for a key." (a new device while the name is being guessed). The
right one: "Logging in..." and the main menu (or PLAY ONLINE's home) as that account: its name, progress, looks and gold
come down from the account; the worlds on this device stay. Every other device of the account is logged out. When this
device's player has gold or progress that would go (a guest who played here, or a player logged out of another
account), the first LOG IN asks: "Pip's gold and progress on this device will go. Your worlds stay. Log in as Anna?"
with NO (the page again) and YES; the key page's SIGN IN asks the same. A new player who has not played yet, and the
same account as before, are never asked.

**3. Logged out by another device** (or the account was deleted there). The socket closes at once (an offline device
hears it at its next sign-in). A card at the top of every scene: "This device was logged out. LOG IN to play here." /
"Everything you played here is kept on this device and goes up when you log in again as Anna_7." with LOG IN, NEW
PLAYER and LATER (offline play goes on). LOG IN and NEW PLAYER show on the main menu only; in a world the card says "Go
to the main menu to LOG IN." beside LATER. LOG IN with the same account keeps what was played here; NEW PLAYER asks
first ("Start as a new player? What you played here since you were logged out goes. Your worlds stay." NO / YES), then
starts again (the account, if it still exists, is safe on the server). It never makes a new account by itself.

**4. LOG OUT** (the main menu's own LOG OUT under the name; SETTINGS beside GROWN-UPS, on the main menu, for a player with
an online account; PLAY ONLINE's account card): one tap, then "Log out, Anna_7?" / "Your game is saved to your account
first. LOG IN with your name and password brings it back." with NO and YES, LOG OUT. Never the parent gate. "Saving your
game..."; offline: "Connect to the internet first, so your game is saved." with TRY AGAIN and BACK. It logs out only
when every coin and the profile backup are on the server: gold over the server's hourly cap says "Some of your gold is
still on its way: try LOG OUT again in an hour."; a backup the server refused or a gold report that didn't land says
"Your game could not be saved yet. Try again in a moment." (the player plays on, nothing forgotten). An account with no
password: "Make a password first, so you can log back in." (the MAKE page), then the log out goes on. Then this device
leaves the account: the start screen (PLAY or LOG IN); the worlds stay on the device.

**5. FORGOT PASSWORD?** "Ask a grown-up: on a device where you are still logged in, open GROWN-UPS and choose CHANGE
PASSWORD." There: "Don't know the old password? Leave it empty: a key made on this device proves it's you." with OLD,
PASSWORD and AGAIN; CHANGE IT; a key made this way is shown ("A new sign-in key was made. Your old key stopped working.
Write this one down."). PASSWORD on the account card (or SETTINGS) changes it with the old one.

**6. Someone tried.** A new device's wrong try is told to the account at most once an hour: "Someone tried to log in as
you on a new device. If it wasn't you, a grown-up can change your password."

**7. DELETE MY ONLINE ACCOUNT** (GROWN-UPS → ONLINE PLAY): signs in first if needed; what goes on the server and "On this
device this player goes too: the name, progress, gold, looks and books. Worlds on this device stay, …"; PASSWORD beside
HOLD TO DELETE ("Type the password to delete." when it is empty; "That password is not right. Nothing was deleted.";
offline: "Can't delete now: … Nothing was deleted."). Done: "The online account is deleted, and this player is gone from
this device: … The game starts again for a new player." OK → the start screen. Nothing signs in again by itself.

**Resting: the move by code** (built for #99: a 6-digit code typed on a device of the account, then a one-time key). Off
in the game (`DeviceMoveRules.enabled`) and on the server (`MoveRules.ENABLED`); its tests switch it on for themselves.

## What was built

**Server (module 0.2.20):**
- `src/rules/password_rules.ts`, `src/server/passwords.ts`: `password` (`state`, `set`, `change` with `old` or a `key`),
  `sign_in_with_password` (the new id linked, every other device logged out, the asking account kept) and `log_out` (this
  device unlinked, a placeholder custom id first when it is the last one; tombstoned; the sessions end). The rules (6 to
  64 characters and at most 72 bytes; not the name, also with digits and signs around it; the commonest, the examples the
  game showed; straight runs of 6, either way). The frozen brake (two windows). One bcrypt compare on every path against a
  probe hash made at startup with `nk.bcryptHash` (the real cost). Storage, server-only, written by version:
  `account/password` (bcrypt), `account/password_tried`, `limits/password_pair:<id>` (on the asking account),
  `limits/password_name` (on the account), `limits/password_change`, the tombstones `account/removed_device:<salted
  hash>` (system user, salt `account/device_salt`). Notification 112 `{"what": "tried"}`, at most once an hour.
- `keys.ts`: `sign_in_with_key` logs the other devices out and caps the linked ids (10); wrong keys counted per asking
  account only; one bcrypt compare on every path (the probe hash when the account has no key, a fixed probe for a
  malformed key), so the timing never says whether an account has a key. `accounts.ts`: `beforeAuthenticateDevice` refuses a tombstoned id (PERMISSION_DENIED `device_logged_out`).
- `delete_account`'s player path needs the password once there is one; `Deletion.run` tombstones a claimed account's
  device ids (never a never-claimed one's).
- `retention.ts`: `SQL_OLD_PASSWORD_WINDOWS` (2 days), `SQL_OLD_REMOVED_DEVICES` (13 months).
- `move_request` / `move_approve` rest (`MoveRules.ENABLED = false`).

**Game:**
- `core/net/password_rules.gd` (`PasswordRules`): the rules and every word; the commonest passwords in
  `core/net/common_passwords.gd` (`CommonPasswords.LIST`, never shown: `test_costumes.gd`'s banned-name check of shipped
  strings leaves it out, as it does UsernameRules' blocked words — some common passwords are characters' names).
- `net/online_service.gd`, section "Owner #105": `make_password`, `change_password` (old, or a key made here, which it
  returns to be shown), `password_state`, `needs_password`, `log_in` / `log_in_with_password`, `sign_in_with_key`,
  `_ask_to_log_in` (a second connection with `user://login_device.json`; remade once on a 404 or 403; waits out
  `too_new`), `_become` (the same account, known by its user id `OnlinePrefs.account_id`, keeps what was played; another
  starts fresh and takes the account's gold as the server has it: `_adopt_server_gold`), `progress_goes` (whose gold and
  progress a LOG IN would make go: `DeviceMoveRules.has_progress` / `NOT_PROGRESS`), `save_for_log_out` (every coin on
  the server: the phone's gold equals the wallet marker, no refused backup; `_f_report_capped` for the hourly cap), `log_out`,
  `forget_player` (`forget_online` + `_fresh_profile`: the profile file goes, `Profile.reload()`; the worlds stay),
  `move_sign_in` (the resting move), `logged_out`, `tried_note`, the logged-out card (layer 93). `sign_in` uses
  `create=false` once a device id file exists; `device_logged_out` is the logged-out case whatever the prefs say.
- `NakamaOnlineBackend`: a 403 `device_logged_out` → `device_logged_out`, a 404 with `create=false` → `account_gone`.
- `autoloads/session.gd`: a world's sign-in uses `create=false` once a device id file exists (`_online_new_ok`).
- UI (`ui/online/`): `password_field.gd`, `password_page.gd` (MAKE / CHANGE / GROWN_UP; `compact`; `note`),
  `log_in_page.gd` and `key_sign_in_page.gd` (`goes`: the GUEST_GOES question, YES / NO), `logged_out_card.gd` (LOG IN
  and NEW PLAYER on the main menu only, NEW PLAYER's YES / NO, `on_menu` for tests), `accounts_flow.gd` (VIEW_CONFIRM, VIEW_LOG_OUT,
  VIEW_PASSWORD, VIEW_LOG_IN, the key gate and page), `accounts_overlay.gd` (`settings_buttons()`, `menu_button()`,
  `start_log_in_button()`, `open_password`, `to_menu()`), `play_online_screen.gd`, `grown_ups_panel.gd` (CHANGE PASSWORD),
  `ui/parents/delete_account_page.gd`.
- **Marked lines in shared files:** `ui/menus/settings_panel.gd`: `last.add_child(AccountsOverlay.settings_buttons())`;
  `ui/menus/menu.gd`: `_ui.add_child(AccountsOverlay.menu_button(null, _logo))` after the name, and
  `v.add_child(AccountsOverlay.start_log_in_button())` under the start screen's PLAY. If a VR agent changed these spots,
  keep the lines.
- **Removed** (the final review's decision): the kept player slots — `core/save/account_list.gd` (AccountList),
  `net/account_switch.gd` (AccountSwitch), Who is playing? and REMOVE FROM THIS DEVICE, `Profile`'s `recover()` call —
  and their tests (`test_account_list.gd`, `test_account_switch.gd`).
- `tests/fakes/fake_online_server.gd`: section "Owner #105" (`password`, `sign_in_with_password`, `log_out`,
  `FAKE_PASSWORD`, `claims_make_password`, `password_tried`, `removed_devices` and the `device_logged_out` refusal,
  `log_out_others`, `sign_in_fails`).
- Tools: `tools/net_test.sh --login`; `--move` says SKIP while the move is off; `tools/delete_test_account.gd --password=`.

## Rulings (decisions made on the owner's behalf)
1. **A password made right after the name, with no LATER**; an account from before is asked once, with LATER. *Cost if
   wrong:* one more page at the start.
2. **One player on a device** (the final review's decision: the owner asked for log out, log in with the name and the
   password, and one device at a time, nothing more). *Cost if wrong:* a family tablet's children log out and in to
   share it (a kept-slots switcher was built and removed; git history has it).
3. **LOG IN and a grown-up's key both log every other device out.** *Cost if wrong:* none known (a lost phone stops at once).
4. **The worlds stay on the device on LOG OUT, LOG IN as another account, and DELETE** (they belong to the device, not
   the account; they are not in the profile backup). *Cost if wrong:* the next player on a shared device sees and can play
   the last one's worlds (the Memory Book and My Shorts stay with the device too, as before #99).
5. **LOG IN as another account starts from a fresh player** (this device's account files forgotten, a new profile), so
   nothing merges and gold can't double; LOG IN as the SAME account (logged out elsewhere) keeps what was played here.
   It asks first when this player has gold or progress (the final review's 2). *Cost if wrong:* a never-online
   player's local progress on this device is replaced when it says YES (its worlds stay).
6. **LOG OUT needs a password first** (else the player could never log back in), unlinks this device on the server and
   forgets the account here. *Cost if wrong:* one more page for an account made before #105.
7. **A logged-out device never makes a new account by itself** (`create=false`; the server's `device_logged_out`).
8. **No lock-out of a child, ever** (the frozen brake: see below). *Cost:* a determined guesser is slowed (about 144 + 10
   a day per name), not stopped; an attacker can slow a child's first login on a brand-new device to one try per 10 minutes.
9. **LOG OUT is one tap and YES, never the parent gate** (#104).
10. **DELETE takes this player off the device too** (worlds stay), needs the password, and opens the start screen.
11. **FORGOT PASSWORD is a grown-up's CHANGE PASSWORD on a device still logged in**; a key made for it is shown.
12. **The asking account (`login_device.json`) stays on the server**; an empty one goes after 13 months; LOG IN remakes it
    once on a 404 or 403. *Cost:* one empty account per device that ever logged in.
13. **The move by code rests.**
14. **LOG OUT goes only with every coin and the backup on the server** (the final review's 1): after the sync the phone's
    gold must equal the wallet marker, and a refused backup (`too_big`, `bad_profile`, `not_allowed`) is not saved
    either. *Cost if wrong:* a child far over the hourly cap waits an hour to log out (the words say so).
15. **"The same account" is its user id**, noted with the name (`OnlinePrefs.account_id`; the final review's 7). The LOG
    IN page predicts it by the name (it can't know the id before the server answers). *Cost:* an account deleted
    elsewhere whose name was claimed again, logged in here with the new account's password: what was played here since
    the logout goes without the question (a fresh start; nothing merges). Prefs from before this build have no id: a
    fresh start, and the page asks.
16. **What counts as progress** (`DeviceMoveRules.NOT_PROGRESS`): everything in the profile but the name, the age band,
    the settings, the looks, the hints seen, the tutorial, the HUD's moves, the switches and the day's counters. *Cost:*
    a guest who only chose looks loses them without the question.
17. **A fresh player made by LOG IN takes the account's gold as the server has it** (its 25 start gold is never reported
    as earned; the final review's 4).
18. **The logged-out card's LOG IN and NEW PLAYER show on the main menu only** (in a world its files are open; the
    final review's 7). In a world: "Go to the main menu to LOG IN." beside LATER.

## Security: the FROZEN design (the lead, 2026-10-16, after three adversarial reviews)
Three rounds of cleverer brakes each opened a new gap, so the brake was simplified and frozen. Do not redesign it.
- **A name alone opens nothing**; LOG IN needs the password, the key path a grown-up's key. One answer for a wrong name
  and a wrong password, and one bcrypt compare on every path (a real hash or a dummy, a fixed non-empty probe, the same
  try/catch on both paths), so neither the answer nor its timing says whether a name exists or has a password.
- **Exactly two windows, and nothing else** (no network window, no growth, no decay, no stored list of past devices):
  - the **pair** (target account x asking account): 5 wrong in 15 minutes, then a wait to that window's end;
  - the **name** (per target account), counting only tries from devices NOT known to the account: a 24-hour window
    (from its first wrong try); past 10 wrong, each further try from an unknown device passes once every 10 minutes (one fixed wait).
  Every try is counted before the password is checked, by version, failing closed (`locked`). A correct login clears
  only its own pair window; nothing else is ever released or decremented.
- **Known = linked to the account right now.** Such a device, and the grown-up key path (wrong keys counted per asking
  account only, never per name), are never braked: the key always works.
- **True numbers:** at most about 144 + 10 guesses a day per name; a child's longest wait on a brand-new device is 10
  minutes (her own repeated typos on one device: the pair's 15 minutes). **Accepted residual:** an attacker can slow a
  child's FIRST login on a brand-new device to one try per 10 minutes. The account hears "Someone tried…" at most hourly.
- **No quiet new account, ever.** The client signs the menu and a world in with `create=false` once a device id file
  exists (`OnlineService.sign_in`, `Session._online_new_ok`). The server tombstones every device id unlinked from a
  CLAIMED account (a LOG IN elsewhere, SIGN OUT OTHER DEVICES, a DELETE, the 10-device cap) in
  `account/removed_device:<salted hash>`, and `beforeAuthenticateDevice` refuses such an id with PERMISSION_DENIED
  `device_logged_out`; the game maps that code to its logged-out words whatever its prefs say (so a profile from before
  this build, which kept no account name, is covered). A never-claimed account that went (the 13-month clean-up) leaves
  no tombstone: its device gets a plain 404 and starts anew, and LOG IN remakes `login_device.json` once if its asking
  account went. Tombstones are kept 13 months; an account keeps at most 10 linked device ids.
- **One player on a device** (the final review): there are no kept slots, so there is no "one tap back" to protect.
  LOG IN as another account starts from a fresh player, so nothing merges and gold can't double.
- **Passwords at rest:** bcrypt only, at most 72 bytes (a longer one is refused with clear words); the game can never
  read `account/*` or `limits/*`. The example passwords the game ever showed are in COMMON; the shown idea has no
  copyable example. FORGOT PASSWORD (a change with no old password) shows the new key it makes.
- **One device at a time:** a LOG IN with the password or with a key unlinks (and tombstones) every other device id,
  ends the sessions and closes the sockets; a logged-out token answers 401. LOG OUT unlinks this device itself.
- **Known residual (the final review's 7):** a sign-in 404 with no tombstone and no kept name (a claimed account whose
  tombstones the 13-month clean-up already removed, or one deleted before tombstones existed, on a profile from before
  this build) starts anew as a new player instead of saying "logged out". *Cost:* rare; nothing of the old account is
  touched, and LOG IN still brings it back.
- **The move by code** (resting): its own review stays in git history (`4d84c0bb`'s version of this file).

## The adversarial reviews (2026-10-16)
- **Second review of `8f4fcde6`** (`docs/devlog/parts/accounts-105-review.md`): one HIGH (a quiet new account after an
  unlink or DELETE), four MEDIUM, several LOW. Fixed in `46a577e4`.
- **Third review of `46a577e4`: NOT MERGEABLE** (N1-N9). The lead froze the brake (A-G); `446f929c` implements it: A the
  two windows (N4, N6, N8, N9 — the network window and `releaseSoft` gone); B the online flag (N1); C no tombstone for
  never-claimed accounts and the asking-id remake (N2); D the `device_logged_out` code (N3); E the fixed probe (N5); F the
  10-id cap and the 13-month tombstone clean-up (N7).
- **Final review of `446f929c`: NOT MERGEABLE** — password-less accounts locked out of their kept slot (1) and the wrong
  `known_device` from Who is playing? (2); the key path failing from a logged-out device (3); a cost-10 dummy hash against
  Nakama's real cost (4: 97-107 ms against 734-748 ms); no cap and no logout of the others on the key path (5); the
  login_device remake on any failure (6); a 404 with no tombstone (7); the docs (8). The lead's decision: SIMPLIFY — one
  player on a device. This round: the kept slots removed (1, 2 at the root); LOG OUT unlinks this device and forgets the
  account and the player (a password first); the key path asks with the asking account (3); the probe hash made at
  startup with `nk.bcryptHash` and a timing assertion against the real server (4: 732 ms against 734 ms); the cap and the
  logout of the others on the key path (5); the remake only on a 404 or 403 (6); 7 written as a known residual; the docs
  fixed (8: neutral logged-out words, keys counted per asking account, a fixed 24-hour window).
- **Final review of `0963af9f`** (two blockers and small items; its probe and 8 throwaway tests, now real tests in
  `test_log_out.gd`): 1 LOG OUT forgot gold over the hourly cap (30000 played, 20000 taken) and a refused backup →
  rulings 14 (`GOLD_ON_ITS_WAY`, `NOT_SAVED`); 2 LOG IN erased a guest's progress without asking → the GUEST_GOES question
  on LOG IN and the key page; 3 NEW PLAYER on the card asks, the saved line names the account; 4 a fresh player's start
  gold went up as earned → ruling 17; 5 the key path answered in 13 ms for an account with no key against 772 ms with
  one → one compare on every path (730 / 728 / 728 ms now); 6 `link_new_device` and the stale "Who is playing?" comments
  removed; 7 the card's buttons in a world, "the same account" by name → ruling 18 and 15.

## Tests and results
- **Node** (`npm --prefix server/modules test`): **485/485** (`passwords_rpcs.test.ts` with the two windows, `log_out`,
  the probe hash; `account_lockout.test.ts`; `keys_rpcs.test.ts` with one device at a time on the key path and one
  bcrypt compare on every key path; the move's tests with `ENABLED` switched on).
- **Real server** (the private Nakama 3.41 + PostgreSQL 16, compose project `easycraft_acct99`, ports 7499-7501):
  `passwords.server.ts` **4/4** (LOG IN logs the phone out and its id is refused; a nobody's name answers as slowly as a
  real one, 732 ms against 734 ms; LOG OUT unlinks the device, its id is refused, LOG IN brings the account back);
  `tools/net_test.sh --server=127.0.0.1:7500 --login --delete-accounts` **PASS** (the real client).
- **GUT:** `test_log_out.gd` (rewritten for the simple model: the YES / NO question and no gate; offline; saving first;
  a save that can't land; nothing to log out; a password first; LOG OUT unlinks, forgets the account files and the player,
  keeps the worlds; LOG IN after LOG OUT brings the account back with its gold once; LOG IN as another account starts
  fresh (no merge, no doubled gold); LOG IN logs the other device out; a key works from a logged-out device; busy;
  a late answer never lands; PLAY ONLINE's card; the main menu's button; the start screen's LOG IN; the settings row),
  `test_account_password.gd`, `test_account_key.gd` (the key path's new rules), `test_device_move.gd` (`move_sign_in`),
  `test_account_password_rules.gd`. Removed with the slots: `test_account_list.gd`, `test_account_switch.gd`.
  The final review's round: LOG IN asks a guest with progress (NO, typed again, YES), a new player is never asked, the
  hourly cap, a wallet blip, a refused backup, a logged-out device plays on and logs in again, a kill after the server's
  log_out, logged out of one account and in as another, no start gold made, DELETE then a new player, a name that is
  another account now (`test_log_out.gd`); the card's NEW PLAYER question and its buttons in a world
  (`test_account_password.gd`); the key page's question (`test_account_key_pages.gd`). The account batch (16 files):
  **198/198**.
- **The review's probe** (`probe.mjs`, against the private server, deletes its accounts): PASSWORD medians 732 / 747 /
  739 ms (nobody / a real password / no password); KEY medians 730 / 728 / 728 ms (nobody / with a key / no key).
- **Full suite** (`acct99_full6.log`, 3486 s): 10049 tests, 10046 passing, **1 failing**: `test_costumes.gd`'s
  `test_no_player_facing_string_uses_a_banned_name` (the common-password list in `password_rules.gd` names Superman,
  Batman and Pokemon; there since `8f4fcde6`). Fixed by moving the list to `common_passwords.gd` (NEVER_SHOWN);
  `test_costumes.gd` and the account files pass again.

## Measurements (this PC, the private server, the real Nakama client)
- LOG IN (name + password, an asking account old enough): **945 ms** to playing as the account. A brand-new device's first
  try waits about **30 s** (`too_new`; `prepare_log_in` starts the clock when LOG IN opens).
- Timing on the real server: a name nobody has 732 ms, a real name with a wrong password 734 ms (one bcrypt each);
  the key path 730 / 728 / 728 ms (nobody / with a key / no key).
- Page sizes in the menu's panel (1224 x 534): Make a password 1000 x 466; asked once 1000 x 512; LOG IN 1000 x 510 (also
  on a logged-out device); CHANGE 1000 x 510; the grown-up's CHANGE PASSWORD 1206 x 523; DELETE with the password
  1201 x 296; the LOG OUT question 1000 x 384; "make a password first" 1000 x 512; LOG OUT offline 1000 x 220; PLAY
  ONLINE's home with the account card 828 x 502; the logged-out card 744 x 294 (in a world 744 x 294; NEW PLAYER's
  question 742 x 259); LOG IN's question 1000 x 434; LOG OUT's "gold on its way" 1000 x 220; SETTINGS with LOG OUT and
  PASSWORD 1253 x 711 (of 1280 x 720).

## Deploy steps for the lead
1. Merge this branch into `lead-merge` (expect conflicts only on the marked lines in `ui/menus/settings_panel.gd` and
   `ui/menus/menu.gd`, the end of `net/online_service.gd` / the fake server, and the owner-feedback rows #104 and #105).
2. The lead's dev Nakama: `npm --prefix server/modules run build`, copy the build, `docker restart easycraft-nakama`, the
   log's `module 0.2.20 loaded`; then `EASYCRAFT_SERVER=http://127.0.0.1:7350 node --test
   server/modules/test/integration/passwords.server.ts` (4/4) and `tools/net_test.sh --login --delete-accounts`.
3. The live server: `server/deploy/kit.sh pack`, copy, unpack, `./kit.sh update`, `./kit.sh check
   https://178-104-20-64.sslip.io`; then `tools/net_test.sh --server=https://178-104-20-64.sslip.io --login
   --delete-accounts`. An old game against 0.2.20: its key sign-in now logs the other devices out; its logged-out
   device's sign-in is refused (an error, never a new account).
4. The game: a web build and an Android release carry the new screens. Re-check Play's Data safety form before the upload
   (`docs/store/data-safety.md`); the store pages from `docs/store/privacy-policy.md` (`tools/make_store_pages.py`).
5. On the emulator (the lead's check): claim a name, make a password; on the desktop or a browser, LOG IN with it: the
   emulator's card says "This device was logged out."; LOG OUT (main menu, one tap) → the start screen → LOG IN brings the
   account back; DELETE with the password → the start screen.

## Open
- The move by code's return, if the owner wants it beside the password.
- Several players on one device (a family tablet), if the owner asks for it again.
- A dictionary-word check for passwords (a bundled word list), if the owner wants one.
