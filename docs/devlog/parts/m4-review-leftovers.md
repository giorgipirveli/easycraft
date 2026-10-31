# The M4 review's leftovers: C, D, E, F, G, I (notes)

The M4 whole-branch review (`docs/devlog/parts/m4-task-10-review.md`, "Not fixed") left nine findings. A came with
module 0.2.9 (`remove_guest`, the lead). This follow-up fixed C, D, E (its gate part), F, G and I, each test-first
(RED seen for the reason named, then GREEN). It was done by a background agent in its own worktree, with `lead-merge`
merged at the start (`3a1da90`) and again before the final suites (`256b3da`). It used no editor, emulator, adb or
godot-mcp, and touched no server: neither the live one nor the Docker development server.

**Server module 0.2.10** (from 0.2.9). Node tests **275** (269 before), all pass.

## Fixed

| # | Finding | Fix | Tests (RED: why it failed first) |
|---|---|---|---|
| C | A modified host could empty a guest's server gold: `wallet_award` with a negative amount and the guest's `user_id` had no limit. | `WalletRules.spend` (`server/modules/src/rules/wallet_rules.ts`) and `rpcWalletAward` (`server/economy.ts`). A spend that **another player** reports for this player counts in that player's own hourly window, `limits/wallet_spent` (server only; entries `[ms, gold spent]`). The limit is 20,000 × 2^(u−1) an hour (`SPEND_HOUR_MAX_BASE`, u from the report, clamped to 1..12). A spend that does not fit is refused whole (`spend_limit`) and counts nothing, so the guest keeps that gold. A player's own spends are unchanged (only the balance limits them). A spend over the balance (`not_enough_gold`) counts nothing either. | Node `economy_rules`: "spends another player reports: at most the hour's limit…"; `wallet_host`: "wallet_award: spends a host reports for a guest are limited per hour…", "a spend over the guest's gold counts nothing against the window" (RED: `W.spend is not a function`; the 5th spend went through, 79,999). GUT `test_online_wallets.gd::test_a_guests_spend_over_the_servers_hour_limit_is_dropped` (the fake server mirrors 0.2.10; RED: 79,999). |
| D | Gold Farm clocks were unlimited in number: any `world` key made a new one. | `FarmRules.MAX_FARMS` = 20 and `startRefusal` (`rules/farm_rules.ts`). `Economy.farmCount` lists at most 20 of the player's `farm` objects. A `start` for a world with no clock yet, when there are 20, is `too_many_farms`. Starting a world's clock again, or after a collect (which deletes it), works. | Node `economy_rules`: "farm start: at most 20 farm clocks per player…"; `economy_rpcs`: "farm_collect: at most 20 farm clocks per player…" (RED: the 21st started). GUT `test_online_economy.gd::test_a_21st_farm_clock_is_refused_in_plain_words` (RED: the fake started it; then the words were the generic ones). |
| E | The grown-up gate allowed unlimited tries. | `ParentGate` (`core/validation/parent_gate.gd`) keeps one count and one rest for the app run: 3 wrong answers in a row (`MAX_WRONG`) rest **every** gate for 60 s (`LOCK_MSEC`), and a right answer starts the count again. `GrownUpGate` (`ui/online/grown_up_gate.gd`: SETTINGS' GROWN-UPS, PLAY ONLINE's grown-up page) disables its pad, BACK still works, and the line counts down: "Let's take a short break. A grown-up can try again in 42 seconds." After the rest, a new question appears. The Theater's gate (`ui/theater/theater_panel.gd`) does the same, with the pad taken off its card. Closing a gate and opening it again keeps the rest. The question is still the grown-up's multiplication in words. | `test_parent_gate.gd` (3 tests: the count, a right answer resets it, the line; RED: the stubs never locked). `test_grown_up_gate.gd` (new, 3 tests; RED: the third wrong answer said "Not quite" again, the pad worked, and the right answer passed). `test_theater.gd::test_three_wrong_answers_rest_the_theaters_gate_for_a_minute` (RED: a new question). |
| F | Report windows (`limits/report`) kept the ids of reported players until the reporter's next report. | The daily clean-up (`Retention.run`) deletes a report window whose last write is an hour old: `SQL_OLD_REPORT_WINDOWS` on `storage.update_time`, at most 5,000 a run, answered as `report_windows`. A window is written only with a stored report, so everything in such a window is older than `ReportRules.accept`'s hour. Other windows (`wallet_award`, `friend_requests`, …) name nobody and stay. | Node `retention`: "report windows (the ids a player reported) go once their last report is an hour old; other windows stay", and `report_windows` in the owner's run (RED: no such field). The integration test `data_rights.server.ts` now also checks `report_windows`, so the SQL runs on PostgreSQL when the lead runs `test:server`. |
| G | A blocked player's sticker note still counted: `OnlineService._i_on_notified` checked only `is_muted`. | It checks `_i_hidden` (muted or blocked), like every other received thing. | `test_online_gifts.gd::test_a_sticker_note_from_a_blocked_player_is_not_heard` (RED: `sticker_received` emitted, `new_stickers` 1). |
| I | A guest's `EditOverlay._chunks` never shrank. | Guest: `WorldSync` listens to the terrain's `block_unloaded`. A chunk with known edits that stays unloaded for `FORGET_AFTER_MS` (10 s, looked at every 500 ms) leaves the overlay (`EditOverlay.forget`, which also drops its `_racing` mark). Loaded again sooner, it keeps its edits. Host: when Voxel Tools says a chunk came into a guest's view **again** (`SyncedTerrain.chunk_entered`), `GuestSync.forget` makes the guest owed that chunk's list once more. Before this, a chunk the guest had was never sent again, which was only safe because the guest never forgot anything. | `test_edit_overlay.gd::test_a_chunks_edits_can_be_forgotten`, `test_guest_sync.gd::test_a_forgotten_chunk_is_owed_its_list_again` (RED: stubs). `test_world_sync.gd::test_a_guest_forgets_the_edits_of_chunks_it_left_and_gets_them_again_when_it_comes_back`: a host world with a save, a guest world, a house, and the guest's viewer 640 blocks away and back. Both worlds unload the house, the guest forgets it (0 cells), and after the return the guest's world equals the host's block for block (RED: nothing was forgotten). `test_a_chunk_that_unloads_for_a_moment_keeps_its_edits` (RED: never forgotten). |

## Not fixed (and why)

- **D's second half** (farm payouts counted in the wallet's hourly window): not asked for. With 20 clocks at most 1,000
  × 2^(u−1) gold an hour each for 24 h, a modified game can still mint about as much as `wallet_award`'s own hourly
  limit allows. Gold is never sold, so no real money is involved.
- **E's second half** (friend approvals and chat switches through the consent provider's parent dashboard): this
  needs a provider (Kids Web Services), which does not exist yet. Until then the phone's gate is the check.
- **C's universe** is the host's word, as the review said. A modified host that claims universe 12 may still spend up
  to 20,000 × 2,048 of a guest's gold an hour. The server keeps no player's universe. The fix would be the guest's
  own `profiles/profile` backup (the guest's word, which protects the guest) as a ceiling for u.
- **B and H** were not part of this task. They stay in the review's table and in `docs/DEVELOPMENT.md` §9.

## New error codes and where the game shows them

| Code | From | Plain words (`OnlineRules.message`) | Where it shows |
|---|---|---|---|
| `spend_limit` | `wallet_award` (0.2.10) | "That's a lot of shopping for one hour. The rest can wait!" | **Nowhere on screen today.** Wallet reports run in the background after the host's world has already decided the purchase. `send_wallet_report` drops a refused piece, as it does for `limit`, `too_much` and `not_enough_gold`. The guest keeps that gold on the server, and its next online world starts from it (`get_gold_of`). A line to either child would be wrong: the host didn't spend it, and the guest's purchase went through. |
| `too_many_farms` | `farm_collect start` (0.2.10) | "Your farm keeps time on this phone for now." | Carried in `OnlineService.farm_start`'s answer (`text`). **No screen shows it.** `FarmDirector._start_server_clock` falls back to the phone's clock, as for any refusal, so the welcome-back still pays. The game uses at most 12 farm keys (`survivor_1`..`survivor_12`, `ModeRules.slot`), so only a modified game meets it. |

Both are in `test_online_rules.gd`'s list of codes that must read plainly, kindly and briefly, and both are listed in
`server/README.md`. Older games show the generic "Something went wrong" for them, which never happens in play.

## Rulings (decisions on the owner's behalf; cost if wrong)

1. **C counts only spends another player reports** (the host for a guest). A player's own reports (sign-in sync,
   solo, the menu's shop) are their own gold. *Cost:* none seen. A modified game can only spend its own gold.
2. **C's limit is 20,000 × 2^(u−1) an hour, and a spend that does not fit is refused whole.** Partial spends make no
   sense for a purchase. *Cost:* a guest who gives away or spends more than that in one hour in a friend's world (a
   big gold trade) keeps the rest on the server. Their phone shows it spent, and the next online world starts from
   the server's higher balance. This is in the child's favour (§6), but it lets two friends duplicate gold, up to the
   receiver's award limit per hour, which a modified game could already award itself.
3. **The host's game drops a refused spend** and never retries it, like its other refusals. *Cost:* the server and
   the guest's phone differ (the server is higher) until the guest's next online world.
4. **At most 20 farm clocks**, counted from storage before a new world's clock. Two starts at the very same moment
   at 19 can make 21. *Cost:* none for the game (at most 12 keys). If more save slots ever get farms, raise
   `MAX_FARMS`.
5. **One rest for the whole app run, shared by every parent gate**, like the code field's `CodePanel.shared_tries`.
   It is in memory, not on disk. *Cost:* a child who restarts the app gets 3 more tries after the restart (about 15 s)
   instead of 60 s. This is still much slower than before. A rest on disk would need the wall clock, which the
   child can change.
6. **The Theater's gate shares the count** (the task named only the grown-up gate). Three wrong answers at the Theater
   also rest the grown-up area, and the other way round: it is the same child guessing. *Cost:* a grown-up who
   mistypes at the Theater three times waits a minute before the grown-up area as well.
7. **F runs in the daily clean-up**, not at sign-in. A window whose last report is an hour old is gone by the next
   day's run, at most about 25 h later (before: until the reporter's next report, maybe never). *Cost:* not "≤ 1 h"
   to the minute. The policy row now says what is enforced (`docs/store/data-retention-and-security.md`).
8. **I waits 10 s before forgetting**, and the host re-sends on every re-entry. The host streams around its copy of
   the guest's player, which lags behind the guest. A chunk that leaves the guest's view for a moment may never leave
   the host's copy, and would never be sent again. After 10 s away, the host's copy has left it too. *Cost if
   wrong:* if the host's copy of a guest kept a chunk in view for more than 10 s after the guest's own terrain
   dropped it, the guest would see that chunk without the host's edits until it leaves and comes back. That needs
   the host's view distance for the guest to differ from the guest's own. The host applies the guest's own
   (`_rpc_view_distance` → `set_view_of`), so this can only happen in the moments after a join. Re-sending costs one
   list per edited chunk the guest returns to (a few hundred bytes).
9. The host still sends single changes for a chunk the guest forgot, because the host does not know it left. They go
   into the overlay again and stay until that chunk loads and unloads once more. What piles up is bounded by what gets
   built while the guest is away. The chunk's full list comes when it is back in view, so correctness is unaffected.
10. The host's per-guest `GuestSync._has` (what each guest has) still only grows for a session. This is host memory,
   not the review's finding, and was left as it was.

## Final suites (after merging `lead-merge` `256b3da` last)

- Node (`npm --prefix server/modules test`): **275 tests, 275 pass**.
- GUT (`tests/run_tests.sh`): **633 scripts, 5890 tests, 5888 passing, 2 risky/pending** (the voxel "did not assert"
  checks), **0 SCRIPT ERRORs, exit 0**.
- English only (owner #52): the new words are English, and no translation was added (`test_english_only.gd` is in the
  full run).

## Deploy (the lead; module 0.2.10)

1. On the development PC: `npm --prefix server/modules test` (275 pass), then `server/dev.sh reload` and
   `EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server`. The integration tests expect
   0.2.10. `data_rights.server.ts` runs the clean-up's new SQL (`report_windows`) on PostgreSQL; the Node tests cover
   it only against the fake.
2. `server/deploy/kit.sh pack`, copy it to the server, unpack it, `./kit.sh update`, then `./kit.sh check` (the `rpc`
   line shows 0.2.10).
3. Older games work with 0.2.10: they never meet the new limits in normal play, and the new codes read as the generic
   words there. C, D and F need only the server. E, G and I ship with the next APK.

## What the lead should check

1. **Gate (E), on the emulator:** SETTINGS → GROWN-UPS → three wrong answers. The pad greys out, the line counts down
   from 60, and BACK works. Reopen GROWN-UPS: still resting. After a minute a new question appears, and the right
   answer opens the area. The same at the Theater's Grown-ups card, where the pad disappears while it rests.
2. **World sync (I), online or LAN with two games:** the host builds something, the guest sees it, flies about
   300 blocks away for more than 10 s and comes back. The build is there, and `WorldSync.stats.forgotten` is above 0
   on the guest.
3. **Server (C, D, F), after the deploy:** `healthcheck` says 0.2.10. `retention_run` from the console's API Explorer
   answers `report_windows`. An online Survivor world with a guest who buys at the trader: the guest's gold on the
   server follows (well under the limit).
4. The whole online round of M4 acceptance (Task 9) still passes.
