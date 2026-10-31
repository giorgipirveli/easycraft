# M4 Wave 1, Agent D: the hosting kit (the owner's server on the internet)

Plan: `docs/superpowers/plans/2026-09-24-m4-better-together.md` (Task 1 part, Wave 1 allocation D);
spec §7.1, §11 (open item "Nakama hosting provider and monthly budget"), §17. Built in a worktree
from `1c0e081` (the M4 spike merged). No editor, emulator or adb used; no other game code touched
(only `core/net/online_config.gd` and tests).

**Result.** `server/deploy/` runs EasyCraft's Nakama on any small VPS behind Caddy with automatic
HTTPS, with every secret from a never-committed `.env`, daily checked backups with rotation, a
restore, health checks and log rotation; `docs/hosting.md` walks the owner through it step by step
with three providers, sizes and cost estimates. The kit ran on this PC as compose project
`easycraft_d` (Caddy on 127.0.0.1:8480/8443, its local CA): every part healthy, no "insecure default"
warning from Nakama, the game's own Godot client signed in over HTTPS and relayed a 32 KiB piece over
`wss://` through Caddy, a backup/restore round trip worked, and a relay load of 100 players measured
what a server needs. `OnlineConfig` got the release address and the TLS rule, test-first.

## What was built

| Piece | Where |
|---|---|
| Production compose: PostgreSQL 16, Nakama (built image), Caddy 2.11, backup service; project `easycraft_live`; only 80/443 public, console on 127.0.0.1; json-file logs 10 MB × 5; healthchecks on all four; `unless-stopped` | `server/deploy/docker-compose.yml` |
| Multi-stage image: `node:24-alpine` builds the module (`npm ci`, `npm run build`), `heroiclabs/nakama:3.41.0` gets only `build/`, the production config and the start check | `server/deploy/Dockerfile`, `Dockerfile.dockerignore` |
| Production Nakama settings without secrets (the relay settings equal the development server's) | `server/deploy/nakama/production.yml` |
| Start check: refuses empty, short, placeholder or Nakama-default secrets (exit 78 with the reasons), writes them into `/run/easycraft/secrets.yml` (a tmpfs) as a second `--config`, runs `migrate up`, then Nakama; `EASYCRAFT_RUNTIME_ENV` → `runtime.env`, always with `EASYCRAFT_ENV=production` | `server/deploy/nakama/start.sh` |
| Caddy: automatic HTTPS for `EASYCRAFT_DOMAIN`, http→https redirect, reverse proxy with WebSocket upgrade, `stream_close_delay 5m`, HSTS, no `Server` header, no access log, no HTTP/3 | `server/deploy/caddy/Caddyfile` |
| Backups: `pg_dump` custom format, checked with `pg_restore --list` before it counts, daily at `BACKUP_AT` (UTC) plus one at start when the newest is over 12 h old, keeps the newest `BACKUP_KEEP` (7) per label, files 600 owned by the kit's user; restore (drop, create, `pg_restore --single-transaction`); health = newest daily under 26 h | `server/deploy/backup/backup.sh` |
| Every secret key with comments; the release server key | `server/deploy/.env.example`; `.gitignore` (`.env`, `.env.*`, `backups/`) |
| One command for everything: `keys [domain]`, `up`, `status`, `check [url]`, `logs`, `backup`, `restore <file> [--yes]`, `update`, `down`, `console`, `pack` | `server/deploy/kit.sh` |
| Outside-in check like the game (HTTPS, device sign-in with the key, RPC, wss ping, a piece-sized message, relay both ways; `SKIP` when join rules refuse the uninvited) | `server/deploy/check/smoke.mjs` (Node 22+, run by `kit.sh check` in `node:24-alpine`) |
| Relay load generator for sizing (test servers only) | `server/deploy/check/load.mjs` |
| Trying the kit on a shared PC (ports 8480/8443 on 127.0.0.1, no console port, own image tag) | `server/deploy/local-try.yml` |
| Release server address and TLS rule | `core/net/online_config.gd`: `RELEASE_SERVER` (empty until the owner has one), `RELEASE_SERVER_KEY`, `is_release_build()`, `default_server()`, `server_for_build()`, `release_server()`, `key_for()`, `--online-server=release` |
| Owner's guide | `docs/hosting.md` |
| Licences of the images | `THIRD_PARTY_NOTICES.md` (Caddy, PostgreSQL 16, Node.js) |

## Patterns chosen and rejected

- **godot-prompter `dedicated-server` skill: rejected** its pattern (a headless Godot server export,
  systemd, UDP ports). The game's design is host-authoritative over Nakama's relay (§7.3, M4 ruling 2),
  so the server is Nakama, not Godot; Docker Compose gives the restart, health and log rotation that
  the skill gets from systemd. Its checklist items that apply were kept: restart policy, logs you can
  follow, only the needed ports open, release builds without debug settings.
- **Secrets:** a second Nakama config file written at start into a tmpfs (chosen) rather than
  command-line flags (visible in `ps` on the host) or a committed YAML with placeholders (a real key
  one `git add` away from the repository). Nakama merging `--config a --config b` key by key was
  checked first (a scratch run: the name from the first file, the keys from the second, no warning).
- **One production config, not layered on `server/nakama/local.yml`:** layering would carry
  development-only settings (the console password, and whatever the server agent adds, such as a fake
  consent provider) into production. The values the game depends on are kept equal by a test instead.
- **Caddy, not nginx + certbot or Traefik:** one small container, certificates and renewals with no
  cron job, WebSocket upgrades without configuration.
- **Backups in the stack (a service with a sleep loop), not a host cron job:** nothing to install on
  the VPS, it starts and stops with the server; `init: true` so it stops at once.
- **`OnlineConfig`: the key follows the server (`key_for`), not the build.** A developer build can then
  try the real server (`--online-server=release`), and a release build can't send the development key
  to it. `SERVER_KEY` stays the development key, so nothing that already uses it changes.

## Tests (RED → GREEN)

- `tests/unit/test_online_config.gd`: 10 new tests (14 → 24). **RED:** the script did not parse
  (`Static function "server_for_build()" not found in base "OnlineConfig"`, `Cannot find member
  "RELEASE_SERVER"`, 15 parse errors), **GREEN:** 24/24, 107 asserts. They cover developer builds
  (desktop 127.0.0.1, emulator 10.0.2.2), release builds (https, port 443, no scheme means https),
  refusing http for the release server, no release server yet (release builds have none), the committed
  `RELEASE_SERVER` empty or https, `default_server()` in a test run, one key per server, the release
  key not Nakama's default, `--online-server=release`, and the build's own server as the default.
- `tests/unit/test_hosting_kit.gd` (new, 7 tests, 67 asserts): the release key equals `.env.example`;
  production's relay and session settings equal `server/nakama/local.yml`'s; no secret in
  `production.yml`; every secret is in `.env.example`, checked by `start.sh` and required by compose;
  only 80 and 443 published to the world; `.env` and `backups/` git-ignored; the release server is
  reached as `https://…:443` and `wss://…` through the real addon. Written after the files, so each was
  **proven by mutation**: six changes (the key set to `defaultkey`, the message size to 4096, a
  `server_key` in `production.yml`, the console port opened, one `check` line removed from `start.sh`,
  `backups/` removed from `.gitignore`) made exactly those six tests fail; restored, 7/7 pass.
- Full suite: before 177 scripts, 1733 tests (1732 passing, 1 pending); after: see "Suite" below.

## Validation of the kit (this PC, compose project `easycraft_d`, 2026-09-24 12:51–13:05, load average 45–66)

| Check | Result |
|---|---|
| `docker compose config` | production file with a `kit.sh keys` env: valid; with the bare `.env.example`: refused ("POSTGRES_PASSWORD is empty in .env (run ./kit.sh keys)"), as designed; with `local-try.yml`: Caddy only on 127.0.0.1:8480/8443, Nakama publishes nothing |
| `caddy validate` with a real-looking domain | "Valid configuration" (automatic HTTPS, http→https redirect) |
| `kit.sh up` (build + start) | image built (module compiled in the Node stage), migrations applied (20), module loaded (4 RPCs), all four containers healthy |
| Nakama's own view (console API `/v2/console/config` from inside the network) | `warnings: []` (the development server logs six "insecure default" warnings); effective config merged: name `easycraft`, `max_message_size_bytes` 65536, `outgoing_queue_size` 1024, the release server key, `runtime.env` `["EASYCRAFT_ENV=production"]`, JSON logs to stdout only |
| `kit.sh check https://localhost:8443` | `https`, `sign-in`, `rpc`, `socket` (ping 20 ms), `big-message` (43,692 characters accepted), `relay` (both ways) all ok |
| Negative checks | Nakama's default key: `401 Server key invalid`; without trusting Caddy's CA: `UNABLE_TO_GET_ISSUER_CERT_LOCALLY`; an 81,920-character message: the server closed the socket (1009), so the 65,536 limit is really in force |
| **The game's own client** (Godot 4.7.2, the nakama-godot addon, `OnlineConfig.key_for`) through Caddy, with a temporary `override.cfg` trusting Caddy's local root | sign-in over `https://localhost:8443` 63–69 ms, socket `wss://localhost:8443` 61–62 ms, healthcheck RPC ok, a 32,768-byte piece host → guest intact in 56 ms. Control run without the CA: mbedTLS `-0x2700` (verification failed), so TLS is really checked |
| HTTP, headers | `http://` → `308` to `https://`; `Strict-Transport-Security: max-age=31536000`; no `Server` header |
| Backups | one at start (mode 600, owned by the kit's user); next at 03:30 UTC ("next backup in 1117 min", the busybox date parsing works); `kit.sh backup` 48 KiB |
| Restore round trip | account A made, backup, account B made, `kit.sh restore <file> --yes` (a `before-restore` backup first): A signs in (200), B is gone (404); 10 s |
| Rotation | 9 backups with `BACKUP_KEEP=3` leave 3; `backup.sh health` ok |
| `start.sh` refusals | defaults, a bad character, `admin`, a short password, two empty keys, equal session keys, bad runtime env pairs: 9 reasons, exit 78, nothing started (and `*` was not expanded) |
| Logs | `json-file`, `max-size 10m`, `max-file 5` on every service |
| Memory at rest | Nakama 22 MiB, PostgreSQL 58 MiB, Caddy 15 MiB, backup 2 MiB |

## The whole game over TLS, and a 40 ms stall found on the way

After the commit, two headless games (`tools/net_test.sh --server=https://localhost:8443`) played
through the kit with two temporary edits (both undone with `git checkout`, the tree checked clean):
`RELEASE_SERVER` set to the local try and NakamaLink sending `OnlineConfig.key_for(server)`, plus a
temporary `override.cfg` trusting Caddy's local root. **Every check passed** (edits both ways, undos,
the same world checksum over 9,216 blocks, the host's walk, pieces up to 886 KB packets).

But the ping was slow: steady median **103 ms** through Caddy with TLS against **34 ms** straight to
the development server at the same load (33). Narrowed down with a scratch echo test of the game's
own client (one message every 100 ms, the other player echoes it; load 9–21, 145 fps):

| Path | Round trip (median) | First leg A → B |
|---|---|---|
| `ws://` straight to Nakama | 13.9 ms | 7.1 ms |
| `ws://` through Caddy (plain HTTP site, experiment) | 14.0 ms | 7.1 ms |
| `wss://` through Caddy (TLS 1.3, the kit) | 55.3 ms | 41.9 ms |
| `wss://` through Caddy, TLS 1.2 only | 48.6 ms | 41.9 ms |
| `wss://`, `WebSocketPeer.set_no_delay(true)` **before** connecting | 55.3 ms | |
| `wss://`, `set_no_delay(true)` **after** the socket is open | **13.9 ms** | **7.1 ms** |

A packet capture on loopback shows why: over TLS, Godot writes a WebSocket frame's header and its
payload as two TLS records (27 bytes, then 138), Nagle's algorithm holds the second until the first is
acknowledged, and the server delays that ACK by 40 ms (Linux delayed ACK). The echo leg is quick only
because the server had just sent data on that connection. `set_no_delay(true)` called before
`connect_to_url` does not reach the TLS connection's socket; called once the socket is open, it does.
With that one line added (temporarily) in `NakamaLink.sign_in` after `connect_async`, the whole game
through the kit had a steady ping median of **21 ms** and the guest's placement round trip 36 ms
(135 ms without). Over the internet the stall is at least one network round trip per message on top
(Nagle waits for the ACK), so this matters more there than here. Not Caddy's fault (Node's client
through the same Caddy: 2–3 ms), not the TLS version.

## Relay load (sizing; `check/load.mjs` through Caddy with TLS, 60 s runs)

Each match: the host sends 20 messages/s of 300 bytes to every guest; each guest sends the same to the
host only (≈ 48 kbit/s of game data each way per guest: the spike's guest upload and §17.0's target).

| Players (matches × 4) | Load average before → after | Nakama CPU | Caddy CPU | PostgreSQL CPU | Received / expected | Nakama sent | Memory N / C / P |
|---|---|---|---|---|---|---|---|
| 40 (10) | 52 → 55 | 5.75 s / 62.9 s = 9.1 % of a core | 4.28 s = 6.8 % | 0.31 s | 71,760 / 71,760 | 50,182 KiB = 6.5 Mbit/s | 40 / 20 / 58 MiB |
| 100 (25) | 50 → 45 | 12.80 s / 63.1 s = 20.3 % | 10.10 s = 16.0 % | 0.33 s | 179,400 / 179,400 | 124,892 KiB = 16.2 Mbit/s | 49 / 30 / 58 MiB |

Linear: about 0.37 % of a desktop core per player (Nakama + Caddy), no message lost, about
160 kbit/s sent per player on the wire (a guest receives about 100 kbit/s, a host with 3 guests about
300: the JSON envelope with the sender's presence and base64 add about 230 bytes to each 300-byte
message). That is about 70 MB per player-hour. `docs/hosting.md` turns this into sizes and monthly
traffic. Two cautions: this PC was very busy (so CPU is pessimistic; a VPS core is slower, so it's
roughly a wash), and the model is not the game's real traffic: replace it with Agent A's measured
numbers when they arrive.

## Rulings (decisions made on the owner's behalf)

1. **Caddy with Let's Encrypt, and the server needs a name** (a domain, or a free DuckDNS name).
   Let's Encrypt certifies bare IP addresses since January 2026 (6-day `shortlived` certificates) and
   Caddy 2.11.4 can ask for them (`issuer acme { profile shortlived }` plus `default_sni`; an earlier
   Caddy refused, issue 7399), but the game's side is untested: whether Godot's mbedTLS checks an IP
   certificate and handles a handshake without a name. A name also lets the owner move servers without
   a new game version (the address is compiled into the game). *Cost if wrong:* the owner spends a
   minute on DuckDNS or about €10 a year on a domain; an IP option is two lines in the Caddyfile once
   tested.
2. **No ACME email.** Let's Encrypt stopped sending expiry emails in 2025 and Caddy renews by itself;
   one less thing for the owner to fill in. *Cost if wrong:* add `email` to the Caddyfile's global block.
3. **The console only through an SSH tunnel** (published on the VPS's 127.0.0.1). *Cost if wrong:* the
   owner runs one ssh command before reviewing reports; exposing it behind Caddy is a 5-line change,
   but then its login faces the whole internet.
4. **A release server key committed in the game and in `.env.example`**
   (`easycraft-3d4365aad6885d9a2e4bcc05`). It ships inside every APK, so it is not a secret; it only
   has to differ from `defaultkey`, which scanners try. *Cost if wrong:* a new key means a new game
   version (both files; the test checks they match).
5. **`RELEASE_SERVER` stays empty until the owner has a server;** release builds then have no online
   server (`default_server()` returns `{error}`) and the UI should say so kindly. *Cost if wrong:* the
   0.5.0 release APK can't play online until the owner finishes `docs/hosting.md`; developer builds and
   the emulator are unaffected.
6. **Release builds refuse any server that is not `https://`** (`release_server()`): children's
   accounts never cross the internet unencrypted. *Cost if wrong:* none known; a plain-http test server
   is still reachable from developer builds.
7. **Developer builds on Android default to `10.0.2.2`** (the emulator's name for this PC) instead of
   127.0.0.1, which on a phone is the phone itself. *Cost if wrong:* a debug APK on a real phone on the
   LAN still needs `--online-server` (as before).
8. **PostgreSQL `16-alpine` (latest 16.x) in production, `caddy:2.11-alpine`, `node:24-alpine`,
   Nakama pinned at 3.41.0.** Minor updates of the database and proxy are security fixes that
   `kit.sh update` should bring; the major versions stay fixed so the data volume and the module stay
   compatible. *Cost if wrong:* pin exact tags in two lines.
9. **Project name `easycraft_live`, never `easycraft`,** so the kit can never recreate the development
   server's containers on this PC. *Cost if wrong:* none.
10. **Backups keep the newest 7 per label (count, not age), checked before rotation.** A failing
    backup job never deletes good old backups. *Cost if wrong:* more disk if many manual backups are
    made (each label keeps 7).
11. **No access log in Caddy** (privacy: no record of who connected from where; spec §5.14). *Cost if
    wrong:* abuse is harder to trace to an address; Nakama still logs errors, and reports carry user ids.
12. **`EASYCRAFT_ENV=production` is always in the module's `ctx.env`,** so server code can refuse
    development-only behaviour (the fake consent provider) on the real server. *Cost if wrong:* none;
    the server agent's code has to read it (see "For the lead").
13. **Provider options: Hetzner CX23, OVHcloud VPS-1, DigitalOcean 2 GB** (prices from their pages and
    price notices on 2026-09-24, marked as estimates). *Cost if wrong:* the owner pays a few euros more
    or less; any Ubuntu VPS works with the kit.

## For the lead

**Integration (one line each, not mine to change):**
0. **Latency over wss (for Agent A / the lead):** in `NakamaLink.sign_in`, right after `connect_async`
   succeeds, add `ws.set_no_delay(true)` (the `WebSocketPeer` it already configures). Without it every
   message through TLS waits for a delayed ACK: round trip 55 ms instead of 14 ms on this PC, and
   worse over the internet (section above). It has to come after the socket is open. A test could
   assert it through the adapter's `_ws` only indirectly; the proof is the echo measurement above.
1. `net/nakama_link.gd` line 41 sends `OnlineConfig.SERVER_KEY` to every server. Change it to
   `OnlineConfig.key_for(server)`; until then the release server refuses release builds with
   "Server key invalid" (checked: `kit.sh check` with `defaultkey` gets 401). The scratch Godot run
   above used exactly that call.
2. Agent C's online service should take its server from `OnlineConfig.default_server()` and turn its
   `{error}` (a release build with no server yet) into plain words ("Online play is coming soon").
3. Agent B's consent adapter must never pick the fake provider when `ctx.env.EASYCRAFT_ENV ==
   "production"`; the provider's settings go into `.env` as `EASYCRAFT_RUNTIME_ENV="KEY=value ..."`.
   Runtime env entries in `server/nakama/local.yml` are not copied to production (on purpose).
4. When B's changes to `server/nakama/local.yml` touch the socket, session or `js_entrypoint`
   settings, `test_hosting_kit.gd` fails until `server/deploy/nakama/production.yml` matches.
5. With B's `MatchJoin` hook in, `kit.sh check` reports `relay SKIP ... join rules` (expected).

**Checks with two games (emulator + desktop):**
- On this PC, after items 0 and 1 are in (I ran it with both as temporary edits: all checks passed,
  steady ping 21 ms): the whole game over TLS through the kit. Start the local try (commands at the top
  of `server/deploy/local-try.yml`), set `RELEASE_SERVER` to `https://localhost:8443` for the run only
  (else `key_for` sends the development key), put a temporary `override.cfg` in the project root
  (`[network]` / `tls/certificate_bundle_override="<Caddy's root.crt>"`, copied out with
  `docker compose -p easycraft_d cp caddy:/data/caddy/pki/authorities/local/root.crt <file>`), run
  `tools/net_test.sh --server=https://localhost:8443`, then delete `override.cfg` and
  `docker compose -p easycraft_d down -v`. (The emulator can't trust Caddy's local CA; use the dev
  server for the emulator.)
- Once the owner has a server: set `RELEASE_SERVER`, run `kit.sh check` there, then a desktop
  developer build with `--online-server=release` and a release APK on the emulator play together.

## Suite

`tests/run_tests.sh` (12:58–13:08, load average 30–66, the development server up so its relay tests
ran): **178 scripts, 1750 tests, 1749 passing, 1 pending** (the same pending test as before), no
script errors, exit 0. Before: 177 scripts, 1733 tests, 1732 passing, 1 pending. +17 tests (10 in
`test_online_config.gd`, 7 in `test_hosting_kit.gd`). Afterwards `docker compose -p easycraft_d down -v`
removed the try (containers, volumes, network) and the `easycraft/nakama:local-try` image; the
development server (`easycraft`) and Agent B's `easycraft_b` were never touched. `node:24-alpine` and
`caddy:2.11-alpine` stay pulled (new tags no other project uses). The scripts' shellcheck (koalaman/shellcheck,
`-S warning`) is clean; the two changed test files re-ran green after the last script edits (31/31).
