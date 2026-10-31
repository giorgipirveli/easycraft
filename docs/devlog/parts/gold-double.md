# The gold-double bug: a code's 1000 gold counted twice (2026-10-01)

`tests/integration/test_nakama_account_key.gd` (`test_a_new_browser_signs_in_with_the_key_and_the_account_feels_loaded`,
against the local Nakama server) failed now and then with "[2000] expected to equal [1000]: the wallet's gold": suite 37
on 2026-10-01 and an agent's run on 2026-09-30, both under load; alone it passed. The lead's read (the dev log's 02:55
entry): not the simple sync race (`test_gold_that_changes_while_a_sync_waits_is_never_counted_twice` passes), open:
which step adds the second 1000. Worked by an agent in its own worktree (reset to `lead-merge` 04edf4e6), against the
local server only (`easycraft-nakama`, module 0.2.14); no editor, emulator or adb.

## The evidence

Temporary prints (now removed) of every wallet step: each `get_account_state` sent and answered (with its gold), each
`sync_wallet` start, read, plan and result (uid, phone gold, marker), each code paid. A normal, passing run shows the
window (the phone's tag, times in ms):

```
6239 sync start fresh=true phone=0 marker=-1        <- the claim's first backup went up: `uploaded` -> sync_wallet
6239 get_account_state sent
6239 redeem sent                                    <- the test redeems the 1000 code in the same frame
6252 get_account_state answered gold=0              <- answered first, by 1 ms: all is well
6253 redeem answered gold=1000
```

The two answers come back within a millisecond of each other, in either order. A seam that held each
`get_account_state` answer for 3 more frames on the client (the real server, the real test; temporary) made the other
order every time: **3 failures in 3 runs**, with the same message, and this trace:

```
6286 sync start fresh=true phone=0 marker=-1
6286 get_account_state sent                         <- the server reads the wallet: 0
6286 redeem sent                                    <- then pays the code: 1000
6299 redeem answered gold=1000                      <- this answer is handled first:
6299 redeem paid phone=1000 marker=-1 syncing=true  <- phone 1000; no marker yet, so none moves
6320 get_account_state answered gold=0              <- the sync reads 0 (from before the code)
6320 sync read server=0 phone=1000 marker=-1
6334 sync planned={report: 1000} credited=1000      <- a first sync sends what the server "lacks": the code again
6368 get_account_state answered gold=2000           <- the wallet has 2000; the phone and then the browser follow it
```

## The sequence (the root cause)

1. The phone claims its name; `_f_claimed` uploads the first backup; `ProfileSync.uploaded` starts `sync_wallet()`,
   the phone's **first** sync on the account (no marker in `wallet_sync.json`). It sends `get_account_state`.
2. In the same frame the test redeems `FIRST_CODE`: the server pays 1000 into the wallet **after** it read the wallet
   for the sync (0).
3. The code's answer reaches the phone **before** the read's: the phone's gold becomes 1000; `_f_move_marker` moves
   nothing (there is no marker yet).
4. The sync resumes with the server's 0 and the phone's 1000: `WalletSync.plan` (a first sync counts from the smaller
   of the two) reports +1000 as this phone's own gold. The wallet now holds 2000.
5. The next syncs give the phone 2000, and the browser that signs in with the key reads 2000.

The general fault: `sync_wallet` read the server's wallet at one moment and the phone's gold and marker at another (when
the answer was handled). A gold move the server makes and then the phone (a code paid by the server, a farm collected)
that crosses that read breaks the snapshot, in three ways, all reproduced on the fake server before the fix:

| The crossing | What happened | Test (red before the fix) |
|---|---|---|
| server read → paid; the payment's answer first; a first sync | the code's gold sent again: **2000 on the server** | `test_a_code_paid_while_a_first_sync_reads_the_server_is_not_sent_again` |
| the same, a later sync (a marker) | the marker moved with the gold, the sync planned from the old 0: **the phone's 1000 vanished** until the next sync | `test_a_code_paid_while_a_sync_reads_the_server_never_vanishes_from_the_phone` |
| paid → server read; the read's answer first | the sync gave the phone the server's 1000, then the code's answer added 1000: **2000 on the phone** until the next sync | `test_a_code_answered_after_a_sync_read_the_server_is_not_given_twice`, `test_a_farm_answered_after_a_sync_read_the_server_is_not_given_twice` |
| a sign-in's read, then a code, then the sign-in's `sync_wallet(false)` | planned from the read before the code: **2000 on the server** | `test_a_sync_never_plans_from_a_server_read_older_than_a_code` |

The profile merge was cleared: `ProfileBackup.merge` keeps the local `survivor_gold` (the backup has none), and the
browser's own steps were all right (its trace: a first sync with phone 25, marker -1, server 2000 → 2000; the 2000 was
already on the server). `WalletSync`'s arithmetic, the per-account markers and `record_offline_codes` were right too.

## The fix (`net/online_service.gd`)

- **Paying calls are counted while on their way** (`_f_paying`): `redeem_code` from its send until the code's gold is
  on the phone, `farm_collect` until the caller has paid the phone (`_f_paid` deferred: Session's
  `farm_pay_collected` → `farm_paid_on_phone` runs right after the answer).
- **Every move the server already has that reaches the phone is counted** (`_f_moves`, `_f_moved_gold`, in
  `_f_move_marker`: codes, farms, an online world's gold), with or without a marker.
- **`sync_wallet` reads the wallet only in the clear** (`_f_read_wallet`): it waits while a paying call is on its way,
  then reads; a read during which a payment started or arrived is read again (at most `WALLET_READ_TRIES` 4, then the
  next change or sign-in syncs). `refresh_account` stamps each read (`_f_gold_read_at`): `sync_wallet(false)` (the
  sign-in's) keeps the account's gold only when nothing moved since a clean read.
- **Moves during the report** (`_f_report_now`'s awaits) come from the in-memory sum, not the marker file's difference
  (a first sync has no marker, so a code paid then was lost from the marker and sent again at the next sync).

The code panel never waits for a sync; a sync waits for at most one call (the Nakama client's timeout is 10 s).

Test seam: `FakeOnlineBackend.answer_frames` (`tests/fakes/fake_online_backend.gd`): name → frames; the fake server does
the call at once and only its answer comes back late, so two calls in flight end in the other order than the server
did them. `test_gold_that_changes_while_a_sync_waits_is_never_counted_twice` now really forgets the marker
(`_forget_markers`: JsonStore keeps the one before as `.bak`, so removing the file alone left a marker of 0); it still
passes.

## Results

- The six new fake-server tests in `tests/integration/test_online_wallets.gd`: red before (2000, 0, 2000, 2000, 2000 where
  1000 was right), green after; the file 26/26.
- The real-server test with the 3-frame seam (temporary): 3/3 failed before, **13/13 passed after**.
- The wallet, profile, account-key, code, farm and invite files (19 scripts, both real-server tests included): 223/223.
- The account-key test against the local server (the clean code, no seam), 20 runs in a row: **20/20 passed**.
- The full suite (`tests/run_tests.sh`, the local server up, so both real-server tests ran): **9584 tests, 9582
  passing, 0 failing**, 2 risky (`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`: they never
  assert, as before); 3392 s. `MEASURE owner67 key sign-in to a loaded account: 932 ms` (939 ms before the fix: the
  normal path adds no call).

## Rulings

1. **The fix is on the phone, not the server.** The server could say which moves its balance includes (a ledger
   sequence in `get_account_state` and in every paying answer), which would be the strongest fix but needs a module
   bump and a deploy. Cost if wrong: a new call that pays gold on the server and then the phone, added without
   `_f_paying` / `_f_move_marker`, could cross a sync again; the comment at `_f_paying` says so.
2. **The sync waits for a code, never the other way round** (the child's code answers at once). Cost: a sync started
   while a code is on its way finishes up to one call later.
3. **After 4 crossed reads a sync gives up quietly** (returns "", nothing changed; the next upload or sign-in syncs).
   Cost: in a pathological stream of payments, the gold arrives on the other devices a little later.
4. **The real-server test is unchanged**: it found a real bug.

## Open (not this bug; for the lead)

- **A code's answer lost on the network after the server paid it**: `redeem_code` falls back to the phone's own check
  (`"network"` → `CodeRules.redeem`), which pays the phone too; the next sync then reports that 1000 as the phone's own,
  and `record_offline_codes` only records the hash. Impact: a lost answer (rare) doubles a code's gold. A fix needs the
  server to answer, for recorded hashes, which it had already paid (a module change).
- **A host's batched report (5 s) still on its way when a sync reads**: syncs never start inside an online world
  (`in_online_world`), but right after leaving one, the host may not have reported the last few seconds yet. The sync
  then reads a wallet without that gold and the phone shows it again only at the next sync (it leaves and comes back,
  never twice). Not seen in a test; a fix would wait for the host's last batch (or the wallet's word on it) after a world.

## The two leftovers, fixed (module 0.2.19; 2026-10-01, a second agent)

Worked in its own worktree (reset to `worktree-agent-abe11df3ea7d156bf`, the fix above), server and device together,
tested on a private Nakama 3.41 for the worktree (compose project `easycraft_gd`, ports 7489-7491, the README's recipe)
and against the lead's development server (7350, module 0.2.14: the older-server path). No editor, emulator or adb;
nothing deployed.

### What the second look found

- **A guest's last batch was never on the server at all**, not "late": the host reports a guest's gold in 5 s batches,
  and the server takes a report for a guest only while the guest is in the host's match (`Economy.target`:
  `not_in_match`). A guest who leaves within 5 s of a gold change (every guest, at its last change) had that batch
  refused, and the host drops refusals. The phone had moved its marker with the gold, so its next sync took the
  server's balance: **the guest's last seconds of gold left the phone for good** (not "came back"). The same when the
  host closes its world first (its presence goes: `not_host` for every guest's pending batch).
- **A code paid offline and typed again online before the server heard of it** was a second road to the double: the
  server paid it (accepted), the phone said "already used" and moved nothing, and the next sync reported the phone's
  offline 1000 as its own: 2000.
- The host's **own** last batch from its online world had the same window as the guest's (no refusal: its own reports
  have no match check; its sync after the world read the wallet before the batch and showed the gold a sync later).

### 1. A lost code answer: the designs chosen

- **Server (0.2.19):** `codes/redeemed` keeps, beside the hashes, the gold codes the server paid itself
  (`paid: {hash: {gold, at_ms}}`). `redeem_code {"code"}` for such a code answers `already_used` with
  `paid: {"gold", "at_ms"}` ("already paid: N gold, at T"); `redeem_code {"hashes"}` answers `paid: [{hash, gold,
  at_ms}]` for those of them the server had paid. A code a phone recorded (it paid it itself) has no `paid`.
- **Device:** the phone's own check (`CodeRules.redeem`, offline or with no answer) puts the gold code into
  `ProfileData.codes_unsettled` (hash -> gold; device-only: `ProfileBackup.DEVICE_ONLY_FIELDS`, kept from the local
  copy in every merge). The server's word settles it (`OnlineService._f_code_settled`): the server paid it -> the
  marker moves with that gold (the phone's 1000 *is* the account's 1000, never reported); it did not -> the phone's own
  gold, reported by the sync as for any code used offline. The word comes from: `_f_settle_codes` (a `{"hashes"}`
  record of the unsettled codes) **before every wallet read** of a sync (a sync never plans while a code is unsettled:
  `_f_wallet_read_clean`; if the record fails, no sync now); the sign-in's `record_offline_codes`; asking again
  (`already_used` + `paid`); and the server accepting a code the phone had paid offline (now settled as the server's).
  `redeem_code` ends its paying count (`_f_paid`) only after the fallback paid the phone, so a waiting sync sees the
  unsettled code. "Already used" for a code the phone never had adds its hash (used on the account elsewhere: the
  phone's own check then knows it).
- **Why this design (no request id, no retry first):** the offline fallback already shows "Code accepted!", so a
  retry would not change what the child sees; what was wrong was only the sync's count, and the server's word on the
  hashes fixes exactly that, for a lost answer and for offline use alike, with one small call the sign-in made anyway.

### 2. The host's last batch for a guest: the design chosen

- **Server (0.2.19):** `wallet_award` takes an optional `seq` (the host's count of that guest's gold moves, 1, 2, ...).
  The server keeps the highest count it heard per guest (`limits/wallet_hosted` `{match_id, host_id, seq, seen_ms}`,
  server-only; a piece the rules refuse counts too: the host never sends it again), `amount: 0` + `seq` reports the
  count alone (a batch that netted to nothing), and **a report with a seq is taken after the guest left the match or
  the host left it** (`Economy.target`'s `late`, `WalletRules.lateAllowed`): only for the match the server saw the
  guest in (`get_gold_of`, the host's seed, notes it; so does every report while the guest is there), from that
  match's host (its hosting record still names the match), within `LATE_MS` (24 h, as a rejoin) of seeing it there.
  `get_account_state` answers `hosted: {"match_id", "seq"}` or `null`. A report without a seq is answered as before.
- **Device, the host:** `WalletReport.seq` counts every change, `sent_seq` what the server heard; `_f_send_reports`
  puts the count on the last piece of each guest's batch (a lost piece goes again with the rest of its batch and the
  count; a net-zero batch goes as a 0 piece). Each `_rpc_gold_moved` to the guest carries the count
  (`OnlineWallets.seq_of` -> `OnlineService.report_seq`). The host sends its batches **at once** when a guest's peer
  leaves (`Session._a_peer_disconnected`) and when it closes its world (`_online_close`): `_f_flush_wallet_reports`.
  A call while a send runs sends again right after it (`_f_send_again`).
- **Device, the guest:** `_rpc_gold_moved(balance, delta, seq)` emits `Session.hosted_gold_seq(match_id, seq)`; the
  service keeps the highest (`_f_host_wait`). After the world, its sync waits (`_f_host_reported`, a read every
  `HOST_POLL_SEC` 0.5 s) until `hosted` names that match with that count; it stops waiting at once when the server can't
  say (an older module: no `hosted`), when `hosted` names another match (the server saw the guest elsewhere since, or
  never there: no late batch can land), and after `HOST_WAIT_MSEC` (15 s: the host's game never told the server; the
  server's word stands, as the host decides gold). Playing online again ends the wait (the host reports there). The wait runs in the background (`_f_sync_after_host`): whoever asked for the sync (a sign-in, an invite's welcome) has its answer at once.
- **Device, its own last batch:** before a sync reads, a host's own pending batch is sent and awaited
  (`_f_flush_own_report`; also one already taken and on its way: `take()` empties a batch before its answer); if the network keeps it, no sync now.
- **Why both halves (the simplest exact design):** "the host flushes a leaving player's batch at once" alone was not
  exact twice over: the server refused it (the guest had left), and the guest's game could still read the wallet first
  (the host only hears of the leave after the server, then needs a round trip). "The device holds its sync until the
  host's last report is seen" alone needed the server to take that report. With the count, the server is the one place
  that knows what landed, the guest waits only for what it was told, and the wait is usually under a second (the
  flush). A count per guest (not a wallet-wide one) is what the host can know when it tells the guest.

### 3. A wallet sequence number: not adopted (ruling)

A server-wide count of the wallet's changes in every wallet answer would let `sync_wallet` tell whether a payment
crossed its read. Not adopted, because it would not make the device code simpler: the device must keep working with
the live 0.2.18 server until the deploy (and with any older module after it), so `_f_paying` / `_f_moves` /
`_f_read_wallet` stay either way and a count would be a second path; even with a count, a payment answered after a read
that included it must not reach the phone twice, and one the read missed must be kept, which is the bookkeeping those
counters already do; and Nakama's wallet has no version, so the count would be one more storage write on the hottest
path (every 5 s batch of every player online). Cost if wrong: a new call that pays on the server and then on the phone
must still use `_f_paying` and `_f_move_marker` (the comment at `_f_paying` says so); with a count it would have been
safe by construction.

### Rulings

1. **Once per account for codes.** A gold code the server paid (anywhere: a lost answer, another device of the
   account) settles the phone's own payment of the same code as the server's gold. Cost if wrong: a phone that had
   already received the other device's 1000 through a sync and then redeemed the code offline (its profile not merged
   yet) sees its second 1000 go at the next sync (it was the account's second use).
2. **Two phones using one code offline still pay twice** (as before): the server can't tell the second phone's gold
   from the first phone's report. Cost: 1000 gold per such pair, only offline.
3. **The guest's wait lives in memory.** A game killed within seconds of leaving forgets it: its next sign-in's sync
   may show the gold one sync late (it comes back when the host's batch lands; never twice). Cost: a few seconds of
   gold shown late, rarely.
4. **Late batches for 24 h, only from the match's host, for the match the server saw the guest in.** A modified host
   could keep reporting a friend's spends after the friend left, within `spend_limit` (as while the friend is there),
   until either plays in another match. Cost if wrong: the window is the rejoin window's length.
5. **`_rpc_gold_moved` gained an argument** (with a default: an older host's call still works). Games of different
   versions in one world already don't match (every release adds RPCs), so no version check was added.
6. **Payments made before 0.2.19 have no `paid` record**: a lost answer from before the deploy settles the old way
   (the phone's own; the old double can't be undone automatically). Cost: nothing new.
7. **An older server (0.2.18) is feature-detected**: no `paid` -> codes settle as the phone's own (old behaviour); no
   `hosted` -> no wait; a 0 piece answers `bad_request` (dropped like a refusal). Tests: the fake server's `old_module`.
8. **The age-rule real-server tests fail on a module with no age rules** (`nakama.server.ts` 10, `parents.server.ts`,
   `keys.server.ts`, `gifts.server.ts`, `ghosts.server.ts` one each: under_13, consent): the module ships with
   `AccountRules.ageRules` off since 0.2.13 and those integration files were never switched; not this work. Their
   wallet, code and host-wallet tests pass.

### Tests

- Module (Node): `server/modules/test/wallet_exact.test.ts` (13: codes paid and asked again, a record's `paid`,
  `paidFrom`, the seq kept / refused / seq-only, late batches after the guest or the host left, and refused for another
  match, another host, a guest never seen, after a day; 0.2.19), the answers' new shapes in `economy_rpcs`,
  `parents`; `npm --prefix server/modules test` **403/403**. Real server (private Nakama, 0.2.19): two new tests in
  `test/integration/nakama.server.ts` (the late batch with its seq over real sockets and `hosted`; a code paid then
  asked again and recorded) pass; with `keys`, `together`, `referrals`, `data_rights`, `gifts`, `ghosts`: every
  wallet, code and version test passes (the age-rule failures: ruling 8).
- Fake server (`tests/fakes/fake_online_server.gd`, mirrors 0.2.19; `old_module` answers as 0.2.18) and fake backend
  (`lose_answers`: the server does the call, the answer never arrives; `call_frames`: a call reaches the server late). `tests/integration/test_online_wallets.gd`: 21
  new tests (a lost answer paid once at the sync, at the next sign-in, asked again, while a sync waits, a settling call
  lost too, offline then online, offline never seen, an older server; a guest's last batch after it left, the guest
  waiting for it, at most HOST_WAIT_MSEC, in the background, another match since, an older server; a net-zero batch's count, a lost
  batch's count, the host's own last batch (pending, and on its way), Session's flush on a leave, the RPC's count, `OnlineWallets.seq_of`); unit
  tests in `test_wallet_report`, `test_code_rules`, `test_profile_backup`, `test_online_rules`. **Red before:** with the
  fixes switched off, 13 of the first 18 failed for the reasons above (`[2000] expected to equal [1000]` for the codes,
  `[300] expected to equal [330]` for the guest, `[50] ... [90]` for the host's own batch); the 19th (another match
  since) failed on the commit before its rule (the sync still waiting after 3 s), the 20th (the host's own batch on
  its way) before its fix (`[50] expected to equal [90]`), the 21st (the wait in the background) before its fix ("the answer at once").
- Real server, GUT: new `tests/integration/test_nakama_wallet_exact.gd` (a backend that loses the code's answer;
  `EASYCRAFT_TEST_SERVER`; pending on a module older than 0.2.19): 2/2 on the private server, pending on 7350 (0.2.14).
  **The account-key test with it, 20 runs in a row on the private server: 20/20**, twice (after the main fix, key
  sign-in 918-1049 ms; on the final code, 918-953 ms). `test_nakama_profile_backup` 2/2 there.
- The wallet, code, profile, farm, invite, account-key and real-server files (28 scripts, the real-server ones against
  the lead's 0.2.14 server: the older-server path): **340/340** (mid-way).
- `tools/net_test.sh --server=127.0.0.1:7490`: plain PASS, `--drop=close` PASS, `--crew` PASS, `--invite
  --delete-accounts` PASS (again on the final code).
- **The full suite** on the final code (`EASYCRAFT_TEST_SERVER=127.0.0.1:7490 tests/run_tests.sh`: the account-key and
  wallet-exact tests on the private 0.2.19 server, the other real-server tests on the lead's 0.2.14): **1047 scripts,
  9613 tests, 9611 passing, 0 failing**, 2 risky (`test_the_column_cache_changes_nothing`,
  `test_chunks_meet_without_seams`: they never assert, as before); 3449 s; exit 0. `MEASURE owner67 key sign-in to a
  loaded account: 952 ms`. (A first run's log shared its file name with the lead's suite in the session's scratchpad
  folder; it was discarded and the suite run again with a log of its own.)

### The lead's deploy steps (module 0.2.19)

The device code works with the live 0.2.18 server and the new module answers older games as before, so the order is
free; the module first lets the next web build use it at once.

1. Merge this branch; `npm --prefix server/modules test` (403/403).
2. `server/deploy/kit.sh pack`, copy **exactly the file it printed** (`docs/hosting.md`, step 4), unpack over
   `~/easycraft` on the server, `./kit.sh update`.
3. `./kit.sh check`: its `rpc ok healthcheck` line must say `"version":"0.2.19"`.
4. Optional, on the live server (it makes two accounts and deletes them): `tools/net_test.sh
   --server=https://178-104-20-64.sslip.io --invite --delete-accounts`.
5. The web build (`tools/deploy_web.sh`) and the next APK carry the device half; until a device updates, it settles
   codes and waits for nothing, as before.
6. The lead's development server (7350, 0.2.14 now): `server/dev.sh reload` from the merged checkout runs 0.2.19, so
   `test_nakama_wallet_exact.gd` runs instead of pending.
