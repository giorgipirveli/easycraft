# M4 early spike: the online foundation (Nakama)

An early de-risking spike for M4 "Better Together" (spec §2, §5.13, §5.14, §7.1–7.4), built on a
worktree branch cut from `m2-survive-the-night` while the M2 agents worked. It changes no M2
gameplay and adds no menu entries: online play is reachable only through developer args. No editor
or emulator was used; the lead verifies after the merge.

**Result.** The existing game runs over a Nakama relayed match unchanged. Two headless instances,
one hosting and one joining by match id, pass the same checks as over LAN: the host's early edit
reaches the guest, both placements, both undos, the host's walk, and the guest's world equal to the
host's. Two things had to be solved on the way:
- Nakama closed the host's connection the moment a guest joined. The voxel sync sends the whole
  world around the guest as one 0.2–0.9 MB packet; `RelayBridge` now sends big packets in pieces.
- A few small incompatibilities between the official client and Godot 4.7.2 (below).

The biggest risk for M4 is bandwidth, not latency. Streaming the world to one guest who flies costs
the host 4–9 Mbit/s of world data (5–12 Mbit/s on the wire), all of it from the host's upload (the
table below). M4 should let guests generate the terrain from the seed and receive only the host's
edits (plan item 1).

## Two-instance results (headless, this PC, 2026-09-24)

`tools/net_test.sh` (relay) and `tools/net_test.sh --lan` alternated; each instance has its own user
folder, and every run is a new world (another seed). The PC was shared with a dozen other agents:
load averages of 24 to 67 on 24 cores, so absolute times are pessimistic and only the relay/LAN
comparison and the byte counts mean much.

**Checks.** Relay, after the fix for point 1 below: 10 runs, 9 passed. The one failure was the test's
own mistake: it expected air where the undo rightly put back a tree's leaves (A had been placed into
a tree on that seed). LAN: 5 passed. Its failures: three runs found port 24565 taken by another
worktree; one starved guest missed the host's short walk (the host now waits for the guest before
walking); one looked like the leaves case, but it ran before the tool printed undo steps, so that is
not proven. The final pair (11:20, load 36–39) passed on both transports, and so did the original
`--lan-test` pair (A=16 and B=12 on both sides, the host's walk seen). Some passing runs reported
`errors=` above 0: those were Godot's leak reports when a headless game quits in the middle of a
world ("... leaked at exit", "resources still in use at exit"), which `net_test.sh` no longer counts.

**Calm run (load 24, 11:09):**

| | LAN (ENet) | Relay (Nakama) |
|---|---|---|
| Guest's RPC ping to the host, while its world streams in (median, max) | 12.6 ms, 28 ms | 26.2 ms, 44 ms |
| Ping afterwards, steady (median, max) | 12.7 ms, 21 ms | 26.0 ms, 61 ms |
| Guest's block placement until it sees the block (request, host check, sync back) | 18 ms | 21 ms |
| Host's biggest single packet (the joining guest's world) | n/a | 193,732 bytes |
| Guest flying 150 m in 10 s: what the host sent meanwhile | 20.5 MB = 16.4 Mbit/s (ENet, on the wire) | 11.3 MB = 9.0 Mbit/s (Godot packets; about 12 Mbit/s as base64 in JSON) |

**Busy runs (load 33–67), ranges over all passing runs:**

| | LAN | Relay |
|---|---|---|
| Steady ping, median | 13–15 ms | 22–72 ms (typically about 30) |
| Ping while the world streams in, median | 10–32 ms (two starved guests: 673 and 1,727 ms) | 26–110 ms |
| Guest's placement round trip | 6–35 ms (one 125) | 21–50 ms (three runs 154–212) |
| Host's biggest single packet | n/a | 193 KB – 935 KB (the voxel sync's batch for a joining guest) |
| Host sent for joining and the checks (about 10 s, before any flight) | n/a | 0.7–1.5 MB |
| Host sent while the guest flew 150 m in 10 s | 11.0–16.4 Mbit/s (on the wire) | 3.7–9.0 Mbit/s (Godot packets; ×1.37 on the wire) |
| Guest's upload (its player sync, pings, requests) | about 110 kbit/s (on the wire) | about 48 kbit/s (Godot packets) |
| Worst frame (headless, loaded PC) | 24–150 ms | 45–150 ms |

The relay adds about 13 ms to a round trip on this PC (two hops through Nakama plus JSON and base64
on both sides); over the internet it adds the trip to the server. Placements stay quick. The flight
numbers vary with the terrain (sea, hills, caves) far more than with the transport: roughly
**1–2 MB/s of world data per flying guest**, all of it from the host's upload. That is the M4
problem to solve (risk 1).

**Server dies mid-game** (`docker stop easycraft-nakama` with a host and a guest playing): both print
`ONLINE error the connection to the server closed`; the host keeps playing solo and the guest goes
back to the menu, as a LAN guest does when its host quits. The first try also logged
`Condition "ready_state != STATE_OPEN"`: `NakamaLink.leave()` sent "leave match" on the closed
socket. It now sends it only while the socket is open, and the rerun was clean.

## What was built

| Piece | Where |
|---|---|
| Nakama 3.41.0 + PostgreSQL 16.8 in Docker, compose project `easycraft`, named volume `easycraft_db`, healthchecks | `server/docker-compose.yml`, config `server/nakama/local.yml` |
| Start/stop/logs/reset wrapper (builds the module first) | `server/dev.sh`, documented in `server/README.md` |
| TypeScript runtime module: `healthcheck` RPC; `redeem_code`, `farm_collect`, `report_user` answer `{"ok": false, "error": "not_yet"}` | `server/modules/src/main.ts` → `server/modules/build/index.js` (git-ignored, built by `dev.sh`) |
| Official Nakama client for Godot 4, pinned, no autoload | `addons/com.heroiclabs.nakama/` (`tools/fetch_nakama_godot.sh`, `SOURCE.md`, `LICENSE`) |
| Pure rules: server address, match ids, developer args | `core/net/online_config.gd` (`OnlineConfig`) |
| Pure rule: this install's device id, kept crash-safe in `user://device_id.json` | `core/net/device_id.gd` (`DeviceId`) |
| Pure rule: big packets cut into pieces and put back together | `core/net/relay_pieces.gd` (`RelayPieces`) |
| Sign in, realtime socket, relayed match | `net/nakama_link.gd` (`NakamaLink`) |
| The bridge that sends big packets in pieces, drops a leaving peer's unread packets | `net/relay_bridge.gd` (`RelayBridge extends NakamaMultiplayerBridge`) |
| Session's online path | `autoloads/session.gd`, section "M4 early: Nakama online peer (spike)", plus one line in `close()` |
| Developer args `--online-host`, `--online-join=<id>`, `--online-server=<address>` | `scenes/main.gd` `_start_online`; `scenes/sandbox.gd` (two call sites) |
| Two-instance check over LAN or the relay | `tools/net_test.gd` (`--net-test`, `--net-test-fly`), `tools/net_test.sh [--lan] [--fly]` |
| Licences | `THIRD_PARTY_NOTICES.md` (new), pointer in `assets/CREDITS.md` |

How the online path works: the host keeps playing solo while it signs in and creates the match,
then switches `multiplayer.multiplayer_peer` to the bridge's peer (as `host_lan` switches to ENet)
and prints `ONLINE host match_id=<id>`. A guest uses a "waiting" peer while it signs in, so it is
never taken for the host, then the bridge's peer; `connected_to_server` fires when the host gives it
a peer id, and the existing `hello → world_info → client_ready` handshake follows. The Nakama
client is only loaded when a game goes online: Session loads `net/nakama_link.gd` by path and keeps
it untyped, so solo and LAN games never load the addon.

## Versions and ports

| What | Version |
|---|---|
| Nakama | 3.41.0 (`heroiclabs/nakama:3.41.0`, build `3.41.0+cab8af5`, go1.27.1), released 2026-09-18 |
| PostgreSQL | 16.8 (`postgres:16.8-alpine`, the version Heroic Labs' `docker-compose-postgres.yml` pins) |
| Nakama runtime types | nakama-common 1.48.0 (what Nakama 3.41.0's `go.mod` names), vendored |
| TypeScript | 5.9.3 (Node 24.17, npm 12.1) |
| nakama-godot | master `6dc7b3951d98cc3807cafb3f1dbc9b44d9b98d21` (2026-09-21), Apache-2.0 |
| Godot | 4.7.2 |

Ports, all bound to 127.0.0.1 (the emulator reaches them as 10.0.2.2): **7350** HTTP API and
realtime socket (the game), 7349 gRPC, 7351 developer console (`admin` / `easycraft-dev`).
PostgreSQL is not published. The defaults were free on this PC (`ss -ltn`, 2026-09-24); the other
projects' containers use 5433–5435, 8000, 8025/8026, 9100–9103 and 55321–55327.

## Commands

```bash
server/dev.sh up              # build the module, start Nakama + PostgreSQL, wait until healthy
tools/net_test.sh             # two headless instances over the relay; exit 0 = both passed
tools/net_test.sh --lan       # the same over LAN, for comparison
tools/net_test.sh --fly       # then the guest flies 150 m: what streaming the world costs
tests/run_tests.sh            # the relay tests run when the server answers, else skip themselves
server/dev.sh down            # stop (the database volume stays); server/dev.sh reset deletes it
```

By hand: `godot --headless --path . -- --online-host` prints the match id; a second instance with
its own `XDG_DATA_HOME` runs `godot --headless --path . -- --online-join=<id>`.

## What worked at once

- The client parses and runs on Godot 4.7.2: all 17 scripts load, device authentication takes about
  15 ms locally, RPCs, the realtime socket and relayed matches work.
- The whole game over the bridge: the handshake, every Session RPC, the MultiplayerSpawners, the
  players' MultiplayerSynchronizers and the Voxel Tools terrain synchronizer, with no change to any
  of them.
- The server module loads (4 RPCs registered) and answers the game (`test_nakama_link.gd`).

## What didn't, and what was done

1. **Nakama closed the host's session as a guest joined.** Nakama's log: `Error reading message
   from client ... websocket: read limit exceeded`, then the guest printed `ONLINE the host left`.
   The host had sent one Godot packet of 537,551 bytes (later runs: 193 KB to 935 KB, depending on
   the terrain), the Voxel Tools synchronizer's batch of every block around the joining guest. The
   client sends it as base64 inside JSON, about 717 KB, over Nakama's `socket.max_message_size_bytes`
   (default 4,096 bytes; 262,144 in the first try). Voxel Tools' `VoxelTerrainMultiplayerSynchronizer`
   has no setting to limit its batches (its API is two RPC methods). **Fix:** `RelayBridge` sends any
   packet over 32 KiB as `RelayPieces` on its own op code (9003) and the receiving bridge puts them
   back together before the multiplayer API reads them. One sender's messages arrive in order, so a
   piece that does not continue its packet means one was lost, and that packet is dropped, never
   delivered with a hole. Nakama's limit is now 65,536 bytes (a piece is about 44 KB on the wire).
   Tests: `test_relay_pieces.gd` (7), `test_a_packet_bigger_than_the_servers_message_limit_crosses_in_pieces`.
2. **`MultiplayerPeer.close()` on a `NakamaMultiplayerPeer` is an engine error** in Godot 4.7.2
   ("Required virtual method MultiplayerPeerExtension::_close must be overridden"); the peer also
   lacks `_disconnect_peer`. `Session.close()` calls `close()` on any non-offline peer, so the online
   section swaps in an `OfflineMultiplayerPeer` first, then leaves the match (`Session._online_close`).
3. **A guest never hears `server_disconnected` when the host leaves**: the bridge reports it as
   "peer 1 disconnected" (its socket to Nakama is still open). `Session._on_online_peer_disconnected`
   ends the guest's game on that, like a LAN disconnect (back to the menu).
4. **Upstream bug (not patched):** `NakamaMultiplayerBridge._on_nakama_socket_closed` assigns to the
   read-only `match_state` property, which does nothing, so the bridge stays "connected" after its
   socket closed. `NakamaLink` watches the socket's `closed` signal itself; Session then ends a
   guest's game or lets the host play on solo.
5. **The host logged `Condition "!connected_peers.has(sender)"` errors when a guest left:** the
   guest's last packets were still queued in the peer when the bridge announced it gone (ENet drops
   a gone peer's packets itself). `RelayBridge` drops them with the peer. Test:
   `test_a_guest_who_leaves_takes_its_unread_packets_along`.
6. **Freeing a `NakamaLink` right after a failed sign-in was an engine error** ("freed while a signal
   is being emitted"): the client's awaits resume inside its `HTTPRequest`'s signal. The link waits
   one frame before returning from each network call.
7. **Godot's WebSocket buffers** are 64 KiB by default for everything queued, and the client's socket
   adapter ignores `send()`'s error, so a message that does not fit is lost without a word. The host
   queues a joining guest's whole world in one frame, so `NakamaLink` sets both buffers to 4 MiB.
   Real flow control is an M4 item (risks 2 and 4).
8. **Over the relay the host's undo step can arrive a frame after the block itself** (they are two
   messages). A player who presses undo in that moment gets nothing undone. Harmless for people (a
   press comes much later); the test waits for the step.
9. **Tooling:** npm 12 refuses git and URL dependencies by default (`EALLOWGIT`, `EALLOWREMOTE`), and
   the Nakama runtime types are not on the npm registry, so `index.d.ts` is vendored. TypeScript 6
   deprecates `target: es5` and `outFile` (TypeScript 7 removes them), which Nakama's goja runtime
   needs, so TypeScript stays on 5.9. Nakama's docs' `!InitModule && InitModule.bind(null);` line
   fails strict type checking and is only for Rollup, so it is left out. In GUT, an override
   `func should_skip_script() -> Variant:` parsed alone but failed ("signature doesn't match the
   parent") in a full run; it must stay untyped like GUT's own.
10. **For the lead, not changed here (shared LAN code):**
    - When a guest leaves, the host once logged `Attempt to call RPC with unknown peer ID` (no
      GDScript backtrace, so native code): most likely the terrain synchronizer still sending blocks
      to the departed guest's `VoxelViewer` in the frame before its Player is freed. Possible fix:
      clear the viewer's network peer id in `sandbox._on_peer_left` before `queue_free`.
    - LAN tests of parallel worktrees collide on the fixed port 24565: three of my LAN runs failed
      with `LAN host_lan err=Can't create` while nothing of mine held the port. A `--lan-port=` arg
      would fix it.
    - My first test version expected air where an undo restores a tree's leaves (one online failure
      shown to be the test's, one LAN failure probably the same). The game is right.

## Rulings (decisions made on the owner's behalf)

1. **PostgreSQL, not CockroachDB, for development.** Heroic Labs ships compose files for both; Postgres
   is lighter on this shared PC and is what they pin in their Postgres file. *Cost if wrong:* switch
   the compose file; a development database holds nothing worth migrating.
2. **Nakama 3.41.0, the newest release** (6 days old), with the matching nakama-common 1.48.0 types.
   *Cost if wrong:* pin an older tag in two places.
3. **nakama-godot from a pinned master commit, not the v3.4.0 release.** v3.4.0 is from March 2024,
   before the Godot 4.4 update, the typing rewrite, request retry time limits and `get_device_id()`.
   *Cost if wrong:* an unreleased regression; our tests cover what we use, and
   `tools/fetch_nakama_godot.sh` switches commits in one line.
4. **The client without its autoload, the Satori LiveOps client or the C# adapters.** `project.godot`
   stays untouched and solo/LAN games never load it. *Cost if wrong:* one autoload line if a later
   feature wants the `Nakama` singleton.
5. **Our own device id, not `Nakama.get_device_id()` and not the Android ID.** A random UUID in
   `user://device_id.json`, written crash-safe (JsonStore) and never in `profile.json`, so a restored
   profile backup (§7.4) never carries another phone's id and nothing identifies the child's
   hardware. *Cost if wrong:* reinstalling makes a new account until account linking (§5.13, later).
6. **Nakama's default ports (7349–7351), bound to 127.0.0.1 only.** The console's default password is
   changed; `NAKAMA_BIND=0.0.0.0` opens it to the LAN for a real phone. *Cost if wrong:* none (env vars).
7. **TypeScript 5.9 and a plain `tsc` build, no bundler.** Nakama's runtime is ES5 and finds functions
   by global name. *Cost if wrong:* M4 adds Rollup once it wants npm libraries on the server.
8. **Vendored type definitions instead of turning npm's git/URL guard off.** *Cost if wrong:* one file
   to refresh per Nakama upgrade.
9. **Big packets are cut into pieces in our code (a bridge subclass), not by patching the addon or by
   raising Nakama's limit to megabytes.** A megabyte-sized limit would still break on a bigger world
   burst. *Cost if wrong:* `RelayBridge` relies on the bridge's internal names (`_id_map`, `_users`, the
   two handler names); the pinned commit and `test_nakama_link.gd` guard that.
10. **When the server connection drops, the host plays on solo and a guest goes back to the menu**,
    the same as LAN. No reconnect in the spike. *Cost if wrong:* M4 item 6.
11. **The spike signs in without a username** (Nakama makes a random one). Claiming the profile's
    username on the server, uniqueness and the filter are M4's account work. *Cost if wrong:* none.
12. **The server RPCs M4 fills in answer `{"ok": false, "error": "not_yet"}` with success,** so the game
    can tell "server fine, feature not there yet" from a failure. *Cost if wrong:* none.
13. **The addon ships in the APKs from now on** (exports exclude only `spikes/`, `tests/`, `addons/gut/`).
    About 10,000 lines of GDScript that are never loaded until a game goes online. *Cost if wrong:* a
    little APK size; add it to the exclude list until M4 if the owner cares.

## Risks for M4

1. **Relay bandwidth for the voxel sync (the big one).** The host streams every block around each
   guest through the relay. Measured: a 0.2–0.9 MB burst when a guest joins, and 4–9 Mbit/s of world
   data (5–12 Mbit/s on the wire) while one guest flies at 15 m/s (table above). A phone's upload on mobile data is often 2–10
   Mbit/s, and a host has up to three guests; Nakama's egress is also what a VPS bills. **Proposal:**
   guests generate the terrain from the seed (the generator is a pure function of the seed and the
   position, `MeadowsGenerator`) and receive only the host's edits: the list of changed blocks per
   chunk when a chunk comes into view, then single changes as they happen. That cuts the traffic by
   orders of magnitude and makes joining instant.
2. **One reliable TCP stream for everything.** `NakamaMultiplayerPeer` reports every packet as
   reliable on channel 0, so position updates queue behind a world burst (head-of-line blocking). The
   first ping series, taken while the guest's world streams in, was 1.5–5× slower than the steady one
   (table above). Pace the voxel sync (a budget per frame per guest) and keep player sync small.
3. **Overhead per message:** base64 inside JSON (+37 %), and the client formats every sent message
   into a debug string even when logging is off (`NakamaSocket._send_async`,
   `logger.debug("..." % p_message)`). Measure on the emulator; if it costs frames, patch that line or
   batch small packets.
4. **No flow control:** a full WebSocket buffer loses messages without an error (point 7 above). With
   pieces, a lost piece drops that packet; with reliable RPCs that is a desync. Pacing (risk 2) and a
   check of `send()`'s result belong together.
5. **Reconnects: none.** A dropped socket ends a guest's game. Mobile networks switch (Wi-Fi ↔ mobile)
   and phones background apps. Plan a rejoin of the same match within about 30 s, keeping the guest's
   player on the host meanwhile.
6. **Host migration: none,** as the spec says (the session ends when the host leaves, the world is
   saved on the host). The host's phone going to the background ends everyone's game.
7. **Mobile NAT: solved by design** (everything goes through Nakama over a WebSocket; with TLS on port
   443 it passes nearly every network). Latency is two hops through the server.
8. **Who may join:** a relayed match id is an unguessable UUID, but anyone who has it can join, and
   relayed matches have no join hook in the match itself. M4 checks invites in a server hook on the
   realtime `MatchJoin` message (`registerRtBefore`) and the host refuses more than 3 guests.
9. **Parental and age rules on the server:** the chat band is still self-declared on LAN
   (`session.gd` chat section). M4 moves the age band, chat permissions and parent settings to the
   account (server-side checks in hooks), so a modified client can't lie.

## Proposed M4 plan outline ("Better Together")

1. **World sync over the relay (first, it decides the rest):** guests generate terrain from the seed
   and get edits only; pace what is still streamed; count bytes per guest in the net test. Target:
   joining in under 2 s and under 50 kbit/s per guest while playing, measured on the emulator.
2. **Accounts:** device sign-in at start (`DeviceId`, done), keeping the session and refresh tokens,
   claiming the profile's username on the server (unique, case-insensitive; the username filter ported
   to TypeScript in a `beforeUpdateAccount` hook), the age band in account metadata.
3. **Friends:** add by exact username, accept or decline, list with online status (Nakama friends and
   status presence), block (Nakama's blocked state), all behind a parent setting.
4. **Invites:** a host invites a friend (server RPC `invite_friend`: friendship, parent settings and
   the 4-player cap checked, then a Nakama notification carrying the match id); the friend's game
   shows it and joins with `Session.join_online`; the `MatchJoin` hook refuses anyone not invited.
5. **Chat:** in-game chat stays host-checked (ChatRules) but reads each player's age band from the
   server account; friends' direct messages and team chat in Nakama channels (history 30 days: a
   server cleanup job), quick chat only for under-13s enforced in a `beforeChannelMessageSend` hook.
6. **Safety:** `report_user` stores reports in a server-owned storage collection, reviewed in the
   console; mute on the device; block through friends. **Parent settings** behind the parent gate:
   chat off, online off, change the age band, stored on the server.
7. **Reconnect and robustness:** rejoin within about 30 s; the host plays on solo if the server goes
   away (done in the spike); pacing and flow control (risks 2 and 4); TLS (wss) for the VPS.
8. **Server-side economy:** `redeem_code` (hashed codes, one use per account), `farm_collect` by server
   time, and Survivor gold in the Nakama wallet (open question: the host decides gold during play, so
   it reports awards through a rate-limited RPC); the profile backed up to Nakama storage (§7.4).
9. **UI:** a first-launch username claim, friends list, invites, an online indicator, parent settings,
   and HOST ONLINE / JOIN in the menus.
10. **Hosting:** a small VPS with this compose file behind a TLS proxy (open item in spec §11), backups
    of the database, and a bandwidth budget from plan item 1's measurements. Production config: a new
    server key, session and refresh encryption keys, console credentials and signing key, and runtime
    HTTP key (Nakama warns at start about each default).
11. **Tests:** TypeScript unit tests for the server module (Node's test runner), the Godot tests against
    the development server (they skip without it), and `tools/net_test.sh` for every network change.

## Tests added (44; the suite: 637 → 681 with the server up, 672 run and 9 skipped without it)

- `tests/unit/test_online_config.gd` (14): server addresses (default, host only, host and port,
  schemes, IPv6 in brackets, 14 bad forms), match ids (relayed and authoritative, trimming and case, 9
  non-ids), developer args (none, host, join, server, 4 bad combinations).
- `tests/unit/test_device_id.gd` (6): UUID v4 form and uniqueness, Nakama's limits, made once and kept,
  a broken file or a refused id replaced, never the profile's file.
- `tests/unit/test_relay_pieces.gd` (7): piece sizes, a 537 KB round trip, one-piece packets, senders
  kept apart, a missing piece drops only that packet, garbage and oversized claims, forgetting a sender.
- `tests/integration/test_nakama_link_no_server.gd` (4, always run): no server fails with a reason in
  time, a bad device id, joining without signing in, the waiting peer is never the host.
- `tests/integration/test_session_online_no_server.gd` (4, always run): a host that can't sign in stays
  solo, a joining guest is never the host and a failure ends in `disconnected`, the device id's file,
  leaving forgets the online settings.
- `tests/integration/test_nakama_link.gd` (7, skipped without a server): sign-in and healthcheck, the
  same device is the same account, the not-yet RPCs, a guest joins and packets cross both ways, a
  600 KB packet crosses in pieces with the next one in order, a leaving guest's unread packets go, a
  match that is not there.
- `tests/integration/test_session_online.gd` (2, skipped without a server): a host switches to the
  relay and `Session.close()` goes back to solo with no engine error (proven to fail without the
  `online_reset()` line in `close()`), a guest joining a match that is not there ends its game.
- `tests/integration/nakama_probe.gd` (helper, not a test): the two server-backed scripts skip only
  when Nakama really does not answer (a 2 s probe once skipped them on the busy PC while it was up).

`tools/net_test.sh` is the end-to-end check (two game instances); it is not part of the suite.
