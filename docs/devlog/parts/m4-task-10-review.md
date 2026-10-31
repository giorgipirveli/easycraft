# M4 Task 10: the whole-branch review and fix pass for the online game (notes)

Plan `docs/superpowers/plans/2026-09-24-m4-better-together.md` Task 10. Done by a background agent in its own worktree
(cut from `m2-survive-the-night`, `lead-merge` merged at the start (release 0.4.0) and again before the final suites),
without the editor, the emulator, godot-mcp or any server (the live and development servers were not touched).
Scope: the server module (`server/modules/src/`: RPCs, rules, storage, rate limits, data deletion, consent and age
gates), `net/`, the online parts of `autoloads/session.gd`, `ui/online/`, `ui/gifts/`, the relay play and online
trading. Two read-only helper reviews ran in parallel (the relay's flow control and reconnects; the online screens'
crash paths); every finding below was confirmed here by reading the code path or by a failing test.

**Server module 0.2.8** (from 0.2.7). Node tests **263** (252 before), all pass.

## Fixed (each test-first: RED seen for the reason named, then GREEN)

| # | Finding (severity) | Where | Fix | Test |
|---|---|---|---|---|
| 1 | **The store's age signal never reached the server account** (high, child safety). An account claimed as 13+ whose phone later learns the player is under 13 (Play Age Signals: `_f_on_age_signal` made only the *profile's* band stricter) kept the server's 13+ rules: filtered free text, friends without a grown-up's yes, no consent needed. The spec says the signal "only ever makes the band stricter". | `net/online_service.gd` `refresh_account`, `_f_on_age_signal` | Whenever the game reads the account and the phone's band is under 13 but the account's is 13+, it sends `set_parent_settings {"age_band": "under_13"}` (a stricter band needs no grown-up) and takes the answer; a signal while signed in does it at once; until the server has heard (network), the phone keeps under-13's rules itself. | `test_online_economy.gd`: `test_a_store_signal_after_a_13_plus_claim_makes_the_server_account_under_13`, `test_a_store_signal_while_signed_in_tells_the_server_at_once`, `test_the_phone_keeps_under_13_rules_when_the_server_cant_hear_it_yet`; Node `account_rpcs`: "a 13+ account made under_13 loses free text, friends' rules and online play" |
| 2 | **Any game call lifted an under-13 account to 13+** (high, the server trusted the client's age). `set_parent_settings {"age_band": "13_plus"}` from an under-13 account was accepted (the test even said "a parent may change the band"), but the server can't see the phone's parent gate and the game never sends it: a modified game (or a script with the device's session) got free text, friends without approval and online play without consent. | `server/modules/src/rules/account_rules.ts` `applyParentSettings` | The band only ever gets stricter: under_13 → 13_plus is `age_band_locked`. | Node `account_rules`: "the band only ever gets stricter; under_13 never becomes 13_plus from a game"; `account_rpcs` (the old assertion turned round) |
| 3 | **A DM went on after an unfriend or a block** (medium). Nakama checks friendship only when a DM channel is joined; a player who stayed in the channel kept sending to the child who unfriended or blocked them. | `server/modules/src/server/chat.ts` `Chat.channelLevels` | A DM message (and an edit) needs the two to still be mutual friends: `not_friends`. | Node `social_rpcs`: "a DM stops the moment the two are no longer friends (unfriended or blocked)" |
| 4 | **A blocked guest could come back into the host's world for 24 h** (medium). The MatchJoin hook let an invited player in (1 h) and back after a drop (24 h) without looking at the friendship again. | `server/modules/src/server/social.ts` `rtBeforeMatchJoin` | An invite and the way back need the host and the guest to still be friends: `not_invited` otherwise. | Node `social_rpcs`: "a guest the host unfriended or blocked can't come (back) in" |
| 5 | **Team chat from a player no longer in the match** (medium). The team room was checked at the join only: a player who left the match, or was dropped and may not come back (#4), kept talking to the children in the room. | `chat.ts` `Chat.channelLevels` | A room message needs its sender in the room's match now: `room_not_allowed`. | Node `social_rpcs`: "team chat only from a player who is in the match now" |
| 6 | **Notifications were kept forever** (medium, retention). Invites (101, persistent), a grown-up's yes (103) and Nakama's friend notes are never read or removed by the game on the server; the policy said "until read and removed", which never happened. | `server/modules/src/server/retention.ts`, `rules/retention_rules.ts` | The daily clean-up deletes notifications older than 30 days (`old_notifications`, at most 5,000 a run, `more` when it stops at that). The policy row changed to "at most 30 days (enforced)". | Node `retention`: "notifications older than 30 days go (an invite lasts an hour; nothing reads them later)" |
| 7 | **Groups and friend imports were open** (low, hardening). `CreateGroup` (a free-text name and description anyone can list, members anyone can see) and `ImportFacebookFriends` / `ImportSteamFriends` (friends that skip AddFriends' consent check and the grown-up's yes) were not refused; the game uses none of them. | `social.ts` `beforeRefuseSocial`, `main.ts` | Refused (`not_available`), like matchmaking and parties. | Node `social_rpcs`: "groups and imported friends are switched off" |
| 8 | **A gift or bottle opened while a grown-up kept online play off** (low, consent). `list_gifts` / `list_bottles` refused, `open_gift` / `open_bottle` did not (ids known from an earlier list). | `server/modules/src/server/gifts.ts` `Gifts.open` | `not_allowed_online`, the thing stays; discarding still works. | Node `gifts_rpcs`: "open_gift and open_bottle: nothing opens while a grown-up keeps online play off; discarding still works" |
| 9 | **A hidden child's name could be confirmed by a stranger** (low, privacy: "no findable username before consent"). `invite_friend` by name answered `not_friends` (not `not_found`) for a child who may not be online, and `report_user` / `report_build` by name answered `ok`. | `rules/invite_rules.ts`, `social.ts` `Social.findReported`, `gifts.ts` | By name such a child is nobody (`not_found`); by id (a player met while allowed online) a report still works. | Node `social_rpcs`: "a child who may not be online looks like nobody to a stranger's invite or report by name" |
| 10 | **CANCEL while SHOW IT read the showcase area published it anyway** (medium, a SCRIPT ERROR and a share the child cancelled). The area is read on a worker for a few frames; CANCEL cleared it meanwhile, the showcase still went up with "Your showcase is up!", and with a buddy nearby `nearest_buddy` read `origin` of the empty area. | `ui/gifts/share_panel.gd` `publish` | After the read: nothing more when the panel was cancelled, closed or left. | `test_share_panel.gd::test_cancel_while_the_area_is_read_shares_nothing` (RED: the SCRIPT ERROR and the showcase on the fake server) |
| 11 | **Friend requests had no limit** (medium, a missing rate limit). Nakama has none of its own: a stranger guessing names could send hundreds of requests to children who may be online. | `social.ts` `beforeAddFriends`, `Social.takeRequests` | At most 20 **new** requests an hour per player (`limits/friend_requests`); a "yes" to a request that came in, or a friend already, never counts; `too_many` shows the game's existing "Wow, that was fast!" words. | Node `social_rpcs`: "at most 20 new friend requests an hour; saying yes to a request never counts" |
| 12 | **A new match reset the invite limit** (low, rate limit). The window (20 invites in 10 minutes) lived in the hosting record that every new match replaced: a host could make matches to send invite after invite (each a persistent notification). | `social.ts` `afterMatchCreate`, `rules/invite_rules.ts` `invite` | The window carries over to the new record. | Node `social_rpcs`: "a new match does not start a new invite window" |
| 13 | **A frame's packets for a guest who left were relayed to everyone** (medium, relay). `RelayBridge` gathers a frame's small packets for one target and sends them at the end of the frame; when that guest's leave came first, the run went without presences, which Nakama relays to every other player: a packet the host meant for one guest (its inventory, gold, rejoin spot, world edits) reached the others, whose games ran it as the host's. Found by the relay helper review (its finding 1). | `net/relay_bridge.gd` `_end_run` | A run for a player who is gone is dropped. | `tests/unit/test_relay_bridge_targets.gd` (3 tests; RED: the run queued with no presences) |
| 14 | **A restored profile backup lifted the phone's under-13 band** (medium, child safety; #1's other half). `ProfileBackup.merge` took the winning copy's band: a backup from before the phone knew better (a 13+ answer, then the store's signal said under 13) won on a new install, and the phone's chat registration and LAN rules followed it until the next start. | `core/save/profile_backup.gd` `merge` | The band is the stricter of the two copies (unknown never wins). | `test_profile_backup.gd::test_a_restored_backup_never_lifts_the_phones_under_13_band` (RED: 13_plus after the merge) |

## Not fixed (with where, why and the proposed fix)

Later (2026-09-25): C, D, E (its gate part), F, G and I were fixed test-first in a follow-up, module 0.2.10:
`docs/devlog/parts/m4-review-leftovers.md`. A came with module 0.2.9 (`remove_guest`, the player card's REPORT, BLOCK and REMOVE FROM MY WORLD).
B (module 0.2.11, `match_players`) and H (reproduced, then fixed) were fixed test-first in the safety leftovers:
`docs/devlog/parts/safety-leftovers.md`.

| # | Finding | Where | Why not now | Proposed fix |
|---|---|---|---|---|
| A | **Fixed by the lead, 2026-09-25 (spec §17.3 "Safety in the world", module 0.2.9):** the name tag's card in every world with REPORT, BLOCK and the host's REMOVE (`remove_guest`); tests `remove_guest.test.ts`, `test_player_card_safety.gd`, `test_host_removes_guest.gd`. Was: **The host can't remove a player from its world, and a child can't report or block a player who is not their friend from the world** (moderation). The name tag's card (owner #37) has TRADE only; REPORT and BLOCK live on the FRIENDS page (friends only) and on a team-chat line. A guest the host blocks now can't come back (#4), but stays until they leave; the host's only way out is to close the world. | `ui/trade/player_card.gd`, `world/trade_director.gd` (`player_card.open_for`), `net/relay_bridge.gd` (no way to drop a peer) | A new RPC, a new card and new screens: bigger than a review fix. | Server: `remove_guest {"user_id", "match_id"}` (host only, like `get_gold_of`'s check): `nk.streamUserKick` of the guest's presences on the relayed stream (mode 5, the match's subject; the others' bridges see a leave, the host's game drops the peer) and the guest struck from `invited`. Game: online, the name tag's card gets REPORT (the reasons page, `OnlineService.report` with the peer's user id from `Session._f_user_of`) and, for the host, REMOVE FROM MY WORLD (asks first; also offered after BLOCK). |
| B | **Fixed, 2026-09-25 (module 0.2.11, `docs/devlog/parts/safety-leftovers.md`: `match_players`, host only; the host registers each guest from the server's answer; online the relay passes quick phrases only and the chat rests when the team room can't open; Node `match_players.test.ts`, GUT `test_host_players_online.gd`, `test_match_roster.gd`, `test_chat_panel_online.gd`).** Was: **Online, the host's chat names and bands are the guests' own word.** `chat_join(username, band)` comes from each game's profile (`autoloads/session.gd:375` `_host_chat_join`, `ui/hud/chat_panel.gd:115`); the host checks relay chat, trades (`_pt_refusal`, `session.gd:4556`) and `chat_recipients` with those. A modified guest can show another name, or claim 13+ to get free text on the relay. The team room (server-checked) carries online chat, so this matters only when the room could not open (`chat_panel.gd:538-541` falls back to the host's relay chat, which also skips a grown-up's "quick" setting for a 13+ child). | `session.gd:375-392`, `chat_panel.gd:530-541` | Needs the server to tell the host each guest's name and chat level (the socket's presence names are the random ones until the next sign-in). | A host-only RPC `match_players {"match_id"}` answering each present player's username and `chat_level` (from the account); `_host_chat_join` online takes those instead of the guest's word; online, no relay-chat fallback (the chat says it is resting until the room opens). |
| C | **Fixed, 2026-09-25 (module 0.2.10, `docs/devlog/parts/m4-review-leftovers.md`: `limits/wallet_spent`, `spend_limit`; Node `wallet_host`, GUT `test_online_wallets.gd`).** Was: **A modified host can empty a guest's server gold.** `wallet_award` with a negative amount for a guest in its match has no limit (a spend is a purchase in the host's world). | `server/modules/src/server/economy.ts` `rpcWalletAward` (`step.credit < 0`) | Host-authoritative by design (spec §7.3); a cap needs the real prices, and the universe is the host's word too. | Count spends reported by another player in an hourly window like awards (`limits/wallet_spent`, 20,000 × 2^(u−1)); the guest's own phone reconciles at the next sync. |
| D | **Fixed, 2026-09-25 (module 0.2.10, `docs/devlog/parts/m4-review-leftovers.md`: at most 20, `too_many_farms`; Node `economy_rpcs`, GUT `test_online_economy.gd`).** Was: **Gold Farm clocks are unlimited in number** (`farm_collect start` with any `world` key makes a new storage object, each paying up to 1,000 × 2^(u−1) an hour for 24 h). A modified game can mint gold (already possible within `wallet_award`'s generous hourly limit) and fill storage. | `economy.ts` `rpcFarmCollect`, `rules/farm_rules.ts` | The farm's real rates are M3 Task 10's; gold is never sold (no real money), and the wallet's limits already allow about as much. | At most 20 farms per player (a `storageList` count before a new world's `start`: `too_many_farms`), and farm payouts counted in the wallet's hourly window. |
| E | **Fixed, 2026-09-25 (the gate part; `docs/devlog/parts/m4-review-leftovers.md`: three wrong answers rest every parent gate for a minute; `test_grown_up_gate.gd`, `test_parent_gate.gd`, `test_theater.gd`; the provider part waits for a consent provider).** Was: **The grown-up gate is a speed bump** (a multiplication in words, unlimited new questions); `approve_friend` and `set_parent_settings` trust it (the server can't see it). It matters once a consent provider exists (today no under-13 player is online at all). | `ui/online/grown_up_gate.gd`, `core/validation/parent_gate.gd` | A design decision (spec §5.14) that the provider is the real check. | Lock the gate for a minute after three wrong answers; with Kids Web Services, friend approvals and chat switches through the provider's parent dashboard (its per-feature permissions) instead of the phone. |
| F | **Fixed, 2026-09-25 (module 0.2.10, `docs/devlog/parts/m4-review-leftovers.md`: the daily clean-up deletes a window an hour after its last report, `report_windows`; Node `retention`).** Was: **Report windows keep the ids of reported players until the reporter's next report** (`limits/report` `last`), longer than the policy's "≤ 1 h of use". Pseudonymous ids in a server-only object, gone with either account. | `server/modules/src/rules/report_rules.ts` `accept` | Negligible. | Filter the window in the retention clean-up, or read it through `windowFrom` + `accept`'s filter when an account signs in. |
| G | **Fixed, 2026-09-25 (`docs/devlog/parts/m4-review-leftovers.md`: `_i_hidden`; `test_online_gifts.gd::test_a_sticker_note_from_a_blocked_player_is_not_heard`).** Was: **A blocked player's sticker note would still count** in `OnlineService._i_on_notified` (`is_muted` only, not `_i_hidden`). Not reachable: `sign_guestbook` already refuses a player who is not a mutual friend (a block ends the friendship). | `net/online_service.gd:1174-1175` | Not a live bug. | Use `_i_hidden` there too when that file is next touched. |
| H | **Fixed, 2026-09-25 (reproduced in `test_relay_bridge_targets.gd`, then fixed: a join first names the players of every waiting "everyone else" message, `RelayQueue.retarget_everyone`; `docs/devlog/parts/safety-leftovers.md`).** Was: **The relay's "only other player" shortcut and a join** (low, suspected, not reproduced). A packet for the only other player goes without presences (`net/relay_bridge.gd` `_only_other`, about 300 bytes saved); one still in the `RelayQueue` (flow control holds it) when a third player joins reaches the newcomer too, and the host's peer-id messages go straight to the socket (the addon's `_host_add_peer`), so they can overtake it: the newcomer's game could run a packet meant for the other guest. | `net/relay_bridge.gd:46-47`, `:104-106` | Needs a join exactly while the host's queue holds messages; the lead's relay tests never showed it. | Name the target in every queued message once a second guest may join (always send presences when `_users.size() < 4`), or end the shortcut when a join arrives by rewriting the queued messages' JSON with the target's presence. |
| I | **Fixed, 2026-09-25 (`docs/devlog/parts/m4-review-leftovers.md`: forgotten 10 s after the guest's terrain unloads the chunk, sent again when it comes back into view; `test_world_sync.gd`, `test_edit_overlay.gd`, `test_guest_sync.gd`).** Was: **A guest's `EditOverlay._chunks` never shrinks** (low, memory): every chunk a guest ever got edits for stays for the session (the host's `WorldSync._seen` has a cap and forgets unloaded chunks). A few cells per chunk; a long flight adds up slowly. From the relay helper review (its finding 2). | `core/net/edit_overlay.gd:8-35` | Small and bounded by one session's exploring. | Forget a chunk's overlay when the guest's terrain unloads it (as `WorldSync._forget_unloaded`). |

**Handed over by the M3 review** (`docs/devlog/parts/m3-task-19-review.md`): "the awaits in `ui/hud/chat_panel.gd`
(`_submit`, `_send_phrase`, `_report_from_menu`) can resume after the panel is freed". Checked with a test before
any change (`test_chat_panel_online.gd::test_a_message_or_report_on_its_way_when_the_world_closes_ends_quietly`: a
slow fake network, a message, a wheel phrase and a report on their way, the panel freed): nothing resumes and
nothing is logged, and the report still reaches the server. Godot 4.7 drops a freed script instance's pending
awaits (the instance's destructor clears their connections), and a panel only taken out of the tree is safe
(`_fill_history` returns off-tree). **Not a bug; no code change**; the test stays as a guard.

Checked and found sound (the helper reviews and here): the relay's reassembly is bounded (`RelayPieces.Assembler`:
16 MB, one packet per sender, a gap drops it), `EditCodec.open` checks every size, index and id, the rejoin state
machine (`RejoinRules`) gives up after its window and every `await` in `Session._a_*` re-checks its link, a returning
player's old connection is cleaned up before its peer id is reused, and the host's keep-alive runs while paused. The
online screens read every field from the network through typed checks (`GiftRules`, `OnlineChatRules.parse`,
`OnlineRules.parse_invite`, `RaceGhost.from_wire`, `GhostBook.from_json`), and every RPC's field names match
`server/README.md`. Under-13 players without consent reach nothing social on the server (every social RPC and hook
checks `canPlayOnline`; a relayed match they create can't get invites); with consent: friends wait for a grown-up,
chat is quick phrases in every channel they are in, trades only with their own friends, ghost names only with consent.

## Final suites (after merging `lead-merge` `c406484` last)

- Node (`npm --prefix server/modules test`): **263 tests, 263 pass**.
- GUT (`tests/run_tests.sh`): **607 scripts, 5689 tests, 5687 passing, 2 risky/pending** (the voxel "did not assert"
  checks), **0 SCRIPT ERRORs, exit 0**. An earlier full run found one SCRIPT ERROR from this task's own new test
  (`test_relay_bridge_targets.gd`: the bridge's deferred flush ran after the test freed the socket's adapter). The
  test now lets go of the bridge in `after_each` (commit `4ab0846`). It was a test-only problem.
- Owner #52 (English only) came in with the merge: this task added no translations and no Georgian.

## Rulings (decisions on the owner's behalf; cost if wrong)

1. **The server never lifts an under-13 account** (#2). The game has no screen that asks for it, and the server can't
   see the parent gate. A child registered as under 13 by mistake (or who turned 13) is moved by the owner in the
   Nakama console (the account's metadata `age_band`) on a parent's e-mail. *Cost:* a teen waits for the owner.
2. **The phone's stricter band wins, both ways it is read** (#1): the account follows the phone at the next read, and
   the phone keeps under-13's rules while the server has not heard. A 13+ account whose phone profile says under 13
   (a family's shared phone, a restored backup onto a child's profile) becomes under 13. *Cost:* such a 13+ player
   needs the owner's console to go back.
3. **Notifications 30 days** (#6): the game shows invites for 10 minutes and never reads old notifications from the
   server; 30 days matches DM history. *Cost:* none seen (friend requests live in Nakama's friend list, not in the notes).
4. **A cancelled SHOW IT shares nothing, even when the read had finished** (#10): the child's last tap wins.
5. **20 new friend requests an hour** (#11): a child adds a few friends at a time; accepting never counts. *Cost:* a
   player adding a whole class at once waits an hour after the 20th.
6. **A dropped run for a guest who left** (#13) loses nothing: that guest's game is gone from the match, and a
   rejoin gets the world, inventory and gold from the host again.

## Deploy (the lead; module 0.2.8)

1. On the development PC, from the game's folder: `npm --prefix server/modules test` (263 pass), then
   `server/dev.sh reload` and `EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server`
   (the integration tests now expect 0.2.8; `data_rights.server.ts` runs the retention clean-up's new SQL on
   PostgreSQL — the notification SQL is only covered by the fake in Node).
2. `server/deploy/kit.sh pack`, `scp build/server/easycraft-server-*.tar.gz` to the server, unpack over the old folder
   (`.env` and `backups/` stay), `./kit.sh update`, then `./kit.sh check` (the `rpc` line shows 0.2.8).
3. The game needs no new build for the server's fixes; #1, #10 and #13 ship with the next APK. Older games work
   with 0.2.8 unchanged (no field or answer they read changed; the new refusals use codes they already show).

## What the lead should check (emulator and online)

With the development server on 0.2.8 (`server/dev.sh reload`), the emulator (`Pixel_8_API_35`, `--online-server=10.0.2.2`)
and a desktop game, two 13+ accounts A (emulator) and B (desktop) who are friends:

1. **DM after unfriend:** A and B open a DM; B unfriends A in FRIENDS; A's next message says it can't be sent (the
   server's `not_friends` in plain words) and B sees nothing more. The same after a BLOCK.
2. **Rejoin after block:** A hosts, invites B, B joins; B's game is closed (drop); A blocks B; B's JOIN (or the
   automatic rejoin) is refused ("Ask your friend to invite you again.").
3. **Team chat after leaving:** B leaves A's world; A's team chat keeps working for A (and nothing from B arrives).
4. **Friend requests:** 20 ADDs to other names in an hour work, the 21st says "Wow, that was fast!".
5. **Age signal (Android only):** hard to fake on the emulator (Play Age Signals); the GUT tests cover it. On a
   supervised Google account (a Family Link child) that claimed 13+ before: after the next PLAY ONLINE the grown-ups
   area shows the under-13 page (ask a grown-up), and the console's account metadata says `under_13`.
6. **SHOW IT, then CANCEL at once** (SHARE → MY SHOWCASE): nothing goes up (a friend's VISIT says there is no
   showcase), no toast, no error in `adb logcat`; SHOW IT again works.
7. **Retention:** `retention_run` from the console's API Explorer answers `old_notifications` (0 on a fresh server).
8. The whole online round of M4 acceptance (Task 9) still passes: consent gates, invites, relay play of 4, chat by
   age, gifts, showcases, ghosts, trades, DELETE MY ONLINE ACCOUNT.
