# M4 Wave 1 — Agent A: world sync over the internet, and robustness

Spec §17.0, plan `docs/superpowers/plans/2026-09-24-m4-better-together.md` (Wave 1, agent A; part of
Task 1). Worktree branch cut from `m2-survive-the-night` with the M4 spike merged (`1c0e081`). I used
no editor and no emulator. The lead's Nakama server (compose project `easycraft`, port 7350) was used
read-only. The work stopped early because the owner was leaving (the lead's order, 13:35).
Everything below is committed and green: `b373bd7` (pure rules) and `a173572` (wiring).

## What was built

| Part | Where |
|---|---|
| Edit log per 16³ chunk: the cells that differ from the generator, keeping the generated id so an undo takes a cell off the list; a cap per chunk (`CAP` 512; over it the chunk is diffed when needed), an LRU cap on chunks, and a diff against the generator | `core/net/edit_log.gd` (`EditLog`) |
| Edit packets: chunk lists and single changes in one packet, deflated when big, read defensively | `core/net/edit_codec.gd` (`EditCodec`) |
| Guest side: the host's edits, written over every generated chunk on worker threads | `core/net/edit_overlay.gd` (`EditOverlay`), `world/generators/edited_generator.gd` (`EditedGenerator`) |
| What the host owes each guest, and in what order: single changes first, then lists, nearest chunk first; a list is made at the moment it is sent, so a change can never overtake its list | `core/net/guest_sync.gd` (`GuestSync`) |
| A byte budget per guest per frame (token bucket: 32 KB/s, 4 KB burst); nothing is sent while the relay link still holds more than 16 KB | `core/net/sync_pacer.gd` (`SyncPacer`) |
| Glue. Host: chunk-in-view notifications, the log, diffs, one packet per guest per frame. Guest: `receive`, a recheck when a chunk loads | `net/world_sync.gd` (`WorldSync`, node of every `WorldService`, `world.sync`), `world/synced_terrain.gd` (`SyncedTerrain`) |
| `WorldService`: a guest generates from the seed (automatic loading on, no `VoxelTerrainMultiplayerSynchronizer`); `put_block` | `world/world_service.gd` |
| Relay flow control: every message is queued; the WebSocket gets only what fits; each send result is checked, and a refused message stays first in line | `core/net/relay_queue.gd` (`RelayQueue`), `net/relay_bridge.gd` |
| Batches: one frame's packets for the same target go as one relay message; a message for the only other player carries no presence | `core/net/relay_batch.gd` (`RelayBatch`), `net/relay_bridge.gd` |
| Sync pacing: every `MultiplayerSynchronizer` gets set intervals (players 20 Hz, everything else 10 Hz). In a networked game, creatures sync only what changed | `core/net/sync_pace.gd` (`SyncPace`), applied in Session |
| Rejoin. Host: an online guest's player stays 30 s (`peer_away`, then `peer_back` or `peer_left`), and the host tells a returning guest where its player stands. Relay: a returning account gets its old peer id, also while its old connection lingers on the server. Guest: rejoins within 30 s (the socket closed, or 8 s without a word from the host; the host sends a keepalive every 2 s), then goes back to the menu with kind words | `core/net/rejoin_rules.gd` (`RejoinRules`), Session section `# --- M4 A: world sync`, `net/relay_bridge.gd` |
| Plain words: raw reasons → codes → kind sentences; the overlay shows "Trying again…" over the game, short notes, and goodbye words (3 s before the menu) | `core/net/net_words.gd` (`NetWords`), `ui/net/net_overlay.gd` (`NetOverlay`), sandbox section "M4 A" |
| Measurements: a play window, bytes per guest, packet kinds, world sync counts, `--drop=close\|dead`, `--fps` (default 60) | `tools/net_test.gd`, `tools/net_test.sh` |

Small hooks in shared code (for the merge): `Session._ready` (the `peer_disconnected` handler and
`_a_ready()`), `register_world`, `_rpc_hello`, `_on_online_closed`, `_on_online_peer_disconnected` (one
line each), and `sandbox.gd`'s `_ready`, `_start_client`, `_on_world_info`, `_on_disconnected` and
`_back_to_menu` (one or two lines each). Agent C owns `host_online` / `join_online`; I did not change
them. The rejoin calls `join_online(match_id)` again, and its failure path must keep emitting
`online_failed` and `disconnected`.

## Patterns (godot-prompter skills)
- multiplayer-sync: chose event-sourced world edits (a list per chunk, then changes) over state
  replication of blocks; chose longer replication intervals and on-change delta sync for creatures;
  rejected per-peer distance visibility filters for now (they would despawn and respawn creatures at
  the edge, in entity code owned by other agents).
- multiplayer-basics: rejected "free the player node on peer_disconnected" for online guests (kept 30 s
  instead). Rejoin keeps the same peer id, so all host state keyed by peer id survives.
- godot-ui: the overlay is a code-built full-rect Control with containers, `PROCESS_MODE_ALWAYS`, like
  `KnockoutOverlay`; rejected a popup dialog.

## Tests (RED → GREEN)
Suite: the first run (12:52) had 1783 tests, 50 of them mine, so about 1733 before. After:
**1823 tests, 1822 pass, 1 pending**, `tests/run_tests.sh` exit 0 (13:35, load about 40).

| Test | Count | RED seen |
|---|---|---|
| `tests/unit/test_net_words.gd` | 5 | class missing |
| `tests/unit/test_edit_log.gd` | 13 | class missing; `edit_count` missing |
| `tests/unit/test_edit_codec.gd` | 5 | class missing |
| `tests/unit/test_edit_overlay.gd` | 5 | class missing |
| `tests/unit/test_guest_sync.gd` | 9 | class missing |
| `tests/unit/test_sync_pacer.gd` | 7 | class missing |
| `tests/unit/test_rejoin_rules.gd` | 8 | class missing |
| `tests/unit/test_relay_queue.gd` | 6 | class missing |
| `tests/unit/test_relay_batch.gd` | 3 | written with the class |
| `tests/integration/test_world_sync.gd` | 5 | all 5 failed without the `WorldService` wiring (`sync` missing) |
| `tests/integration/test_relay_flow.gd` (needs the server) | 6 | a burst lost its last packet, no per-guest counts, a returning guest got a new peer id, the takeover was not seen |
| `tests/integration/test_net_overlay.gd` | 5 | class missing |
| `tests/integration/test_session_rejoin.gd` | 6 | written after the code (no RED) |
| `tests/integration/test_sync_pace.gd` | 6 | class missing |

`test_world_sync.gd` builds a host world and a guest world of one seed in one process, with the host's
packets handed to the guest. The guest's box around a secret equals the host's block for block: after
a house built before the guest came, single changes and an undo, edits saved in an earlier session
(diffed), edits that arrive before the chunk loads, and a 1,600-cell slab paced over many frames.

## Measurements (headless, this PC, shared with many agents)

`tools/net_test.sh` with one host and one guest. Games are capped at 60 FPS from the "after" runs on;
uncapped headless games sent more, because every synchronizer sent once per frame. "Payload" means
Godot packets. "Wire" means the JSON the host's socket took.

| | Before (this branch at `1c0e081`) | After (`a173572`) |
|---|---|---|
| Relay: host → guest while playing (10 s) | 9.2 MB sent in the 120 s run (615 KB packets; the run timed out, so there was no flight) | **11.9 kbit/s payload, 35.1 kbit/s wire** |
| Relay: host → guest while the guest flew 150 m | 3.7–9.0 Mbit/s (spike's table) | **22.3 kbit/s payload, 41.6 kbit/s wire** |
| World data in a whole run | 0.2–0.9 MB burst at join, then 1–2 MB/s while flying | 120 bytes (1 list, 7 changes) |
| LAN: flight | 9,312 kbit/s on the wire | 253 kbit/s before sync pacing (13:00); not measured after pacing |
| Guest upload (relay) | about 48 kbit/s (spike) | 7.6 kbit/s payload, about 24 kbit/s wire |
| Guest: sandbox start to standing (`SANDBOX spawned_ms`) | 1,986 ms (load 26) | 2,107–2,762 ms (load 45–58) |
| Guest ping, steady median | 83.7 ms (load 26–29) | 51.4 ms (load 55–58) |

Measured with (load average at the start → end):
- Before: relay 12:36 (26 → about 100); LAN 12:43 (the run ended at 105).
- After: the relay row is from 13:28 (58 → 54). Earlier steps of the same day:
  - world sync only, uncapped: flight 49 kbit/s payload;
  - at 60 FPS without pacing: play 234 kbit/s, flight 371 kbit/s, almost all `sync`;
  - pacing at 12 Hz: play 31.9 kbit/s, flight 64.8;
  - 10 Hz + on-change: play 12.4 kbit/s, flight 20.1 (wire 78 and 96);
  - batches at a 30 Hz tick: wire 39 and 47, but the ping went up;
  - batches per frame: the numbers in the table.

Both games' packet kinds (host → guest, after): `sync` 84%, `spawn` 14%, `rpc` 2%.

Join time: the target is under 2 s. On this loaded PC the guest stood after 2.1–2.8 s, and most of
that is generating and meshing its own spawn area, like a solo start. The breakdown into sign-in,
connect, world info and standing is not measured yet (see next steps).

The host's first diff took 301 ms in one run and 11–45 ms in others. A separate timing (load 30):
`generate_block` of a surface chunk on the main thread costs 6–9 ms; copy and diff cost under 0.05 ms.

## Rulings (decided on the owner's behalf; cost if wrong)
1. **The guest's world = the seed + the host's diff; the host learns unknown chunks by diffing its
   blocks against the generator.** I did not persist a separate edit log with the save. The save stays
   the only truth, so old saves and generator changes are covered. *Cost if wrong:* the host generates
   each saved chunk once more when a guest first sees it (6–9 ms here, more on a phone). See next
   step 1.
2. **Creatures sync at 10 Hz and only on change; players at 20 Hz.** This is set centrally by Session,
   so no entity file changed, and on-change applies only in networked games (the existing tests keep
   their modes). *Cost if wrong:* remote animals, monsters, bots and buddies step 10 times a second,
   and remote players 20 times, until entities smooth remote positions (next step 4).
3. **One frame's small packets per target go as one relay message, and a message to the only other
   player carries no presence.** *Cost if wrong:* a guest that joins in the same frame may receive a
   packet meant for the other guest. Its bridge drops it with an error line.
4. **A rejoin reloads the guest's scene** (the world is generated again). Godot frees everything a peer
   spawned when that peer's link goes, so a frozen world could not be kept. *Cost if wrong:* the child
   sees "Trying again…" over an empty sky instead of the frozen world, then waits about 2 s more.
5. **"Trying again…" shows animated dots, not a countdown** (a kinder screen for children). The goodbye
   words stay 3 s before the menu, so the menu code did not change. *Cost if wrong:* a line in the menu
   later.
6. **LAN guests do not rejoin** (the task asks for the online match). *Cost if wrong:* LAN keeps the old
   "back to the menu".
7. **The net test runs both games at 60 FPS.** *Cost if wrong:* none; `--fps=` changes it.

## Not done / not verified (next steps, in order)
1. **Diff on a worker thread.** Today the host diffs up to `DIFF_MS` (3 ms) per frame on the main
   thread, at least one chunk, which is 6–9 ms here. The plan (not started, nothing uncommitted):
   - copy the chunk on the main thread and run generate + diff with `WorkerThreadPool`;
   - record the changes to that chunk meanwhile and replay them into the log when the result arrives;
   - in `GuestSync.take`, `null` should mean "skip this chunk this frame" (not stop), so a pending diff
     never holds back other lists.
2. **The end-to-end rejoin was never run.** `tools/net_test.sh --drop=close` and `--drop=dead` are
   written but untested. The host part (away, back, let go, rejoin spot) has tests, and the relay part
   (same peer id, takeover) is tested against the server. The guest's scene reload and repeated tries
   are only covered by the pure `RejoinRules` tests. Expect small fixes.
3. **Join time breakdown.** Log the guest's sign-in, connect, world info and standing times in the net
   test, and measure on the emulator (the target: under 2 s).
4. **Smooth remote bodies** (interpolate position between syncs) in player, animal, monster and bot
   code, owned by the entity agents. This makes 10–20 Hz sync look as good as per-frame sync.
5. **LAN after pacing**, and repeat runs at a quieter load for ranges.

## What the lead should check with two games (emulator + desktop)
- The host builds a house and saves; a guest joins; the house, the secrets and the trees look the same
  on both (the net test's checksum does this headless). Edits in both directions show up at once; undo
  works.
- The guest flies far and comes back: the host's builds are still there, and nothing flickers for long
  at the view edge.
- Watch `NETTEST ... play streaming` / `flight streaming` on the relay: they should stay under 50 kbit/s.
- Rejoin: turn the emulator's network off for 5–10 s and on again:
  - "The internet went away. Trying again…" shows;
  - the guest comes back where it stood, and the host kept its player meanwhile;
  - off for more than 30 s: kind words, then the menu.
- Stop the server (`docker stop easycraft-nakama`): the host plays on with a short note ("Your friends
  can't reach this world right now…"), and the guests get the rejoin screen, then the menu.
- Remote animals and players move at 10–20 Hz; judge whether that looks too steppy before smoothing.
