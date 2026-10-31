# EasyCraft online backend (Nakama)

The game's server for online play (spec §2, §5.13, §7.1–7.4, §17): Nakama with a TypeScript module
for accounts by device, parental consent, parent settings, friends, invites into a host's relayed
match, chat rules, reports, secret codes, the Gold Farm clock and the Survivor gold wallet (M4 Wave 1,
agent B: `docs/devlog/parts/m4-b.md`), and data rights and retention: deleting an online account, the
retention clean-up and a snapshot of a reported message (M4 Task 8b, agent G: `docs/devlog/parts/m4-g.md`), and friends when they are not online together: blueprint gifts, showcase visits with guestbook stickers, bottle mail and reports about builds (M4 Wave 3, agent I: `docs/devlog/parts/m4-i.md`), and ghost races on friends' courses (M4: `docs/devlog/parts/m4-ghosts.md`). The spike's results, measurements and risks:
`docs/devlog/parts/m4-online-spike.md`.

| Part | Version | Where |
|---|---|---|
| Nakama | 3.41.0 (`heroiclabs/nakama:3.41.0`) | `docker-compose.yml`, config `nakama/local.yml` |
| PostgreSQL | 16.8 (`postgres:16.8-alpine`, as Heroic Labs' own compose file) | `docker-compose.yml`, volume `easycraft_db` |
| Server logic | TypeScript 5.9.3 → one ES5 script `modules/build/index.js` | `modules/` |
| Nakama runtime types | nakama-common 1.48.0 (the version Nakama 3.41.0 is built with), vendored | `modules/vendor/nakama-runtime/` |
| Game client | nakama-godot (Heroic Labs), pinned commit | `addons/com.heroiclabs.nakama/`, installed by `tools/fetch_nakama_godot.sh` |

**On the internet** (the owner's server): `deploy/` is the hosting kit (Nakama with this module built
in, PostgreSQL, Caddy with automatic HTTPS, daily backups, `deploy/kit.sh`); the owner's guide is
`docs/hosting.md`. A change to the socket, session or runtime settings in `nakama/local.yml` must go
into `deploy/nakama/production.yml` too (`tests/unit/test_hosting_kit.gd` compares them).

## Ports (bound to 127.0.0.1 only)

| Port | What |
|---|---|
| 7350 | HTTP API and realtime socket: **the game connects here** |
| 7349 | gRPC API (unused by the game) |
| 7351 | Developer console: http://127.0.0.1:7351, user `admin`, password `easycraft-dev` |

PostgreSQL is not published at all. Other projects on this PC use other ports (checked with
`ss -ltn` on 2026-09-24). To use other ports, set `NAKAMA_HTTP_PORT`, `NAKAMA_GRPC_PORT` or
`NAKAMA_CONSOLE_PORT` when starting, and pass the game `--online-server=127.0.0.1:<port>`.
The Android emulator reaches this PC's 127.0.0.1 as `10.0.2.2`: `--online-server=10.0.2.2`.
For a real phone on the LAN, start with `NAKAMA_BIND=0.0.0.0` (then the console is on the LAN
too: change its password in `nakama/local.yml` first).

## Commands

Always compose project **`easycraft`** (`dev.sh` does it): other projects' containers, images and
volumes on this PC are never touched.

```bash
server/dev.sh up       # build the module (npm ci the first time), start both, wait until healthy
server/dev.sh status   # containers and health
server/dev.sh logs     # follow Nakama's log (Ctrl+C stops following, not the server)
server/dev.sh reload   # rebuild the module and restart Nakama (keeps the database)
server/dev.sh down     # stop and remove the containers; the database volume is kept
server/dev.sh reset    # down and DELETE the database volume (every account and match is gone)
```

The same by hand: `npm --prefix server/modules ci && npm --prefix server/modules run build`, then
`docker compose -f server/docker-compose.yml -p easycraft up -d --wait`; stop with
`docker compose -f server/docker-compose.yml -p easycraft down` (add `-v` to delete the database).

Nothing starts at boot (restart policies `no` / `on-failure`): run `server/dev.sh up` when needed and
`server/dev.sh down` when done. Extra Nakama flags for experiments: `NAKAMA_EXTRA_ARGS="--logger.level DEBUG" server/dev.sh up`.

Check it answers: `curl http://127.0.0.1:7350/healthcheck` (Nakama itself), and the module's RPC:

```bash
TOKEN=$(curl -s -u defaultkey: -X POST 'http://127.0.0.1:7350/v2/account/authenticate/device?create=true' \
  -H 'Content-Type: application/json' -d '{"id":"curl-check-device-0001"}' | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')
curl -s -X POST http://127.0.0.1:7350/v2/rpc/healthcheck -H "Authorization: Bearer $TOKEN" -d '""'
```

## The TypeScript module (`modules/`)

- `src/rules/` holds pure rules (no Nakama calls); `src/server/` the glue that reads and writes
  Nakama; `src/main.ts` registers everything. `tsconfig.json` lists the files **in load order** (one
  plain script, `tsc` with `outFile`, not a bundle), `main.ts` last.
- Nakama's JavaScript runtime is **ES5**, finds registered functions by their global names, and reads
  `InitModule`'s own source to find them: every function passed to the initializer is a top-level
  `function` declaration (never a lambda or a variable), and every `initializer.register*(...)` call
  is written inside `InitModule` itself (registering from a helper makes Nakama refuse to start:
  "function key could not be extracted"). No regular-expression `u` flag, no `for...of` over strings.
- Ported from the game with the same word lists and test cases (keep them in step):
  `UsernameRules` (`core/validation/username_rules.gd`), `ChatRules` (`core/rules/chat_rules.gd`),
  `CodeRules` (`core/codes/code_rules.gd` and `code_tries.gd`: the same salt and hashes).
- TypeScript stays on 5.9: TypeScript 6 deprecates `target: es5` and `outFile`, and 7 removes them.
  Moving on means adding a bundler (Rollup with Babel, as Heroic Labs' docs describe).
- The runtime types (`nakama-runtime`, from nakama-common) are not on the npm registry, and npm 12
  refuses git and URL dependencies by default, so `index.d.ts` is vendored with its licence. When
  Nakama is upgraded, fetch the nakama-common tag that its `go.mod` names.

### RPCs (JSON in, JSON out: `{"ok": true, ...}` or `{"ok": false, "error": "<code>"}`)

Every RPC needs a signed-in player (except the owner's ones below, which also run without a session:
the runtime HTTP key, or the console's API Explorer with no user id); a payload that is not a JSON
object answers `bad_request`, a failure on the server `server_error`. The game turns each code into
plain words for the child.

| RPC | Payload | Answer / error codes |
|---|---|---|
| `healthcheck` | — | `module`, `version` (0.2.6: 0.2.1 agent E's chat, 0.2.2 agent F's approvals, codes by hash, host wallets, 0.2.3 agent G's data rights and retention, 0.2.4 agent I's gifts, showcases and bottles, 0.2.5 owner #45b's block ids up to 399 in builds, 0.2.6 ghost races, 0.2.7 owner #36's costume code, 0.2.8 the M4 Task 10 review: `docs/devlog/parts/m4-task-10-review.md`, 0.2.9 `remove_guest`, 0.2.10 the review's leftovers: `docs/devlog/parts/m4-review-leftovers.md`, 0.2.11 `match_players`: `docs/devlog/parts/safety-leftovers.md`, 0.2.12 owner #67's `account_key`, `sign_in_with_key` and the cleaned profile: `docs/devlog/parts/owner-67-cloud-profile.md`, 0.2.13 no age rules, 0.2.14 profiles up to 1 MiB, 0.2.15 block ids 512-1023 in builds, never the items' 400-511 (cosmos: Titan's page 29): `docs/devlog/parts/cosmos-titan.md`, 0.2.17 owner #89's Theater channel list: `theater_channels`, `theater_set_channels`, `docs/devlog/parts/tv-shows.md`, 0.2.18 owner #81/#82/#85's better together: `social_info`, `social_learned`, `social_moment`, `social_cheer`, `present_send`, `present_open`, `present_thank`, `study_buddy`, `crew`, `docs/devlog/parts/daily-and-friends.md`, 0.2.19 the gold-double bug's leftovers: `redeem_code`'s `paid`, `wallet_award`'s `seq` and late batches, `get_account_state`'s `hosted`, `docs/devlog/parts/gold-double.md`, 0.2.20 owner #99's `move_request`, `move_approve` and the one-time key in `sign_in_with_key` (resting: `MoveRules.ENABLED` false), owner #105's `password` and `sign_in_with_password` (one device at a time), `delete_account`'s password: `docs/devlog/parts/accounts-99.md`), `server_time_ms`, `user_id` |
| `claim_username` | `username`, `age_band` (on the first claim) | the account state (as `get_account_state`); `too_short`, `too_long`, `bad_chars`, `must_start_with_letter`, `personal_info`, `blocked_word`, `taken`, `bad_age_band` |
| `get_account_state` | — | `user_id`, `username`, `claimed`, `age_band`, `consent`, `online_allowed`, `chat`, `can_play_online`, `chat_level`, `consent_available`, `consent_request` (none, pending, verified, denied), `gold`, `hosted` (0.2.19: `{"match_id", "seq"}` of the last relayed match the server saw this player in and the highest count its host reported, or `null`; every account answer has it), `server_time_ms` |
| `set_parent_settings` | `online_allowed`?, `chat`? (off, quick, filtered), `age_band`? (0.2.8: only ever stricter; the game sends `under_13` when the store's age signal made the phone's band stricter after a 13+ claim) | the account state; `not_claimed`, `consent_needed` (under_13 online without consent), `chat_not_allowed` (filtered for under_13), `age_band_locked` (0.2.8: an under_13 account is never lifted to 13_plus by a game; the owner changes it in the console on a parent's request), `bad_request` |
| `consent_start` | `parent_contact`? (passed to a real provider, never stored) | the account state (`consent: pending`); `not_claimed`, `not_needed` (13_plus), `consent_unavailable` (no provider) |
| `consent_status` | — | the account state; a parent's yes sends notification **103** `{"what": "consent"}` |
| `invite_friend` | `user_id` or `username`, `match_id` (relayed: `"<uuid>."`), `world_name`? | `user_id`, `username`, `expires_ms`; notification **101** to the friend; `not_allowed_online`, `not_found` (nobody, or 0.2.8: a child who may not be online and is not your friend), `cannot_invite_self`, `not_friends`, `friend_cannot_join`, `not_in_match`, `not_host`, `match_full`, `too_fast`, `bad_world_name` |
| `remove_guest` (0.2.9) | `user_id`, `match_id` | the match's host takes a guest out of it (their presences are kicked off the relayed stream) and off its invite list (no rejoin); notification **107** `{"match_id"}` to the guest; `in_match`; `bad_request` (yourself, junk ids), `not_host`, `busy` |
| `match_players` (0.2.11) | `match_id` | the match's host only (as `get_gold_of`): `players`, everyone in the relayed match now (the host too), each `{"user_id", "username", "age_band", "chat_level"}` from the account: the band read strictly (no valid band is `under_13`), the chat level as the team room applies it (`AccountRules.chatLevel`: `off`, `quick`, `filtered`). The host's game names its players and checks its relay chat, trades and pets with this, never with a guest's own word (the M4 Task 10 review's B); `bad_request`, `not_host` |
| `report_user` | `user_id` or `username`, `reason` (`mean_words`, `bad_name`, `bad_build`, `personal_info`, `scary`, `cheating`, `other`), `match_id`?, `channel_id`?, `message_id`?, `message`? (agent G: the message as the game showed it, `{"text"}` or `{"emote"}` + `at_ms`) | `{"ok": true}`; `not_found` (0.2.8: by name, a child who may not be online is nobody too; by id anyone), `cannot_report_self`, `too_many` (10 an hour; the same player again within 10 min is thanked, stored once). With a `message_id` the report keeps a snapshot of that one message (`message`: `text` or `emote`, `at_ms`, `source`): the server's own copy (`"server"`: every message it passed on is remembered for an hour, and a kept DM is looked up in its history by one of its two players), else the reporter's copy (`"reporter"`: "as shown by the reporter"), else `null` |
| `redeem_code` | `code` | `status: "accepted"`, `reward` (`{"kind": "gold", "amount"}` or `{"kind": "cosmetic", "item"}`), `gold`; `unknown`, `already_used` (0.2.19: + `paid` `{"gold", "at_ms"}` when the server paid that gold code itself: a game whose answer was lost asks again and learns the server holds it), `locked` (+ `wait` seconds: 5 wrong in a row lock 30 s), `empty` |
| `redeem_code` (codes used offline) | `hashes`: at most 50 salted hashes the game redeemed on the phone | `status: "recorded"`, `recorded`, `already`, `gold`, `paid` (0.2.19: `[{"hash", "gold", "at_ms"}]` of those the server had paid itself: the game counts that gold as the server's, never its own): known hashes join the redeemed list, **nothing is paid** (the phone paid), unknown ones are ignored (no lock); `bad_request` |
| `farm_collect` | `action`: `start` (`world`, `rate_per_hour`, `universe`?, `cap_hours`?), `peek` or `collect` (`world`) | start: `started_ms` and the clamped values; peek and collect: `earned`, `away_ms`, `capped` (+ `gold` on collect); `not_started`; `too_many_farms` (0.2.10: a start for a new `world` when the player already has 20 farm clocks; starting one that is there again, or after a collect, works) |
| `wallet_award` | `amount` (whole; negative = spent), `reason`?, `universe`?; `user_id` + `match_id` (agent F): a guest's gold, reported by the host of the relayed match the guest is in | `credited`, `capped`, `gold` (of that player); `too_much` (over 2,000 × 2^(u−1) at once), `limit` (20,000 × 2^(u−1) an hour, per player), `spend_limit` (0.2.10: a spend the host reports for a guest when that guest's spends reported by another player this hour, `limits/wallet_spent`, would pass 20,000 × 2^(u−1); refused whole, the guest's gold stays; a player's own spends have no such limit), `not_enough_gold`, `not_host`, `not_in_match`; the ledger entry says `by` whom. 0.2.19: `seq`? (1 to 2^31−1: the host's count of that guest's gold moves, on the last piece of a batch) is kept in `limits/wallet_hosted` (the highest, also when the piece is refused) and answered back; `amount: 0` with a `seq` reports the count alone; with a `seq` a batch is still taken after the guest left the match or the host left it, for the match the server saw the guest in (`get_gold_of` or a report while it was there), from that match's host, within 24 h (`WalletRules.lateAllowed`); a bad `seq` is `bad_request` |
| `get_gold_of` | `user_id`? + `match_id`? (agent F) | `user_id`, `gold`: the caller's own, or a guest's in the relayed match the caller hosts (the host starts a guest's wallet from this, never from the guest's word; 0.2.19: the server notes it saw the guest in this host's match, `limits/wallet_hosted`); `not_host`, `not_in_match`, `bad_request` |
| `delete_account` | a player: `{}`, then `{"confirm"}`; the owner (no session): `{"user_id"` or `"username"}`, then the same with `"confirm"` | the first call deletes nothing: `confirm` (lasts 10 min), `expires_ms`, `user_id`, `username`; the second deletes the account: `deleted: true`, `user_id` and what went (`friends`, `held`, `notifications`, `messages`, `reports_anonymised`, `objects`). `confirm_wrong`, `confirm_expired` (ask again), `not_allowed` (a player naming another account), `not_found` (the owner's name matches nobody). 0.2.20 (owner #105): a player's second call needs `"password"` once the account has one: `password_needed`, `wrong_password`, `locked` + `wait` (`limits/password_change`: 5 wrong in 15 min; the confirmation stays usable); the owner's calls need none. M4 Task 8b, agent G: see "Deleting an account" |
| `retention_run` | — (the owner only: no session) | the clean-up now: `accounts`, `messages`, `old_notifications` (0.2.8), `orphan_notifications`, `orphan_messages`, `reports_deleted`, `reports_stamped`, `reports_anonymised`, `report_windows` (0.2.10), `password_windows` (0.2.20: `limits/password_*` not written for 2 days), `more` (call again); a game gets `not_allowed`. It counts as the day's run. See "Retention" |
| `approve_friend` | — (list), or `user_id` + `approve` (bool) | `requests`: `[{"user_id", "username", "direction": "in" (they asked) or "out" (the child asked), "at_ms"}]` waiting for a grown-up; a yes also answers `friend` `{"user_id", "username", "state": "friend" or "asked"}` and sends notification **103** `{"what": "friend", "user_id"}`; a no forgets it (and removes a request that came in). `not_found` (no such request, or that player can't be online any more: dropped), `consent_needed`, `bad_request`. M4 Wave 2, agent F |
| `send_gift` | `user_id` or `username`, `build` (a build text, below: at most 8 × 8 × 8 and 512 blocks) | `gift_id`; notification **104**. `not_allowed_online`, `not_found` (nobody, or a child who may not be online), `cannot_gift_self`, `not_friends`, `bad_build`, `too_big`, `empty_build`, `too_many_gifts` (10 unopened from you), `inbox_full` (50), `too_fast` (30 an hour). M4 Wave 3, agent I |
| `list_gifts` | — | `gifts`: `[{"gift_id", "from_user_id", "from_username", "count", "size", "created_ms", "ghost"?: true}]` (`ghost`: the sender's ghost comes with it, 0.2.6), oldest first, from mutual friends only (a gift from someone no longer a friend, or blocked, is deleted); `not_allowed_online` |
| `open_gift` | `gift_id`, `discard`? | `gift`: `{"gift_id", "from_user_id", "from_username", "build", "size", "count", "created_ms", "ghost"?}` (a ghost as `share_ghost` took it) and the server deletes it; with `discard`: `{"ok", "discarded": true}` (deleted unopened, always works); `not_found`, `not_allowed_online` (0.2.8: nothing opens while the player may not be online; it stays) |
| `publish_showcase` | `build` (at most 32 × 32 × 32, 48 KiB of text; this RPC's payload may be 56 KiB), `buddy`? `{"build" (at most 17 wide, 200 blocks), "at": [x, y, z] inside the area}`; or `{"remove": true}` | `count`, `size`, `updated_ms`; `removed` (the guestbook goes too; taking it down always works, even when the player may not be online now). `not_allowed_online`, `bad_build`, `too_big`, `empty_build`, `bad_buddy`, `too_fast` (12 an hour) |
| `get_showcase` | `user_id` or `username`; nothing (or yourself) for your own | `owner_id`, `owner_username`, `build`, `size`, `buddy`?, `updated_ms`; your own also `guestbook`: `[{"entry_id", "from_user_id", "from_username", "sticker", "at_ms"}]` (a visitor never sees it). `not_allowed_online`, `not_found`, `not_friends`, `no_showcase` |
| `sign_guestbook` | `user_id` or `username`, `sticker` (`star`, `heart`, `smile`, `wow`, `thumbs_up`, `rainbow`, `trophy`, `flower`) | notification **106**; the guestbook keeps the newest 30 of 60 days. `bad_sticker`, `no_showcase`, `cannot_sign_own`, `not_friends`, `not_found`, `too_fast` (the same visitor once in 10 minutes) |
| `remove_sticker` | `entry_id` | `guestbook` (your own, without it; an empty one is deleted); `not_found` |
| `send_bottle` | `user_id` or `username`, `phrase` (a quick-chat phrase, `ChatRules.QUICK_PHRASES`), `build`? (at most 4 × 4 × 4) | `bottle_id`; notification **105**. `bad_phrase`, the build's codes, `too_many_bottles` (5 unopened from you), `inbox_full` (30), `too_fast`, and `send_gift`'s friend codes |
| `list_bottles` | — | `bottles`: `[{"bottle_id", "from_user_id", "from_username", "created_ms"}]` (what is inside shows when opened), friends only |
| `open_bottle` | `bottle_id`, `discard`? | `bottle`: `{"bottle_id", "from_user_id", "from_username", "phrase", "build"?, "size"?, "count"?, "created_ms"}`, then deleted; `discarded`; `not_found`, `not_allowed_online` (0.2.8, as `open_gift`) |
| `report_build` | `user_id` or `username`, `what` (`showcase`, `gift`, `bottle`, `ghost`), `build`? (as the reporter's game has it), `ghost_id`?, `ghost`? (0.2.6), `reason`? (default `bad_build`) | `{"ok": true}`: a report in `reports` (as `report_user`, sharing its limits) with `what` and `build`: the server's copy of a showcase (`source: "server"`), else the reporter's (`"reporter"`), else `null`. 0.2.6: a showcase's report keeps its `ghosts`; `what: "ghost"` keeps `ghost`: the server's copy of that showcase ghost (`ghost_id`, `source: "server"`), else the reporter's (`ghost`, `"reporter"`), else `null`; a gift's report may carry its `ghost` too. `not_found`, `cannot_report_self`, `too_many`, `bad_request` |
| `share_ghost` | `{"to": "showcase", "ghost"}`; `{"to": "gift", "user_id" or "username", "build", "ghost"}`; `{"remove": "<ghost_id>"}`. A ghost: `{"start": [x, y, z], "finish": [x, y, z]` (cells in the showcase or the gift), `"ms"` (1,000-180,000), `"path"` (base64 of int16 little-endian decimetres from START's top, 5 samples a second), `"look"` (the avatar look code, a JSON object text, at most 2,048)`}`; the payload may be 16 KiB | on the showcase: `ghost_id`, `ms` (one ghost per course: a new run of the same START replaces it; at most 3; a new showcase or none takes them down); with a gift: `gift_id` (a gift like `send_gift`'s, with its caps, windows and notification 104); remove: `removed` (always works). `not_allowed_online`, `no_showcase`, `bad_ghost` (its shape), `not_on_course` (no START or FINISH where it says), `impossible_run` (not from START, not to FINISH, out of the course's box and margin, faster than 40 m/s, or a jump that does not land on a START, CHECKPOINT or TELEPORT_PAD), `too_many_ghosts`, `too_fast` (12 shares an hour; a gift: the gift window), `not_found`, the gift's codes, `bad_request`. M4 ghost races |
| `account_key` (0.2.12) | `action`: `state`; `new`; `sign_out_others` + `device_id` (this device's); the owner (no session: the HTTP key or the console's API Explorer) names the account with `username` or `user_id` for `state` and `new` (a family whose every device lost the account: `docs/hosting.md`) | owner #67, the account on every device. `state`: `has_key`, `made_ms`, `devices` (ids linked to the account), `username`. `new` (a claimed account; the game asks behind its parent gate): `key` (`XXXX-XXXX`, 8 Crockford base32 symbols, 40 random bits, shown once), `username`, `made_ms`, `devices`; only a bcrypt hash is kept (`account/sign_in_key`, the game can't read it) and it replaces the one before; `rate_limited` (5 an hour, `limits/key_new`), `not_claimed`. `sign_out_others`: every other device id is unlinked, the account's sessions logged out and its open sockets closed (a token already handed out works for plain HTTP until it expires, 2 h, and can't be refreshed): `removed`, `devices`; `not_allowed` (that id isn't the account's). `bad_request` |
| `sign_in_with_key` (0.2.12) | `username`, `key` (as typed: any case, spaces, dashes, O for 0, I/L for 1), `device_id` (a **new** random id the asking game made) | owner #67: `user_id`, `username`, `left`: the new id is linked to the named account (Nakama's own device table), so the game signs in with it next; the asking account is `deleted` when it never claimed a name (a new device's own empty account: `Deletion.run`), else `kept`; `same` when it is that account already (nothing linked). `wrong_key` for a wrong key, an unknown name, a name without a key or a never-claimed one (one answer: no hint who plays); `locked` + `wait` seconds (10 wrong from one asking account in an hour lock it for the hour; the second review: counted per asking account only, never per name, so a stranger's wrong keys can't keep a grown-up's right key out; counted in the node's cache only); `bad_request` (an odd id, or one already linked anywhere). 0.2.20 (owner #105): like LOG IN with the password, every other device of the account is then logged out (`Keys.signOutOthers`) and a link beyond 10 ids unlinks an older one; one bcrypt compare on every path (the startup probe hash when the account has no key, a fixed probe for a malformed key), so the timing never says whether a name has a key (the private server: 730 / 728 / 728 ms for nobody / a key / no key). 0.2.20 (owner #99): `key` may also be the one-time key an approved `move_request` handed to this very asking account (only that account, once, within 5 minutes of the approval); it is used up (the ask "done", by version) before the device is linked, and the account's devices hear notification 110 `{"what": "moved", "kind"}` |
| `password` (0.2.20) | `action`: `state`; `set` + `password`; `change` + `password` + `old` (the password now) or `key` (the account's sign-in key, a grown-up's: FORGOT PASSWORD) | owner #105. `state`: `has_password`, `tried_ms` (the last new device's wrong try the account was told of, `account/password_tried`). `set` (a claimed account without one) / `change`: `ok`; the rules again on the server (`PasswordRules.problem`: `too_short`, `too_long`, `bad_chars`, `is_name` (the name, also with digits and signs around it), `too_common`, `straight_run` (6 in a row of 0-9, a-z or a keyboard row, either way)); `not_claimed`, `has_password` (`set` twice), `wrong_password` (the old one or the key; 5 wrong in 15 min: `locked` + `wait`). Only a bcrypt hash is kept (`account/password`, server only) |
| `sign_in_with_password` (0.2.20) | `username`, `password`, `device_id` (a **new** random id the asking game made), `known_device` (the id this device played as the account with before, if any) | owner #105, LOG IN on any device, one device at a time: the new id is linked to the account (like `sign_in_with_key`) and **every other device of the account is logged out** (`Keys.signOutOthers`: unlinked, sessions ended, sockets closed: a game hears it at once, or at its next sign-in, which it makes with `create=false` and so never makes a new account; the unlinked id is also tombstoned — see `beforeAuthenticateDevice` below). `user_id`, `username`, `left` (`kept`: the asking account stays, the device's own credential for asking; `same`). `wrong_password` for a wrong name, a wrong password or an account without one (one answer); `too_new` + `wait` (the asking account is under 30 s old); `locked` + `wait` (the PAIR window, this asking account and this target account: 5 wrong in 15 minutes, then a wait to the window's end; also a count that can't be written: fail closed); `slow_down` + `wait` (the NAME window, per target account, only devices not linked to it: past 10 wrong in a 24-hour window from its first try, one try every 10 minutes for everyone). A device whose `known_device` is linked to the account right now, and the key path, are never braked. No network window. Every try is counted before the password is checked, with one bcrypt compare against a real or a dummy hash on every path (no timing tell); a correct login clears only its own pair window, nothing else is ever released. A link beyond `KeyRules.MAX_LINKED` (10) unlinks an older id (tombstoned). A new device's wrong try sends notification 112 (persistent, `{"what": "tried"}`) at most once an hour |
| `log_out` (0.2.20) | `device_id` (this device's own) | owner #105 (the final review's simple model): `ok`: this device is unlinked from the caller's account (when it is the account's last device, a random custom id nobody holds is linked first: Nakama never unlinks the last identifier), tombstoned (`account/removed_device`) and the account's sessions end; the account stays safe and LOG IN brings it back. `password_needed` (a claimed account with no password: the game asks for one first), `not_claimed`, `not_allowed` (that id is not the caller's) |
| `move_request` (0.2.20) | `action`: `start` + `username` + `kind` (`phone`, `tablet`, `computer`); `status` + `id`; `cancel` + `id` | **Resting** (the lead's quick-ship round, 2026-10-15: `MoveRules.ENABLED` false): every action answers `not_available`, and `sign_in_with_key` takes no one-time key. When it is on again: owner #99, the same name on a new device with proof (never by the name alone). `start`: `id`, `code` (6 digits from the server's randomness), `valid_s` (300): nothing about the account (not whether a device of it is online, not its name's case); the account's devices get notification 110 `{"what": "asked", "kind"}` (not persistent: an old device that comes online reads `move_approve` `list`); `no_such_player` (no claimed account has that name: claim_username already says "taken" for these names), `self`, `rate_limited` + `wait` (this asking account's own asks: 6 an hour). Past a name's limit (5 asks for it in 15 min, whoever asks) the answer is the same but it is a decoy: it reaches no device and its code approves nothing. `status`: `state` `waiting` + `left_s` (also when the account's device said NOT ME, three wrong codes were typed there, or newer asks replaced it: the asker is never told, it waits until its code is over), `approved` + `key` (one-time, for `sign_in_with_key`; each look hands a new one and only its bcrypt hash is kept, 5 at most) + `username`, `ended` + `why` (`expired`, or `cancelled` after its own BACK), `done`; `not_found` (not this account's newest ask). `cancel`: the ask ends (its card goes). Notification 110 `{"what": "approved"}` to the asker when the code was right |
| `move_approve` (0.2.20) | `action`: `list`; `approve` + `id` + `code`; `decline` + `id` | Resting like `move_request` (`not_available`). Owner #99, on a device of the account asked for (the game asks behind its parent gate). `list`: `username`, `asks` `[{id, kind, left_s}]` (never the code, never who asked); at most 3 open per account (a newer one ends the oldest). `approve`: `ok` (the right code), `wrong_code` + `tries_left`, `ended` + `why` (the third wrong code, or it was over: `expired`, `declined`, `cancelled`, `replaced`), `not_found`; each try counted by version on top of any other at the same moment. `decline` (NOT ME): `ok`, `not_found`. A write that never lands answers `server_error` (fail closed) |
| `theater_channels` (0.2.17) | — | owner #89: `list`, the Theater's channel list the owner keeps (`theater/channels`), or `null` when there is none (games play their bundled `data/theater/channels.json`). Any signed-in game; the owner too. The game keeps the answer on the device (`TheaterFeed`) |
| `theater_set_channels` (0.2.17) | the owner only (no session: the HTTP key or the console's API Explorer): `{"list": {...}}` (the shape of `data/theater/channels.json`), or `{"clear": true}`; up to 64 KiB | `enabled`, `channels`, `videos`, `updated_ms`; `{"list": {"enabled": false, "channels": []}}` is the kill-switch; `cleared`. The list is checked field by field (`TheaterListRules`) and refused whole: `bad_list` + `problems` (each mistake with where, at most 50); `bad_request`, `too_big`; a game gets `not_allowed`. Only the known fields are kept, with `source: "server"`, `version`, `updated_ms`. `tools/theater_list.py push` sends the file |
| `list_ghosts` | `user_id` or `username`; nothing (or yourself) for your own | `owner_id`, `owner_username`, `ghosts`: `[{"ghost_id", "start", "finish", "ms", "path", "look", "updated_ms"}]` (`[]` when none): a friend's showcase ghosts, to race. `not_allowed_online`, `not_found`, `not_friends` (nobody else ever sees a time: no ranking) |
| `invite_info` (0.2.16) | `seen`? (true: the news were shown, the server forgets them) | owner #79: `claimed`, `code` (made on the first call for a claimed account: two kid-safe words and a number, BLUE-OTTER-42; `""` before a name is claimed), `can_use_code` (this account may still use a friend's code: never used one and younger than 14 days), `guide` (who brought it; `""` when none or deleted), `friends`: `[{"name" (a claimed name, else ""), "learned", "joined_ms", "friends", "learned_friends"}]` (newest first, up to 100; a friend's friends are counts only), `counts`: `{"friends", "learned", "tree_friends", "tree_learned", "children_learning"}`, `month` and `caps` (`learned`, `tree`, `landed`: rewards with gold in the last 30 days, and the caps 10, 20, 10), `earned` (invite gold, all time), `groups`: `{"class"|"family": {"code", "members", "learned", "mine"}}` (counts only), `made` (the codes it made), `news`: `[{"what" (joined, learned, tree, landed), "name", "gold", "at_ms"}]`, `world`: `{"joined", "learned"}` (children brought by children, no names), `rewards` (the numbers) |
| `invite_use` (0.2.16) | `code` (typed any way: case, spaces, dashes or none) | `kind` (`friend`, `class`, `family`), `guide` (the code's maker's name), `welcome` (gold given now: 100 to a new account that had no inviter; 0 for an older account joining a group), `gold` (the balance), `group` (`""` or the kind joined). A friend's code: a new account only (under 14 days, by Nakama's create time), never its own, once in its life (`by` is kept even when the inviter's account is gone). A class or family code: anyone joins (one class, one family; at most 40 and 12), and a new account with no inviter is also its maker's referral. `unknown`, `own_code`, `already_used`, `not_new`, `already_in`, `group_full`, `locked` + `wait` seconds (5 unknown codes in 15 minutes lock typing for 15 minutes; counted in the node's cache, `invite_tries:<user id>`) |
| `invite_progress` (0.2.16) | `event`: `learned` (`unit`? the first School unit mastered) or `landed` + `where`: `moon` | `counted` (false: counted before), `gold` (paid to this player now), `guide`. Once per account per event. `learned`: the inviter +250 (within 10 a rolling 30 days; past it counted without gold), this player +50, the inviter's inviter +25 (within 20; the tree's second level, never named); `landed` on the Moon: the inviter +150 (within 10). Each with a news item for the one paid and notification **108**. A player nobody brought: counted, nothing paid (its class still counts it). `bad_request` |
| `invite_group` (0.2.16) | `action`: `make`, `leave` or `remove`; `kind`: `class` or `family` | `make` (a claimed account; the game asks behind its parent gate): `code` (`CLASS-JADE-OWL-27`, `FAMILY-MINT-YAK-11`); one of each kind (asking again shows it); the maker is its first member unless already in a group of that kind. `leave`: out of the group of that kind. `remove` (its maker): the code stops working and the group goes (members' records forget it when next read). `not_claimed`, `bad_request` |
| `social_info` (0.2.18) | `seen`? (true: the news were shown, the server forgets them) | owner #81/#85: `allowed` (the account may be online), `friends`: `[{"id", "name", "days" (days together), "level" (0-3: none, good 1, great 7, best 30), "today" (a day together counted today), "buddy": {"state" ("", `asked`, `asking`, `yes`), "days" (days both learned as study buddies: never falls), "row" (the last 7 days, 2 both learned, 1 one, 0 rest, from the day they said yes)}}]` (mutual friends who may be online, by name), `feed`: `[{"id", "name", "kind", "place", "at_ms"}]` (friends' proud moments to cheer), `presents`: `[{"id", "name", "kind", "at_ms", "opened", "thanked", "link"}]`, `link_gifts` (kinds waiting on the invite code), `news`: `[{"what" (cheer, thanks, present, link_present, buddy_ask, buddy_yes, crew_invite, crew_join, level), "name", "kind", "gold", "place", "at_ms"}]`, `crew`: `null` or `{"id", "name", "adjective", "noun", "badge", "mine", "members": [{"name", "me", "look", "week": {"days", "units"}}], "goal": {"done", "target"}, "full"}`, `crew_invites`: `[{"crew", "name", "badge", "from", "members", "full"}]`, `sends_left`, `cheers_left`, `rules` (the numbers). Moments and presents of players who are not friends now, and news naming deleted accounts, are left out (and tidied away) |
| `social_learned` (0.2.18) | `unit`? (a unit mastered now) | `first` (today's first), `together` (friends who learned today too). The game calls it when a School round or the Daily Mission is finished: the day goes into the player's last 14 learned days and the week's learning (days, units mastered: the crew page); on today's first, each mutual friend who also learned today is a day together (once a day per pair; a level reached is news for both) and study buddies both learning is a shared day |
| `social_moment` (0.2.18) | `kind` (`landed`, `mission`, `unit`, `grade`, `stamp`, `deposit`), `place` (an id: `moon`, `g4.maths.fractions`, `g4.maths`) | `told`: the moment goes into each mutual friend's feed (up to 100 friends; the feed keeps 20) with notification **109**. 5 a day (`too_many_today`); `bad_request`, `not_allowed_online` |
| `social_cheer` (0.2.18) | `moment_id`, `cheer` (`well_done`, `amazing`, `star`, `high_five`, `so_proud`, `you_did_it`: never typed words) | the moment leaves the feed; its owner gets news `cheer` (`place`: `kind:place`), a day together for both, note 109. 30 a day; `not_found` (not in the feed, once, or no longer friends), `bad_request` |
| `present_send` (0.2.18) | `user_id` and `kind` (`rocket_part`, `seeds`, `buddy_egg`, `map_piece`); or `link: true` and `kind` | to a mutual friend: `sends_left`; one a day to each friend (`sent_today`), 5 a day in all (`too_many_today`), an inbox of 20 unopened (`inbox_full`), `not_friends`; the friend's news `present`, a day together, note 109. `link`: it waits on the sender's invite code (`waiting`, at most 3: `too_many_waiting`; a claimed account: `not_claimed`) and goes to the next new friend who joins with the code (`invite_use`), with news `link_present` for the sender |
| `present_open` (0.2.18) | `id` | `kind`, `name` (the sender), `link`; once (`not_found` after). A present from a player who is no longer a friend goes away unopened (a guide's waiting present opens while the guide's account exists). The game gives the thing (`FriendPresents.open`) |
| `present_thank` (0.2.18) | `id` (an opened present) | `gold`: the sender +10 gold (5 thank-yous a day; past it the news without gold), news `thanks`, a day together, note 109; `not_opened`, `already_thanked`, `not_found`. Ledger `{"source": "together", "reason": "thanks"}` |
| `study_buddy` (0.2.18) | `action` (`ask`, `yes`, `no`, `stop`), `user_id` | `state`: `ask` a mutual friend (at most 3 buddies each: `too_many_buddies`; asking one who asked you makes you buddies; news `buddy_ask`), `yes` (news `buddy_yes`; a day both learned already counts), `no` / `stop` (quietly, both sides); `not_friends`, `not_found` |
| `crew` (0.2.18) | `action`: `make` (`adjective`, `noun` from the kid-safe lists, `badge`, `look`?), `invite` (`user_id`), `join` (`crew`, `look`?), `decline` (`crew`), `leave`, `look` (`look`) | `crew` (the crew page, as in `social_info`) for make, join and look. A crew is 1-6 members (a crew of 2-6 once a friend joins); one crew each (`in_a_crew`); invitations to mutual friends (`not_friends`, `already_in`, `crew_full`), news `crew_invite`, `crew_join`; the last one out: the crew goes. `bad_name`, `bad_badge`, `no_crew`, `not_invited`, `not_claimed`. A look keeps short ids only, never the boy / girl choice |

Notifications (0.2.18): **109** friends' news `{"what"}` (not persistent: `social_info`'s `news`, `feed` and `presents` are
the mailbox).
Notifications (0.2.16): **108** invite news `{"what": "joined" | "learned" | "tree" | "landed", "gold"}` (not persistent: `invite_info`'s `news` is the mailbox).
Notifications: **101** invite `{"match_id", "from_username", "from_user_id", "world_name"}` (persistent),
**102** invite cancelled (reserved, not sent yet), **103** a parent approved something `{"what"}`
(`"consent"`, or `"friend"` with `user_id`; both persistent). M4 Wave 3, agent I (not persistent: the lists
are the mailbox, a note only nudges a game that is open): **104** a gift and **105** a bottle
`{"from_username", "from_user_id", "kind": "gift" | "bottle"}`, **106** a sticker `{"from_username",
"from_user_id", "sticker"}`.

**A build** (agent I; the game's `BuildCodec`, `core/gifts/build_codec.gd`; the server's `BuildRules`) is
one base64 text: a version byte (1), the box's size (three bytes), then runs of (count, block id) as
unsigned LEB128 until every cell is covered, cells x fastest, then z, then y. The server decodes every
build it keeps: the sizes, the number of blocks and every id (blocks only: 1-99 and 176-255, never an item
id 100-175 or bedrock 18) are its own check.

### Hooks

| Hook | Rule |
|---|---|
| before AuthenticateDevice, Custom, Email | a username sent with the sign-in passes the username filter |
| before AuthenticateDevice (owner #105) | plus: a device id tombstoned in `account/removed_device` (unlinked from a claimed account by a LOG IN elsewhere, SIGN OUT OTHER DEVICES, a DELETE or the 10-device cap) is refused with PERMISSION_DENIED `device_logged_out` — the game shows its logged-out words, and no fresh empty account is ever made (covers old builds too). A never-claimed account that went leaves no tombstone (its device gets a plain 404 and starts anew) |
| before UpdateAccount | the username filter and case-insensitive uniqueness; no display name, avatar link, location or time zone (personal info) |
| after MatchCreate (realtime) | records the creator as the match's host (`invites`, key `current`) |
| before MatchJoin (realtime) | only the host and the players it invited (an invite lasts 1 h; once in, a player may come back for 24 h), and (0.2.8) only while the host and the guest are still friends: a guest the host unfriended or blocked stays out; never a 5th player. Errors: `not_invited`, `match_full`, `not_allowed_online` |
| before MatchmakerAdd, PartyCreate (realtime) | refused (`not_available`): strangers could meet there |
| before CreateGroup, ImportFacebookFriends, ImportSteamFriends (0.2.8) | refused (`not_available`): a group's free-text name and its members are visible to anyone, and imported friends skip AddFriends' consent and grown-up rules; the game uses neither |
| before AddFriends | only players who may play online, only to players who may (a child without consent is `not_found`, like nobody); names match whatever their case. An **under_13** player's request (or "yes" to one that came in) never reaches Nakama: it waits in `parent/friend_requests` for a grown-up (`approve_friend`) and the call is refused with `needs_grown_up` (players already friends pass). 0.2.8: at most 20 **new** requests an hour per player (`limits/friend_requests`; a "yes" to a request that came in never counts): `too_many` |
| before GetUsers | lookups by name whatever the case; never returns a child who may not be online (except to themselves) |
| before ChannelJoin (realtime) | DMs between friends who may chat; rooms only if named after a match the player is in (team chat); no groups. History (0.2.1, agent E): kept only for a DM between two players at the text level (13+ with text chat), whatever the game asks; never with an under_13 player, never in a team room; opening a kept DM removes its messages older than 30 days |
| before ChannelMessageSend, ChannelMessageUpdate (realtime) | content is `{"text": ...}` or `{"emote": "<id>"}`; the channel's level is the strictest of its players': `off` refuses, `quick` allows quick phrases and emotes (an under_13 player is there), `filtered` runs the chat filter; the cleaned text is what gets sent. A DM (0.2.8) needs the two to still be friends (`not_friends`), and a team room message a sender who is in the room's match now (`room_not_allowed`): Nakama checks only at the join, so an unfriended or blocked player who stayed in the DM, or a player who left the match but stayed in its room, stops at once |
| before WriteStorageObjects, DeleteStorageObjects | a game writes only its own private `profiles` object, key `profile` (0.2.12: any other key is `not_allowed`), at most 64 KiB. 0.2.12 (owner #67): every write is cleaned first (`ProfileRules.clean`): a JSON object with a `version` (1–99) and sane shape (depth 8, lists 2,000, 1,000 keys, texts 1,024, finite numbers, 64 fields) else `bad_profile`; `survivor_gold` (the wallet's), `hud_moves`, `farm_note_at` and one device's settings (`graphics`, `view_distance`, `show_fps`, `install_not_now`, `install_asked_at`, `farm_note`) and the avatar's `base` are dropped; known fields of the wrong kind are dropped; `username` and `age_band` become the account's. Nakama's own version check stays (the game writes by version: another device of the account wrote first → "version check failed") |
| after AuthenticateDevice (agent G) | records the player's sign-in (`activity/signed_in`, server only), then runs the day's retention clean-up if it is due; never stops the sign-in |
| before DeleteAccount (agent G) | Nakama's own `DELETE /v2/account` is refused (`use_delete_account`): only `delete_account` cleans everything |
| after ChannelMessageSend (realtime, agent G) | remembers the message (sender, channel, content, time) for an hour in Nakama's in-memory cache, for a report about it |

### Storage and metadata

Account metadata (only the server writes it): `{"age_band": "under_13"|"13_plus", "consent":
"none"|"pending"|"verified", "online_allowed": bool, "chat": "off"|"quick"|"filtered"}`; a missing
value reads as the strictest one. Collections: `profiles` (the game's backup, the only one it writes),
`parent` (`settings` with a short history, `consent`, `friend_requests`: an under_13 player's requests
waiting for a grown-up, at most 20, 30 days), `reports` (system-owned, one object per report:
the console's Storage page, collection `reports`), `codes` (`redeemed` hashes and, 0.2.19, `paid`: `{hash: {gold, at_ms}}` of the gold codes the server paid itself; `tries`), `farm` (one
per world), and three the game never reads: `invites` (`current`: the match a player hosts and whom it
invited), `limits` (rate-limit windows; 0.2.10: `wallet_spent`, a guest's spends another player reported this hour; 0.2.19: `wallet_hosted`, `{match_id, host_id, seq, seen_ms}`: the last match the server saw the player in, its host and the highest count it reported; `delete_account`: the confirmation handed out) and `activity`
(agent G: `signed_in`, the player's last sign-in; the system user's `retention`, the clean-up's
once-a-day guard with its last result). Agent I: `gifts` and `bottles` (one object per unopened thing,
owned by the friend it is for), `showcases` (`showcase`), `guestbook` (`guestbook`: `entries`, `oldest_ms`),
all server-only (the game reads them through the RPCs), and the send windows `limits/gifts`, `bottles`,
`showcase`. M4 ghost races: `ghosts` (`showcase`: `{"ghosts": [...]}`, server-only; a gift's ghost lives in its
gift's object) and the share window `limits/ghosts`. The wallet key is `survivor_gold`, with a ledger entry per
change (`source`: `code`, `farm` or `award`). Owner #67 (0.2.12): `account` (`sign_in_key`: `{salt, hash,
made_ms}`, server-only, the game can't read it) and `limits/key_new`; wrong sign-in keys are counted in the node's
cache (`key_tries_name:<lower-case name>`, `key_tries_by:<user id>`), never in storage. Owner #79 (0.2.16):
`referrals` (`me`, server-only: the player's code, who brought them `{user_id, kind, at_ms}`, the friends they brought
`[{id, at_ms, learned_ms, landed_ms}]`, when capped rewards were paid, invite gold earned, unseen news as ids, the class
and family they are in and the codes they made; no names), and the system user's `invite_codes` (key: the canonical code,
`BLUEOTTER42`; `{user_id, kind, code, made_ms}`), `invite_groups` (key: the canonical code; `{kind, owner_id, code,
members, made_ms}`) and `invite_stats` (`world`: `{joined, learned}`); unknown codes typed are counted in the node's cache
(`invite_tries:<user id>`). Owner #99 (0.2.20): `account/move_asks` on the account asked for (`{asks: [{id, from, kind, code,
made_ms, state, wrong, why, approved_ms, handed, key_hash}]}`: the codes and the newest one-time key's bcrypt hash,
server-only; ended asks are forgotten after 30 minutes), `account/move_asked` on the asking account (`{target, id, made_ms}`,
its newest ask; `target` "" for a decoy), `limits/move_name` (on the account asked for) and `limits/move_ask` (on the asking
account), every one written by version. Owner #105 (0.2.20): `account/password` (`{hash, made_ms}`, bcrypt),
`account/password_tried` (`{at_ms}`), `limits/password_pair:<account id or name key>` (on the asking account),
`limits/password_name` (on the account named: unknown devices' wrong tries, a 24-hour window from its first try),
`limits/password_change`, `account/removed_device:<hash>` (the system user's, salt `account/device_salt`: each device id
unlinked from a CLAIMED account, so `beforeAuthenticateDevice` refuses it with `device_logged_out`), every one server-only
and written by version; the retention clean-up deletes `limits/password_*` 2 days after their last write and the
`removed_device` tombstones after 13 months (`removed_devices`). Invite gold's ledger entries say `source: "invite"` and a `reason` (`welcome`,
`friend_learned`, `learned_with_guide`, `tree_learned`, `friend_landed`). Owner #81/#82/#85 (0.2.18): `together` (`me`,
server-only: friendships `{<id>: {days, last}}`, the last 14 learned days, the week's learning, study buddies, friends'
moments to cheer, the presents' inbox, presents waiting on the invite code, the day's counts, unseen news as ids, the
crew's id and crew invitations; no names) and the system user's `crews` (key: the crew's id; `{id, adjective, noun, badge,
maker, members, looks, made_ms}`); thank-you gold's ledger entries say `source: "together"`, `reason: "thanks"`.
cache (`key_tries_name:<lower-case name>`, `key_tries_by:<user id>`), never in storage. Owner #89 (0.2.17): `theater` (`channels`: the Theater's channel list, owned by the system user, **public read**
(permissionRead 2), written only by `theater_set_channels`).

The game's profile backup (M4 Wave 2, agent F; owner #67: `ProfileSync`, `ProfileBackup`) is `profiles/profile`:
the same JSON as `user://profile.json` without what fits one device (graphics, view distance, FPS, the browser's
install card, the farm note, moved buttons, boy/girl) and, from layout 2 (`"backup": 2`), without the gold; owner
read and write only, cleaned by the server on every write, written by version (a clash: read, merge, write again).
It comes to every device of the account (`sign_in_with_key`). In an online world the server's wallet is each
player's Survivor balance: the host reads a guest's (`get_gold_of`) and reports every change (`wallet_award` with
`user_id`); the phone keeps its own copy for offline play and sends what changed off the server's watch when signed
in (`WalletSync`: awards and spends from a per-account marker on the device, within the limits), and (owner #67)
then takes the server's balance plus what the server has not taken yet: gold given on the server or earned on
another device reaches the phone, gold spent elsewhere is gone here too.

### Deleting an account (M4 Task 8b, agent G)

`delete_account` (and the retention clean-up for inactive accounts) removes, in this order: every
friend edge both ways (`nk.friendsDelete`); the player from other children's requests waiting for a
grown-up (`parent/friend_requests`); notifications the player sent (invites, Nakama's friend notes);
every DM with the player, both sides (nobody can open it any more); the player's name from reports
they made (a new key, `reporter_id` and `reporter_username` blanked, `reporter_deleted_ms`; reports
**about** the player stay for the reviewer); every storage object of the player in `profiles`,
`parent`, `codes`, `farm`, `invites`, `limits`, `activity` and `account` (owner #67: the sign-in key; Nakama's cascade unlinks every device id) (and agent I's `gifts`, `bottles`, `showcases`,
`guestbook`, and the ghost races' `ghosts`); the unopened gifts and bottles the player sent (in friends' inboxes: `gifts_sent`) and the
stickers it left in friends' guestbooks (`stickers_left`); 0.2.16: its `referrals` record, and first (`Referrals.forget`,
`invites`) its invite codes, the class and family it made (their codes and groups), its place in other groups, its
place and news in its inviter's list, and its friends' links to it (`by.user_id` blanked: they keep their gold and can't
use a second code); 0.2.18: first of all (`Together.forget`, `together`: while its friend edges still find who heard
its moments) its place in every friend's `together` record (days together, study buddies, moments, presents, news, crew
invitations it sent) and its crew seat (the last one out: the crew goes), then its own `together` record with its
storage; then Nakama's own deletion
(`nk.accountDeleteId(id, true)`: a tombstone of the id is recorded; the database's cascade removes
the devices, wallet and its ledger, notifications to the player and messages they sent; their
sessions are logged out and their sockets closed, so they leave every match and channel). The same
device id signs in afterwards as a new account. The owner's steps for a parent's e-mail:
`docs/hosting.md`, "A parent asks to delete an account".

### Retention (M4 Task 8b, agent G)

The written policy is `docs/store/data-retention-and-security.md`. Nakama has no cron: every device
sign-in records itself, and the first sign-in after 24 hours (1 hour when the last run had more to do)
runs the clean-up (`RetentionRules`, `Retention.run`); `retention_run` runs it at once for the owner.
One run: accounts without a sign-in for 13 calendar months (the `activity` record, else the account's
last change) are deleted as above (at most 50 a run); chat messages older than 30 days are removed
(at most 5,000 a run; agent E's purge still clears a kept DM when it opens); notifications older than 30
days (0.2.8, `old_notifications`, at most 5,000 a run: invites, a grown-up's yes and Nakama's friend notes
only nudge an open game, which never reads or removes them on the server); what a deletion in the
console left behind is cleaned (notifications from and DMs with players who no longer exist, their
names on reports); reports get their review time written in (`reviewed_ms`: the console save that set
`"status": "reviewed"`) and are deleted 12 months after it (at most 1,000 changes a run). A report
nobody reviewed stays. Agent I: unopened gifts and bottles older than 60 days (`gifts_expired`, at most
5,000 a run), gifts and bottles from players who no longer exist (`gifts_orphaned`), guestbook stickers
older than 60 days (`stickers_expired`) and stickers of players who no longer exist (`stickers_orphaned`);
a guestbook left empty is deleted. 0.2.10 (the M4 Task 10 review's F): report windows (`limits/report`, the ids a player
reported) whose last report is an hour old (`report_windows`, at most 5,000 a run; written only with a stored report,
so nothing in them still counts). Measured on this PC (load 11): a run with nothing to do 8 ms, 50 inactive
accounts 317 ms; a sign-in 6.7 ms median.

### Runtime switches (`nakama/local.yml`, `runtime.env`)

| Switch | Development server | Production server |
|---|---|---|
| `EASYCRAFT_CONSENT_PROVIDER` | `fake`: "a parent" answers `EASYCRAFT_FAKE_CONSENT_DELAY_MS` (2000) after `consent_start`; `{"fake_answer": "deny"}` tests a no | unset until the owner registers a real provider: `consent_unavailable`, and under_13 stays with solo, LAN and bots |
| `EASYCRAFT_DEV_OPEN_MATCHES` | `true`: accounts that never claimed a username (the spike's `--online-host` / `--online-join`, `tools/net_test.sh`, the GUT relay tests) may join by match id; claimed accounts need invites | unset |
| `EASYCRAFT_ENV` | unset | `production` (always set by `server/deploy/`): both developer switches above are ignored even if set (the fake provider answers `consent_unavailable`, a pending fake request is never approved, developer accounts need invites); the start log says `(production)` |

### Tests

```bash
npm --prefix server/modules test         # builds, then the Node tests (no server needed)
EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server   # against a running server
```

`test/integration/parents.server.ts` (agent F) checks friend approvals through the real friends API,
codes recorded by hash and the private profile backup; `EASYCRAFT_SERVER=... node --test
test/integration/parents.server.ts` runs it alone. `test/integration/data_rights.server.ts` (agent G)
checks account deletion (the player's two calls, the owner's through the HTTP key and the console's
API Explorer), Nakama's own deletion refused, the sign-in record and the daily clean-up, `retention_run`
and a reported team-room message's snapshot; it needs the console (`EASYCRAFT_CONSOLE`,
`EASYCRAFT_CONSOLE_PASSWORD`) and the HTTP key (`EASYCRAFT_HTTP_KEY`, default `defaulthttpkey`).
`test/integration/together.server.ts` (0.2.18, owner #81/#82/#85) checks better together on a real server (friends
learning the same day, a present opened once and thanked with the gold in the wallet, a moment cheered, study buddies,
a crew made and joined, a present waiting on the invite code, a deletion taking the player out of everything; 3 of 3 on
a private Nakama 3.41 for this worktree, with `referrals.server.ts` 3 of 3 and `data_rights.server.ts` 7 of 7).
`test/wallet_exact.test.ts` (0.2.19, the gold-double bug's leftovers: `docs/devlog/parts/gold-double.md`) checks
codes the server paid (asked again, recorded) and the host's seq with late batches on the fake Nakama;
`test/integration/nakama.server.ts` has the same on a real server (a late batch over real sockets, `hosted`, a code
paid and asked again). That file's, `parents.server.ts`', `keys.server.ts`', `gifts.server.ts`' and `ghosts.server.ts`'
age-rule tests (under_13, consent) fail on a module that ships with `AccountRules.ageRules` off (since 0.2.13).
`test/moves_rpcs.test.ts` (0.2.20, owner #99) checks the move with proof on the fake Nakama, with a racing fake that
writes in between a read and its versioned write (two asks for a window's last place, two wrong codes at once, two
hand-outs at once, one key used twice at once: each fails closed); `test/integration/moves.server.ts` the same flow on a
real server (the phone's socket hears the ask, the code approves, the one-time key links the computer's new id, the phone
hears "moved"; wrong codes; a key handed to one device is no use to another).
`test/integration/referrals.server.ts` (0.2.16, owner #79) checks the invite program on a real server (a code, the welcome
in the wallet, learned paid once, the news, the deletion, a family code, storage closed to the game).
`test/integration/gifts.server.ts` (agent I) checks gifts, a 33 KB showcase visited by a friend, stickers,
bottles (to an under-13 friend with consent), a build report, and this wave's deletion and retention SQL on
PostgreSQL itself (the same switches, console and key).

`test/*.test.ts` run on Node 24 (its built-in test runner, TypeScript by type stripping): the pure
rules, and the RPCs and hooks against `test/fake_nakama.ts`. `test/integration/nakama.server.ts`
drives a real server over HTTP and the realtime socket (it needs `local.yml`'s switches, and makes new
accounts on every run). A second server for a parallel worktree needs its own compose project, ports
and container names (the names are fixed in `docker-compose.yml`): an override file with
`services: {postgres: {container_name: easycraft_b-postgres}, nakama: {container_name: easycraft_b-nakama}}`,
then `NAKAMA_GRPC_PORT=7459 NAKAMA_HTTP_PORT=7460 NAKAMA_CONSOLE_PORT=7461 docker compose -f
server/docker-compose.yml -f <override> -p easycraft_b up -d --wait` (and `... down -v` to remove it).

## The game side

- Pure rules: `core/net/online_config.gd` (server address, match ids, developer args),
  `core/net/device_id.gd` (this install's device id, `user://device_id.json`).
- `net/nakama_link.gd` (`NakamaLink`): sign in, realtime socket, relayed match through
  `NakamaMultiplayerBridge`. `Session` (section "M4 early: Nakama online peer") hosts or joins with it.
- Developer args: `--online-host` (prints `ONLINE host match_id=<id>`), `--online-join=<id>`,
  `--online-server=<address>`. Two headless instances check each other: `tools/net_test.sh`
  (online) or `tools/net_test.sh --lan`.
- Big packets: `core/net/relay_pieces.gd` and `net/relay_bridge.gd` send Godot packets over 32 KiB in
  pieces (the voxel sync sends a joining guest's whole world at once; Nakama would close the session).
- Chat (M4 Wave 2, agent E): `NakamaOnlineBackend` joins DMs and team rooms on its socket
  (`tests/integration/test_nakama_chat.gd` against the development server); the team room's name is the
  relayed match id. `tools/measure_online_chat.gd` times it.
- Who plays in a hosted match (0.2.11, the M4 Task 10 review's B): an online host registers each guest with the
  server's `match_players` answer (`net/match_roster.gd`, Session section "M4 Task 10 review B"), never with the
  guest's own `chat_join` name and band; online its relay chat carries quick phrases only, and the chat panel shows
  no relay stand-in for the team room (it rests and tries the room again). Tests: `test_match_roster.gd`,
  `test_host_players_online.gd`, `test_chat_panel_online.gd`; Node `match_players.test.ts`.
- LOG IN with the name and the password, LOG OUT, one device at a time (0.2.20, owner #99, #105): `OnlineService`
  sections "Owner #99" and "Owner #105" (`make_password`, `change_password`, `log_in_with_password` (a second connection
  with this device's own asking credential, `user://login_device.json`), `log_in`, `log_out`, `logged_out`,
  `save_for_log_out`, `progress_goes`; `sign_in` uses `create=false` once the device had an account: Nakama's 404 is
  `account_gone`), `ui/online/log_in_page.gd`, `password_page.gd`, `logged_out_card.gd`, `accounts_flow.gd`,
  `accounts_overlay.gd` (one player on a device: no kept player slots); `tools/net_test.sh --login` (two games: "b" logs
  in with the name and the password, "a" is
  logged out and makes no new account). The move by code (`move_game_page.gd`, `move_ask_card.gd`, `tools/net_test.sh
  --move`) rests while `DeviceMoveRules.enabled` / `MoveRules.ENABLED` are false. Notes: `docs/devlog/parts/accounts-99.md`.
- Tests: `tests/unit/test_online_config.gd`, `test_device_id.gd`, `test_relay_pieces.gd`;
  `tests/integration/test_nakama_link_no_server.gd` and `test_session_online_no_server.gd` (always);
  `tests/integration/test_nakama_link.gd` and `test_session_online.gd`, which skip themselves when no
  Nakama answers on 127.0.0.1:7350 (`tests/integration/nakama_probe.gd`).
