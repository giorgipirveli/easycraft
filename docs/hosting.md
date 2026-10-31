# Hosting EasyCraft's online server

This is the owner's guide to putting EasyCraft's online server on the internet, so that friends can
play together from anywhere (spec §7.1, §11, §17). It takes about an hour the first time. Everything
the server needs is in `server/deploy/` (the **hosting kit**); `./kit.sh` does the daily work.

What it costs (estimates from 2026-09-24; check the prices before you buy):

| What | Estimate a month |
|---|---|
| A small server (VPS), step 1 | about €6 to $12 |
| The provider's own backups (optional, recommended) | about €1 to $4 |
| A domain name (optional: a free DuckDNS name works too) | about €1 (€10 to €15 a year) |

## How it fits together

```
the game on a phone ── https:// and wss:// on port 443 ──▶ Caddy ──▶ Nakama ──▶ PostgreSQL
                                                        (HTTPS)    (accounts,   (the database,
                                                                    friends,     backed up
                                                                    the relay)   every day)
```

- **The host's phone runs the world.** The server only signs players in, keeps accounts and friends,
  and relays the game's messages between the players of a match (spec §7.3). That is why a small
  server is enough.
- **Caddy** gets a free HTTPS certificate from Let's Encrypt by itself, renews it, and passes the
  game's requests and its realtime WebSocket to Nakama. Children's accounts never cross the internet
  unencrypted: release builds of the game only talk to the server over TLS (`https://` and `wss://`).
- **Only ports 80 and 443 are open to the world.** Nakama's developer console is on the server's own
  127.0.0.1 and you open it through SSH ("The console" below). The database is not reachable at all.
- **Secrets** (keys and passwords) live in one file, `server/deploy/.env`, on the server only. It is
  never committed to git and never sent to anyone.

## Step 1: Rent a small server (VPS)

Any VPS with 2 CPUs, 2 to 4 GB of memory, 40 GB of disk and Ubuntu 24.04 LTS is enough to start
(see "How big a server" below). Pick a location close to the players: for Georgia and Europe, a data
centre in Germany, Finland or Poland (about 50 to 70 ms away).

| Provider | Plan | CPU, memory, disk | Traffic included | Price a month (estimate, check it) | Good to know |
|---|---|---|---|---|---|
| **Hetzner Cloud** (hetzner.com/cloud) | CX23 | 2 vCPU, 4 GB, 40 GB NVMe | 20 TB | about €5.49 (after the June 2026 price change) + about €0.50 for the IPv4 address + VAT | Cheapest for what you get; Germany and Finland. Some sizes sell out: pick another location or the CX33 (4 vCPU, 8 GB, about €8.49). Backups: +20 % of the server price. |
| **OVHcloud** (ovhcloud.com/en/vps) | VPS-1 | 4 vCores, 8 GB, 75 GB NVMe | unlimited (up to 400 Mbit/s) | about $6.50 (after the March 2026 price change) | Most memory for the money; a daily backup of the last day is included. |
| **DigitalOcean** (digitalocean.com) | Basic Droplet 2 GB | 1 vCPU, 2 GB, 50 GB | 2 TB, then $0.01 per GB | $12 | The simplest control panel; Frankfurt. Backups: +20 % (weekly) or +30 % (daily). |

When you create the server:
1. Choose **Ubuntu 24.04 LTS**.
2. Add your **SSH key** (the provider shows how; on your PC `ssh-keygen -t ed25519` makes one). Then
   you never need a root password.
3. Turn on the provider's **backups** if you can afford them (a copy outside the server; see
   "Backups").
4. Write down the server's **IPv4 address** (for example `203.0.113.10`).

## Step 2: First login, Docker and the firewall

From your PC (replace the address with yours):

```bash
ssh root@203.0.113.10
```

On the server, as root:

```bash
apt update && apt upgrade -y                   # security updates (Ubuntu keeps installing them by itself)
adduser --disabled-password --gecos "" easycraft
usermod -aG sudo easycraft
mkdir -p /home/easycraft/.ssh && cp ~/.ssh/authorized_keys /home/easycraft/.ssh/
chown -R easycraft:easycraft /home/easycraft/.ssh
echo 'easycraft ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/easycraft

curl -fsSL https://get.docker.com | sh           # Docker and docker compose (Docker's own installer)
usermod -aG docker easycraft

ufw allow OpenSSH                                # the firewall: SSH, HTTP and HTTPS only
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

From now on log in as `easycraft`: `ssh easycraft@203.0.113.10`. Once that works, close the door for
root (still on the server): `sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo systemctl restart ssh`.

**About the firewall.** Docker opens the ports it publishes past `ufw`. That is why the kit publishes
only 80 and 443 (and the console on 127.0.0.1, which the internet can't reach). For a second lock
that Docker can't get past, also make a firewall in the provider's control panel (Hetzner: Firewalls;
DigitalOcean: Networking → Firewalls; OVHcloud: Network firewall) that lets in only **TCP 22, 80 and
443**. Never open 7349, 7350, 7351 or 5432.

## Step 3: A name for the server

The game talks to the server only over HTTPS, and the kit's HTTPS needs a name. (Since January 2026
Let's Encrypt also certifies bare IP addresses, with certificates that last 6 days, and Caddy 2.11.4
can ask for them. That path is not tested with the game yet: how the game checks an IP certificate,
and the handshake without a name. A name works everywhere, and it lets you move to another server
later without a new game version.) Pick one:

- **Your own domain** (for example `play.yourgame.com`): at the company where you bought the domain,
  add a DNS record of type **A**, name `play`, value = the server's IPv4 address.
- **A free DuckDNS name**: sign in at duckdns.org, make a sub domain (for example `easycraft-giorgi`),
  and put the server's IPv4 address in it. Your name is then `easycraft-giorgi.duckdns.org`.

Check it from your PC (it can take a few minutes to an hour to show):

```bash
nslookup play.yourgame.com          # must print the server's address
```

## Step 4: Copy the kit to the server

On the development PC, in the game's folder:

```bash
server/deploy/kit.sh pack           # makes build/server/easycraft-server-<date>.tar.gz (it prints the path)
scp build/server/easycraft-server-<date>.tar.gz easycraft@203.0.113.10:   # the path pack printed, nothing else
```
**Copy exactly the file `pack` printed**, never "the newest" by `ls -t`: on the development PC `ls` is an alias for
another tool that ignores `-t`, and on 2026-09-30 00:55 that put a five-day-old module (0.2.8) live for 25 seconds.
After `./kit.sh update`, `./kit.sh check`'s `rpc ok healthcheck` line must show the version in
`server/modules/src/main.ts` (`MODULE_VERSION`); if not, deploy the right file again at once.

On the server:

```bash
mkdir -p ~/easycraft && tar -xzf easycraft-server-*.tar.gz -C ~/easycraft
cd ~/easycraft/server/deploy
```

The pack has the kit (`server/deploy/`) and the server module's source (`server/modules/`); the
server builds the module itself. It never contains `.env`, backups or build output.

## Step 5: Make your `.env` (the secrets)

```bash
./kit.sh keys play.yourgame.com     # your name from step 3
```

This writes `.env` with a new random value for every secret and your server's name, readable only by
you. Then:
- Save a copy of `.env` in a password manager. It has the console password.
- Never commit it, paste it into a chat or send it by email: it holds the keys to every child's account.
- **Never change `POSTGRES_PASSWORD` after the first start**: the database keeps the password it was
  made with.
- `NAKAMA_SERVER_KEY` is already set: it must equal the key inside the game
  (`OnlineConfig.RELEASE_SERVER_KEY`). It is not a secret (it ships in the game), but it is not Nakama's
  well-known default, which scanners try on every server they find.

## Step 6: Start it

```bash
./kit.sh up
```

The first start takes a few minutes: it builds the server module, makes the database and asks Let's
Encrypt for the certificate. It waits until every part is healthy and then says `running`. The server
starts again by itself after a crash or a reboot. (`./kit.sh up` checks `.env` and then runs
`docker compose up -d --build --wait`; plain `docker compose` commands work in this folder too.)

## Step 7: Check it from the outside

```bash
./kit.sh check
```

It uses the server exactly as the game does and prints one line per step. All `ok` looks like:

```
CHECK https ok https://play.yourgame.com
CHECK sign-in ok two check players signed in with the server key
CHECK rpc ok healthcheck: {"ok":true,"module":"easycraft",...}
CHECK socket ok wss:// open, ping answered in 20 ms
CHECK big-message ok match ...: a 43692-character message was accepted
CHECK relay ok messages crossed both ways (guest to host 3 ms)
CHECK done: the server works
```

(`relay SKIP ... join rules` is fine too: it means the server refuses players who were not invited,
which the M4 server does on purpose.) The check signs in the same two "check" accounts every time.
If Node.js 22 or newer is on your PC, you can run the same check from home:
`node server/deploy/check/smoke.mjs https://play.yourgame.com <NAKAMA_SERVER_KEY>`.

## Step 8: Tell the game where the server is

In `core/net/online_config.gd`, put your address into one line:

```gdscript
const RELEASE_SERVER := "https://play.yourgame.com"
```

(or tell the lead / Claude "the server is at https://play.yourgame.com"). The key already matches.
From the next **release** APK on, the game plays online through your server. Developer builds keep
using the development server on the PC; a developer build can try the real server with the user arg
`--online-server=release`. A test (`test_the_release_server_in_the_game_is_empty_or_secure`) makes
sure the address is `https://`.

## Everyday commands

Run them in `~/easycraft/server/deploy` on the server.

| Command | What it does |
|---|---|
| `./kit.sh status` | what runs and whether it is healthy; the newest backups |
| `./kit.sh check` | tries the server from the outside, like the game |
| `./kit.sh logs` | follows every log (`./kit.sh logs nakama` for one part); Ctrl+C stops following |
| `./kit.sh access [lines]` | the access log's files and its newest lines (internet addresses, 14 days at most) |
| `./kit.sh backup` | makes a backup now |
| `./kit.sh restore <file>` | puts a backup back (asks first) |
| `./kit.sh update` | backs up, gets newer versions of the base images, rebuilds and restarts |
| `./kit.sh console` | how to open Nakama's console |
| `./kit.sh down` | stops everything (nothing is deleted); `./kit.sh up` starts it again |

**Updating the server module** (when the game's server code changed): pack and copy again (step 4),
unpack over the old folder (`.env` and `backups/` stay), then `./kit.sh update`.

**Updating the server itself**: Ubuntu installs security updates by itself. Once a month, run
`./kit.sh update` (newer PostgreSQL 16 and Caddy 2.11 fixes) and `sudo apt upgrade`. A new Nakama
version is a change in the game's repository (the `Dockerfile` and `server/docker-compose.yml`
together), tested on the development PC first.

### What the server's logs keep (M4 Task 8b)

| Log | What is in it | How long |
|---|---|---|
| Docker's logs of each part (`./kit.sh logs`) | Nakama's and Caddy's messages: starts, errors, account ids (random codes), never an internet address, a session token or the HTTP key (Caddy cuts them out) | at most 5 files of 10 MB per part, the oldest deleted (Docker counts size, not days) |
| Caddy's access log (`./kit.sh access`) | each request: the internet (IP) address, time, the path without its token, the answer's code; no device details | a new file every midnight (UTC); files are deleted after 12 days, so nothing in it is older than 14 days |
| Nakama's database | accounts and what the game keeps: see "The clean-up" below | the written policy: `docs/store/data-retention-and-security.md` |

The access log is for security (tracing someone who attacks the server), never for finding where a
child lives. It lives in the Docker volume `caddy_logs`; deleting that volume deletes it.

## The console

Nakama's developer console shows accounts, friends and the reports children send (spec §5.14:
reports are reviewed by a person). It is not on the internet. To open it, run this **on your PC**:

```bash
ssh -N -L 7351:127.0.0.1:7351 easycraft@203.0.113.10
```

then open http://127.0.0.1:7351 in your browser and log in with `NAKAMA_CONSOLE_USERNAME` and
`NAKAMA_CONSOLE_PASSWORD` from `.env` (`./kit.sh console` prints them). Ctrl+C in the ssh window
closes it again.

### Reports: reading and closing them

Children's reports are in the console: **Storage** → collection `reports` (owner: the system user,
`00000000-0000-0000-0000-000000000000`). Each report says who reported whom, the reason, and for a
chat message a copy of it (`message`: its `text` or `emote`, its time `at_ms`, and `source`: `server`
= the server's own copy, `reporter` = as the reporter's game showed it, when the server had none).
When you have dealt with one, open it, change `"status": "new"` to `"status": "reviewed"` and press
**Save**. The server deletes a reviewed report 12 months later (the copy of the message goes with it);
it writes the review time into the report (`reviewed_ms`) the next time the clean-up runs. A report
nobody marked as reviewed is kept.

A report about a **build** (a present, a bottle or a showcase; `"reason": "bad_build"`, `"scary"` or
`"other"`, and `"what"`) keeps the build in `build` (`source`: `server` = the showcase as the server had
it, `reporter` = as the child's game had it). The build is a text of letters; to see it, copy the text
after `"build":` into a file on your PC and run, in the game's folder:
`godot --headless --path . --script res://tools/show_build.gd -- --file=<that file>`. It prints how many
of each block and every layer from the ground up as letters. A showcase can also be taken down for the
player: API Explorer → `publish_showcase` with the player's User ID and the body `{"remove": true}`.

### A parent asks to delete an account

The game has this for grown-ups (SETTINGS → GROWN-UPS → the gate → ONLINE PLAY → DELETE MY ONLINE
ACCOUNT, hold the red button 3 seconds). When a parent e-mails instead (they may: Google Play and
COPPA require it), delete it from the console within 30 days:

1. Ask the parent for the child's **online name** (nothing else is needed; never ask for more).
2. Open the console (above) → **Accounts** → type the name into the search box → open the account and
   check the name. Note its **User ID**.
3. **API Explorer** → in the endpoint list, under the runtime functions, choose **delete_account**.
   Leave **User ID** empty. As the request body type `{"username": "TheName"}` and press **Send
   request**. The answer shows `"ok": true`, the `user_id` and `username` (check they are the child's)
   and a `"confirm"` code. Nothing is deleted yet.
4. Within 10 minutes, send again with the code: `{"username": "TheName", "confirm": "<the code>"}`.
   The answer says `"deleted": true`. The account, its friends, invites, chat history, backup,
   gold and codes are gone; reports the child made stay without their name.
5. Reply to the parent that it is done. The daily backups still hold the account for up to 8 days
   (then they are replaced), your provider's backups as long as they keep them.

The same from any terminal: `curl -s -X POST
'https://<your name>/v2/rpc/delete_account?http_key=<NAKAMA_RUNTIME_HTTP_KEY from .env>&unwrap' -d
'{"username": "TheName"}'` (it answers the same way; run it again with `"confirm"`). The HTTP key is
a secret: it goes only over HTTPS, and Caddy cuts it out of its logs.

The account page also has Nakama's own **Delete** button: it deletes the account and most of its data,
but not the child's name on reports they made, invites they sent and DMs with them; the next daily
clean-up removes those. Prefer the steps above.

### A family lost every device of an account (owner #67, module 0.2.12)

Normally a grown-up makes a **sign-in key** in the game (GROWN-UPS → ONLINE PLAY → OTHER DEVICES) and types it on
the new phone or browser (PLAY ONLINE → I HAVE AN ACCOUNT). When no device of the account is left (a lost phone, a
browser whose storage was cleared) and a parent writes in:

1. Ask the parent for the child's **online name** and something only the family knows about the account (for
   example what the child built or their buddy's name; never ask for personal data). If you are not sure it is
   the family, don't make a key.
2. **API Explorer** → **account_key**, User ID empty, body `{"action": "new", "username": "TheName"}` → the answer
   has `"key": "XXXX-XXXX"` (any key made before stops working). Or from a terminal: `curl -s -X POST
   'https://<your name>/v2/rpc/account_key?http_key=<NAKAMA_RUNTIME_HTTP_KEY from .env>&unwrap' -d
   '{"action": "new", "username": "TheName"}'`.
3. Send the parent the name and the key. On the new device: PLAY ONLINE → I HAVE AN ACCOUNT → the parent gate →
   the name and the key. The child's progress, looks and gold come back (worlds were only on the lost device).
4. `{"action": "state", "username": "TheName"}` shows whether a key exists and how many devices are signed in.
   Signing a lost phone out is the family's own step in the game (OTHER DEVICES → SIGN OUT OTHER DEVICES).

### The clean-up (what is deleted by itself)

Once a day (at the first sign-in after 24 hours) the server deletes: accounts nobody signed in to for
13 months (as above), chat messages older than 30 days, reports 12 months after their review, and
presents, bottles and guestbook stickers after 60 days. To
run it now: the console's **API Explorer** → **retention_run**, User ID empty, body `{}` → it answers
what it deleted (`"more": true` means there was more: run it again). The last run and its result are
in **Storage** → collection `activity`, key `retention`, owner the system user.

## Backups

- Every day at 03:30 UTC (`BACKUP_AT` in `.env`) the kit saves the whole database into
  `server/deploy/backups/` and keeps the newest 7 daily backups (`BACKUP_KEEP`). Each one is checked
  (it must read back) before older ones are deleted.
- `./kit.sh backup` makes one now; `restore` and `update` make one first by themselves
  (`before-restore-…`, `before-update-…`).
- **A backup on the same server is lost with the server.** Keep copies elsewhere: turn on the
  provider's backups (step 1), and now and then copy the folder to your PC:
  `scp -r easycraft@203.0.113.10:easycraft/server/deploy/backups ./easycraft-backups`
- Backups hold every child's username and account: keep the copies private and delete old ones.

**Restore** (for example after a mistake in the console):

```bash
./kit.sh status                                  # lists the backups
./kit.sh restore daily-20261001-033000.dump      # asks you to type RESTORE
```

It saves the present state first, stops Nakama, replaces the database with the backup, and starts
everything again (about 10 seconds for a small database). Accounts made after that backup are gone.
To move to a new server: set up steps 1 to 6 there, copy a backup into its `backups/` folder, and
restore it.

## How big a server; bandwidth and cost

**Measured on the development PC** (2026-09-24, with the kit running locally as it would on a server,
through Caddy with TLS; the PC was busy with a load average of about 50, so these are pessimistic).
A load generator played 25 relayed matches of 4 players for 60 seconds: every host sent 20 messages a
second of 300 bytes to its 3 guests, and every guest sent the same to its host (about 48 kbit/s of
game data each way per guest: what the spike measured for a guest, and the M4 target for what a guest
receives, spec §17.0).

| Players at once | Nakama CPU | Caddy (TLS) CPU | PostgreSQL CPU | Memory (Nakama + Caddy + PostgreSQL) | Messages lost | Server sent |
|---|---|---|---|---|---|---|
| 40 (10 matches) | 9 % of one core | 7 % | 0.5 % | 40 + 20 + 58 MB | 0 of 71,760 | 6.6 Mbit/s |
| 100 (25 matches) | 20 % of one core | 16 % | 0.5 % | 49 + 30 + 58 MB | 0 of 179,400 | 16.2 Mbit/s |

So each player playing costs about 0.4 % of a desktop CPU core, and the server sends about
**160 kbit/s per player** (about 100 kbit/s to a guest, 300 kbit/s to a host with 3 guests: the
JSON and base64 around each message more than double the game's own bytes). Estimates from that:

- **CPU:** a 2 vCPU server (slower cores than the PC) carries roughly 200 players playing at the same
  time with room to spare; the 4 vCPU plans roughly twice that. Memory is not the limit.
- **Traffic:** about **70 MB per player-hour**.

| Play a day (all players together) | Traffic a month (estimate) | Fits in |
|---|---|---|
| 50 player-hours (e.g. 25 children × 2 h) | about 105 GB | every plan above |
| 500 player-hours | about 1 TB | every plan above |
| 5,000 player-hours | about 10 TB | Hetzner (20 TB), OVHcloud (unlimited); DigitalOcean: 2 TB + about $90 |

These numbers hold only if M4's world sync works as planned (guests build the terrain from the seed
and get only the host's edits, spec §17.0). The M4 spike streamed the world instead and measured
**5–12 Mbit/s** while one guest flew: 2–5 GB per guest-hour, 30 to 75 times more (500 player-hours a
day would be 30–80 TB a month, and the host's phone upload could not keep up either). When Agent A's
measurements of the real game arrive, replace the model above with them (`server/deploy/check/load.mjs`
re-runs the load with other message sizes and rates).

## What the game needs

| In the game | Where | Value |
|---|---|---|
| The server's address | `OnlineConfig.RELEASE_SERVER` in `core/net/online_config.gd` | `"https://<your name>"`, empty until step 8 |
| The server key | `OnlineConfig.RELEASE_SERVER_KEY` | the same as `NAKAMA_SERVER_KEY` in `server/deploy/.env.example` (a test checks it) |
| TLS | automatic | release builds refuse anything but `https://`; the realtime socket then uses `wss://` |
| Which server a build uses | `OnlineConfig.default_server()` | release builds: `RELEASE_SERVER`; developer builds: this PC's server (`10.0.2.2` from the emulator) |

## Trying the kit on the development PC

`server/deploy/local-try.yml` runs the whole kit on a PC next to other projects: Caddy on
127.0.0.1:8480 and :8443 with its own local certificate, no console port, its own compose project.
The commands are at the top of that file. Never use the project name `easycraft` there (that is the
development server, `server/dev.sh`), and never run `./kit.sh update` on the PC.

## Trouble

| What you see | What to do |
|---|---|
| `kit: set EASYCRAFT_DOMAIN in .env` | Put your name from step 3 into `.env` (`nano .env`). |
| `check`: `https FAIL` | The name does not point at this server yet (step 3), or port 80/443 is closed (step 2, and the provider's firewall), or the certificate is still being made: `./kit.sh logs caddy`. |
| `check`: `sign-in FAIL ... Server key invalid` | `NAKAMA_SERVER_KEY` in `.env` is not the game's `RELEASE_SERVER_KEY`. |
| `check`: `rpc FAIL` | The server module did not load: `./kit.sh logs nakama`. |
| Nakama keeps restarting | `./kit.sh logs nakama`: lines starting with `start:` say which `.env` value is wrong. |
| Nakama can't reach the database after `.env` was edited | `POSTGRES_PASSWORD` was changed: put the old value back. |
| `too many certificates` from Let's Encrypt | Don't delete Docker volumes (`caddy_data` keeps the certificate); wait a few days. |
| The disk is full | `docker system df`, then `docker image prune` removes old images; check `backups/`. |
