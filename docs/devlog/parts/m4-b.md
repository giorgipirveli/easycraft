# M4 Wave 1, agent B: the server (accounts, consent, safety, invites, economy)

Spec §17.0–17.4 and §17.6, §5.13–5.14, §7.3–7.4; plan M4 Tasks 2, 3 (server side), 4 (hooks) and 8,
with the shared names of the plan's Wave 1 table. Built in a worktree from `1c0e081` (the spike merged),
TypeScript only: no `.gd` file changed, no editor or emulator used. The reference is
`server/README.md` (every RPC, hook, error code, storage collection and switch).

## What was built

| Piece | Where |
|---|---|
| Pure rules, no Nakama calls: `UsernameRules` and `ChatRules` (ported from the game with the same word lists, checked by a script against the `.gd` files), `AccountRules` (metadata, bands, who may be online, chat level, parent settings), `Consent` (provider adapter + fake provider), `InviteRules`, `ReportRules`, `CodeRules` (the game's salt and hashes), `WalletRules`, `FarmRules` | `server/modules/src/rules/` |
| Nakama glue: RPCs and hooks, storage helpers | `server/modules/src/server/` (`common`, `store`, `accounts`, `social`, `chat`, `guards`, `economy`) |
| Registration of 11 RPCs, 7 realtime before-hooks, 1 realtime after-hook, 7 API before-hooks | `server/modules/src/main.ts` (module 0.2.0) |
| Runtime switches for the development server: fake consent (2 s), open matches for unclaimed developer accounts | `server/nakama/local.yml` (`runtime.env`) |
| Node tests (built script loaded as Nakama loads it; glue against an in-memory fake Nakama) | `server/modules/test/*.test.ts`, `test/fake_nakama.ts`, `test/harness.ts` |
| Integration script against a real server (HTTP API + realtime socket + the console API) | `server/modules/test/integration/nakama.server.ts` (`npm run test:server`) |
| Docs | `server/README.md` (RPC table, hooks, storage, switches, tests), `docs/DEVELOPMENT.md` (commands, 3 gotchas) |

RPCs: `claim_username`, `get_account_state`, `set_parent_settings`, `consent_start`, `consent_status`,
`invite_friend` (notification 101), `report_user`, `redeem_code`, `farm_collect`, `wallet_award`
(and the spike's `healthcheck`). Hooks: the username filter on sign-in and account update (and no
display name, avatar link, location or time zone); after MatchCreate (the creator is the host);
MatchJoin (invited only, never a 5th player); MatchmakerAdd and PartyCreate refused; AddFriends and
GetUsers (names whatever the case; a child who may not be online is never found); ChannelJoin,
ChannelMessageSend and ChannelMessageUpdate (the age rules); WriteStorageObjects and
DeleteStorageObjects (a game writes only its private `profiles`).

Pattern (godot-prompter `dedicated-server`, invoked before building): its lobby pattern, a
server-authoritative player list checked against max players before a peer is accepted, is what the
MatchJoin hook does, one layer earlier (Nakama refuses before the guest ever connects to the host).
Rejected: a dedicated headless Godot server (spec §7.3 and ruling 2 of the M4 dev log: the host's phone
runs the world, Nakama relays) and "kick by RPC once connected if full" (a stranger would already be
in and receive the world). The pure-rules/glue split follows the game's own `core/` rules vs nodes.

## Tests, RED → GREEN

Each rule file's tests were written first and run against the built module before the file was in the
build (RED for the right reason: `Cannot read properties of undefined (reading 'validate')`, `... 'clean'`,
`... 'matchSubject'`, `S.afterMatchCreate is not a function`, `S[fn] is not a function`), then GREEN.

| | Before | After |
|---|---|---|
| Node tests (`npm --prefix server/modules test`) | 0 | **141** in 10 files (username 14, account rules 13, consent 11, account RPCs 16, chat rules 22, invite rules 14, report rules 5, social RPCs/hooks 21, economy rules 17, economy RPCs 8) |
| Integration (`npm run test:server`, my own server) | 0 | **14** (all RPCs and hooks, notification 101 on the socket, 103 in the list, a team room at the strictest level, stored lists read back and grown, a report read back through the console API) |
| Godot suite (`tests/run_tests.sh`) | 1733 (1732 + 1 risky) | 1733 (1732 + 1 risky): nothing in the game changed |

Two test mistakes were found by running, not the code: a wallet case asked for 19,900 gold in one
award (over the per-award limit, so `too_much` came first), and the integration script expected
`not_invited` for an uninvited 5th player (the cap is checked first: `match_full`).

## Measurements (this PC, own compose project `easycraft_b` on 7459–7461)

- Load average 25–50 on 24 cores during the runs (other agents).
- `npm test` (tsc + 141 tests): about 60–100 s wall time at that load, most of it `tsc`; the tests
  themselves take under a second.
- Integration script: 14 tests in 13.7 s (four of them wait 2.2 s for the fake parent).
- Two headless games over the relay (`tools/net_test.sh --server=127.0.0.1:7460`, the spike's dev
  accounts, joining through the MatchJoin hook): PASS at load 33 (ping steady median 20.6 ms, max 29);
  the lead's spike server at load 40 for comparison: PASS (median 29.9 ms). One earlier run on my
  server at load ~50 failed on "host moved" only (the join, edits, undos and the world checksum had
  passed): the spike's known starved-guest case, not the server.

## What the real server taught (probe before building the glue)

- `nk.sha256Hash` gives the same lowercase hex as the game's known vector (`8764c42a…`), so
  `redeem_code` accepts the owner's first code (checked end to end).
- A relayed match's presences are on stream mode 5 (subject = the match id's uuid; presences have
  `nodeId`); `nk.matchGet` works on relayed ids; the MatchJoin envelope is `{matchJoin: {matchId,
  metadata}}`; MatchCreate's after-hook output is `{match: {matchId, self: {userId, ...}}}`.
- Nakama's username lookups (GetUsers, AddFriends by name) are exact-case; its uniqueness is too.
- **A game could write `parent/consent {"status": "verified"}` itself** before the guard: the probe's
  write succeeded. Now only `profiles` is writable by a game.
- The session token keeps the random username Nakama gave until the game signs in again, so
  presences and chat show it after `claim_username`.
- Nakama reads `InitModule`'s source to find registered functions: a registration inside a helper
  stopped the server at start ("function key could not be extracted").

## Rulings (decisions made on the owner's behalf)

1. **Case-insensitive usernames by a query plus a unique index on `lower(username)`**, created on
   Nakama's `users` table when the module starts (logged, not fatal, if old duplicates exist).
   *Cost if wrong:* a custom index on Nakama's table; `DROP INDEX easycraft_users_username_lower`
   removes it. A sign-in that sends a case-duplicate name gets a generic error, not "taken"
   (the game claims names with `claim_username`, which answers "taken").
2. **No display name, avatar link, location or time zone** can be set by a game (personal info, spec
   §17.2). *Cost if wrong:* none planned; loosen `beforeUpdateAccount` if a feature needs one.
3. **The age band is set by the first claim; afterwards only `set_parent_settings` changes it** (the
   game calls it after its parent gate; the server can't check a parent gate). A band change starts
   from the new band's defaults and keeps the consent state; each change is kept in a short history in
   `parent/settings`. *Cost if wrong:* a child who passes the parent gate can switch to 13_plus, the
   same trust as the first age gate.
4. **Missing or broken metadata reads as the strictest value**; an account that never claimed a
   username gets the under_13 rules. *Cost if wrong:* none (it only refuses).
5. **The fake provider keeps no state**: the answer and the time are in its reference
   (`fake:approve:<ms>`), because Nakama runs calls in separate runtimes. A yes grants online play with
   quick chat, as a real provider's per-feature permissions would. `{"fake_answer": "deny"}` tests a no.
   Without a provider the server answers `consent_unavailable`. *Cost if wrong:* the real provider's
   adapter decides what a yes grants; nothing else changes.
6. **The parent's contact is never stored** (passed to a provider only). *Cost if wrong:* none.
7. **Two server-only collections beyond the shared five: `invites` and `limits`** (the game never
   reads them). *Cost if wrong:* none for other agents; the names are only in this module.
8. **One hosting record per host** (`invites/current`, written after MatchCreate): a new match
   replaces the old invites, so the records never grow. An invite lasts 1 h; a guest who joined may
   come back for 24 h (reconnects, agent A); a host may send 20 invites in 10 minutes.
   *Cost if wrong:* a guest back after a day needs a new invite.
9. **Development server: accounts that never claimed a username may join by match id**
   (`EASYCRAFT_DEV_OPEN_MATCHES=true` in `local.yml`), so the spike's `--online-host`/`--online-join`,
   `tools/net_test.sh` and the GUT relay tests keep working. Claimed accounts need invites there too,
   so agent C's real flow is checked on the development server. *Cost if wrong:* on a server that sets
   it without `EASYCRAFT_ENV=production`, anyone with a match id (an unguessable UUID) and no username
   could join; a production server ignores it (ruling 20).
10. **"Join from the friends list" means taking a pending invite**; there is no "open to friends"
    match. *Cost if wrong:* a friend can't drop in uninvited; a host switch can be added.
11. **Matchmaking and parties are refused** (strangers could meet). *Cost if wrong:* none planned.
12. **A child who may not be online is not findable** (GetUsers drops them, AddFriends answers
    `not_found` like for nobody) and can't send friend requests. **No parent approval queue for
    friends yet**: parents switch online play off or on. *Cost if wrong:* "approve friends" (§17.2)
    waits for the real provider's parent portal or a later task.
13. **Chat channels: friends' DMs and a team room named after the match id only**; no public rooms,
    no groups. Content is `{"text"}` or `{"emote"}`; a channel's level is the strictest of its players'
    (an under_13 player in a DM or team room makes it quick phrases only); 13_plus text runs the ported
    chat filter. No server-side rate limit (the host's in-game limit stays). *Cost if wrong:* agent C
    must use these formats; a different team-chat design changes one check in `rtBeforeChannelJoin`.
14. **Reports: reason codes only** (`mean_words`, `bad_name`, `bad_build`, `personal_info`, `scary`,
    `cheating`, `other`; anything else is `other`), system-owned, 10 an hour, the same player once per
    10 minutes (the child is still thanked). *Cost if wrong:* no free-text detail for moderators; the
    match, channel and message ids are kept when given.
15. **Codes once per account on the server**; the redeemed list is written first, by version, then the
    gold, so two redemptions at the same moment pay once. Cosmetic rewards are returned for the game to
    unlock. *Cost if wrong:* none known.
16. **The farm's time is the server's; its rate, cap and universe come from the game, clamped**
    (1,000 gold/h before 2^(u−1), 24 h, u ≤ 12), because the farm (M3 Task 10) isn't built. Collect
    deletes the record by version first. *Cost if wrong:* a modified game can claim the top rate; M3
    Task 10 should keep the farm's level on the server.
17. **`wallet_award` credits the caller only**; each guest's game reports its own gold. Limits:
    2,000 × 2^(u−1) per award, 20,000 × 2^(u−1) an hour (u from the payload, ≤ 12); what crosses the
    hourly limit is dropped (`capped`); a negative amount is a purchase and needs the balance.
    *Cost if wrong:* soft limits (a modified game can claim up to them); a host can't pay a guest.
18. **The invite notification is persistent** so a friend whose game was in the background still
    sees it; the game should ignore invites older than an hour (the notification's `create_time`).
19. **Node runs the tests as TypeScript by type stripping, without type-checking them**; `tsc` checks
    the module itself. *Cost if wrong:* a typo in a test fails at run time, not build time.
20. **On a production server (`EASYCRAFT_ENV=production` in the module's env, which agent D's kit
    always sets) both developer switches are ignored**, not only the fake provider the lead asked
    about: `consent_start` answers `consent_unavailable`, `consent_available` is false, a pending fake
    request is never approved, and developer accounts need invites like everyone. The start log says
    `(production)` and warns when the switches are present. "Production" is matched trimmed and in
    any case. Tested in Node (3 tests) and on my server restarted with `EASYCRAFT_ENV=production`
    plus both switches on. *Cost if wrong:* none; a server without `EASYCRAFT_ENV` behaves as before.

## Lead's messages during the work

- *Production must never use the fake provider* (from agent D's kit): done, ruling 20.
- *Socket or session settings in `server/nakama/local.yml`*: **unchanged** (and `js_entrypoint` too);
  I only added `runtime.env` entries, which the production kit does not copy (on purpose). D's parity
  test (`test_hosting_kit.gd`) needs nothing.

## For the lead: after the merge, and with two games (emulator + desktop)

1. `server/dev.sh reload` (the module and `local.yml` changed). The log should say
   `easycraft module 0.2.0 loaded (development); consent provider: fake`.
2. **GUT `test_the_rpcs_m4_fills_in_answer_not_yet`** (`tests/integration/test_nakama_link.gd:55`)
   fails once the server runs this module: with `{}` the RPCs now answer `redeem_code` → `bad_request`,
   `farm_collect` → `bad_request`, `report_user` → `not_found`. I may not edit `.gd` files; replace it
   with those codes (or a real redemption). The other relay tests and `tools/net_test.sh` pass
   (developer accounts, rule 9; net_test checked on my server).
3. `npm --prefix server/modules test` (141) and
   `EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server` (14).
4. With two games through agent C's UI (under_13 on one): claim names; `consent_start`, and 2 s later
   `consent_status` turns it on (notification 103); add a friend by name in another case; host, invite
   (toast from notification 101), join; a third account that wasn't invited is refused (`not_invited`);
   a DM or team chat with the under_13 player takes quick phrases only; report → the console
   (http://127.0.0.1:7351, Storage, collection `reports`); the first code once (1,000 gold, then
   `already_used`); farm start/collect; wallet awards.
5. Agent C: sign in again after `claim_username` (the token keeps the old name); chat content
   `{"text"}`/`{"emote"}`; team room = the match id; error codes in `server/README.md`.
6. Agent D's production server: with `EASYCRAFT_ENV=production` the developer switches are ignored
   anyway (ruling 20); the start log should say `(production); consent provider: none`. `kit.sh
   check`'s `relay SKIP ... join rules` is expected with the MatchJoin hook (D's notes).
7. Suggestions outside my files: a `server/.gdignore` (with "export all resources", Godot may pack the
   `.json` files of `server/modules/node_modules` into the APK); container names from the project name
   in `docker-compose.yml` (a second server for a worktree now needs an override file for the fixed
   names, see `server/README.md`).
